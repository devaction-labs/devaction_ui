import test from "node:test"
import assert from "node:assert/strict"
import Editor from "./editor.js"
import {hostNames, uploadHeaders} from "./editor_logic.js"

const line = () => ({textContent: "", hidden: true})

const build = (dataset = {}) => {
  const status = line()
  const parts = {"[data-editor-status]": status}
  const calls = {pushed: [], chain: []}
  const chain = new Proxy(
    {},
    {
      get: (_target, name) => (...args) => {
        calls.chain.push([name, ...args])
        return name === "run" ? true : chain
      },
    },
  )
  const hook = {
    ...Editor,
    el: {
      id: "e",
      dataset: {uploadUrl: "/uploads", uploadMax: "1000", uploadErrors: '{"failed":"Could not send"}', ...dataset},
      querySelector: (selector) => parts[selector] ?? null,
      querySelectorAll: () => [],
    },
    editor: {chain: () => chain, getMarkdown: () => "# draft"},
    pushEventTo: (target, event, payload) => calls.pushed.push([target, event, payload]),
  }
  return {hook, status, calls, parts}
}

const withBrowser = ({token, fetch}, run) => {
  const saved = {document: globalThis.document, location: globalThis.location, fetch: globalThis.fetch}
  globalThis.document = {
    querySelector: (selector) => (selector === `meta[name='${token.name}']` ? {getAttribute: () => token.value} : null),
  }
  globalThis.location = {href: "http://app.test/page", origin: "http://app.test"}
  globalThis.fetch = fetch
  return Promise.resolve(run()).finally(() => Object.assign(globalThis, saved))
}

const image = {name: "photo.png", type: "image/png", size: 10}
const picked = (file) => ({files: [file], value: "x"})

test("the names of the host have Phoenix's defaults and can be replaced", () => {
  assert.deepEqual(hostNames({}), {
    csrfMeta: "csrf-token",
    csrfHeader: "x-csrf-token",
    improve: "improve",
    replace: "editor:replace",
    failed: "editor:failed",
  })
  assert.deepEqual(
    hostNames({csrfMeta: "xsrf", csrfHeader: "x-xsrf", improveEvent: "rewrite", replaceEvent: "r", failedEvent: "f"}),
    {csrfMeta: "xsrf", csrfHeader: "x-xsrf", improve: "rewrite", replace: "r", failed: "f"},
  )
})

test("the upload headers carry the token in the header asked for, or an empty one", () => {
  assert.deepEqual(uploadHeaders({token: "abc", csrfHeader: "x-xsrf", type: "image/png"}), {
    "x-xsrf": "abc",
    "content-type": "image/png",
  })
  assert.deepEqual(uploadHeaders({token: undefined, csrfHeader: "x-csrf-token", type: "image/gif"}), {
    "x-csrf-token": "",
    "content-type": "image/gif",
  })
})

test("an image is sent with the token of the meta and the header the element names", async () => {
  const {hook, calls} = build({csrfMeta: "xsrf", csrfHeader: "x-xsrf"})
  const requests = []
  const fetch = async (target, options) => {
    requests.push([String(target), options])
    return {ok: true, json: async () => ({url: "/img/1.png"})}
  }

  await withBrowser({token: {name: "xsrf", value: "secret"}, fetch}, () => hook.upload(picked(image)))

  assert.equal(requests.length, 1)
  assert.equal(requests[0][0], "http://app.test/uploads")
  assert.equal(requests[0][1].headers["x-xsrf"], "secret")
  assert.equal(requests[0][1].headers["content-type"], "image/png")
  assert.deepEqual(calls.chain.find(([name]) => name === "setImage"), ["setImage", {src: "/img/1.png", alt: "photo"}])
})

test("the defaults send x-csrf-token from the csrf-token meta", async () => {
  const {hook} = build()
  const requests = []
  const fetch = async (_target, options) => {
    requests.push(options)
    return {ok: true, json: async () => ({url: "/img/2.png"})}
  }

  await withBrowser({token: {name: "csrf-token", value: "t0k"}, fetch}, () => hook.upload(picked(image)))

  assert.equal(requests[0].headers["x-csrf-token"], "t0k")
})

test("a file that is not an image, or too large, is refused before anything is sent", async () => {
  const {hook, status} = build({uploadErrors: '{"unsupported":"Not an image","too_large":"Too large"}'})
  let sent = 0
  const fetch = async () => (sent += 1)

  await withBrowser({token: {name: "csrf-token", value: "t"}, fetch}, async () => {
    await hook.upload(picked({name: "a.txt", type: "text/plain", size: 1}))
    assert.equal(status.textContent, "Not an image")
    await hook.upload(picked({...image, size: 5000}))
    assert.equal(status.textContent, "Too large")
  })

  assert.equal(sent, 0)
  assert.equal(status.hidden, false)
})

test("a failed answer shows what the server said, and a broken request says it failed", async () => {
  const {hook, status} = build({uploadErrors: '{"too_large":"Too large","failed":"Could not send"}'})

  await withBrowser(
    {
      token: {name: "csrf-token", value: "t"},
      fetch: async () => ({ok: false, json: async () => ({error: "too_large"})}),
    },
    () => hook.upload(picked(image)),
  )
  assert.equal(status.textContent, "Too large")

  await withBrowser(
    {
      token: {name: "csrf-token", value: "t"},
      fetch: async () => {
        throw new Error("offline")
      },
    },
    () => hook.upload(picked(image)),
  )
  assert.equal(status.textContent, "Could not send")
})

test("an upload address on another origin is not used", async () => {
  const {hook, status} = build({uploadUrl: "https://evil.test/up"})
  let sent = 0

  await withBrowser(
    {token: {name: "csrf-token", value: "t"}, fetch: async () => (sent += 1)},
    () => hook.upload(picked(image)),
  )

  assert.equal(sent, 0)
  assert.equal(status.textContent, "Could not send")
})

test("improve sends the Markdown as the event the element names, once", () => {
  const {hook, calls} = build({improveEvent: "rewrite", aiLabels: '{"working":"Working"}'})
  const button = {disabled: false}

  hook.improve(button)
  hook.improve(button)

  assert.deepEqual(calls.pushed, [["#e", "rewrite", {markdown: "# draft"}]])
  assert.equal(button.disabled, true)
})

test("improve does nothing for an empty text", () => {
  const {hook, calls} = build()
  hook.editor.getMarkdown = () => "  "
  hook.improve({disabled: false})
  assert.deepEqual(calls.pushed, [])
})

test("the answer replaces the text only for this editor and frees the button", () => {
  const {hook, calls} = build({aiLabels: '{"done":"Done"}'})
  const button = {disabled: true}
  hook.el.querySelectorAll = () => [button]

  hook.replace({id: "other", markdown: "x"})
  assert.equal(calls.chain.length, 0)

  hook.replace({id: "e", markdown: "better"})
  assert.deepEqual(calls.chain.find(([name]) => name === "setContent"), ["setContent", "better", {contentType: "markdown"}])
  assert.equal(button.disabled, false)
})
