include .env

.PHONY: up down stop prune ps shell drush logs

default: help

DRUPAL_ROOT ?= /var/www/html/web

up: ## Starting up containers for project
	@echo "Starting up containers for $(PROJECT_NAME)..."
	docker-compose pull
	docker-compose up -d --remove-orphans

down: stop ## Stop containers for project

stop: ## Stop containers for project
	@echo "Stopping containers for $(PROJECT_NAME)..."
	@docker-compose stop

prune: ## Stop and prune containers for project
	@echo "Removing containers for $(PROJECT_NAME)..."
	@docker-compose down -v

ps: ## List container for project
	@docker ps --filter name='$(PROJECT_NAME)*'

shell: ## Open the shell in PHP container
	docker exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") bash

drush: ## Run a Drush command in PHP container
	docker exec $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(DRUPAL_ROOT) $(filter-out $@,$(MAKECMDGOALS))

logs: ## List container for project
	@docker-compose logs -f $(filter-out $@,$(MAKECMDGOALS))

## Custom commands.
create-solr-core: ## Create the core in solr for Drupal site
	docker exec $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") make create core="$(filter-out $@,$(MAKECMDGOALS))" host="localhost" -f /usr/local/bin/actions.mk

exec: ## Run a command in PHP container
	docker exec $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") $(filter-out $@,$(MAKECMDGOALS))

drupal: ## Run a DrupalConsole command in PHP container
	docker exec $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") drupal --root=$(DRUPAL_ROOT) $(filter-out $@,$(MAKECMDGOALS))

sqlc: ## Open a SQL command-line interface using Drupal's credentials
	docker exec -ti $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") drush  -r $(DRUPAL_ROOT) sql-cli --extra=-A

cs: ## Run the PHP Code sniffer
	docker exec $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") bin/phpcs --standard=Drupal --extensions='php,module,inc,install,test,profile,theme,info' /var/www/html/web/modules/custom /var/www/html/web/themes/custom"

cbf: ## Run the PHP Code sniffer fixing error automatically
	docker exec $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") bin/phpcbf --standard=Drupal --extensions='php,module,inc,install,test,profile,theme,info' /var/www/html/web/modules/custom /var/www/html/web/themes/custom"

help: ## List of commands
	@eval $$(sed -r -n 's/^([a-zA-Z0-9_-]+):.*?## (.*)$$/printf "\\033[36m%-30s\\033[0m %s\\n" "\1" "\2" ;/; ta; b; :a p' $(MAKEFILE_LIST))

# https://stackoverflow.com/a/6273809/1826109
%:
	@: