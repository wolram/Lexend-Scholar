// webapp/api/contato.js — Vercel Serverless Function
// LS-193: Endpoint POST /api/contato com Supabase + Resend

export default async function handler(req) {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405 });
  }

  const { nome, email, mensagem, escola } = await req.json();
  if (!nome || !email || !mensagem) {
    return new Response(JSON.stringify({ error: 'Campos obrigatórios: nome, email, mensagem' }), { status: 400 });
  }

  const SUPABASE_URL = process.env.SUPABASE_URL;
  const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

  // Salvar lead no Supabase
  await fetch(`${SUPABASE_URL}/rest/v1/contact_leads`, {
    method: 'POST',
    headers: {
      'apikey': SUPABASE_SERVICE_KEY,
      'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
      'Content-Type': 'application/json',
      'Prefer': 'return=minimal'
    },
    body: JSON.stringify({ nome, email, mensagem, escola, created_at: new Date().toISOString() })
  }).catch(console.error); // non-blocking

  // Enviar email via Resend (opcional, graceful failure)
  const RESEND_API_KEY = process.env.RESEND_API_KEY;
  if (RESEND_API_KEY) {
    await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${RESEND_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: 'contato@lexendscholar.com.br',
        to: 'team@lexendscholar.com.br',
        subject: `Novo contato: ${nome} — ${escola || 'escola não informada'}`,
        html: `<p><strong>Nome:</strong> ${nome}</p><p><strong>Email:</strong> ${email}</p><p><strong>Escola:</strong> ${escola || '-'}</p><p><strong>Mensagem:</strong><br>${mensagem}</p>`
      })
    }).catch(console.error);
  }

  return new Response(JSON.stringify({ success: true, message: 'Mensagem enviada com sucesso!' }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  });
}
