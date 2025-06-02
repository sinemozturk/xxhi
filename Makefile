# Detect OS and set DOCKER command appropriately:
OS := $(shell uname -s)
ifeq ($(OS), Darwin)
	DOCKER := docker
else
	DOCKER := sudo docker
endif

APP_NAME ?= hello-app

.PHONY: docker package appbundle clean

all: docker package appbundle

docker:
	$(DOCKER) build -t $(APP_NAME):latest .

package: docker
	$(DOCKER) save $(APP_NAME):latest | gzip > $(APP_NAME).tar.gz

appbundle:
	@echo "Removing old $(APP_NAME).tar.gz and dist/ folder..."
	@rm -f $(APP_NAME).tar.gz
	@rm -rf dist
	@echo "Creating temporary folder dist/$(APP_NAME)..."
	@mkdir -p dist/$(APP_NAME)
	@echo "Copying roles/ and actions/..."
	@cp -r bundles/${APP_NAME}/roles dist/$(APP_NAME)/
	@cp -r bundles/${APP_NAME}/actions dist/$(APP_NAME)/
	@cp bundles/${APP_NAME}/appbundle.yml dist/$(APP_NAME)/
	@echo "Building Docker image via existing docker target..."
	@$(MAKE) docker
	@echo "Saving Docker image tar..."
	@$(DOCKER) save $(APP_NAME):latest | gzip > dist/docker-image.tar.gz
	@mkdir -p dist/$(APP_NAME)/images
	@mv dist/docker-image.tar.gz dist/$(APP_NAME)/images/$(APP_NAME).tar.gz
	@echo "Packaging Helm chart..."
	@helm package bundles/${APP_NAME}/charts
	@mkdir -p dist/$(APP_NAME)/charts
	@mv *.tgz dist/$(APP_NAME)/charts/
	@echo "Generating ansible.cfg file..."
	@echo "[defaults]" > dist/$(APP_NAME)/ansible.cfg
	@echo "roles_path = roles" >> dist/$(APP_NAME)/ansible.cfg
	@echo "playbook_dir = actions" >> dist/$(APP_NAME)/ansible.cfg
	@echo "Creating final tarball $(APP_NAME).tar.gz..."
	@cd dist/${APP_NAME} && find . -type f -name '*.tgz' -o -name '*.tar.gz' -o -name '*.yml' -o -name 'ansible.cfg' | tar czf ../$(APP_NAME).tar.gz -T -
	@echo "Appbundle created at dist/$(APP_NAME).tar.gz"

clean:
	rm -f $(APP_NAME) $(APP_NAME).tar.gz
	rm -rf dist