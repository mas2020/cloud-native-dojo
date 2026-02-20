VENV ?= .venv
VENV_PYTHON := $(VENV)/bin/python
DEPS_STAMP := $(VENV)/.deps-installed

.PHONY: setup serve build clean

$(VENV_PYTHON):
	python3 -m venv $(VENV)

$(DEPS_STAMP): requirements-docs.txt | $(VENV_PYTHON)
	$(VENV_PYTHON) -m pip install --upgrade pip
	$(VENV_PYTHON) -m pip install --upgrade -r requirements-docs.txt
	touch $(DEPS_STAMP)

setup: $(DEPS_STAMP)

serve: setup
	NO_MKDOCS_2_WARNING=1 $(VENV_PYTHON) -m mkdocs serve

build: setup
	NO_MKDOCS_2_WARNING=1 $(VENV_PYTHON) -m mkdocs build --strict

clean:
	rm -rf $(VENV) site
