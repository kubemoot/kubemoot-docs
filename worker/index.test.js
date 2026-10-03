// Run: node --test worker/index.test.js
import test from "node:test";
import assert from "node:assert/strict";
import worker, { redirectTarget } from "./index.js";

test("www redirects to the apex and keeps path and query", () => {
  assert.equal(
    redirectTarget("https://www.kubemoot.org/docs/introduction/quickstart/?a=1"),
    "https://kubemoot.org/docs/introduction/quickstart/?a=1",
  );
  assert.equal(redirectTarget("https://www.kubemoot.org/"), "https://kubemoot.org/");
});

test("the apex and other hosts are not redirected", () => {
  assert.equal(redirectTarget("https://kubemoot.org/docs/"), null);
  assert.equal(redirectTarget("https://notwww.kubemoot.org/"), null);
  assert.equal(redirectTarget("https://www.kubemoot.org.example.com/"), null);
});

test("fetch answers www with a 301 to the apex", async () => {
  const res = await worker.fetch(new Request("https://www.kubemoot.org/docs/x/"), {
    ASSETS: { fetch: () => assert.fail("assets must not be read for www") },
  });
  assert.equal(res.status, 301);
  assert.equal(res.headers.get("location"), "https://kubemoot.org/docs/x/");
});

test("fetch hands the apex to the static assets unchanged", async () => {
  const req = new Request("https://kubemoot.org/nope/");
  const asset = new Response("missing", { status: 404 });
  const res = await worker.fetch(req, { ASSETS: { fetch: (r) => (r === req ? asset : null) } });
  assert.equal(res.status, 404);
});
