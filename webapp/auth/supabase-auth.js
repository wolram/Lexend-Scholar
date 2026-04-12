/**
 * supabase-auth.js
 * Lexend Scholar — Supabase Auth helpers for the web app.
 *
 * Provides:
 *  - Browser Supabase client (uses anon key, respects RLS)
 *  - signIn / signOut / resetPassword wrappers
 *  - getSession / getUser helpers
 *  - onAuthStateChange subscription helper
 *  - Typed session accessor that returns role + school_id from JWT metadata
 */

import { createClient } from '@supabase/supabase-js';

// ---------------------------------------------------------------------------
// Environment — these NEXT_PUBLIC_ vars are safe to expose to the browser
// ---------------------------------------------------------------------------
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  throw new Error(
    'Missing NEXT_PUBLIC_SUPABASE_URL or NEXT_PUBLIC_SUPABASE_ANON_KEY. ' +
    'Check your .env.local file.'
  );
}

// ---------------------------------------------------------------------------
// Singleton browser client
// ---------------------------------------------------------------------------
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    // Persist the session in localStorage so the tab stays logged in
    persistSession: true,
    autoRefreshToken: true,
    // Detect OAuth redirects automatically
    detectSessionInUrl: true,
  },
});

// ---------------------------------------------------------------------------
// Auth helpers
// ---------------------------------------------------------------------------

/**
 * Sign in with email and password.
 * Returns { session, user, error }.
 *
 * @param {string} email
 * @param {string} password
 */
export async function signIn(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) return { session: null, user: null, error };
  return { session: data.session, user: data.user, error: null };
}

/**
 * Sign out the current user and clear the local session.
 * Returns { error } — null on success.
 */
export async function signOut() {
  const { error } = await supabase.auth.signOut();
  return { error };
}

/**
 * Send a password reset email.
 * The email will contain a link that redirects to /reset-password.
 *
 * @param {string} email
 * @param {string} [redirectTo] — Override the redirect URL (defaults to app origin + /reset-password)
 */
export async function resetPassword(email, redirectTo) {
  const redirect = redirectTo || `${window.location.origin}/reset-password`;
  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: redirect,
  });
  return { error };
}

/**
 * Update the user's password after they've clicked the reset link.
 * Must be called while the user has a valid recovery session.
 *
 * @param {string} newPassword
 */
export async function updatePassword(newPassword) {
  const { error } = await supabase.auth.updateUser({ password: newPassword });
  return { error };
}

// ---------------------------------------------------------------------------
// Session & User accessors
// ---------------------------------------------------------------------------

/**
 * Returns the current active session or null.
 * Performs a lightweight network call to refresh the token if needed.
 */
export async function getSession() {
  const { data, error } = await supabase.auth.getSession();
  if (error) return null;
  return data.session;
}

/**
 * Returns the current user object or null.
 */
export async function getUser() {
  const { data, error } = await supabase.auth.getUser();
  if (error) return null;
  return data.user;
}

/**
 * Extracts the Lexend Scholar profile from the JWT metadata.
 * Returns { id, email, role, school_id } or null if not authenticated.
 *
 * role is read from app_metadata first, then user_metadata, defaulting to 'teacher'.
 * school_id is read from app_metadata first, then user_metadata.
 *
 * @returns {Promise<{id: string, email: string, role: string, school_id: string} | null>}
 */
export async function getProfile() {
  const user = await getUser();
  if (!user) return null;

  const role =
    user.app_metadata?.role ||
    user.user_metadata?.role ||
    'teacher';

  const school_id =
    user.app_metadata?.school_id ||
    user.user_metadata?.school_id ||
    null;

  return {
    id: user.id,
    email: user.email,
    role,
    school_id,
  };
}

// ---------------------------------------------------------------------------
// Auth state subscription
// ---------------------------------------------------------------------------

/**
 * Subscribe to auth state changes (SIGNED_IN, SIGNED_OUT, TOKEN_REFRESHED, etc.).
 * Returns the unsubscribe function — call it in useEffect cleanup.
 *
 * @param {(event: string, session: object | null) => void} callback
 * @returns {() => void} unsubscribe
 *
 * @example
 * useEffect(() => {
 *   const unsubscribe = onAuthStateChange((event, session) => {
 *     if (event === 'SIGNED_OUT') router.push('/login');
 *   });
 *   return unsubscribe;
 * }, []);
 */
export function onAuthStateChange(callback) {
  const { data: { subscription } } = supabase.auth.onAuthStateChange(callback);
  return () => subscription.unsubscribe();
}

// ---------------------------------------------------------------------------
// React hook — useAuth
// ---------------------------------------------------------------------------
// NOTE: This requires React. Import only in client components ('use client').

/**
 * useAuth — React hook that provides the current auth profile and loading state.
 *
 * Returns { profile, loading, signIn, signOut, resetPassword }
 *
 * @example
 * 'use client';
 * import { useAuth } from '@/webapp/auth/supabase-auth';
 *
 * export default function ProfileBadge() {
 *   const { profile, loading } = useAuth();
 *   if (loading) return <Spinner />;
 *   return <span>{profile?.email}</span>;
 * }
 */
export function useAuth() {
  // Dynamic import to avoid SSR issues — this file may also be imported server-side.
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const { useState, useEffect } = require('react');

  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Initial load
    getProfile().then((p) => {
      setProfile(p);
      setLoading(false);
    });

    // Subscribe to changes
    const unsubscribe = onAuthStateChange(async (event) => {
      if (event === 'SIGNED_OUT') {
        setProfile(null);
      } else {
        const p = await getProfile();
        setProfile(p);
      }
    });

    return unsubscribe;
  }, []);

  return { profile, loading, signIn, signOut, resetPassword };
}
