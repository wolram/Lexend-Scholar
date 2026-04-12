# Contabilidade e NF-e — Lexend Scholar

**Versão**: 1.0
**Owner**: Financeiro / Operações
**Última atualização**: Abril 2026

---

## Stack Recomendado para SaaS Brasileiro

Para uma startup SaaS em estágio inicial no Brasil, recomendamos a seguinte stack financeira:

| Ferramenta | Função | Custo Estimado |
|---|---|---|
| **Conta Azul** | Contabilidade, DRE, gestão financeira, conciliação bancária | R$99-299/mês |
| **NFE.io** | Emissão automática de NFS-e e NF-e via API | R$99/mês + R$0,20/nota (até 500/mês) |
| **Stripe** | Cobrança e assinaturas (já configurado) | 3,99% + R$0,39 por transação BR |
| **Banco Inter PJ** | Conta bancária (sem tarifas, PIX grátis, API disponível) | Grátis |
| **Contador** | Escritório contábil para obrigações fiscais mensais | R$500-1.000/mês |

---

## Regime Tributário Recomendado: Simples Nacional

### Por que o Simples Nacional?

Para uma startup de SaaS em early stage (faturamento até R$4,8 milhões/ano), o **Simples Nacional — Anexo III (Serviços de Tecnologia)** é o regime mais vantajoso:

| Faixa de Faturamento (12 meses) | Alíquota Efetiva Estimada |
|---|---|
| Até R$180.000 | 6,0% |
| De R$180.001 a R$360.000 | 11,2% |
| De R$360.001 a R$720.000 | 13,5% |
| De R$720.001 a R$1.800.000 | 16,0% |
| De R$1.800.001 a R$3.600.000 | 21,0% |
| De R$3.600.001 a R$4.800.000 | 33,0% |

**Vantagens**:
- Pagamento unificado de impostos (IRPJ, CSLL, PIS, COFINS, CPP, ISS)
- Processo simplificado de apuração mensal
- Emissão de NFS-e mais simples (alguns municípios têm alíquota de ISS mínima de 2%)
- Menos obrigações acessórias

**Quando sair do Simples**:
- Faturamento ultrapassa R$4,8 milhões/ano → Lucro Presumido ou Real
- Acionistas com participação em outras empresas (verificar vedações)
- Atividade não permitida no Simples (verificar CNAE)

**CNAE recomendado**: 6201-5/01 — Desenvolvimento de programas de computador sob encomenda
**CNAE secundário**: 6311-9/00 — Tratamento de dados, provedores de serviços de aplicação

---

## Configuração do Conta Azul

### 1. Criar conta
1. Acesse [contaazul.com](https://contaazul.com)
2. Selecione plano adequado (Basic → R$99/mês é suficiente para early stage)
3. Configure empresa: CNPJ, regime tributário (Simples Nacional), conta bancária

### 2. Integrar com banco
1. Conectar conta corrente do Banco Inter (ou outro banco)
2. Configurar conciliação bancária automática
3. Categorizar transações: Receitas (SaaS), Despesas (Infraestrutura, Marketing, etc.)

### 3. Centros de custo a configurar
- Infraestrutura (AWS, Supabase, Vercel, Cloudflare)
- Marketing e Vendas (Google Ads, conteúdo, CRM)
- Produto (ferramentas de desenvolvimento, design)
- Administrativo (contador, jurídico, banco)
- Pessoal (pró-labore dos sócios)

### 4. Relatórios importantes
- **DRE Mensal**: Receita bruta, impostos, margem bruta, despesas, EBITDA
- **Fluxo de Caixa**: Entradas e saídas previstas vs realizadas
- **Inadimplência**: Clientes com pagamento em atraso

---

## Configuração do NFE.io

### O que é o NFE.io?

NFE.io é uma API para emissão automatizada de Notas Fiscais de Serviço (NFS-e), Notas Fiscais Eletrônicas (NF-e) e Notas Fiscais de Produto (NF-e).

Para o Lexend Scholar (SaaS = serviço de software), emitimos **NFS-e** a cada pagamento de assinatura.

### 1. Criar conta no NFE.io
1. Acesse [nfe.io](https://nfe.io)
2. Criar conta com CNPJ da empresa
3. Configurar certificado digital (A1 — arquivo .pfx) — obrigatório para emissão
4. Configurar dados fiscais: CNPJ, endereço, regime tributário, inscrição municipal

### 2. Obter certificado digital A1
- Custo: ~R$300/ano
- Emitido por: Certisign, Serasa Experian, Valid, ou outro autorizado
- Tipo: A1 (arquivo digital — não precisa de token físico)
- Para PJ: E-CNPJ A1

### 3. Configurar no NFE.io

```javascript
// Configuração da empresa no NFE.io
const nfeio = require('nfe.io')({
  apiKey: process.env.NFEIO_API_KEY,
  companyId: process.env.NFEIO_COMPANY_ID
});

// Configurações fiscais
// ISS: verificar alíquota do município (São Paulo: 2% para software)
// Item da lista: 1.05 — Licenciamento ou cessão de direito de uso de programas de computação
```

---

## Fluxo de Emissão Automática de NFS-e via Stripe Webhook

O fluxo completo é:

```
Escola paga assinatura
    ↓
Stripe dispara evento invoice.payment_succeeded
    ↓
Webhook handler processa o pagamento
    ↓
Sistema chama API do NFE.io para emitir NFS-e
    ↓
NFE.io emite nota na Prefeitura (via XML ABRASF)
    ↓
NFE.io retorna número da nota e PDF
    ↓
Sistema armazena nota no banco de dados
    ↓
Sistema envia PDF da nota por email para o responsável financeiro da escola
    ↓
Sistema registra receita no Conta Azul via API (opcional)
```

### Implementação do handler de emissão

```typescript
// lib/nfeio.ts
import axios from 'axios';

interface NFeIoServiceInvoice {
  cityServiceCode: string;  // Código do serviço no município (ex: "01.05" em SP)
  description: string;
  servicesAmount: number;   // Valor em reais (não centavos)
  borrower: {
    federalTaxNumber: string;  // CNPJ da escola cliente
    name: string;
    email: string;
    address: {
      country: string;
      state: string;
      city: string;
      district: string;
      additionalInformation: string;
      street: string;
      number: string;
      postalCode: string;
    };
  };
}

export async function emitirNFSe(school: School, invoice: StripeInvoice) {
  const amountInReais = invoice.amount_paid / 100;
  
  const serviceInvoice: NFeIoServiceInvoice = {
    cityServiceCode: '1.05', // Licenciamento de software — verificar código do município
    description: `Assinatura Lexend Scholar - Plano ${school.plan.toUpperCase()} - ${formatMonth(invoice.period_start)}`,
    servicesAmount: amountInReais,
    borrower: {
      federalTaxNumber: school.cnpj.replace(/\D/g, ''),
      name: school.legalName,
      email: school.financialEmail,
      address: {
        country: 'BRA',
        state: school.state,
        city: school.city,
        district: school.neighborhood,
        additionalInformation: school.addressComplement || '',
        street: school.street,
        number: school.addressNumber,
        postalCode: school.zipCode.replace(/\D/g, '')
      }
    }
  };

  try {
    const response = await axios.post(
      `https://api.nfe.io/v1/companies/${process.env.NFEIO_COMPANY_ID}/serviceinvoices`,
      serviceInvoice,
      {
        headers: {
          'Authorization': process.env.NFEIO_API_KEY,
          'Content-Type': 'application/json'
        }
      }
    );

    const nfse = response.data;
    
    // Salvar referência da NFS-e no banco
    await db.invoices.update({
      where: { stripeInvoiceId: invoice.id },
      data: {
        nfseId: nfse.id,
        nfseNumber: nfse.number,
        nfseStatus: nfse.status,
        nfsePdfUrl: nfse.pdfUrl
      }
    });

    // Enviar email com a NFS-e para o responsável financeiro da escola
    await sendNFSeEmail(school, nfse);
    
    return nfse;
    
  } catch (error) {
    // Log do erro + alerta no Slack para verificação manual
    console.error('Erro ao emitir NFS-e:', error);
    await notifySlack(`Falha na emissão de NFS-e para escola ${school.id} (invoice ${invoice.id})`);
    throw error;
  }
}
```

---

## Tratamento de NFS-e para Clientes Pessoa Física

Escolas geridas por MEI ou pessoa física (ex: professores com escola pequena) podem não ter CNPJ. Nesse caso:

- Emitir NFS-e com CPF do responsável (campo `federalTaxNumber` com CPF)
- ISS retido na fonte: verificar obrigatoriedade pelo município

---

## Obrigações Fiscais Mensais (Checklist)

| Obrigação | Prazo | Responsável | Ferramenta |
|---|---|---|---|
| Apuração do Simples Nacional (DAS) | Dia 20 do mês seguinte | Contador | Portal do Simples Nacional |
| Emissão das NFS-e | No ato do pagamento | Sistema automático | NFE.io |
| Conciliação bancária | Semanal | Founder | Conta Azul |
| DRE mensal | Primeiro dia útil do mês seguinte | Fundador + Contador | Conta Azul |
| DCTF (se aplicável) | Mensal | Contador | — |
| Folha de pagamento / pró-labore | Até dia 5 | Contador | — |

---

## Alíquotas de ISS por Município Principal

| Município | Alíquota ISS (Software/Serviços Tech) |
|---|---|
| São Paulo (SP) | 2% (mínimo constitucional) |
| Belo Horizonte (MG) | 2% |
| Curitiba (PR) | 2,5% |
| Porto Alegre (RS) | 3% |
| Rio de Janeiro (RJ) | 2% |
| Brasília (DF) | 2% |

**Nota**: A empresa paga ISS no município da sede, não onde o cliente está localizado. Verificar com o contador.

---

## Configuração do Conta Azul via API (Opcional)

Para registrar receitas automaticamente no Conta Azul quando o Stripe confirmar pagamento:

```typescript
// Registrar receita no Conta Azul
async function registrarReceitaContaAzul(invoice: StripeInvoice, school: School) {
  const response = await axios.post(
    'https://api.contaazul.com/v1/sales',
    {
      number: invoice.number,
      emission: new Date(invoice.created * 1000).toISOString().split('T')[0],
      customer: { personType: 'LEGAL', name: school.legalName, taxPayerIdentification: school.cnpj },
      services: [{
        description: `Assinatura Lexend Scholar - Plano ${school.plan}`,
        value: invoice.amount_paid / 100,
        service_code: 'SAAS_SUBSCRIPTION'
      }],
      payment: {
        type: 'PARCELED_RECEIPT',
        installments: [{ value: invoice.amount_paid / 100, due_date: new Date().toISOString().split('T')[0] }]
      }
    },
    { headers: { Authorization: `Bearer ${process.env.CONTA_AZUL_TOKEN}` } }
  );
  return response.data;
}
```
