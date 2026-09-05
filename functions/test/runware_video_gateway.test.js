const assert = require('node:assert/strict');
const test = require('node:test');

const {
  buildRunwareVideoGatewayStatus,
  runwareDeliveryMethod,
  runwareOutputFormat,
  runwareTaskType,
  runwareVideoGatewayMode,
  validateFutureRunwareVideoRequest,
} = require('../src/runware_video_gateway');

test('Runware gateway remains disabled even if a future secret and quota are present', () => {
  const status = buildRunwareVideoGatewayStatus({
    authenticated: true,
    hasApiKey: true,
    monthlyCapUsd: 25,
    dailyJobLimit: 2,
  });

  assert.equal(status.provider, 'Runware');
  assert.equal(status.gatewayMode, runwareVideoGatewayMode);
  assert.equal(status.taskType, runwareTaskType);
  assert.equal(status.deliveryMethod, runwareDeliveryMethod);
  assert.equal(status.outputFormat, runwareOutputFormat);
  assert.equal(status.enabled, false);
  assert.equal(status.externalCallsAllowed, false);
  assert.match(status.message, /No story, image, audio, or video is sent/);
});

test('Runware rejects a request before every provider-side condition while disabled', () => {
  const result = validateFutureRunwareVideoRequest({
    gatewayEnabled: false,
    hasApiKey: true,
    userId: 'owner-1',
    consentReceiptId: 'consent-1',
    quotaRemaining: 1,
  });

  assert.deepEqual(result, { allowed: false, code: 'GATEWAY_DISABLED' });
});

test('Runware future task requires explicit consent, a positive quota, async delivery, MP4, and text-only input', () => {
  const noConsent = validateFutureRunwareVideoRequest({
    gatewayEnabled: true,
    hasApiKey: true,
    userId: 'owner-1',
    quotaRemaining: 1,
  });
  assert.deepEqual(noConsent, { allowed: false, code: 'CONSENT_REQUIRED' });

  const wrongScope = validateFutureRunwareVideoRequest({
    gatewayEnabled: true,
    hasApiKey: true,
    userId: 'owner-1',
    consentReceiptId: 'consent-1',
    quotaRemaining: 1,
    deliveryMethod: 'sync',
    inputKind: 'image',
  });
  assert.deepEqual(wrongScope, { allowed: false, code: 'ASYNC_TASK_CONTRACT_REQUIRED' });
});
