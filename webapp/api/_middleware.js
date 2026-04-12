// Shared auth helpers for Vercel Serverless Functions (Web Request/Response API)
// No Express — pure utility functions consumed by each handler file.
import { createClient } from '@supabase/supabase-js';

/**
 * Verify the Supabase JWT from the Authorization header.
 * Returns the user object { id, email, role, school_id } or null if invalid.
 */
export async function getAuthUser(request) {
  const authHeader = request.headers.get('authorization') || '';
  if (!authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.slice(7);

  // Use anon key client to verify the JWT — does NOT bypass RLS
  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data?.user) return null;

  const u = data.user;
  const schoolId = u.app_metadata?.school_id || u.user_metadata?.school_id;
  if (!schoolId) return null;

  return {
    id: u.id,
    email: u.email,
    role: u.app_metadata?.role || u.user_metadata?.role || 'teacher',
    school_id: schoolId,
  };
}

/**
 * Build a JSON Response with the given status code.
 */
export const jsonResponse = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });

/**
 * Build a JSON error Response.
 */
export const errResponse = (message, code, status) =>
  jsonResponse({ error: message, code }, status);

/**
 * Parse ?limit and ?offset query params with safe defaults.
 */
export function parsePagination(url) {
  const limit = Math.min(parseInt(url.searchParams.get('limit') || '50', 10), 200);
  const offset = parseInt(url.searchParams.get('offset') || '0', 10);
  return { limit, offset };
}

/**
 * Return a service-role Supabase client (server-side only — bypasses RLS).
 */
export function getSupabaseAdmin() {
  return createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );
}
