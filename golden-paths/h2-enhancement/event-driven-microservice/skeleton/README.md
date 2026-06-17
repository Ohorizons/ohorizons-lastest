# ${{values.name}}

${{values.description}}

## Overview

Event-driven microservice with message broker integration for asynchronous communication.

| Property | Value |
|----------|-------|
| Owner | ${{values.owner}} |
| System | ${{values.system}} |
| Lifecycle | ${{values.lifecycle}} |
| Message Broker | ${{values.messageBroker}} |

## Features

- Message consumption and publishing
- Dead-letter queue handling
- Automatic retry with exponential backoff
- Message deduplication
- Distributed tracing integration
- Health checks for broker connectivity

## Architecture

![Event-Driven Architecture](../../../../docs/assets/gp-event-driven.svg)

## Message Handlers

| Topic/Queue | Handler | Description |
|-------------|---------|-------------|
| `input-events` | `EventHandler` | Process incoming events |
| `dlq-events` | `DLQHandler` | Handle failed messages |

## Running Locally

```bash
# Start with local message broker
docker-compose up -d

# Run the service
python -m src.main

# Send test message
python scripts/send_test_message.py
```

## Configuration

Environment variables:

- `BROKER_CONNECTION_STRING`: Message broker connection string
- `INPUT_QUEUE`: Name of the input queue/topic
- `OUTPUT_QUEUE`: Name of the output queue/topic
- `MAX_RETRIES`: Maximum retry attempts (default: 3)
- `DLQ_ENABLED`: Enable dead-letter queue (default: true)

## Monitoring

- Message processing rate
- Error rate and DLQ metrics
- Processing latency
- Queue depth alerts

## Links

- [Azure Service Bus](https://docs.microsoft.com/azure/service-bus-messaging/)
- [Event-Driven Architecture](https://docs.microsoft.com/azure/architecture/guide/architecture-styles/event-driven)
