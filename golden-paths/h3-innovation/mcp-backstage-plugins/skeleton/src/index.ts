import { startHttpServer } from "./shared/server-factory.js";
import { registerBackstagePluginsTools } from "./tools/backstage-plugins.js";

await startHttpServer((server) => {
  registerBackstagePluginsTools(server);
});
