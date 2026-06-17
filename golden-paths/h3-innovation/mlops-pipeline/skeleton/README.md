# ${{values.name}}

${{values.description}}

## Overview

Production-grade MLOps pipeline for model training, versioning, and deployment.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |
| Framework | ${{values.framework}} |

## Features

- Model training and versioning
- Feature store integration
- Automated model deployment
- A/B testing and canary releases
- Model monitoring and drift detection
- Integration with Azure ML and AI Foundry

## Pipeline Stages

![MLOps Pipeline](../../../../docs/assets/gp-mlops-pipeline.svg)

## Directory Structure

```
pipelines/
├── data/
│   └── prepare_data.py
├── train/
│   └── train_model.py
├── evaluate/
│   └── evaluate_model.py
└── deploy/
    └── deploy_model.py
```

## Running the Pipeline

```bash
# Run full pipeline
python -m pipelines.main --stage all

# Run specific stage
python -m pipelines.train --model-name ${{values.name}}

# Deploy to production
python -m pipelines.deploy --environment prod
```

## Configuration

Environment variables:

- `AZURE_ML_WORKSPACE`: Azure ML workspace name
- `AZURE_ML_RESOURCE_GROUP`: Resource group
- `MODEL_REGISTRY`: Model registry URL
- `FEATURE_STORE_URL`: Feature store endpoint

## Model Versioning

- Automatic version incrementing
- Model lineage tracking
- Experiment tracking with MLflow
- Model registry integration

## Monitoring

- Model performance metrics
- Data drift detection
- Prediction latency
- Feature importance

## Links

- [Azure Machine Learning](https://docs.microsoft.com/azure/machine-learning/)
- [MLflow](https://mlflow.org/)
