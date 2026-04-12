# Makefile — LexendScholar
# Comandos de desenvolvimento, build, teste e deploy para o projeto.
#
# Uso: make <target>
# Exemplo: make setup

.PHONY: help setup ios web test-ios lint deploy-web clean open ci

# ─── Configurações ────────────────────────────────────────────────────────────

SCHEME        := LexendScholar
PROJECT       := LexendScholar.xcodeproj
SPEC          := project.yml
SIM_NAME      := iPhone 16 Pro
WEBSITE_DIR   := website
WEBSITE_PORT  := 3000
BUILD_DIR     := .build

# Cores para output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
BLUE   := \033[0;34m
RESET  := \033[0m

# ─── Help ─────────────────────────────────────────────────────────────────────

help: ## Mostra esta ajuda
	@echo ""
	@echo "$(BLUE)LexendScholar — Comandos disponíveis$(RESET)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-18s$(RESET) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""

# ─── Setup ────────────────────────────────────────────────────────────────────

setup: ## Instala todas as dependências (XcodeGen, SwiftLint, Node.js tools)
	@echo "$(BLUE)==> Instalando dependências...$(RESET)"
	@echo ""

	@echo "$(YELLOW)--> Verificando Homebrew...$(RESET)"
	@command -v brew >/dev/null 2>&1 || \
		(echo "Homebrew não encontrado. Instalando..." && \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")

	@echo "$(YELLOW)--> Instalando XcodeGen...$(RESET)"
	@command -v xcodegen >/dev/null 2>&1 && echo "  XcodeGen já instalado ($(shell xcodegen --version 2>/dev/null))" || brew install xcodegen

	@echo "$(YELLOW)--> Instalando SwiftLint...$(RESET)"
	@command -v swiftlint >/dev/null 2>&1 && echo "  SwiftLint já instalado ($(shell swiftlint version 2>/dev/null))" || brew install swiftlint

	@echo "$(YELLOW)--> Instalando Node.js tools...$(RESET)"
	@command -v node >/dev/null 2>&1 || brew install node
	@command -v serve >/dev/null 2>&1 || npm install -g serve
	@command -v htmlhint >/dev/null 2>&1 || npm install -g htmlhint
	@command -v vercel >/dev/null 2>&1 || npm install -g vercel

	@echo "$(YELLOW)--> Instalando git hooks...$(RESET)"
	@$(MAKE) install-hooks

	@echo ""
	@echo "$(GREEN)==> Setup concluído! Execute 'make ios' para gerar o projeto Xcode.$(RESET)"

install-hooks: ## Instala os git hooks (pre-commit SwiftLint)
	@echo "$(YELLOW)--> Configurando git hooks...$(RESET)"
	@git config core.hooksPath .githooks
	@chmod +x .githooks/pre-commit 2>/dev/null || true
	@echo "  Hooks instalados em .githooks/"

# ─── iOS ──────────────────────────────────────────────────────────────────────

ios: ## Gera LexendScholar.xcodeproj via XcodeGen e abre no Xcode
	@echo "$(BLUE)==> Gerando projeto Xcode...$(RESET)"
	@xcodegen generate --spec $(SPEC)
	@echo "$(GREEN)==> Projeto gerado: $(PROJECT)$(RESET)"
	@echo "$(YELLOW)--> Abrindo no Xcode...$(RESET)"
	@open $(PROJECT)

generate: ## Apenas gera o .xcodeproj (sem abrir Xcode)
	@echo "$(BLUE)==> Gerando $(PROJECT)...$(RESET)"
	@xcodegen generate --spec $(SPEC)
	@echo "$(GREEN)==> $(PROJECT) gerado com sucesso$(RESET)"

open: ## Abre o projeto no Xcode (sem re-gerar)
	@open $(PROJECT)

build-ios: ## Compila o app iOS para simulador (sem rodar)
	@echo "$(BLUE)==> Compilando para simulador...$(RESET)"
	@xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "platform=iOS Simulator,name=$(SIM_NAME)" \
		-configuration Debug \
		| xcpretty 2>/dev/null || xcodebuild build \
			-project $(PROJECT) \
			-scheme $(SCHEME) \
			-destination "platform=iOS Simulator,name=$(SIM_NAME)" \
			-configuration Debug
	@echo "$(GREEN)==> Build iOS concluído$(RESET)"

# ─── Web ──────────────────────────────────────────────────────────────────────

web: ## Serve o website localmente em http://localhost:3000
	@echo "$(BLUE)==> Iniciando servidor local do website...$(RESET)"
	@echo "$(YELLOW)   URL: http://localhost:$(WEBSITE_PORT)$(RESET)"
	@echo "$(YELLOW)   Pressione Ctrl+C para parar$(RESET)"
	@echo ""
	@command -v serve >/dev/null 2>&1 || npm install -g serve
	@serve $(WEBSITE_DIR) --listen $(WEBSITE_PORT)

web-open: ## Abre o website no browser (requer 'make web' rodando)
	@open http://localhost:$(WEBSITE_PORT)

# ─── Testes ───────────────────────────────────────────────────────────────────

test-ios: ## Roda os testes do iOS (XCTest) no simulador
	@echo "$(BLUE)==> Rodando testes iOS...$(RESET)"
	@xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "platform=iOS Simulator,name=$(SIM_NAME)" \
		-configuration Debug \
		-resultBundlePath TestResults.xcresult \
		| xcpretty 2>/dev/null || xcodebuild test \
			-project $(PROJECT) \
			-scheme $(SCHEME) \
			-destination "platform=iOS Simulator,name=$(SIM_NAME)" \
			-configuration Debug
	@echo "$(GREEN)==> Testes concluídos$(RESET)"

test-ios-ci: ## Roda testes no formato CI (sem xcpretty, saída bruta)
	@echo "$(BLUE)==> Rodando testes iOS (modo CI)...$(RESET)"
	@xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination "platform=iOS Simulator,name=$(SIM_NAME)" \
		-configuration Debug \
		-resultBundlePath TestResults.xcresult

# ─── Lint ─────────────────────────────────────────────────────────────────────

lint: ## Roda SwiftLint + HTMLHint em todos os arquivos
	@$(MAKE) lint-swift
	@$(MAKE) lint-html

lint-swift: ## Roda SwiftLint no código Swift
	@echo "$(BLUE)==> Rodando SwiftLint...$(RESET)"
	@command -v swiftlint >/dev/null 2>&1 || (echo "SwiftLint não instalado. Execute 'make setup'" && exit 1)
	@swiftlint lint --config .swiftlint.yml
	@echo "$(GREEN)==> SwiftLint: OK$(RESET)"

lint-swift-fix: ## Autocorrige violações SwiftLint corrigíveis automaticamente
	@echo "$(BLUE)==> Autocorrigindo com SwiftLint...$(RESET)"
	@swiftlint --fix --config .swiftlint.yml
	@echo "$(GREEN)==> Autocorreção concluída$(RESET)"

lint-html: ## Roda HTMLHint nos arquivos do website
	@echo "$(BLUE)==> Rodando HTMLHint...$(RESET)"
	@command -v htmlhint >/dev/null 2>&1 || npm install -g htmlhint
	@htmlhint $(WEBSITE_DIR)/**/*.html --config .htmlhintrc 2>/dev/null || \
		htmlhint "$(WEBSITE_DIR)/*.html"
	@echo "$(GREEN)==> HTMLHint: OK$(RESET)"

# ─── Deploy ───────────────────────────────────────────────────────────────────

deploy-web: ## Deploy do website para Vercel (produção)
	@echo "$(BLUE)==> Fazendo deploy para Vercel (produção)...$(RESET)"
	@command -v vercel >/dev/null 2>&1 || npm install -g vercel
	@vercel --prod
	@echo "$(GREEN)==> Deploy concluído$(RESET)"

deploy-web-preview: ## Deploy do website para Vercel (preview)
	@echo "$(BLUE)==> Criando preview deployment no Vercel...$(RESET)"
	@vercel
	@echo "$(GREEN)==> Preview deployment concluído$(RESET)"

# ─── CI ───────────────────────────────────────────────────────────────────────

ci: ## Roda todos os checks de CI localmente (lint + build + test)
	@echo "$(BLUE)==> Rodando pipeline de CI localmente...$(RESET)"
	@echo ""
	@$(MAKE) lint
	@echo ""
	@$(MAKE) generate
	@echo ""
	@$(MAKE) build-ios
	@echo ""
	@$(MAKE) test-ios
	@echo ""
	@echo "$(GREEN)==> Pipeline CI local concluída com sucesso!$(RESET)"

# ─── Limpeza ──────────────────────────────────────────────────────────────────

clean: ## Remove arquivos de build gerados
	@echo "$(BLUE)==> Limpando arquivos de build...$(RESET)"
	@xcodebuild clean \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Debug 2>/dev/null || true
	@rm -rf TestResults.xcresult
	@rm -rf swiftlint-report.json
	@echo "$(GREEN)==> Limpeza concluída$(RESET)"

clean-derived: ## Remove DerivedData (build cache completo do Xcode)
	@echo "$(BLUE)==> Removendo DerivedData...$(RESET)"
	@rm -rf ~/Library/Developer/Xcode/DerivedData/LexendScholar-*
	@echo "$(GREEN)==> DerivedData removido$(RESET)"

# ─── Utilitários ──────────────────────────────────────────────────────────────

simulators: ## Lista simuladores iOS disponíveis
	@xcrun simctl list devices available | grep -E "iPhone|iPad" | head -20

version: ## Exibe versões das ferramentas instaladas
	@echo "$(BLUE)Versões das ferramentas:$(RESET)"
	@echo "  Xcode:      $(shell xcodebuild -version 2>/dev/null | head -1 || echo 'não instalado')"
	@echo "  XcodeGen:   $(shell xcodegen --version 2>/dev/null || echo 'não instalado')"
	@echo "  SwiftLint:  $(shell swiftlint version 2>/dev/null || echo 'não instalado')"
	@echo "  Node.js:    $(shell node --version 2>/dev/null || echo 'não instalado')"
	@echo "  Vercel CLI: $(shell vercel --version 2>/dev/null || echo 'não instalado')"
	@echo "  HTMLHint:   $(shell htmlhint --version 2>/dev/null || echo 'não instalado')"
	@echo "  Git:        $(shell git --version 2>/dev/null)"

.DEFAULT_GOAL := help
