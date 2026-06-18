import { startHttpServer } from "./shared/server-factory.js";
// Group A — Agent & AI frameworks
import { registerSpecKitTools } from "./tools/spec-kit.js";
import { registerAnthropicsSkillsTools } from "./tools/anthropics-skills.js";
import { registerAgentFrameworkTools } from "./tools/agent-framework.js";
import { registerGhAwTools } from "./tools/gh-aw.js";
import { registerAgentsMdTools } from "./tools/agents-md.js";
import { registerGitHubCopilotDocsTools } from "./tools/github-copilot-docs.js";
// Group B — Backstage ecosystem
import { registerBackstageDocsTools } from "./tools/backstage-docs.js";
import { registerBackstagePluginsTools } from "./tools/backstage-plugins.js";
import { registerBackstageUiTools } from "./tools/backstage-ui.js";
import { registerSpotifyBackstageTools } from "./tools/spotify-backstage.js";
import { registerBackstageOrgTools } from "./tools/backstage-org.js";
// Group C — Official documentation
import { registerMicrosoftLearnTools } from "./tools/microsoft-learn.js";
import { registerVsCodeDocsTools } from "./tools/vscode-docs.js";
import { registerGitHubDocsTools } from "./tools/github-docs.js";
import { registerAnthropicDocsTools } from "./tools/anthropic-docs.js";
import { registerAzureCafTools } from "./tools/azure-caf.js";
import { registerAzureWafTools } from "./tools/azure-waf.js";

await startHttpServer((server) => {
  // Group A — Agent & AI frameworks
  registerSpecKitTools(server);
  registerAnthropicsSkillsTools(server);
  registerAgentFrameworkTools(server);
  registerGhAwTools(server);
  registerAgentsMdTools(server);
  registerGitHubCopilotDocsTools(server);

  // Group B — Backstage ecosystem
  registerBackstageDocsTools(server);
  registerBackstagePluginsTools(server);
  registerBackstageUiTools(server);
  registerSpotifyBackstageTools(server);
  registerBackstageOrgTools(server);

  // Group C — Official documentation (Microsoft, GitHub, VS Code, Anthropic, CAF, WAF)
  registerMicrosoftLearnTools(server);
  registerVsCodeDocsTools(server);
  registerGitHubDocsTools(server);
  registerAnthropicDocsTools(server);
  registerAzureCafTools(server);
  registerAzureWafTools(server);
});
