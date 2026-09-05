const gatewayMode = "disabled_pending_owner_budget";

function buildElevenLabsGatewayStatus({
  hasApiKey = false,
  budgetApproved = false,
  authenticated = false,
} = {}) {
  return {
    provider: "ElevenLabs",
    gatewayMode,
    enabled: false,
    externalCallsAllowed: false,
    authenticated,
    hasApiKey,
    budgetApproved,
    message:
      "ElevenLabs gateway is intentionally disabled. No text or audio is sent to the provider.",
  };
}

function validateFutureElevenLabsRequest({
  gatewayEnabled = false,
  hasApiKey = false,
  userId,
  operation,
  consentId,
  quotaRemaining = 0,
} = {}) {
  if (!gatewayEnabled) {
    return { allowed: false, code: "GATEWAY_DISABLED" };
  }
  if (!hasApiKey) {
    return { allowed: false, code: "SERVER_SECRET_MISSING" };
  }
  if (typeof userId !== "string" || userId.length === 0) {
    return { allowed: false, code: "AUTH_REQUIRED" };
  }
  if (quotaRemaining <= 0) {
    return { allowed: false, code: "QUOTA_EXHAUSTED" };
  }
  if (operation === "instant_voice_clone" && !consentId) {
    return { allowed: false, code: "CONSENT_REQUIRED" };
  }
  return { allowed: true, code: "APPROVED_FOR_PROVIDER_CALL" };
}

module.exports = {
  buildElevenLabsGatewayStatus,
  gatewayMode,
  validateFutureElevenLabsRequest,
};
