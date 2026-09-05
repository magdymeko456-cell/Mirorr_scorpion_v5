const { onCall } = require("firebase-functions/v2/https");
const { logger } = require("firebase-functions");
const { initializeApp } = require("firebase-admin/app");

const { buildHealthResponse } = require("./src/health");
const { buildElevenLabsGatewayStatus } = require("./src/elevenlabs_gateway");
const { buildRunwareVideoGatewayStatus } = require("./src/runware_video_gateway");

// تعتمد Cloud Functions على هوية بيئة التشغيل الافتراضية.
// لا تُضف serviceAccountKey.json أو أي مفتاح خاص إلى المشروع.
initializeApp();

exports.healthCheck = onCall({ region: "us-central1" }, (request) => {
  const response = buildHealthResponse({
    activeProjectId: process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT,
    authenticated: request.auth != null,
  });

  logger.info("Mirror Scorpion healthCheck completed", {
    activeProjectId: response.activeProjectId,
    authenticated: response.authenticated,
  });

  return response;
});

// لا ينفذ هذا المسار أي طلب إلى ElevenLabs. يثبت فقط أن وضع البوابة
// يبقى مغلقاً إلى أن يعتمد المالك الميزانية والخادم ومفتاح الخدمة.
exports.elevenLabsGatewayStatus = onCall({ region: "us-central1" }, (request) => {
  const response = buildElevenLabsGatewayStatus({
    authenticated: request.auth != null,
    hasApiKey: Boolean(process.env.ELEVENLABS_API_KEY),
    budgetApproved: false,
  });

  logger.info("Mirror Scorpion ElevenLabs gateway status checked", {
    authenticated: response.authenticated,
    enabled: response.enabled,
  });

  return response;
});

// لا ينفذ هذا المسار أي طلب فيديو. لا يُفعل Runware إلا بعد سقف مالي صريح
// ومفتاح مخزن في الخادم وموافقة مرئية قابلة للتدقيق لكل طلب.
exports.runwareVideoGatewayStatus = onCall({ region: "us-central1" }, (request) => {
  const response = buildRunwareVideoGatewayStatus({
    authenticated: request.auth != null,
    hasApiKey: Boolean(process.env.RUNWARE_API_KEY),
    monthlyCapUsd: 0,
    dailyJobLimit: 0,
  });

  logger.info("Mirror Scorpion Runware video gateway status checked", {
    authenticated: response.authenticated,
    enabled: response.enabled,
  });

  return response;
});
