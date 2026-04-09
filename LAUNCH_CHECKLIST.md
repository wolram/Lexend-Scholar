# Launch Checklist

Checklist pratico para colocar o website no ar com foco em um primeiro lancamento enxuto.

## Fase 1: Base do projeto

- [x] Isolar esta pasta em um repositorio Git proprio
- [x] Criar arquivos base do repositorio (`README.md`, `.gitignore`)
- [ ] Definir o website como escopo oficial do MVP de lancamento
- [ ] Escolher a pagina principal entre `homepage_lexend_scholar` e `landing_page_lexend_scholar`

## Fase 2: Consolidacao do site

- [ ] Transformar `website/` em uma estrutura unica de site
- [ ] Criar rotas reais para `/`, `/pricing` e `/blog`
- [ ] Unificar header, footer, identidade visual e CTAs
- [ ] Remover `href="#"` e placeholders de navegacao

## Fase 3: Conteudo final

- [ ] Revisar o posicionamento da marca "Lexend Scholar"
- [ ] Traduzir ou padronizar idioma do site inteiro
- [ ] Definir textos finais de hero, beneficios, provas sociais e CTA
- [ ] Validar precos, planos e proposta comercial
- [ ] Substituir artigos e autores ficticios do blog por conteudo real
- [ ] Adicionar contato comercial real (`email`, WhatsApp ou formulario)

## Fase 4: Assets e credibilidade

- [ ] Trocar imagens externas temporarias por assets proprios
- [ ] Adicionar favicon, logo final e imagem social para compartilhamento
- [ ] Criar paginas de Privacidade e Termos
- [ ] Preparar SEO basico: `title`, `meta description`, Open Graph e sitemap

## Fase 5: Pronto para producao

- [ ] Remover dependencia de Tailwind via CDN e configurar build local
- [ ] Adicionar configuracao de deploy para hospedagem estatica
- [ ] Configurar dominio, HTTPS e redirecionamento `www`
- [ ] Conectar analytics e evento de clique nos CTAs principais

## Fase 6: QA de lancamento

- [ ] Revisar responsividade mobile, tablet e desktop
- [ ] Testar formularios, botoes e links internos
- [ ] Corrigir acessibilidade basica: contraste, `alt`, hierarquia de headings
- [ ] Verificar performance e peso de imagens
- [ ] Fazer uma rodada final de revisao visual

## Ordem recomendada de execucao

1. Escolher a homepage oficial do MVP.
2. Consolidar as paginas em um unico site.
3. Fechar conteudo e contato comercial.
4. Configurar build e deploy.
5. Rodar QA e publicar.
