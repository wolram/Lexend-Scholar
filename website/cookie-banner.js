/**
 * Lexend Scholar — Cookie Consent Banner
 * Exibe banner de consentimento para cookies analíticos (Plausible Analytics).
 * Sem cookies de marketing ou PII. Conformidade LGPD / GDPR by design.
 *
 * Uso: incluir este script no <head> ou antes do </body> de cada página do website.
 * Exemplo: <script src="/cookie-banner.js"></script>
 */

(function () {
  'use strict';

  var STORAGE_KEY = 'cookies_accepted';
  var PLAUSIBLE_DOMAIN = 'lexendscholar.com.br';
  var PLAUSIBLE_SRC = 'https://plausible.io/js/script.js';

  // Carrega o script do Plausible Analytics dinamicamente
  function loadPlausible() {
    if (document.querySelector('script[src="' + PLAUSIBLE_SRC + '"]')) {
      return; // já carregado
    }
    var script = document.createElement('script');
    script.defer = true;
    script.setAttribute('data-domain', PLAUSIBLE_DOMAIN);
    script.src = PLAUSIBLE_SRC;
    document.head.appendChild(script);
  }

  // Verifica preferência salva e age de acordo
  function applyStoredPreference() {
    var stored = localStorage.getItem(STORAGE_KEY);
    if (stored === 'true') {
      loadPlausible();
      return true; // preferência já definida
    }
    if (stored === 'false') {
      return true; // preferência já definida (recusado)
    }
    return false; // sem preferência — exibir banner
  }

  // Remove o banner do DOM
  function removeBanner(banner) {
    if (banner && banner.parentNode) {
      banner.parentNode.removeChild(banner);
    }
  }

  // Cria e exibe o banner de consentimento
  function showBanner() {
    var banner = document.createElement('div');
    banner.id = 'ls-cookie-banner';
    banner.setAttribute('role', 'dialog');
    banner.setAttribute('aria-label', 'Aviso de cookies');
    banner.setAttribute('aria-live', 'polite');

    // Estilos inline para independência de framework CSS
    banner.style.cssText = [
      'position: fixed',
      'bottom: 0',
      'left: 0',
      'right: 0',
      'z-index: 9999',
      'background: #1e293b',
      'color: #f1f5f9',
      'padding: 14px 20px',
      'display: flex',
      'align-items: center',
      'justify-content: space-between',
      'flex-wrap: wrap',
      'gap: 12px',
      'font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
      'font-size: 14px',
      'line-height: 1.5',
      'box-shadow: 0 -2px 8px rgba(0,0,0,0.25)',
    ].join('; ');

    var text = document.createElement('p');
    text.style.cssText = 'margin: 0; flex: 1 1 280px;';
    text.innerHTML =
      'Usamos cookies analíticos (<strong>Plausible</strong>, sem dados pessoais). ' +
      '<a href="/docs/legal/cookie-policy.md" style="color:#93c5fd; text-decoration:underline;" target="_blank" rel="noopener">Saiba mais</a>.';

    var actions = document.createElement('div');
    actions.style.cssText = 'display: flex; gap: 10px; flex-shrink: 0;';

    var btnAccept = document.createElement('button');
    btnAccept.textContent = 'Aceitar';
    btnAccept.style.cssText = [
      'background: #3b82f6',
      'color: #fff',
      'border: none',
      'border-radius: 6px',
      'padding: 8px 18px',
      'font-size: 14px',
      'font-weight: 600',
      'cursor: pointer',
      'transition: background 0.2s',
    ].join('; ');
    btnAccept.addEventListener('mouseenter', function () {
      btnAccept.style.background = '#2563eb';
    });
    btnAccept.addEventListener('mouseleave', function () {
      btnAccept.style.background = '#3b82f6';
    });

    var btnDecline = document.createElement('button');
    btnDecline.textContent = 'Recusar';
    btnDecline.style.cssText = [
      'background: transparent',
      'color: #94a3b8',
      'border: 1px solid #475569',
      'border-radius: 6px',
      'padding: 8px 18px',
      'font-size: 14px',
      'font-weight: 500',
      'cursor: pointer',
      'transition: border-color 0.2s, color 0.2s',
    ].join('; ');
    btnDecline.addEventListener('mouseenter', function () {
      btnDecline.style.borderColor = '#94a3b8';
      btnDecline.style.color = '#f1f5f9';
    });
    btnDecline.addEventListener('mouseleave', function () {
      btnDecline.style.borderColor = '#475569';
      btnDecline.style.color = '#94a3b8';
    });

    // Aceitar: salvar preferência, carregar Plausible, remover banner
    btnAccept.addEventListener('click', function () {
      localStorage.setItem(STORAGE_KEY, 'true');
      loadPlausible();
      removeBanner(banner);
    });

    // Recusar: salvar preferência, bloquear Plausible, remover banner
    btnDecline.addEventListener('click', function () {
      localStorage.setItem(STORAGE_KEY, 'false');
      // Plausible NÃO é carregado
      removeBanner(banner);
    });

    actions.appendChild(btnAccept);
    actions.appendChild(btnDecline);
    banner.appendChild(text);
    banner.appendChild(actions);
    document.body.appendChild(banner);
  }

  // Inicialização: aguarda o DOM estar pronto
  function init() {
    var hasPreference = applyStoredPreference();
    if (!hasPreference) {
      showBanner();
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
