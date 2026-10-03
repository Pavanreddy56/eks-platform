# Common tasks. Run `make help` to list them.
ENV        ?= dev
AWS_REGION ?= ap-south-1
TF_DIR     := terraform/envs/$(ENV)

.DEFAULT_GOAL := help
.PHONY: help bootstrap backend init plan apply kubeconfig argocd argocd-password argocd-ui \
        grafana-password grafana-ui app-url test lint destroy

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

bootstrap: ## One-time: create the S3 bucket for Terraform state
	terraform -chdir=terraform/bootstrap init -input=false
	terraform -chdir=terraform/bootstrap apply -var="region=$(AWS_REGION)"
	$(MAKE) backend

backend: ## Generate backend.hcl for the environment from bootstrap outputs
	@printf 'bucket       = "%s"\nkey          = "%s/terraform.tfstate"\nregion       = "%s"\nencrypt      = true\nuse_lockfile = true\n' \
	  "$$(terraform -chdir=terraform/bootstrap output -raw state_bucket)" "$(ENV)" \
	  "$$(terraform -chdir=terraform/bootstrap output -raw region)" > $(TF_DIR)/backend.hcl
	@echo "Wrote $(TF_DIR)/backend.hcl"

init: ## terraform init with the S3 backend
	terraform -chdir=$(TF_DIR) init -backend-config=backend.hcl -input=false

plan: ## terraform plan
	terraform -chdir=$(TF_DIR) plan -out=tfplan

apply: ## terraform apply the saved plan
	terraform -chdir=$(TF_DIR) apply tfplan

kubeconfig: ## Point kubectl at the EKS cluster
	$$(terraform -chdir=$(TF_DIR) output -raw configure_kubectl)

argocd: ## Install Argo CD and the root app-of-apps
	./scripts/bootstrap-argocd.sh

argocd-password: ## Print the initial Argo CD admin password
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo

argocd-ui: ## Port-forward the Argo CD UI to https://localhost:8080
	kubectl -n argocd port-forward svc/argocd-server 8080:443

grafana-password: ## Print the Grafana admin password
	@kubectl -n monitoring get secret kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo

grafana-ui: ## Port-forward Grafana to http://localhost:3000
	kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80

app-url: ## Print the public ALB URL of the demo app
	@echo "http://$$(kubectl -n demo get ingress demo-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

test: ## Run app lint and unit tests
	cd app && ruff check . && ruff format --check . && python -m pytest -q

lint: ## Format/lint checks for Terraform and Helm
	terraform fmt -check -recursive terraform
	helm lint helm/demo-app -f helm/demo-app/values-dev.yaml

destroy: ## Tear down in-cluster resources, then all Terraform infrastructure
	./scripts/destroy.sh
