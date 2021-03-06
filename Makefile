include docker.mk

.PHONY: test

DRUPAL_VER ?= 8
PHP_VER ?= 7.3

# I comment the next lines because the tests are already executed
# in the original project. I leave the structure and operation in case in
# the future it needs to apply personal tests to the changes made.
#test:
#	cd ./tests/$(DRUPAL_VER) && PHP_VER=$(PHP_VER) ./run.sh

test:
	@echo "There are no tests to be run."
