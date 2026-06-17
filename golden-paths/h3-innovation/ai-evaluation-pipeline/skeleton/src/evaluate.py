"""${{ values.name }} — AI Evaluation Pipeline"""
from azure.identity import DefaultAzureCredential
from azure.ai.evaluation import evaluate
import os


def run_evaluation():
    """Run evaluation pipeline for AI models."""
    credential = DefaultAzureCredential()
    results = evaluate(
        data="data/eval_dataset.jsonl",
        evaluators=["relevance", "groundedness", "coherence"],
    )
    return results


if __name__ == "__main__":
    results = run_evaluation()
    print(f"Evaluation complete: {results}")
