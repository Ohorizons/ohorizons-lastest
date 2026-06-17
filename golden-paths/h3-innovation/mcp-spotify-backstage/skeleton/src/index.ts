import { startHttpServer } from "./shared/server-factory.js";
import { registerSpotifyBackstageTools } from "./tools/spotify-backstage.js";

await startHttpServer((server) => {
  registerSpotifyBackstageTools(server);
});
