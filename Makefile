# Definição da versão do Python
PYTHON_VERSION ?= 3.8.10

# Diretórios de bibliotecas
LIBRARY_DIRS = mylibrary

# Diretório de build
BUILD_DIR ?= build

# Opções do PyTest
PYTEST_HTML_OPTIONS = --html=$(BUILD_DIR)/report.html --self-contained-html
PYTEST_TAP_OPTIONS = --tap-combined --tap-outdir $(BUILD_DIR)
PYTEST_COVERAGE_OPTIONS = --cov=$(LIBRARY_DIRS)
PYTEST_OPTIONS ?= $(PYTEST_HTML_OPTIONS) $(PYTEST_TAP_OPTIONS) $(PYTEST_COVERAGE_OPTIONS)

# Opções do MyPy
MYPY_OPTS ?= --python-version $(basename $(PYTHON_VERSION)) --show-column-numbers --pretty --html-report $(BUILD_DIR)/mypy

# Arquivo de versão do Python
PYTHON_VERSION_FILE=.python-version

# Verificação de sistema operacional
ifeq ($(OS),Windows_NT)
  # Configurações específicas para Windows
  PYENV_VERSION_DIR ?= $(USERPROFILE)\.pyenv\versions\$(PYTHON_VERSION)
  PIP ?= pip
else
  # Configurações para sistemas Unix
  ifeq ($(shell which pyenv),)
    PYENV_VERSION_DIR ?= $(HOME)/.pyenv/versions/$(PYTHON_VERSION)
  else
    PYENV_VERSION_DIR ?= $(shell pyenv root)/versions/$(PYTHON_VERSION)
  endif
  PIP ?= pip3
endif

# Configurações do Poetry
POETRY_OPTS ?=
POETRY ?= poetry $(POETRY_OPTS)
RUN_PYPKG_BIN = $(POETRY) run

# Cores para o output
COLOR_ORANGE = \033[33m
COLOR_RESET = \033[0m

##@ Utilidade

.PHONY: help
help:  ## Exibe esta ajuda
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: version-python
version-python: ## Exibe a versão do Python em uso
	@echo $(PYTHON_VERSION)

##@ Testes

.PHONY: test
test: ## Executa os testes
	$(RUN_PYPKG_BIN) pytest \
		$(PYTEST_OPTIONS) \
		tests/*.py

##@ Build e Publicação

.PHONY: build
build: ## Executa o build
	$(POETRY) build

.PHONY: publish
publish: ## Publica o build no repositório configurado
	$(POETRY) publish $(POETRY_PUBLISH_OPTIONS_SET_BY_CI_ENV)

.PHONY: deps-py-update
deps-py-update: pyproject.toml ## Atualiza as dependências do Poetry
	$(POETRY) update

##@ Configuração

# Detecção dinâmica do diretório de instalação do Python com pyenv
$(PYENV_VERSION_DIR):
	pyenv install --skip-existing $(PYTHON_VERSION)
$(PYTHON_VERSION_FILE): $(PYENV_VERSION_DIR)
	pyenv local $(PYTHON_VERSION)

.PHONY: deps
deps: deps-py  ## Instala todas as dependências

.PHONY: deps-py
deps-py: $(PYTHON_VERSION_FILE) ## Instala as dependências de desenvolvimento e runtime do Python
	$(PIP) install --upgrade \
		--index-url $(PYPI_PROXY) \
		pip
	$(PIP) install --upgrade \
		--index-url $(PYPI_PROXY) \
		poetry
	$(POETRY) install

##@ Qualidade de Código

.PHONY: check
check: check-py ## Executa linters e outras ferramentas importantes

.PHONY: check-py
check-py: check-py-flake8 check-py-black check-py-mypy ## Verifica apenas arquivos Python

.PHONY: check-py-flake8
check-py-flake8: ## Executa o linter flake8
	$(RUN_PYPKG_BIN) flake8 .

.PHONY: check-py-black
check-py-black: ## Executa o black em modo de verificação (sem alterações)
	$(RUN_PYPKG_BIN) black --check --line-length 118 --fast .

.PHONY: check-py-mypy
check-py-mypy: ## Executa o mypy
	$(RUN_PYPKG_BIN) mypy $(MYPY_OPTS) $(LIBRARY_DIRS)

.PHONY: format-py
format-py: ## Formata o código com black
	$(RUN_PYPKG_BIN) black .

.PHONY: format-autopep8
format-autopep8: ## Formata o código com autopep8
	$(RUN_PYPKG_BIN) autopep8 --in-place --recursive .

.PHONY: format-isort
format-isort: ## Ordena os imports com isort
	$(RUN_PYPKG_BIN) isort --recursive .
