// Runs INSIDE the LINE extension page. Detects incoming Thai messages and
// renders an English translation underneath each one.
// Translation itself is done in Node (driver.js) so the DeepL key never enters
// the page. We talk to Node through a CDP binding (window.__lineTranslateBridge).
(() => {
  if (window.__lineThaiXlateLoaded) return;
  window.__lineThaiXlateLoaded = true;

  const THAI = /[฀-๿]/;
  const TEXT_SEL = 'pre[class*="textMessageContent-module__text__"]';
  const WRAP_SEL = '[class*="textMessageContent-module__content_wrap__"]';
  const MSG_SEL = '[class*="messageLayout-module__message__"]';

  // Inject styling for the translation block once.
  const style = document.createElement('style');
  style.textContent = `
    .thaixlate {
      margin-top: 4px;
      padding: 4px 8px;
      border-left: 2px solid #06c755;
      background: rgba(6,199,85,0.08);
      border-radius: 4px;
      font-size: 0.92em;
      line-height: 1.35;
      color: #2b2b2b;
      white-space: pre-wrap;
      word-break: break-word;
    }
    .thaixlate__label {
      font-size: 0.72em;
      font-weight: 600;
      letter-spacing: 0.04em;
      color: #06c755;
      opacity: 0.85;
      margin-right: 6px;
    }
    .thaixlate--pending { opacity: 0.55; font-style: italic; }
    .thaixlate--error { border-left-color: #e0245e; background: rgba(224,36,94,0.08); }
    .thaixlate--error .thaixlate__label { color: #e0245e; }
  `;
  document.documentElement.appendChild(style);

  // Find the text element of an *incoming* message bubble that contains Thai.
  function eligibleText(wrap) {
    const msg = wrap.closest(MSG_SEL);
    if (!msg) return null;
    // Incoming = data-direction === "" ; outgoing = "reverse"
    if (msg.getAttribute('data-direction') === 'reverse') return null;
    const pre = wrap.querySelector(TEXT_SEL);
    if (!pre) return null;
    const text = pre.innerText.trim();
    if (!text || !THAI.test(text)) return null;
    return text;
  }

  function ensureBlock(wrap) {
    let block = wrap.parentElement.querySelector(':scope > .thaixlate');
    if (!block) {
      block = document.createElement('div');
      block.className = 'thaixlate thaixlate--pending';
      block.innerHTML = '<span class="thaixlate__label">TH→EN</span><span class="thaixlate__body">translating…</span>';
      wrap.insertAdjacentElement('afterend', block);
    }
    return block;
  }

  function process(wrap) {
    if (wrap.dataset.thaixlate) return;
    const text = eligibleText(wrap);
    if (!text) return;
    const id = wrap.getAttribute('data-message-id') || ('t' + Math.abs(hash(text)));
    wrap.dataset.thaixlate = id;
    ensureBlock(wrap);
    // Ask Node to translate. Fire-and-forget; result comes via applyTranslation.
    try {
      window.__lineTranslateBridge(JSON.stringify({ id, text }));
    } catch (e) {
      applyTranslation(id, null, 'bridge unavailable — is driver.js running?');
    }
  }

  // Called by Node (driver.js) once a translation is ready.
  window.__lineApplyTranslation = function (id, translated, error) {
    applyTranslation(id, translated, error);
  };

  function applyTranslation(id, translated, error) {
    const wrap = document.querySelector(`${WRAP_SEL}[data-message-id="${cssEsc(id)}"]`)
      || [...document.querySelectorAll(WRAP_SEL)].find(w => w.dataset.thaixlate === id);
    if (!wrap) return;
    const block = wrap.parentElement.querySelector(':scope > .thaixlate');
    if (!block) return;
    const body = block.querySelector('.thaixlate__body');
    if (error) {
      block.className = 'thaixlate thaixlate--error';
      body.textContent = error;
    } else {
      block.className = 'thaixlate';
      body.textContent = translated;
    }
  }

  function scan(root) {
    const wraps = (root.matches && root.matches(WRAP_SEL)) ? [root] : root.querySelectorAll?.(WRAP_SEL) || [];
    wraps.forEach && wraps.forEach(process);
    if (root.matches && root.matches(WRAP_SEL)) process(root);
  }

  // Initial sweep.
  document.querySelectorAll(WRAP_SEL).forEach(process);

  // Observe new/changed messages.
  const obs = new MutationObserver(muts => {
    for (const m of muts) {
      for (const node of m.addedNodes) {
        if (node.nodeType !== 1) continue;
        if (node.matches?.(WRAP_SEL)) process(node);
        node.querySelectorAll?.(WRAP_SEL).forEach(process);
      }
    }
  });
  obs.observe(document.body, { childList: true, subtree: true });

  function hash(s) { let h = 0; for (let i = 0; i < s.length; i++) { h = (h * 31 + s.charCodeAt(i)) | 0; } return h; }
  function cssEsc(s) { return String(s).replace(/["\\]/g, '\\$&'); }

  console.log('[thaixlate] injected');
})();
