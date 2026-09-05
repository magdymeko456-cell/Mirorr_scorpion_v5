const runwareVideoGatewayMode = 'disabled-by-owner-policy';
const runwareTaskType = 'videoInference';
const runwareDeliveryMethod = 'async';
const runwareOutputFormat = 'MP4';

function buildRunwareVideoGatewayStatus({
  authenticated = false,
  hasApiKey = false,
  monthlyCapUsd = 0,
  dailyJobLimit = 0,
} = {}) {
  return {
    provider: 'Runware',
    gatewayMode: runwareVideoGatewayMode,
    taskType: runwareTaskType,
    deliveryMethod: runwareDeliveryMethod,
    outputFormat: runwareOutputFormat,
    model: null,
    enabled: false,
    externalCallsAllowed: false,
    authenticated,
    hasApiKey,
    monthlyCapUsd,
    dailyJobLimit,
    retentionPolicy: 'UNDECIDED',
    cancellationPolicy: 'NO_PROVIDER_CANCELLATION_CLAIM',
    message:
      'Runware video gateway is intentionally disabled. No story, image, audio, or video is sent to Runware.',
  };
}

function validateFutureRunwareVideoRequest({
  gatewayEnabled = false,
  hasApiKey = false,
  userId,
  consentReceiptId,
  quotaRemaining = 0,
  taskType = runwareTaskType,
  deliveryMethod = runwareDeliveryMethod,
  outputFormat = runwareOutputFormat,
  inputKind = 'text-only',
} = {}) {
  if (!gatewayEnabled) return { allowed: false, code: 'GATEWAY_DISABLED' };
  if (!hasApiKey) return { allowed: false, code: 'SERVER_SECRET_MISSING' };
  if (typeof userId !== 'string' || userId.trim().isEmpty) {
    return { allowed: false, code: 'AUTH_REQUIRED' };
  }
  if (typeof consentReceiptId !== 'string' || consentReceiptId.trim().isEmpty) {
    return { allowed: false, code: 'CONSENT_REQUIRED' };
  }
  if (!Number.isInteger(quotaRemaining) || quotaRemaining <= 0) {
    return { allowed: false, code: 'QUOTA_EXHAUSTED' };
  }
  if (taskType !== runwareTaskType || deliveryMethod !== runwareDeliveryMethod) {
    return { allowed: false, code: 'ASYNC_TASK_CONTRACT_REQUIRED' };
  }
  if (outputFormat !== runwareOutputFormat || inputKind !== 'text-only') {
    return { allowed: false, code: 'POLICY_SCOPE_EXCEEDED' };
  }
  return { allowed: true, code: 'APPROVED_FOR_SERVER_QUEUING_ONLY' };
}

module.exports = {
  buildRunwareVideoGatewayStatus,
  runwareDeliveryMethod,
  runwareOutputFormat,
  runwareTaskType,
  runwareVideoGatewayMode,
  validateFutureRunwareVideoRequest,
};
