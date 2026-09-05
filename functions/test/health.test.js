const test = require("node:test");
const assert = require("node:assert/strict");

const { buildHealthResponse, configuredProjectId } = require("../src/health");

test("healthCheck response identifies the configured Firebase project", () => {
  const response = buildHealthResponse({
    activeProjectId: "mirorr-d11b2",
    authenticated: true,
  });

  assert.equal(response.status, "ok");
  assert.equal(response.service, "mirror-scorpion-v4-functions");
  assert.equal(response.configuredProjectId, configuredProjectId);
  assert.equal(response.activeProjectId, "mirorr-d11b2");
  assert.equal(response.authenticated, true);
  assert.match(response.timestamp, /^\d{4}-\d{2}-\d{2}T/);
});

test("healthCheck response uses the local emulator label when no project is injected", () => {
  const response = buildHealthResponse();

  assert.equal(response.activeProjectId, "local-emulator");
  assert.equal(response.authenticated, false);
});
