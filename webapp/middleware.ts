import { NextResponse, type NextRequest } from 'next/server';

const PUBLIC_PATHS = ['/login', '/api/', '/_next/', '/favicon'];
const PROTECTED_PATHS = ['/dashboard', '/alunos', '/turmas', '/financeiro', '/painel-responsavel'];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const isPublic = PUBLIC_PATHS.some(p => pathname.startsWith(p));
  if (isPublic) return NextResponse.next();

  const token = request.cookies.get('sb-access-token')?.value ||
                request.cookies.get('supabase-auth-token')?.value;

  const isProtected = PROTECTED_PATHS.some(p => pathname.startsWith(p));
  if (isProtected && !token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  return NextResponse.next();
}

export const config = { matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'] };
