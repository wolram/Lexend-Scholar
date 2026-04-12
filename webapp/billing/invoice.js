/**
 * Lexend Scholar — Invoice / Recibo
 *
 * Funções para geração de recibos a partir de paymentIntents Stripe:
 *   - generateReceipt:    constrói objeto receipt a partir do paymentIntent expandido
 *   - formatReceiptHTML:  retorna HTML simples do recibo
 *   - sendReceiptEmail:   retorna objeto { to, subject, html } pronto para envio
 *
 * O paymentIntent deve ser expandido com: customer, invoice.subscription
 */

/**
 * generateReceipt
 * Constrói objeto receipt estruturado a partir de um paymentIntent expandido.
 *
 * @param {Stripe.PaymentIntent} paymentIntent — com expand: ['customer', 'invoice.subscription']
 * @returns {object} receipt
 */
export function generateReceipt(paymentIntent) {
  const invoice      = paymentIntent.invoice;
  const customer     = paymentIntent.customer;
  const subscription = invoice?.subscription;

  // Mapear plano a partir do price nickname ou metadata
  const planName = subscription?.items?.data?.[0]?.price?.nickname
    || subscription?.metadata?.plan
    || 'Lexend Scholar';

  // Número de recibo baseado no invoice number ou payment intent
  const receiptNumber = invoice?.number
    || `REC-${paymentIntent.id.slice(-8).toUpperCase()}`;

  return {
    receiptNumber,
    school: {
      id:    customer?.metadata?.school_id || null,
      name:  customer?.name  || 'Escola',
      email: customer?.email || '',
    },
    amount:   paymentIntent.amount,           // em centavos
    currency: paymentIntent.currency || 'brl',
    paidAt:   paymentIntent.created
      ? new Date(paymentIntent.created * 1000)
      : new Date(),
    period: {
      start: invoice?.period_start
        ? new Date(invoice.period_start * 1000)
        : null,
      end: invoice?.period_end
        ? new Date(invoice.period_end * 1000)
        : null,
    },
    planName,
    stripePaymentIntentId: paymentIntent.id,
    stripeInvoiceId:       invoice?.id || null,
    invoiceUrl:            invoice?.hosted_invoice_url || null,
  };
}

/**
 * formatReceiptHTML
 * Retorna HTML simples do recibo formatado em BRL.
 *
 * @param {object} receipt — retorno de generateReceipt()
 * @returns {string} HTML
 */
export function formatReceiptHTML(receipt) {
  const appUrl = process.env.APP_URL || 'https://app.lexendscholar.com.br';

  const formatBRL = (cents) =>
    new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })
      .format(cents / 100);

  const formatDate = (date) => date
    ? date.toLocaleDateString('pt-BR', { day: '2-digit', month: 'long', year: 'numeric' })
    : '—';

  const periodStr = receipt.period.start && receipt.period.end
    ? `${formatDate(receipt.period.start)} a ${formatDate(receipt.period.end)}`
    : '—';

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <title>Recibo ${receipt.receiptNumber}</title>
  <style>
    body { font-family: Arial, sans-serif; color: #1a1a1a; background: #f9f9f9; padding: 24px; }
    .container { max-width: 600px; margin: 0 auto; background: #fff; border-radius: 8px;
                 border: 1px solid #e0e0e0; padding: 40px; }
    .logo { height: 36px; margin-bottom: 24px; }
    h1 { font-size: 22px; color: #1E3A5F; margin-bottom: 4px; }
    .receipt-number { color: #666; font-size: 13px; margin-bottom: 32px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 24px; }
    td { padding: 10px 0; border-bottom: 1px solid #f0f0f0; font-size: 14px; }
    td:first-child { color: #666; width: 40%; }
    td:last-child { font-weight: 500; }
    .total-row td { border-bottom: none; font-size: 18px; font-weight: bold; color: #1E3A5F; }
    .footer { font-size: 12px; color: #999; margin-top: 32px; text-align: center; }
  </style>
</head>
<body>
  <div class="container">
    <img src="${appUrl}/logo.png" alt="Lexend Scholar" class="logo" />
    <h1>Recibo de Pagamento</h1>
    <div class="receipt-number">Nº ${receipt.receiptNumber}</div>

    <table>
      <tr>
        <td>Escola</td>
        <td>${receipt.school.name}</td>
      </tr>
      <tr>
        <td>Email</td>
        <td>${receipt.school.email}</td>
      </tr>
      <tr>
        <td>Plano</td>
        <td>${receipt.planName}</td>
      </tr>
      <tr>
        <td>Período</td>
        <td>${periodStr}</td>
      </tr>
      <tr>
        <td>Data do pagamento</td>
        <td>${formatDate(receipt.paidAt)}</td>
      </tr>
      <tr class="total-row">
        <td>Total pago</td>
        <td>${formatBRL(receipt.amount)}</td>
      </tr>
    </table>

    ${receipt.invoiceUrl
      ? `<p><a href="${receipt.invoiceUrl}" style="color: #1E3A5F;">Ver fatura completa no Stripe</a></p>`
      : ''}

    <div class="footer">
      Lexend Scholar — Sistema de Gestão Escolar<br />
      suporte@lexendscholar.com.br | lexendscholar.com.br
    </div>
  </div>
</body>
</html>`;
}

/**
 * sendReceiptEmail
 * Retorna objeto de email pronto para envio via SMTP/SES/SendGrid.
 *
 * @param {string} schoolEmail
 * @param {object} receipt — retorno de generateReceipt()
 * @returns {{ to: string, subject: string, html: string }}
 */
export function sendReceiptEmail(schoolEmail, receipt) {
  const formatBRL = (cents) =>
    new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })
      .format(cents / 100);

  return {
    to:      schoolEmail,
    subject: `Recibo de pagamento Lexend Scholar — ${receipt.receiptNumber}`,
    html:    formatReceiptHTML(receipt),
    text: [
      `Recibo Nº ${receipt.receiptNumber}`,
      `Escola: ${receipt.school.name}`,
      `Plano: ${receipt.planName}`,
      `Valor: ${formatBRL(receipt.amount)}`,
      `Data: ${receipt.paidAt.toLocaleDateString('pt-BR')}`,
      receipt.invoiceUrl ? `Fatura: ${receipt.invoiceUrl}` : '',
    ].filter(Boolean).join('\n'),
  };
}
