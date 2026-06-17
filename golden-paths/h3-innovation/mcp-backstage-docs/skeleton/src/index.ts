import { startHttpServer } from "./shared/server-factory.js";
import { registerBackstageDocsTools } from "./tools/backstage-docs.js";

await startHttpServer((server) => {
  registerBackstageDocsTools(server);
});
