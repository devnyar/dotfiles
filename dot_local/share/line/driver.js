// CDP driver: injects inject.js into the LINE app and serves DeepL translations
// over a CDP binding. The DeepL key lives only here, never in the page.
import CDP from 'chrome-remote-interface';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';

try { process.loadEnvFile('.env'); } catch { /* no .env yet */ }

const PORT = Number(process.env.CDP_PORT || 9222);
const LINE_ID = 'ophjlpahpchlmihnnnihgmmeilfjmjjc';
const KEY = process.env.DEEPL_API_KEY;
const API = (process.env.DEEPL_API_URL || 'https://api-free.deepl.com').replace(/\/$/, '');
const BRIDGE = '__lineTranslateBridge';

if (!KEY || KEY.includes('your-key-here')) {
  console.error('✗ DEEPL_API_KEY missing. Copy .env.example to .env and add your key.');
  process.exit(1);
}

const INJECT = readFileSync(new URL('./inject.js', import.meta.url), 'utf8');

// Translation cache, persisted to disk so identical messages are never
// re-translated — even across driver restarts (saves DeepL quota).
const CACHE_FILE = new URL('./cache.json', import.meta.url);
const cache = loadCache(); // text -> translated

function loadCache() {
  try {
    if (existsSync(CACHE_FILE)) return new Map(Object.entries(JSON.parse(readFileSync(CACHE_FILE, 'utf8'))));
  } catch { /* corrupt/empty cache — start fresh */ }
  return new Map();
}

function saveCache() {
  // Synchronous: the file is small and translation calls are infrequent, so
  // this guarantees the cache survives even an abrupt driver exit.
  try { writeFileSync(CACHE_FILE, JSON.stringify(Object.fromEntries(cache))); } catch { /* best effort */ }
}

async function deepl(text) {
  if (cache.has(text)) return cache.get(text);
  const res = await fetch(`${API}/v2/translate`, {
    method: 'POST',
    headers: {
      Authorization: `DeepL-Auth-Key ${KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ text: [text], source_lang: 'TH', target_lang: 'EN-US' }),
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`DeepL ${res.status}: ${body.slice(0, 140)}`);
  }
  const data = await res.json();
  const out = data.translations?.[0]?.text ?? '';
  cache.set(text, out);
  saveCache();
  return out;
}

function findLineTarget(targets) {
  return targets.find(t => t.type === 'page' && t.url.includes(LINE_ID));
}

async function attach() {
  const targets = await CDP.List({ host: '127.0.0.1', port: PORT });
  const target = findLineTarget(targets);
  if (!target) throw new Error('LINE page target not found. Run ./launch-line.sh first.');

  const client = await CDP({ target: target.webSocketDebuggerUrl });
  const { Runtime, Page } = client;
  await Runtime.enable();
  await Page.enable();
  await Runtime.addBinding({ name: BRIDGE });

  // Register event handlers BEFORE injecting. inject.js fires bridge calls
  // synchronously during its initial sweep, so the listener must already be
  // attached or those early events are lost.
  Runtime.bindingCalled(async ({ name, payload }) => {
    if (name !== BRIDGE) return;
    let id, text;
    try { ({ id, text } = JSON.parse(payload)); } catch { return; }
    try {
      const translated = await deepl(text);
      await apply(Runtime, id, translated, null);
      console.log(`✓ ${text.slice(0, 30)} → ${translated.slice(0, 40)}`);
    } catch (e) {
      await apply(Runtime, id, null, e.message);
      console.error(`✗ ${text.slice(0, 30)}: ${e.message}`);
    }
  });

  Page.frameNavigated(async ({ frame }) => {
    if (!frame.parentId) {
      // top-level navigation: addScriptToEvaluateOnNewDocument handles it,
      // but evaluate again as a safety net once the doc settles.
      setTimeout(() => Runtime.evaluate({ expression: INJECT }).catch(() => {}), 500);
    }
  });

  // Re-inject on every document (covers reloads / navigation within the app).
  await Page.addScriptToEvaluateOnNewDocument({ source: INJECT });
  // Reset any state from a previous driver, then inject fresh against THIS
  // process's live bridge so existing on-screen messages get re-scanned.
  await Runtime.evaluate({ expression: `(()=>{
    window.__lineThaiXlateLoaded=false;
    document.querySelectorAll('.thaixlate').forEach(b=>b.remove());
    document.querySelectorAll('[data-thaixlate]').forEach(w=>w.removeAttribute('data-thaixlate'));
  })()` });
  await Runtime.evaluate({ expression: INJECT });

  client.on('disconnect', () => {
    console.error('• CDP disconnected (LINE closed/restarted). Will reconnect when it returns…');
    connectLoop(); // resume the retry loop instead of dying
  });

  console.log(`✓ Attached to LINE. DeepL endpoint: ${API}. Watching for incoming Thai messages…`);
  return client;
}

async function apply(Runtime, id, translated, error) {
  const expr = `window.__lineApplyTranslation(${JSON.stringify(id)}, ${JSON.stringify(translated)}, ${JSON.stringify(error)})`;
  await Runtime.evaluate({ expression: expr }).catch(() => {});
}

// Keep trying to attach. Survives LINE not running yet, or being closed and
// reopened — never exits on a refused connection.
let connecting = false;
async function connectLoop() {
  if (connecting) return;
  connecting = true;
  let warned = false;
  while (true) {
    try {
      await attach();
      connecting = false;
      return;
    } catch (e) {
      if (!warned) {
        console.error(`… waiting for LINE on :${PORT} (${e.message}). Run ./launch-line.sh ${PORT}`);
        warned = true;
      }
      await new Promise(r => setTimeout(r, 2000));
    }
  }
}

connectLoop();
