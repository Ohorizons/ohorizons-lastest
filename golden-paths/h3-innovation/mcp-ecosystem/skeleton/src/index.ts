import { startHttpServer } from "./shared/server-factory.js";
import { registerSpecKitTools } from "./tools/spec-kit.js";
import { registerAnthropicsSkillsTools } from "./tools/anthropics-skills.js";
import { registerAwesomeCopilotTools } from "./tools/awesome-copilot.js";
import { registerAgentFrameworkTools } from "./tools/agent-framework.js";
import { registerGhAwTools } from "./tools/gh-aw.js";
import { registerAgentsMdTools } from "./tools/agents-md.js";
import { registerAnthropicDocsTools } from "./tools/anthropic-docs.js";
import { registerBackstageDocsTools } from "./tools/backstage-docs.js";
import { registerBackstagePluginsTools } from "./tools/backstage-plugins.js";
import { registerBackstageUiTools } from "./tools/backstage-ui.js";
import { registerSpotifyBackstageTools } from "./tools/spotify-backstage.js";
import { registerBackstageOrgTools } from "./tools/backstage-org.js";

await startHttpServer((server) => {
  // Agent & AI frameworks
  registerSpecKitTools(server);
  registerAnthropicsSkillsTools(server);
  registerAwesomeCopilotTools(server);
  registerAgentFrameworkTools(server);
  registerGhAwTools(server);
  registerAgentsMdTools(server);
  registerClaudeCodeTools(server);
  registerAnthropicDocsTools(server);

  // Backstage ecosystem
  registerBackstageDocsTools(server);
  registerBackstagePluginsTools(server);
  registerBackstageUiTools(server);
  registerSpotifyBackstageTools(server);
  registerBackstageOrgTools(server);
});
