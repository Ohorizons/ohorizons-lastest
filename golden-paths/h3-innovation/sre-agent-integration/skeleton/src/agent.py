"""${{ values.name }} — SRE Agent Integration"""
from azure.identity import DefaultAzureCredential
import os


def create_sre_agent():
    """Create an SRE agent for automated incident response."""
    credential = DefaultAzureCredential()
    # Configure monitoring integrations
    return {
        "agent": "${{ values.name }}",
        "integrations": ["prometheus", "grafana", "pagerduty"],
    }


if __name__ == "__main__":
    agent = create_sre_agent()
    print(f"SRE Agent configured: {agent}")
