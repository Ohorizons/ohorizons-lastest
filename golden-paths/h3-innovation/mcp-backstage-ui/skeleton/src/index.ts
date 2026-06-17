import { startHttpServer } from "./shared/server-factory.js";
import { registerBackstageUiTools } from "./tools/backstage-ui.js";

await startHttpServer((server) => {
  registerBackstageUiTools(server);
});
