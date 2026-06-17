"""${{ values.agentName }} — Azure AI Foundry Agent"""
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
import os


def create_agent():
    """Create and configure the AI Foundry agent."""
    credential = DefaultAzureCredential()
    project = AIProjectClient(
        credential=credential,
        subscription_id=os.environ["AZURE_SUBSCRIPTION_ID"],
        resource_group_name=os.environ["AZURE_RESOURCE_GROUP"],
        project_name=os.environ.get("AI_PROJECT_NAME", "${{ values.agentName }}"),
    )

    agent = project.agents.create_agent(
        model=os.environ.get("AZURE_OPENAI_MODEL", "${{ values.primaryModel }}"),
        name="${{ values.agentName }}",
        instructions="${{ values.agentPurpose }}",
    )
    return agent


if __name__ == "__main__":
    agent = create_agent()
    print(f"Agent created: {agent.id}")
