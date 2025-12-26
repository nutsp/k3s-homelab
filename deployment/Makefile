HELM := helm
RELEASE_NAME := app-deployment
NAMESPACE := app
VALUES_FILE := values.dev.yaml
OUTPUT_DIR := kubernetes/dev

## help: show this help message
.PHONY: help
help:
	@echo "Available targets:"
	@grep -E '^##' Makefile | sed 's/## //'

## check-helm: verify that helm is installed
.PHONY: check-helm
check-helm:
	@which $(HELM) > /dev/null || (echo "Error: helm is not installed or not in PATH. Please install helm first." && exit 1)

## dev: create Development Kubernetes Configuration split by service and config (default)
.PHONY: dev
dev: check-helm clean-output
	@echo "Generating Kubernetes manifests for development..."
	@mkdir -p $(OUTPUT_DIR)
	@echo "Generating auth-config.yaml..."
	@$(HELM) template $(RELEASE_NAME) . --values ./$(VALUES_FILE) --show-only templates/auth-config.yaml > $(OUTPUT_DIR)/auth-config.yaml
	@echo "✓ Generated: $(OUTPUT_DIR)/auth-config.yaml"
	@echo "Generating auth-service.yaml..."
	@$(HELM) template $(RELEASE_NAME) . --values ./$(VALUES_FILE) --show-only templates/auth-service.yaml > $(OUTPUT_DIR)/auth-service.yaml
	@echo "✓ Generated: $(OUTPUT_DIR)/auth-service.yaml"
	@echo "Generating profile-config.yaml..."
	@if $(HELM) template $(RELEASE_NAME) . --values ./$(VALUES_FILE) --show-only templates/profile-config.yaml > $(OUTPUT_DIR)/profile-config.yaml 2>/dev/null && [ -s $(OUTPUT_DIR)/profile-config.yaml ]; then \
		echo "✓ Generated: $(OUTPUT_DIR)/profile-config.yaml"; \
	else \
		echo "# Profile service not enabled or empty" > $(OUTPUT_DIR)/profile-config.yaml; \
		echo "✓ Generated: $(OUTPUT_DIR)/profile-config.yaml (empty - profile disabled)"; \
	fi
	@echo "Generating profile-service.yaml..."
	@if $(HELM) template $(RELEASE_NAME) . --values ./$(VALUES_FILE) --show-only templates/profile-service.yaml > $(OUTPUT_DIR)/profile-service.yaml 2>/dev/null && [ -s $(OUTPUT_DIR)/profile-service.yaml ]; then \
		echo "✓ Generated: $(OUTPUT_DIR)/profile-service.yaml"; \
	else \
		echo "# Profile service not enabled or empty" > $(OUTPUT_DIR)/profile-service.yaml; \
		echo "✓ Generated: $(OUTPUT_DIR)/profile-service.yaml (empty - profile disabled)"; \
	fi
	@echo "Generating ingress-deploy.yaml..."
	@if $(HELM) template $(RELEASE_NAME) . --values ./$(VALUES_FILE) --show-only templates/ingress.yaml > $(OUTPUT_DIR)/ingress-deploy.yaml 2>/dev/null && [ -s $(OUTPUT_DIR)/ingress-deploy.yaml ]; then \
		echo "✓ Generated: $(OUTPUT_DIR)/ingress-deploy.yaml"; \
	else \
		echo "# Ingress not enabled or empty" > $(OUTPUT_DIR)/ingress-deploy.yaml; \
		echo "✓ Generated: $(OUTPUT_DIR)/ingress-deploy.yaml (empty - ingress disabled)"; \
	fi
	@echo "Generating notification-config.yaml..."
	@if $(HELM) template $(RELEASE_NAME) . --values ./$(VALUES_FILE) --show-only templates/notification-config.yaml > $(OUTPUT_DIR)/notification-config.yaml 2>/dev/null && [ -s $(OUTPUT_DIR)/notification-config.yaml ]; then \
		echo "✓ Generated: $(OUTPUT_DIR)/notification-config.yaml"; \
	else \
		echo "# Notification job not enabled or empty" > $(OUTPUT_DIR)/notification-config.yaml; \
		echo "✓ Generated: $(OUTPUT_DIR)/notification-config.yaml (empty - notification job disabled)"; \
	fi
	@echo "Generating notification-job.yaml..."
	@if $(HELM) template $(RELEASE_NAME) . --values ./$(VALUES_FILE) --show-only templates/notification-job.yaml > $(OUTPUT_DIR)/notification-job.yaml 2>/dev/null && [ -s $(OUTPUT_DIR)/notification-job.yaml ]; then \
		echo "✓ Generated: $(OUTPUT_DIR)/notification-job.yaml"; \
	else \
		echo "# Notification job not enabled or empty" > $(OUTPUT_DIR)/notification-job.yaml; \
		echo "✓ Generated: $(OUTPUT_DIR)/notification-job.yaml (empty - notification job disabled)"; \
	fi
	@echo "Generating keycloak-config.yaml..."
	@if $(HELM) template $(RELEASE_NAME) . --values ./$(VALUES_FILE) --show-only templates/keycloak-config.yaml > $(OUTPUT_DIR)/keycloak-config.yaml 2>/dev/null && [ -s $(OUTPUT_DIR)/keycloak-config.yaml ]; then \
		echo "✓ Generated: $(OUTPUT_DIR)/keycloak-config.yaml"; \
	else \
		echo "# Keycloak service not enabled or empty" > $(OUTPUT_DIR)/keycloak-config.yaml; \
		echo "✓ Generated: $(OUTPUT_DIR)/keycloak-config.yaml (empty - keycloak disabled)"; \
	fi
	@echo "Generating keycloak-service.yaml..."
	@if $(HELM) template $(RELEASE_NAME) . --values ./$(VALUES_FILE) --show-only templates/keycloak-service.yaml > $(OUTPUT_DIR)/keycloak-service.yaml 2>/dev/null && [ -s $(OUTPUT_DIR)/keycloak-service.yaml ]; then \
		echo "✓ Generated: $(OUTPUT_DIR)/keycloak-service.yaml"; \
	else \
		echo "# Keycloak service not enabled or empty" > $(OUTPUT_DIR)/keycloak-service.yaml; \
		echo "✓ Generated: $(OUTPUT_DIR)/keycloak-service.yaml (empty - keycloak disabled)"; \
	fi
	@echo "Generating keycloak-ingress.yaml..."
	@if $(HELM) template $(RELEASE_NAME) . --values ./$(VALUES_FILE) --show-only templates/keycloak-ingress.yaml > $(OUTPUT_DIR)/keycloak-ingress.yaml 2>/dev/null && [ -s $(OUTPUT_DIR)/keycloak-ingress.yaml ]; then \
		echo "✓ Generated: $(OUTPUT_DIR)/keycloak-ingress.yaml"; \
	else \
		echo "# Keycloak ingress not enabled or empty" > $(OUTPUT_DIR)/keycloak-ingress.yaml; \
		echo "✓ Generated: $(OUTPUT_DIR)/keycloak-ingress.yaml (empty - keycloak ingress disabled)"; \
	fi
	@echo ""
	@echo "To deploy:"
	@echo "  kubectl apply -f $(OUTPUT_DIR)/auth-config.yaml"
	@echo "  kubectl apply -f $(OUTPUT_DIR)/auth-service.yaml"
	@echo "  kubectl apply -f $(OUTPUT_DIR)/profile-config.yaml"
	@echo "  kubectl apply -f $(OUTPUT_DIR)/profile-service.yaml"
	@echo "  kubectl apply -f $(OUTPUT_DIR)/ingress-deploy.yaml"
	@echo "  kubectl apply -f $(OUTPUT_DIR)/notification-config.yaml"
	@echo "  kubectl apply -f $(OUTPUT_DIR)/notification-job.yaml"
	@echo "  kubectl apply -f $(OUTPUT_DIR)/keycloak-config.yaml"
	@echo "  kubectl apply -f $(OUTPUT_DIR)/keycloak-service.yaml"
	@echo "  kubectl apply -f $(OUTPUT_DIR)/keycloak-ingress.yaml"
	@echo "  or"
	@echo "  helm install $(RELEASE_NAME) . --values ./$(VALUES_FILE) --namespace $(NAMESPACE) --create-namespace"

## dev-all: create Development Kubernetes Configuration in single file
.PHONY: dev-all
dev-all: check-helm clean-output
	@echo "Generating combined Kubernetes manifests for development..."
	@mkdir -p $(OUTPUT_DIR)
	@$(HELM) template $(RELEASE_NAME) . --values ./$(VALUES_FILE) > $(OUTPUT_DIR)/deploy-all.yaml
	@echo "✓ Generated: $(OUTPUT_DIR)/deploy-all.yaml"
	@echo ""
	@echo "To deploy:"
	@echo "  kubectl apply -f $(OUTPUT_DIR)/deploy-all.yaml"

## lint: lint the Helm chart
.PHONY: lint
lint: check-helm
	@echo "Linting Helm chart..."
	@$(HELM) lint . --values ./$(VALUES_FILE)
	@echo "✓ Lint passed"

## dry-run: perform a dry-run installation
.PHONY: dry-run
dry-run: check-helm
	@echo "Dry-run installation..."
	@$(HELM) template $(RELEASE_NAME) . --values ./$(VALUES_FILE) --debug

## validate: validate generated manifests
.PHONY: validate
validate: dev
	@echo "Validating generated manifests..."
	@kubectl --dry-run=client -f $(OUTPUT_DIR)/auth-config.yaml apply > /dev/null 2>&1 && echo "✓ auth-config.yaml validation passed" || echo "✗ auth-config.yaml validation failed"
	@kubectl --dry-run=client -f $(OUTPUT_DIR)/auth-service.yaml apply > /dev/null 2>&1 && echo "✓ auth-service.yaml validation passed" || echo "✗ auth-service.yaml validation failed"
	@if [ -s $(OUTPUT_DIR)/profile-config.yaml ] && ! grep -q "not enabled\|empty" $(OUTPUT_DIR)/profile-config.yaml; then \
		kubectl --dry-run=client -f $(OUTPUT_DIR)/profile-config.yaml apply > /dev/null 2>&1 && echo "✓ profile-config.yaml validation passed" || echo "✗ profile-config.yaml validation failed"; \
	fi
	@if [ -s $(OUTPUT_DIR)/profile-service.yaml ] && ! grep -q "not enabled\|empty" $(OUTPUT_DIR)/profile-service.yaml; then \
		kubectl --dry-run=client -f $(OUTPUT_DIR)/profile-service.yaml apply > /dev/null 2>&1 && echo "✓ profile-service.yaml validation passed" || echo "✗ profile-service.yaml validation failed"; \
	fi
	@if [ -s $(OUTPUT_DIR)/ingress-deploy.yaml ] && ! grep -q "not enabled\|empty" $(OUTPUT_DIR)/ingress-deploy.yaml; then \
		kubectl --dry-run=client -f $(OUTPUT_DIR)/ingress-deploy.yaml apply > /dev/null 2>&1 && echo "✓ ingress-deploy.yaml validation passed" || echo "✗ ingress-deploy.yaml validation failed"; \
	fi
	@if [ -s $(OUTPUT_DIR)/notification-config.yaml ] && ! grep -q "not enabled\|empty" $(OUTPUT_DIR)/notification-config.yaml; then \
		kubectl --dry-run=client -f $(OUTPUT_DIR)/notification-config.yaml apply > /dev/null 2>&1 && echo "✓ notification-config.yaml validation passed" || echo "✗ notification-config.yaml validation failed"; \
	fi
	@if [ -s $(OUTPUT_DIR)/notification-job.yaml ] && ! grep -q "not enabled\|empty" $(OUTPUT_DIR)/notification-job.yaml; then \
		kubectl --dry-run=client -f $(OUTPUT_DIR)/notification-job.yaml apply > /dev/null 2>&1 && echo "✓ notification-job.yaml validation passed" || echo "✗ notification-job.yaml validation failed"; \
	fi
	@if [ -s $(OUTPUT_DIR)/keycloak-config.yaml ] && ! grep -q "not enabled\|empty" $(OUTPUT_DIR)/keycloak-config.yaml; then \
		kubectl --dry-run=client -f $(OUTPUT_DIR)/keycloak-config.yaml apply > /dev/null 2>&1 && echo "✓ keycloak-config.yaml validation passed" || echo "✗ keycloak-config.yaml validation failed"; \
	fi
	@if [ -s $(OUTPUT_DIR)/keycloak-service.yaml ] && ! grep -q "not enabled\|empty" $(OUTPUT_DIR)/keycloak-service.yaml; then \
		kubectl --dry-run=client -f $(OUTPUT_DIR)/keycloak-service.yaml apply > /dev/null 2>&1 && echo "✓ keycloak-service.yaml validation passed" || echo "✗ keycloak-service.yaml validation failed"; \
	fi
	@if [ -s $(OUTPUT_DIR)/keycloak-ingress.yaml ] && ! grep -q "not enabled\|empty" $(OUTPUT_DIR)/keycloak-ingress.yaml; then \
		kubectl --dry-run=client -f $(OUTPUT_DIR)/keycloak-ingress.yaml apply > /dev/null 2>&1 && echo "✓ keycloak-ingress.yaml validation passed" || echo "✗ keycloak-ingress.yaml validation failed"; \
	fi

## install: install the chart using Helm
.PHONY: install
install: check-helm
	@echo "Installing $(RELEASE_NAME)..."
	@$(HELM) install $(RELEASE_NAME) . --values ./$(VALUES_FILE) --namespace $(NAMESPACE) --create-namespace
	@echo "✓ Installed successfully"

## upgrade: upgrade the chart using Helm
.PHONY: upgrade
upgrade: check-helm
	@echo "Upgrading $(RELEASE_NAME)..."
	@$(HELM) upgrade $(RELEASE_NAME) . --values ./$(VALUES_FILE) --namespace $(NAMESPACE)
	@echo "✓ Upgraded successfully"

## uninstall: uninstall the chart
.PHONY: uninstall
uninstall: check-helm
	@echo "Uninstalling $(RELEASE_NAME)..."
	@$(HELM) uninstall $(RELEASE_NAME) --namespace $(NAMESPACE) || echo "Release not found"
	@echo "✓ Uninstalled"

## status: show the status of the release
.PHONY: status
status: check-helm
	@$(HELM) status $(RELEASE_NAME) --namespace $(NAMESPACE) || echo "Release not found"

## clean: remove generated Kubernetes files
.PHONY: clean
clean: clean-output

## clean-output: remove generated output files
.PHONY: clean-output
clean-output:
	@echo "Cleaning generated files..."
	@rm -rf $(OUTPUT_DIR)
	@echo "✓ Cleaned"

## all: run lint, dev, and validate
.PHONY: all
all: lint dev validate
	@echo ""
	@echo "✓ All tasks completed successfully"
