# Local equivalents of the CI checks. Set TF=tofu to use OpenTofu.
TF ?= terraform

ROOTS   := bootstrap environments/dev environments/prod
TESTED  := modules/network modules/alb stacks/web-app

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

.PHONY: fmt
fmt: ## Format all Terraform files
	$(TF) fmt -recursive

.PHONY: validate
validate: ## terraform validate every root configuration
	@for d in $(ROOTS); do echo "==> $$d"; $(TF) -chdir=$$d init -backend=false -input=false >/dev/null && $(TF) -chdir=$$d validate || exit 1; done

.PHONY: test
test: ## Terraform unit tests (mocked provider, no AWS account needed)
	@for d in $(TESTED); do echo "==> $$d"; $(TF) -chdir=$$d init -backend=false -input=false >/dev/null && $(TF) -chdir=$$d test || exit 1; done

.PHONY: lint
lint: ## tflint with the AWS ruleset
	tflint --init --config $(CURDIR)/.tflint.hcl
	tflint --recursive --config $(CURDIR)/.tflint.hcl --format compact

.PHONY: scan
scan: ## checkov security scan
	checkov -d . --framework terraform,github_actions,dockerfile --quiet --compact

.PHONY: app-test
app-test: ## Run the sample app's unit tests
	cd app && python -m pytest

.PHONY: ci
ci: ## Everything CI runs (except the image build)
	$(TF) fmt -check -recursive
	$(MAKE) validate test lint scan app-test
