.PHONY: up down logs status rebuild clean

up:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f

status:
	docker compose ps

rebuild:
	docker compose up -d --build --force-recreate

clean:
	docker compose down -v --rmi local

health:
	@curl -s http://localhost:3100/health | python3 -m json.tool 2>/dev/null || echo "Server not running"

test-tool:
	@echo "Testing MCP initialize..."
	@curl -s -X POST http://localhost:3100/mcp \
		-H 'Content-Type: application/json' \
		-H 'Accept: application/json, text/event-stream' \
		-d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | grep -o '"name":"mcp-ecosystem"' && echo " ✅ Server responded" || echo " ❌ Server not responding"
