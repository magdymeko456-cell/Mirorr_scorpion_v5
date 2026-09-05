const test = require("node:test");
const assert = require("node:assert/strict");

const {
  buildElevenLabsGatewayStatus,
  gatewayMode,
  validateFutureElevenLabsRequest,
} = require("../src/elevenlabs_gateway");

test("gateway stays disabled even if a future secret and budget flag exist", () => {
  const status = buildElevenLabsGatewayStatus({
    authenticated: true,
    hasApiKey: true,
    budgetApproved: true,
  });

  assert.equal(status.gatewayMode, gatewayMode);
  assert.equal(status.enabled, false);
  assert.equal(status.externalCallsAllowed, false);
  assert.match(status.message, /No text or audio is sent/);
});

test("future provider calls require an enabled gateway before any other condition", () => {
  const validation = validateFutureElevenLabsRequest({
    gatewayEnabled: false,
    hasApiKey: true,
    userId: "owner-1",
    operation: "instant_voice_clone",
    consentId: "consent-1",
    quotaRemaining: 1,
  });

  assert.deepEqual(validation, { allowed: false, code: "GATEWAY_DISABLED" });
});

test("future voice cloning requires a consent receipt after safe activation", () => {
  const validation = validateFutureElevenLabsRequest({
    gatewayEnabled: true,
    hasApiKey: true,
    userId: "owner-1",
    operation: "instant_voice_clone",
    quotaRemaining: 1,
  });

  assert.deepEqual(validation, { allowed: false, code: "CONSENT_REQUIRED" });
});
