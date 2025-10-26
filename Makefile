.PHONY: help install package test test-players test-teams clean deploy db-start db-stop db-create db-delete db-clear db-reset db-status flutter-clean flutter-open flutter-run

help:
	@echo "🏗️  HackTracker - Python Lambda Development"
	@echo ""
	@echo "Setup:"
	@echo "  make install          Install dependencies with uv"
	@echo ""
	@echo "Development:"
	@echo "  make test             Run user Lambda tests (see: make test-help)"
	@echo "  make test-teams       Run team Lambda tests (full suite)"
	@echo "  make test-players     Run player Lambda tests (full suite)"
	@echo "  make test-e2e         Run full end-to-end test suite (all features)"
	@echo "  make test-cloud       Run tests against deployed API Gateway"
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
	@echo "Flutter App:"
	@echo "  make flutter-clean    Clean Flutter build artifacts"
	@echo "  make flutter-run      Run Flutter app (opens in available device)"
	@echo "  make flutter-open     Alias for flutter-run"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean            Remove build artifacts"

install:
	@uv sync

package:
	@uv run python scripts/package_lambdas.py

test:
	@uv run python scripts/test_users.py $(filter-out $@,$(MAKECMDGOALS))

test-teams:
	@echo "🧪 Running full team test suite..."
	@uv run python scripts/test_teams.py full-test $(filter-out $@,$(MAKECMDGOALS))

test-players:
	@echo "🧪 Running full player test suite..."
	@uv run python scripts/test_players.py full-test $(filter-out $@,$(MAKECMDGOALS))

test-e2e:
	@echo "🧪 Running full end-to-end test suite..."
	@uv run python scripts/full_e2e_test.py

test-cloud:
	@uv run python scripts/test_users.py $(filter-out $@,$(MAKECMDGOALS)) --cloud

test-help:
	@uv run python scripts/test_users.py

# Allow passing arguments to test commands
%:
	@:

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

flutter-clean:
	@cd app && flutter clean
	@echo "✅ Cleaned Flutter build artifacts"

flutter-run:
	@cd app && flutter run

flutter-open: flutter-run

