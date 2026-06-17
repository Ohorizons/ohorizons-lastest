# ${{values.name}}

${{values.description}}

## Overview

Kubernetes batch job for scheduled or on-demand data processing.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |
| Schedule | ${{values.schedule}} |

## Features

- Scheduled execution (CronJob)
- Retry on failure
- Resource limits
- Completion notifications
- Data extraction/transformation/loading

## Job Schedule

```
Schedule: ${{values.schedule}}
Timezone: UTC
```

## Running Manually

```bash
# Create job from cronjob
kubectl create job --from=cronjob/${{values.name}} ${{values.name}}-manual

# Check status
kubectl get jobs
kubectl logs job/${{values.name}}-manual
```

## Configuration

Environment variables:
- `BATCH_SIZE`: Number of records per batch
- `MAX_RETRIES`: Maximum retry attempts
- `OUTPUT_PATH`: Output destination

## Monitoring

- Job completion metrics
- Processing time
- Error rates
- Data quality metrics

## Links

- [Kubernetes Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
