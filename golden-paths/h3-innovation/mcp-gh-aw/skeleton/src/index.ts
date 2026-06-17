import { startHttpServer } from "./shared/server-factory.js";
import { registerGhAwTools } from "./tools/gh-aw.js";

await startHttpServer((server) => {
  registerGhAwTools(server);
});
