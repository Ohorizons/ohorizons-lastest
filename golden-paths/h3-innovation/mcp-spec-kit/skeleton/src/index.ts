import { startHttpServer } from "./shared/server-factory.js";
import { registerSpecKitTools } from "./tools/spec-kit.js";

await startHttpServer((server) => {
  registerSpecKitTools(server);
});
