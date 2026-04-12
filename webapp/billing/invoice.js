/**
 * Lexend Scholar — Geração Automática de Invoice / Recibo
 *
 * Fluxo:
 *   1. Stripe gera invoice automaticamente via subscription
 *   2. Webhook `invoice.paid` aciona syncInvoiceFromStripe()
 *   3. billing_invoices é atualizado no Supabase
 *   4. generateReceiptHtml() produz recibo HTML para PDF/e-mail
 *
 * Tabela utilizada: billing_invoices (ver database_schema.sql)
 */

import Stripe from 'stripe';
import { createClient } from '@supabase/supabase-js';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, { apiVersion: '2024-04-10' });

function getSupabase() {
  return createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);
}

// ---------------------------------------------------------------------------
// syncInvoiceFromStripe
// Sincroniza uma invoice Stripe → billing_invoices no Supabase.
// Chamado pelo webhook handler após invoice.paid / invoice.created.
// ---------------------------------------------------------------------------
export async function syncInvoiceFromStripe(stripeInvoice) {
  const supabase = getSupabase();

  // Busca escola pelo stripe_customer_id
  const { data: school } = await supabase
    .from('schools')
    .select('id')
    .eq('stripe_customer_id', stripeInvoice.customer)
    .single();

  if (!school) {
    console.warn(`[Invoice] No school for customer ${stripeInvoice.customer}`);
    return null;
  }

  const record = {
    school_id: school.id,
    stripe_invoice_id: stripeInvoice.id,
    stripe_payment_intent: stripeInvoice.payment_intent ?? null,
    amount_due: stripeInvoice.amount_due,
    amount_paid: stripeInvoice.amount_paid,
    currency: stripeInvoice.currency,
    status: mapStripeInvoiceStatus(stripeInvoice.status),
    invoice_url: stripeInvoice.hosted_invoice_url ?? null,
    invoice_pdf: stripeInvoice.invoice_pdf ?? null,
    period_start: stripeInvoice.period_start
      ? new Date(stripeInvoice.period_start * 1000).toISOString()
      : null,
    period_end: stripeInvoice.period_end
      ? new Date(stripeInvoice.period_end * 1000).toISOString()
      : null,
    paid_at: stripeInvoice.status_transitions?.paid_at
      ? new Date(stripeInvoice.status_transitions.paid_at * 1000).toISOString()
      : null,
    due_date: stripeInvoice.due_date
      ? new Date(stripeInvoice.due_date * 1000).toISOString().split('T')[0]
      : null,
    description: stripeInvoice.description ?? buildInvoiceDescription(stripeInvoice),
    updated_at: new Date().toISOString(),
  };

  const { data, error } = await supabase
    .from('billing_invoices')
    .upsert(record, { onConflict: 'stripe_invoice_id' })
    .select()
    .single();

  if (error) throw new Error(`syncInvoiceFromStripe failed: ${error.message}`);
  return data;
}

// ---------------------------------------------------------------------------
// getInvoices
// Lista invoices de uma escola para exibição no dashboard.
// ---------------------------------------------------------------------------
export async function getInvoices(schoolId, { limit = 12, offset = 0 } = {}) {
  const supabase = getSupabase();

  const { data, error, count } = await supabase
    .from('billing_invoices')
    .select('*', { count: 'exact' })
    .eq('school_id', schoolId)
    .order('created_at', { ascending: false })
    .range(offset, offset + limit - 1);

  if (error) throw new Error(`getInvoices failed: ${error.message}`);
  return { invoices: data || [], total: count || 0 };
}

// ---------------------------------------------------------------------------
// generateReceiptHtml
// Gera HTML do recibo para exibição ou conversão para PDF (puppeteer/wkhtmltopdf).
// ---------------------------------------------------------------------------
export function generateReceiptHtml({ invoice, school }) {
  const amountFormatted = formatBRL(invoice.amount_paid);
  const periodStr = formatPeriod(invoice.period_start, invoice.period_end);
  const paidDateStr = invoice.paid_at
    ? new Date(invoice.paid_at).toLocaleDateString('pt-BR')
    : '—';
  const invoiceNumber = invoice.stripe_invoice_id?.replace('in_', '') ?? invoice.id;

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8"/>
  <title>Recibo Lexend Scholar #${invoiceNumber}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Arial', sans-serif; color: #111418; background: #fff; padding: 48px; }
    .header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 40px; }
    .logo { display: flex; align-items: center; gap: 10px; }
    .logo-icon { width: 36px; height: 36px; background: #137fec; border-radius: 8px; display: flex; align-items: center; justify-content: center; }
    .logo-icon svg { width: 22px; height: 22px; fill: none; stroke: white; stroke-width: 2; }
    .logo-name { font-size: 18px; font-weight: 700; color: #111418; }
    .badge { background: #dcfce7; color: #166534; font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 100px; }
    .title { font-size: 24px; font-weight: 700; margin-bottom: 4px; }
    .subtitle { font-size: 13px; color: #617589; }
    .divider { border: none; border-top: 1px solid #e5e7eb; margin: 24px 0; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-bottom: 32px; }
    .field-label { font-size: 11px; color: #617589; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 4px; }
    .field-value { font-size: 14px; color: #111418; font-weight: 500; }
    .amount-box { background: #f1f3fd; border-radius: 12px; padding: 24px; text-align: center; margin-bottom: 32px; }
    .amount-label { font-size: 13px; color: #617589; margin-bottom: 8px; }
    .amount-value { font-size: 36px; font-weight: 700; color: #137fec; }
    .footer { font-size: 12px; color: #617589; text-align: center; line-height: 1.6; }
    .footer a { color: #137fec; text-decoration: none; }
  </style>
</head>
<body>
  <div class="header">
    <div class="logo">
      <div class="logo-icon">
        <svg viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.746 0 3.332.477 4.5 1.253v13C19.832 18.477 18.246 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/></svg>
      </div>
      <span class="logo-name">Lexend Scholar</span>
    </div>
    <span class="badge">PAGO</span>
  </div>

  <div class="title">Recibo de Pagamento</div>
  <div class="subtitle">Nº ${invoiceNumber}</div>

  <hr class="divider"/>

  <div class="grid">
    <div>
      <div class="field-label">Escola</div>
      <div class="field-value">${escHtml(school.name)}</div>
    </div>
    <div>
      <div class="field-label">E-mail</div>
      <div class="field-value">${escHtml(school.email)}</div>
    </div>
    <div>
      <div class="field-label">Plano</div>
      <div class="field-value">${escHtml(school.plan?.charAt(0).toUpperCase() + school.plan?.slice(1) || '—')}</div>
    </div>
    <div>
      <div class="field-label">Período de competência</div>
      <div class="field-value">${periodStr}</div>
    </div>
    <div>
      <div class="field-label">Data de pagamento</div>
      <div class="field-value">${paidDateStr}</div>
    </div>
    <div>
      <div class="field-label">Método</div>
      <div class="field-value">Cartão de crédito</div>
    </div>
  </div>

  <div class="amount-box">
    <div class="amount-label">Valor pago</div>
    <div class="amount-value">${amountFormatted}</div>
  </div>

  <hr class="divider"/>

  <div class="footer">
    Lexend Scholar — Gestão Escolar SaaS · CNPJ XX.XXX.XXX/0001-XX<br/>
    Dúvidas? <a href="mailto:financeiro@lexendscholar.com.br">financeiro@lexendscholar.com.br</a><br/>
    ${invoice.invoice_url ? `<a href="${escHtml(invoice.invoice_url)}">Ver fatura completa no Stripe</a>` : ''}
  </div>
</body>
</html>`;
}

// ---------------------------------------------------------------------------
// API Handler: GET /api/billing/invoices
// ---------------------------------------------------------------------------
export async function invoicesHandler(req, res) {
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

  const schoolId = req.session?.schoolId || req.headers['x-school-id'];
  if (!schoolId) return res.status(401).json({ error: 'Não autenticado' });

  try {
    const page = parseInt(req.query?.page || '1', 10);
    const limit = 12;
    const offset = (page - 1) * limit;
    const result = await getInvoices(schoolId, { limit, offset });
    return res.status(200).json(result);
  } catch (err) {
    console.error('[Invoice] invoicesHandler error:', err);
    return res.status(500).json({ error: 'Erro ao buscar invoices' });
  }
}

// ---------------------------------------------------------------------------
// API Handler: GET /api/billing/receipt/:invoiceId
// ---------------------------------------------------------------------------
export async function receiptHandler(req, res) {
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

  const schoolId = req.session?.schoolId || req.headers['x-school-id'];
  if (!schoolId) return res.status(401).json({ error: 'Não autenticado' });

  const supabase = getSupabase();
  const { invoiceId } = req.params;

  const { data: invoice } = await supabase
    .from('billing_invoices')
    .select('*')
    .eq('id', invoiceId)
    .eq('school_id', schoolId)
    .single();

  if (!invoice) return res.status(404).json({ error: 'Invoice não encontrada' });

  const { data: school } = await supabase
    .from('schools')
    .select('id, name, email, cnpj, plan')
    .eq('id', schoolId)
    .single();

  const html = generateReceiptHtml({ invoice, school });

  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  return res.status(200).send(html);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function mapStripeInvoiceStatus(status) {
  const map = { draft: 'draft', open: 'open', paid: 'paid', void: 'void', uncollectible: 'uncollectible' };
  return map[status] || 'draft';
}

function buildInvoiceDescription(inv) {
  if (!inv.period_start || !inv.period_end) return 'Assinatura Lexend Scholar';
  const start = new Date(inv.period_start * 1000).toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' });
  return `Assinatura Lexend Scholar — ${start}`;
}

function formatBRL(centavos) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(centavos / 100);
}

function formatPeriod(start, end) {
  if (!start || !end) return '—';
  const s = new Date(start).toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' });
  const e = new Date(end).toLocaleDateString('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' });
  return `${s} – ${e}`;
}

function escHtml(str) {
  return String(str || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}
