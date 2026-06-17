"""${{ values.name }} — MLOps Training Pipeline"""
from azure.identity import DefaultAzureCredential
from azure.ai.ml import MLClient
import os


def create_pipeline():
    """Create an Azure ML training pipeline."""
    credential = DefaultAzureCredential()
    ml_client = MLClient(
        credential=credential,
        subscription_id=os.environ["AZURE_SUBSCRIPTION_ID"],
        resource_group_name=os.environ["AZURE_RESOURCE_GROUP"],
        workspace_name=os.environ.get("AZURE_ML_WORKSPACE", "${{ values.name }}"),
    )
    return ml_client


if __name__ == "__main__":
    client = create_pipeline()
    print("MLOps pipeline client initialized")
