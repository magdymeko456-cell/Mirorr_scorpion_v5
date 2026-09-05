const configuredProjectId = "mirorr-d11b2";

function buildHealthResponse({ activeProjectId, authenticated = false } = {}) {
  return {
    status: "ok",
    service: "mirror-scorpion-v4-functions",
    configuredProjectId,
    activeProjectId: activeProjectId || "local-emulator",
    authenticated,
    timestamp: new Date().toISOString(),
  };
}

module.exports = { buildHealthResponse, configuredProjectId };
