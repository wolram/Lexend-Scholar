# DPO — Encarregado de Dados (Data Protection Officer)

**Versão**: 1.0
**Data**: Abril 2026
**Referência Legal**: Lei Geral de Proteção de Dados (LGPD) — Art. 41

---

## O que é o DPO?

O Encarregado de Dados (DPO — Data Protection Officer) é a pessoa responsável por atuar como canal de comunicação entre o controlador de dados (Lexend Scholar), os titulares dos dados (alunos, responsáveis, professores) e a Autoridade Nacional de Proteção de Dados (ANPD).

A nomeação do DPO é **obrigatória** pela LGPD para controladores e operadores de dados pessoais, incluindo startups de SaaS que lidam com dados pessoais de usuários brasileiros.

---

## Base Legal

- **Art. 41 da LGPD**: Obrigatoriedade de indicar encarregado de dados
- **Art. 41, §1º**: Identificação do encarregado deve ser pública (nome e contato)
- **Art. 41, §2º**: Atribuições mínimas do encarregado
- **Resolução CD/ANPD nº 2/2022**: Detalha as obrigações do encarregado

---

## Responsabilidades do DPO

### Responsabilidades Obrigatórias (LGPD Art. 41, §2º)

1. **Aceitar reclamações e comunicações dos titulares**: Receber e responder solicitações de acesso, correção, portabilidade e exclusão de dados pessoais (DSAR — Data Subject Access Requests)

2. **Prestar esclarecimentos e adotar providências**: Orientar titulares sobre seus direitos e garantir que a empresa os respeite

3. **Receber comunicações da ANPD**: Ser o ponto de contato oficial com o regulador

4. **Orientar funcionários e contratados**: Garantir que toda a equipe entende e cumpre a LGPD

5. **Executar as demais atribuições determinadas pelo controlador**: Incluindo as listadas abaixo

### Responsabilidades Adicionais (Boas Práticas)

6. **Elaborar e manter o ROPA**: Registro de Operações de Tratamento de Dados (Art. 37)

7. **Conduzir DPIAs**: Data Protection Impact Assessments para novas features de alto risco

8. **Responder incidentes de dados**: Coordenar a resposta a incidentes e comunicação à ANPD (prazo: 72 horas)

9. **Revisar contratos com operadores**: Garantir que fornecedores e parceiros que processam dados também estejam em conformidade

10. **Manter a Política de Privacidade atualizada**: Revisar sempre que houver mudança no tratamento de dados

11. **Treinamento da equipe**: Conduizr treinamentos periódicos sobre LGPD

12. **Monitorar mudanças regulatórias**: Acompanhar resoluções da ANPD e atualizações jurídicas

---

## Quem Ocupa o Cargo

### Fase Atual (Early Stage — 2026)

**Opção recomendada para startups early-stage: Fundador como DPO Interno**

Para empresas em estágio inicial com equipe pequena, a recomendação é que o co-fundador mais próximo do produto e da tecnologia assuma o papel de DPO interno. Isso é:
- **Legal**: A LGPD não proíbe que o DPO seja funcionário da empresa
- **Prático**: O fundador tem visibilidade completa sobre como os dados são tratados
- **Econômico**: Elimina o custo de um DPO externo (~R$1.500-3.000/mês para PMEs)

**DPO Designado**: Marlow Sousa (Co-fundador & CTO)
**Contato público**: privacidade@lexendscholar.com

### Quando contratar DPO externo ou especializado?

Considerar transição para DPO externo/especializado quando:
- MRR superar R$100.000/mês (porte que aumenta o risco regulatório)
- Equipe superar 20 pessoas (volume de dados e complexidade aumentam)
- Ocorrer qualquer incidente de dados que exija resposta complexa à ANPD
- Iniciar processamento de dados de crianças em grande escala
- Investidores ou parceiros exigirem DPO certificado

**Fornecedores de DPO como Serviço (DPOaaS) para referência**:
- ICTS Protiviti — dpoaas.com.br
- Opice Blum Academy — dpo.academy
- TozziniFreire Advogados

---

## Contato Público do DPO

Conforme exigido pelo Art. 41, §1º da LGPD, a identidade e o contato do DPO devem ser públicos. Publicar em:

**Website**: lexendscholar.com/privacidade (seção "Contato do Encarregado")
**Texto a publicar**:
```
Encarregado de Dados (DPO):
Marlow Sousa
Email: privacidade@lexendscholar.com
Endereço: [endereço comercial da empresa]
```

**Nos termos de uso e política de privacidade**: Incluir referência ao DPO e contato
**No app iOS**: Settings → Privacidade → Contato do Encarregado de Dados

---

## Registro na ANPD

### Obrigatoriedade
A LGPD não exige registro formal do DPO na ANPD, mas exige que o DPO seja **identificado publicamente**. No entanto, a ANPD pode solicitar informações sobre o DPO em caso de fiscalização.

### Como manter conformidade
1. **Publicar o contato do DPO** em locais de fácil acesso (website, app, política de privacidade)
2. **Manter registro interno** da designação formal do DPO (ata de reunião ou documento assinado pelos sócios)
3. **Responder à ANPD** em caso de consulta ou fiscalização

### Documento de Designação Formal

```
DESIGNAÇÃO DE ENCARREGADO DE DADOS (DPO)

A empresa LEXEND SCHOLAR LTDA., inscrita no CNPJ sob nº XX.XXX.XXX/0001-XX,
por meio de seus sócios, designa como Encarregado de Dados (DPO), nos termos
do Art. 41 da Lei Geral de Proteção de Dados (Lei nº 13.709/2018):

Nome: Marlow Sousa
CPF: XXX.XXX.XXX-XX
Cargo: Co-fundador e CTO
Email: privacidade@lexendscholar.com

O Encarregado aceita a presente designação e se compromete a cumprir as
responsabilidades previstas na LGPD e nas regulamentações da ANPD.

São Paulo, [data]

_______________________          _______________________
Sócio 1                          DPO Designado
```

---

## Fluxo de Atendimento a Titulares (DSAR)

Quando o DPO recebe solicitação de titular:

```
Titular envia email para privacidade@lexendscholar.com
      ↓
DPO acusa recebimento em até 24h (resposta automática configurada)
      ↓
DPO verifica identidade do titular (solicitar documento se necessário)
      ↓
DPO processa a solicitação (acesso, correção, exclusão, portabilidade)
      ↓
DPO responde ao titular em até 15 dias (prazo legal)
      ↓
DPO registra a solicitação e resolução no ROPA
```

**Template de resposta automática de recebimento**:
```
Assunto: Recebemos sua solicitação — Privacidade Lexend Scholar

Olá,

Confirmamos o recebimento da sua solicitação relacionada à proteção de dados.

Nos termos da Lei Geral de Proteção de Dados (LGPD), responderemos em até
15 dias corridos. Caso precise de informações adicionais, entraremos em contato.

Número de protocolo: {PROTOCOLO-AAAA-NNNN}

Atenciosamente,
Marlow Sousa
Encarregado de Dados (DPO)
Lexend Scholar
privacidade@lexendscholar.com
```
