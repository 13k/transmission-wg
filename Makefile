DOCKER ?= docker
IMAGE ?= 13kb/transmission-wg

.PHONY: help
help: ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: clean
clean: ## Remove image (env var: IMAGE)
	$(DOCKER) image rm "$(IMAGE)"

.PHONY: image
image: ## Build image (env var: IMAGE)
	$(DOCKER) build -t "$(IMAGE)" .

.PHONY: publish
publish: ## Publish image to Docker Hub (env var: IMAGE)
	$(DOCKER) push "$(IMAGE)"
