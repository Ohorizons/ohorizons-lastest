# ${{values.name}}

${{values.description}}

## Overview

Data pipeline for ETL/ELT operations using Azure Data Factory or Spark.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |
| Technology | ${{values.technology}} |

## Features

- Data extraction from multiple sources
- Transformation and cleansing
- Loading to data warehouse/lake
- Scheduling and orchestration
- Data quality validation
- Lineage tracking

## Pipeline Structure

```
pipelines/
├── extract/
│   └── source_extract.json
├── transform/
│   └── data_transform.json
└── load/
    └── warehouse_load.json
```

## Data Sources

| Source | Type | Frequency |
|--------|------|-----------|
| Source A | SQL Database | Daily |
| Source B | REST API | Hourly |
| Source C | Blob Storage | Real-time |

## Running

```bash
# Trigger pipeline
az datafactory pipeline create-run \
  --factory-name ${{values.factoryName}} \
  --name ${{values.name}}

# Check status
az datafactory pipeline-run show \
  --factory-name ${{values.factoryName}} \
  --run-id <run-id>
```

## Monitoring

- Pipeline run metrics
- Data volume processed
- Error tracking
- SLA compliance

## Links

- [Azure Data Factory](https://docs.microsoft.com/azure/data-factory/)
- [Apache Spark](https://spark.apache.org/)
