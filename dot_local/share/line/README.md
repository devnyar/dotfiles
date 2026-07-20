# LINE Thai → English in-app translator

Injects an English translation underneath every **incoming** Thai message in the
LINE Chromium app (`chrome-extension://ophjlpahpchlmihnnnihgmmeilfjmjjc`). Your
own (outgoing) messages and non-Thai messages are left untouched.

## How it works

LINE on Linux runs as a Chromium *extension* app. Chrome won't let a separate
extension inject into another extension's page, so instead we drive the running
app over the Chrome DevTools Protocol (CDP):

- `launch-line.sh` relaunches the LINE app with `--remote-debugging-port` (your
  login persists — it's the same Chromium profile).
- `driver.js` connects via CDP, injects `inject.js` into the page, and exposes a
  translation bridge. **The DeepL API key lives only in `driver.js`/`.env`, never
  in the page.**
- `inject.js` watches the chat DOM. For each incoming bubble
  (`data-direction=""`) whose text contains Thai (U+0E00–U+0E7F), it asks the
  driver to translate and renders the result below the message.

## Setup

```bash
cp .env.example .env      # then put your DeepL key in .env (free keys end in :fx)
npm install
```

## Run

### Automatic (the installed setup)

Two pieces make it fully hands-off:

1. `~/.local/share/applications/line.desktop` launches LINE with
   `--remote-debugging-port=9222`, so opening LINE *any* way (search bar, dock)
   is debug-enabled.
2. `~/.config/hypr/autostart.conf` runs `autostart-driver.sh` at login. The
   driver waits for LINE on the debug port and attaches whenever it opens —
   surviving LINE being closed and reopened.

So: just open LINE like normal; translations appear. Nothing to start by hand.

### Manual (dev / one-off)

```bash
./start.sh                # launches LINE + the translator together
# or:
./launch-line.sh          # relaunch LINE with debugging on :9222
node driver.js            # start translating
```

> **Note:** the kill-and-relaunch must happen inside a script (`launch-line.sh`),
> not as a bare `pkill -f -- '--app=…'` in your shell — that pattern matches the
> running shell's own command line and kills it.

## Notes

- Translations are cached per message text, so repeats don't burn DeepL quota.
  Check usage: free tier is 500k chars/month.
- Targeting relies on LINE's obfuscated class names (e.g.
  `textMessageContent-module__text__…`). A LINE update can change these; if
  translations stop appearing, the selectors in `inject.js` need refreshing.
- This is dev-mode (debug port). To make it permanent without keeping a debug
  port open, the same `inject.js` can be baked into a forked unpacked extension.
