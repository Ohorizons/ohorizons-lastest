import { startHttpServer } from "./shared/server-factory.js";
import { registerAgentsMdTools } from "./tools/agents-md.js";

await startHttpServer((server) => {
  registerAgentsMdTools(server);
});
