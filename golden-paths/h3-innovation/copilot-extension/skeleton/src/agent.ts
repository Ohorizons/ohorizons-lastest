/**
 * GitHub Copilot Extension — ${{ values.display_name }}
 *
 * Handles requests from GitHub Copilot Chat and provides
 * custom capabilities for your organization.
 */
import { Octokit } from "@octokit/rest";

interface CopilotRequest {
  messages: Array<{ role: string; content: string }>;
  copilot_references?: unknown[];
}

interface AgentResponse {
  type: "message" | "reference";
  content: string;
  references?: unknown[];
}

export class CopilotAgent {
  private octokit: Octokit;

  constructor(token: string) {
    this.octokit = new Octokit({ auth: token });
  }

  async handleRequest(request: CopilotRequest): Promise<AgentResponse> {
    const userMessage = request.messages[request.messages.length - 1];

    if (userMessage.content.includes("search") || userMessage.content.includes("find")) {
      return this.handleCodeSearch(userMessage.content);
    }

    return {
      type: "message",
      content: "I can help with that. Let me find the relevant information...",
    };
  }

  private async handleCodeSearch(query: string): Promise<AgentResponse> {
    const results = await this.octokit.search.code({ q: query, per_page: 5 });
    return {
      type: "reference",
      content: `Found ${results.data.total_count} results`,
      references: results.data.items.map((item) => ({
        type: "code",
        url: item.html_url,
        title: item.path,
      })),
    };
  }
}
