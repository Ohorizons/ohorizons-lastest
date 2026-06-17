import { startHttpServer } from "./shared/server-factory.js";
import { registerBackstageOrgTools } from "./tools/backstage-org.js";

await startHttpServer((server) => {
  registerBackstageOrgTools(server);
});
