import { startHttpServer } from "./shared/server-factory.js";
import { registerAwesomeCopilotTools } from "./tools/awesome-copilot.js";

await startHttpServer((server) => {
  registerAwesomeCopilotTools(server);
});
