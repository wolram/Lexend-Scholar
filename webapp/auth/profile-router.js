/**
 * profile-router.js
 * Lexend Scholar — Role-based routing for the web app.
 *
 * Determines where to send a user after login based on their role.
 * Also provides guards for page-level access control.
 *
 * Roles (from database_schema.sql role_type enum):
 *   admin | teacher | secretary | guardian | student
 */

// ---------------------------------------------------------------------------
// Route definitions per role
// ---------------------------------------------------------------------------

/**
 * Home route for each role after successful login.
 * @type {Record<string, string>}
 */
export const ROLE_HOME_ROUTES = {
  admin:     '/dashboard',
  secretary: '/dashboard',
  teacher:   '/turmas',
  guardian:  '/painel-responsavel',
  student:   '/painel-aluno',
};

/**
 * Allowed route prefixes for each role.
 * A role can access any route that starts with one of its allowed prefixes.
 * '*' means access to all authenticated routes.
 *
 * @type {Record<string, string[]>}
 */
export const ROLE_ALLOWED_ROUTES = {
  admin: ['*'],

  secretary: [
    '/dashboard',
    '/alunos',
    '/turmas',
    '/ocorrencias',
    '/declaracoes',
    '/comunicados',
    '/mensagens',
    '/eventos',
    '/financeiro',
    '/configuracoes',
  ],

  teacher: [
    '/turmas',
    '/frequencia',
    '/notas',
    '/comunicados',
    '/eventos',
    '/painel-professor',
  ],

  guardian: [
    '/painel-responsavel',
    '/mensagens',
    '/eventos',
  ],

  student: [
    '/painel-aluno',
    '/declaracoes',
  ],
};

/**
 * Display label for each role (used in UI).
 * @type {Record<string, string>}
 */
export const ROLE_LABELS = {
  admin:     'Administrador',
  secretary: 'Secretaria',
  teacher:   'Professor',
  guardian:  'Responsável',
  student:   'Aluno',
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * Returns the home route for a given role.
 * Falls back to '/dashboard' for unknown roles.
 *
 * @param {string} role
 * @returns {string}
 */
export function getProfileHomeRoute(role) {
  return ROLE_HOME_ROUTES[role] ?? '/dashboard';
}

/**
 * Returns the display label for a given role.
 *
 * @param {string} role
 * @returns {string}
 */
export function getRoleLabel(role) {
  return ROLE_LABELS[role] ?? role;
}

/**
 * Checks whether a given role is allowed to access a route.
 *
 * @param {string} role  — One of the role_type values
 * @param {string} pathname — e.g. '/alunos/123'
 * @returns {boolean}
 */
export function canAccess(role, pathname) {
  const allowed = ROLE_ALLOWED_ROUTES[role];
  if (!allowed) return false;
  if (allowed.includes('*')) return true;
  return allowed.some((prefix) => pathname === prefix || pathname.startsWith(prefix + '/'));
}

/**
 * Returns the redirect destination if the role is NOT allowed on the given path.
 * Returns null if access is granted.
 *
 * Usage in Next.js middleware:
 *   const redirect = getUnauthorizedRedirect(role, pathname);
 *   if (redirect) return NextResponse.redirect(new URL(redirect, req.url));
 *
 * @param {string} role
 * @param {string} pathname
 * @returns {string | null}  — URL to redirect to, or null if access is OK
 */
export function getUnauthorizedRedirect(role, pathname) {
  if (canAccess(role, pathname)) return null;
  // Send them to their own home instead of a generic 403
  return getProfileHomeRoute(role);
}

// ---------------------------------------------------------------------------
// Sidebar navigation items per role
// ---------------------------------------------------------------------------

/**
 * @typedef {Object} NavItem
 * @property {string} label
 * @property {string} href
 * @property {string} icon  — Name of a Lucide icon
 */

/**
 * Returns the sidebar navigation items for a given role.
 *
 * @param {string} role
 * @returns {NavItem[]}
 */
export function getSidebarNav(role) {
  /** @type {NavItem[]} */
  const shared = [
    { label: 'Eventos', href: '/eventos', icon: 'CalendarDays' },
  ];

  /** @type {Record<string, NavItem[]>} */
  const NAV = {
    admin: [
      { label: 'Dashboard',       href: '/dashboard',      icon: 'LayoutDashboard' },
      { label: 'Alunos',          href: '/alunos',         icon: 'Users' },
      { label: 'Turmas',          href: '/turmas',         icon: 'BookOpen' },
      { label: 'Frequência',      href: '/frequencia',     icon: 'ClipboardCheck' },
      { label: 'Notas',           href: '/notas',          icon: 'GraduationCap' },
      { label: 'Financeiro',      href: '/financeiro',     icon: 'DollarSign' },
      { label: 'Ocorrências',     href: '/ocorrencias',    icon: 'AlertTriangle' },
      { label: 'Declarações',     href: '/declaracoes',    icon: 'FileText' },
      { label: 'Comunicados',     href: '/comunicados',    icon: 'Megaphone' },
      { label: 'Mensagens',       href: '/mensagens',      icon: 'MessageSquare' },
      ...shared,
      { label: 'Configurações',   href: '/configuracoes',  icon: 'Settings' },
    ],

    secretary: [
      { label: 'Dashboard',       href: '/dashboard',      icon: 'LayoutDashboard' },
      { label: 'Alunos',          href: '/alunos',         icon: 'Users' },
      { label: 'Turmas',          href: '/turmas',         icon: 'BookOpen' },
      { label: 'Ocorrências',     href: '/ocorrencias',    icon: 'AlertTriangle' },
      { label: 'Declarações',     href: '/declaracoes',    icon: 'FileText' },
      { label: 'Comunicados',     href: '/comunicados',    icon: 'Megaphone' },
      { label: 'Mensagens',       href: '/mensagens',      icon: 'MessageSquare' },
      ...shared,
    ],

    teacher: [
      { label: 'Minhas Turmas',   href: '/turmas',         icon: 'BookOpen' },
      { label: 'Frequência',      href: '/frequencia',     icon: 'ClipboardCheck' },
      { label: 'Notas',           href: '/notas',          icon: 'GraduationCap' },
      { label: 'Comunicados',     href: '/comunicados',    icon: 'Megaphone' },
      ...shared,
    ],

    guardian: [
      { label: 'Meu Painel',      href: '/painel-responsavel', icon: 'Home' },
      { label: 'Mensagens',       href: '/mensagens',      icon: 'MessageSquare' },
      ...shared,
    ],

    student: [
      { label: 'Meu Painel',      href: '/painel-aluno',   icon: 'Home' },
      { label: 'Declarações',     href: '/declaracoes',    icon: 'FileText' },
    ],
  };

  return NAV[role] ?? NAV.teacher;
}
