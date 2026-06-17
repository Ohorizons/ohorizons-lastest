import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import { CopilotAgent } from "../agent";

export async function copilotHandler(
  request: HttpRequest,
  context: InvocationContext
): Promise<HttpResponseInit> {
  context.log("Copilot Extension request received");

  const body = (await request.json()) as any;
  const token = request.headers.get("x-github-token");

  if (!token) {
    return { status: 401, body: "Missing GitHub token" };
  }

  const agent = new CopilotAgent(token);
  const response = await agent.handleRequest(body);

  return {
    status: 200,
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(response),
  };
}

app.http("copilot-handler", {
  methods: ["POST"],
  authLevel: "anonymous",
  handler: copilotHandler,
});
