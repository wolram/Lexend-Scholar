# LS-168 — Testes de Acessibilidade WCAG 2.1 AA no Website

## Objetivo

Executar auditoria de acessibilidade em todas as páginas do website Lexend Scholar
com axe-core, corrigir violations críticas e documentar exceções aceitas.
Meta: zero violations WCAG 2.1 nível A e AA.

---

## Páginas a Auditar

| Página | URL | Prioridade |
|--------|-----|-----------|
| Home | /index.html | Alta |
| Sobre | /about.html | Média |
| Preços | /pricing.html | Alta |
| Blog | /blog.html | Média |
| Contato | /contact.html | Alta |
| 404 | /404.html | Baixa |

---

## Ferramentas

| Ferramenta | Uso | Como Executar |
|-----------|-----|--------------|
| axe-core CLI | Auditoria automatizada | `npx axe --save resultado.json URL` |
| axe DevTools (browser) | Inspeção manual | Extensão Chrome/Firefox |
| WAVE | Visualização de erros | wave.webaim.org |
| Colour Contrast Analyser | Verificar contraste | App desktop (gratuito) |
| NVDA / VoiceOver | Teste com leitor de tela | NVDA (Windows), VoiceOver (Mac/iOS) |

---

## Comandos de Auditoria

### Instalação

```bash
npm install -g axe-cli
npm install -g @axe-core/cli
```

### Executar auditoria em todas as páginas

```bash
#!/bin/bash
# scripts/qa/run-accessibility-audit.sh

SITE_URL="http://localhost:8080"
PAGES=("/" "/about.html" "/pricing.html" "/blog.html" "/contact.html" "/404.html")
OUTPUT_DIR="docs/quality/accessibility-reports"

mkdir -p "$OUTPUT_DIR"

echo "Iniciando auditoria de acessibilidade WCAG 2.1 AA..."
echo "================================================"

for PAGE in "${PAGES[@]}"; do
  PAGE_NAME=$(echo "$PAGE" | tr '/' '-' | tr '.' '-' | sed 's/^-//')
  [ -z "$PAGE_NAME" ] && PAGE_NAME="home"
  
  echo "Auditando: $SITE_URL$PAGE"
  
  npx axe "$SITE_URL$PAGE" \
    --tags wcag2a,wcag2aa,wcag21a,wcag21aa \
    --save "$OUTPUT_DIR/axe-$PAGE_NAME.json" \
    --reporter json \
    2>/dev/null
    
  # Verificar se há violations
  VIOLATIONS=$(cat "$OUTPUT_DIR/axe-$PAGE_NAME.json" | python3 -c "
import json, sys
data = json.load(sys.stdin)
violations = data[0]['violations'] if data else []
print(len(violations))
" 2>/dev/null || echo "?")
  
  echo "  Violations encontradas: $VIOLATIONS"
done

echo ""
echo "Relatórios salvos em: $OUTPUT_DIR/"
echo "Executar: cat $OUTPUT_DIR/axe-home.json | python3 scripts/qa/format-axe-report.py"
```

### Script de formatação do relatório

```python
#!/usr/bin/env python3
# scripts/qa/format-axe-report.py

import json
import sys

def format_report(data):
    if not data:
        print("Nenhum dado encontrado.")
        return
    
    result = data[0] if isinstance(data, list) else data
    violations = result.get('violations', [])
    
    print(f"\n{'='*60}")
    print(f"URL: {result.get('url', 'Desconhecida')}")
    print(f"Violations encontradas: {len(violations)}")
    print(f"{'='*60}\n")
    
    if not violations:
        print("✓ Nenhuma violation encontrada!")
        return
    
    for v in violations:
        impact = v.get('impact', 'unknown').upper()
        symbol = {'CRITICAL': '🔴', 'SERIOUS': '🟠', 'MODERATE': '🟡', 'MINOR': '🔵'}.get(impact, '⚪')
        
        print(f"{symbol} [{impact}] {v.get('id')} — {v.get('description')}")
        print(f"   Critério WCAG: {', '.join(v.get('tags', []))}")
        print(f"   Elementos afetados: {len(v.get('nodes', []))}")
        
        for node in v.get('nodes', [])[:2]:  # Mostrar primeiros 2 elementos
            print(f"   → {node.get('html', '')[:100]}")
        print()

if __name__ == '__main__':
    data = json.load(sys.stdin)
    format_report(data)
```

---

## Checklist de Violations Comuns a Verificar

### Nível A (Obrigatório — Bloqueante)

- [ ] **1.1.1 Conteúdo Não Textual:** Todas as imagens têm atributo `alt` descritivo
- [ ] **1.3.1 Informação e Relações:** Estrutura HTML semântica (headings em ordem, listas, tabelas)
- [ ] **1.3.2 Sequência Significativa:** Ordem de leitura faz sentido sem CSS
- [ ] **2.1.1 Teclado:** Todos os elementos interativos acessíveis por teclado (Tab, Enter, Espaço)
- [ ] **2.4.1 Ignorar Blocos:** Link "Pular para o conteúdo" presente
- [ ] **2.4.2 Título da Página:** Cada página tem `<title>` único e descritivo
- [ ] **3.1.1 Idioma da Página:** `<html lang="pt-BR">` definido
- [ ] **4.1.1 Análise:** HTML válido, sem IDs duplicados, tags bem fechadas
- [ ] **4.1.2 Nome, Função, Valor:** Labels em todos os campos de formulário

### Nível AA (Obrigatório — Bloqueante)

- [ ] **1.4.3 Contraste (Mínimo):** Texto normal ≥ 4.5:1, texto grande ≥ 3:1
- [ ] **1.4.4 Redimensionar Texto:** Funciona até 200% sem perda de conteúdo
- [ ] **1.4.5 Imagens de Texto:** Sem texto embutido em imagens (exceto logotipos)
- [ ] **2.4.3 Ordem de Foco:** Ordem de foco do teclado lógica e sequencial
- [ ] **2.4.6 Cabeçalhos e Rótulos:** Cabeçalhos descritivos (não apenas "Clique aqui")
- [ ] **2.4.7 Foco Visível:** Indicador de foco visível em todos os elementos interativos
- [ ] **3.2.3 Navegação Consistente:** Menu de navegação consistente entre páginas
- [ ] **3.3.1 Identificação do Erro:** Erros de formulário descritos em texto
- [ ] **3.3.2 Rótulos ou Instruções:** Instruções claras para campos obrigatórios

---

## Resultados da Auditoria

### Resultados por Página (preencher após execução)

| Página | Violations Críticas | Violations Sérias | Violations Moderadas | Status |
|--------|--------------------|--------------------|---------------------|--------|
| Home | — | — | — | Pendente |
| About | — | — | — | Pendente |
| Pricing | — | — | — | Pendente |
| Blog | — | — | — | Pendente |
| Contact | — | — | — | Pendente |
| 404 | — | — | — | Pendente |

---

## Correções Prioritárias Esperadas

Com base em análise prévia do HTML gerado para websites Tailwind similares:

### Alta Probabilidade de Violations

1. **Contraste de cores** — Texto cinza claro sobre fundo branco pode não atingir 4.5:1
   - Correção: Aumentar escurecimento dos tons cinza (`text-gray-600` → `text-gray-700`)

2. **Imagens sem alt** — Imagens decorativas precisam de `alt=""`
   - Correção: Adicionar `alt=""` em imagens decorativas, alt descritivo nas informativas

3. **Foco visível** — Tailwind remove outline por padrão (`outline: none`)
   - Correção: Adicionar `focus:ring-2 focus:ring-blue-500` em todos os elementos interativos

4. **Labels de formulário** — Formulário de contato pode ter campos sem label associado
   - Correção: Usar `<label for="email">` ou `aria-label` em todos os inputs

5. **Ordem de headings** — Possível pulo de h2 para h4 em seções de features
   - Correção: Garantir hierarquia h1 → h2 → h3 sem pulos

---

## Exceções Aceitas

Violations que podem ser aceitas com justificativa documentada:

| Violation | Página | Justificativa | Aprovado por |
|-----------|--------|--------------|-------------|
| (a preencher após auditoria) | — | — | — |

---

## Integração no CI

```yaml
# .github/workflows/accessibility.yml
name: Accessibility Audit

on:
  pull_request:
    paths: ['website/**']

jobs:
  axe-audit:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install axe-cli
        run: npm install -g @axe-core/cli
      
      - name: Serve website
        run: |
          npm install -g serve
          serve website -p 8080 &
          sleep 3
      
      - name: Run accessibility audit
        run: |
          axe http://localhost:8080 \
            --tags wcag2a,wcag2aa,wcag21a,wcag21aa \
            --exit
          
          axe http://localhost:8080/pricing.html \
            --tags wcag2a,wcag2aa \
            --exit
          
          axe http://localhost:8080/contact.html \
            --tags wcag2a,wcag2aa \
            --exit
```

---

## Referências

- [WCAG 2.1 — W3C](https://www.w3.org/TR/WCAG21/)
- [axe-core — Deque](https://github.com/dequelabs/axe-core)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- [Lighthouse Audit — LS-160](./LS-160-lighthouse-audit.md)
- [Release Criteria — LS-166](./LS-166-release-criteria.md)
