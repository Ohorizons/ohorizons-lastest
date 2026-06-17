import { startHttpServer } from "./shared/server-factory.js";
import { registerAgentFrameworkTools } from "./tools/agent-framework.js";

await startHttpServer((server) => {
  registerAgentFrameworkTools(server);
});
