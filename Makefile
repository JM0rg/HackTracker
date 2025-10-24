.PHONY: help install package test clean deploy db-start db-stop db-create db-delete db-clear db-reset db-status

help:
	@echo "🏗️  HackTracker - Python Lambda Development"
	@echo ""
	@echo "Setup:"
	@echo "  make install          Install dependencies with uv"
	@echo ""
	@echo "Development:"
	@echo "  make test             Test create-user Lambda locally"
	@echo "  make package          Package Lambda functions"
	@echo ""
	@echo "Database:"
	@echo "  make db-start         Start DynamoDB Local"
	@echo "  make db-stop          Stop DynamoDB Local"
	@echo "  make db-create        Create table from Terraform schema"
	@echo "  make db-delete        Delete the table"
	@echo "  make db-clear         Clear all data from table"
	@echo "  make db-reset         Delete and recreate table"
	@echo "  make db-status        Show DynamoDB status"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy           Package and deploy to AWS"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean            Remove build artifacts"

install:
	@uv sync

package:
	@uv run python scripts/package_lambdas.py

test:
	@uv run python scripts/test_create_user.py

db-start:
	@uv run python scripts/db.py start

db-stop:
	@uv run python scripts/db.py stop

db-create:
	@uv run python scripts/db.py create

db-delete:
	@uv run python scripts/db.py delete

db-clear:
	@uv run python scripts/db.py clear

db-reset:
	@uv run python scripts/db.py reset

db-status:
	@uv run python scripts/db.py status

deploy: package
	@cd terraform && terraform apply

clean:
	@rm -rf terraform/lambdas/*.zip
	@rm -rf .temp
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "✅ Cleaned build artifacts"

