include .env

default: help

COMPOSER_ROOT ?= /var/www/html
DRUPAL_ROOT ?= /var/www/html/web

## help	:	Print commands help.
.PHONY: help
ifneq (,$(wildcard docker.mk))
help : docker.mk
	@sed -n 's/^##//p' $<
else
help : Makefile
	@sed -n 's/^##//p' $<
endif

## up	:	Start up containers.
.PHONY: up
up:
	@echo "Starting up containers for $(PROJECT_NAME)..."
	docker-compose pull
	docker-compose up -d --remove-orphans

## down	:	Stop containers.
.PHONY: down
down: stop

## start	:	Start containers without updating.
.PHONY: start
start:
	@echo "Starting containers for $(PROJECT_NAME) from where you left off..."
	@docker-compose start

## stop	:	Stop containers.
.PHONY: stop
stop:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	@docker-compose stop

## prune	:	Remove containers and their volumes.
##		You can optionally pass an argument with the service name to prune single container
##		prune mariadb	: Prune `mariadb` container and remove its volumes.
##		prune mariadb solr	: Prune `mariadb` and `solr` containers and remove their volumes.
.PHONY: prune
prune:
	@echo "Removing containers for $(PROJECT_NAME)..."
	@docker-compose down -v $(filter-out $@,$(MAKECMDGOALS))

## ps	:	List running containers.
.PHONY: ps
ps:
	@docker ps --filter name='$(PROJECT_NAME)*'

## shell	:	Access `php` container via shell.
.PHONY: shell
shell:
	docker exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") sh

## bash	:	Access `php` container via shell(bash).
.PHONY: bash
bash:
	docker exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") bash

## composer	:	Executes `composer` command in a specified `COMPOSER_ROOT` directory (default is `/var/www/html`).
##		To use "--flag" arguments include them in quotation marks.
##		For example: make composer "update drupal/core --with-dependencies"
.PHONY: composer
composer:
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") composer --working-dir=$(COMPOSER_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## drush	:	Executes `drush` command in a specified `DRUPAL_ROOT` directory (default is `/var/www/html/web`).
##		To use "--flag" arguments include them in quotation marks.
##		For example: make drush "watchdog:show --type=cron"
.PHONY: drush
drush:
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(DRUPAL_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## logs	:	View containers logs.
##		You can optinally pass an argument with the service name to limit logs
##		logs php	: View `php` container logs.
##		logs nginx php	: View `nginx` and `php` containers logs.
.PHONY: logs
logs:
	@docker-compose logs -f $(filter-out $@,$(MAKECMDGOALS))

## solrc	:	Create the core in solr for Drupal site
.PHONY: solrc
solr-core:
	docker exec $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") make create core="$(filter-out $@,$(MAKECMDGOALS))" host="localhost" -f /usr/local/bin/actions.mk

## exec	:	Run a command in PHP container
.PHONY: exec
exec:
	docker exec $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") $(filter-out $@,$(MAKECMDGOALS))

## drupal	:	Run a DrupalConsole command in PHP container
.PHONY: drupal
drupal:
	docker exec $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") drupal --root=$(DRUPAL_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## sqlc	:	Open a SQL command-line interface using Drupal's credentials
.PHONY: sqlc
sqlc:
	docker exec -ti $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") drush  -r $(DRUPAL_ROOT) sql-cli --extra=-A

## cs	:	Run the PHP Code sniffer
.PHONY: cs
cs:
	docker exec $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") bin/phpcs --standard=Drupal --extensions='php,module,inc,install,test,profile,theme,info' /var/www/html/web/modules/custom /var/www/html/web/themes/custom"

## cbf	:	Run the PHP Code sniffer fixing error automatically
.PHONY: cbf
cbf:
	docker exec $(shell docker ps --filter name='$(PROJECT_NAME)_php' --format "{{ .ID }}") bin/phpcbf --standard=Drupal --extensions='php,module,inc,install,test,profile,theme,info' /var/www/html/web/modules/custom /var/www/html/web/themes/custom"

# https://stackoverflow.com/a/6273809/1826109
%:
	@:
