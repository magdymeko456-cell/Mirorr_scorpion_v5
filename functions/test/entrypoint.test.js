const test = require("node:test");
const assert = require("node:assert/strict");

test("Functions entrypoint loads safe callables without a service-account file", () => {
  const functions = require("../index");

  assert.equal(typeof functions.healthCheck, "function");
  assert.equal(typeof functions.elevenLabsGatewayStatus, "function");
  assert.equal(typeof functions.runwareVideoGatewayStatus, "function");
});
