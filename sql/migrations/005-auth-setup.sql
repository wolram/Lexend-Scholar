-- ============================================================
-- LS-104: Autenticação via Supabase Auth
-- Migration: 005-auth-setup.sql
-- ============================================================

-- ------------------------------------------------------------
-- ENUM: roles do sistema
-- ------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM (
    'diretor',
    'coordenador',
    'professor',
    'secretaria',
    'responsavel'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ------------------------------------------------------------
-- Garantir que a tabela users existe com coluna auth_id
-- ------------------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS auth_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL;

-- ------------------------------------------------------------
-- FUNÇÃO: get_current_school_id()
-- Retorna o school_id do usuário autenticado via JWT
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_current_school_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT school_id
  FROM public.users
  WHERE auth_id = auth.uid()
  LIMIT 1;
$$;

-- ------------------------------------------------------------
-- FUNÇÃO: get_current_user_role()
-- Retorna o role do usuário autenticado via JWT
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role::TEXT
  FROM public.users
  WHERE auth_id = auth.uid()
  LIMIT 1;
$$;

-- ------------------------------------------------------------
-- FUNÇÃO: handle_new_auth_user()
-- Trigger que cria registro em public.users quando um novo
-- usuário é criado em auth.users
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_school_id UUID;
  v_role      role_type;
  v_full_name TEXT;
BEGIN
  -- Extrair metadados passados no signup
  v_school_id := (NEW.raw_user_meta_data->>'school_id')::UUID;
  v_role      := COALESCE(
                   (NEW.raw_user_meta_data->>'role')::role_type,
                   'teacher'::role_type
                 );
  v_full_name := COALESCE(
                   NEW.raw_user_meta_data->>'full_name',
                   NEW.email
                 );

  -- Só cria registro se school_id foi fornecido
  IF v_school_id IS NOT NULL THEN
    INSERT INTO public.users (
      auth_id,
      school_id,
      email,
      full_name,
      role,
      active,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      v_school_id,
      NEW.email,
      v_full_name,
      v_role,
      TRUE,
      NOW(),
      NOW()
    )
    ON CONFLICT (email) DO UPDATE
      SET auth_id    = EXCLUDED.auth_id,
          updated_at = NOW();
  END IF;

  RETURN NEW;
END;
$$;

-- ------------------------------------------------------------
-- TRIGGER: on_auth_user_created
-- ------------------------------------------------------------
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_auth_user();

-- ------------------------------------------------------------
-- FUNÇÃO: get_current_user_id()
-- Retorna o UUID interno (public.users.id) do usuário logado
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_current_user_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id
  FROM public.users
  WHERE auth_id = auth.uid()
  LIMIT 1;
$$;

-- ------------------------------------------------------------
-- Índice para acelerar lookups por auth_id
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_users_auth_id ON public.users (auth_id);

COMMENT ON FUNCTION public.get_current_school_id() IS
  'Retorna o school_id do usuário autenticado. Usado em políticas RLS.';

COMMENT ON FUNCTION public.get_current_user_role() IS
  'Retorna o role (TEXT) do usuário autenticado. Usado em políticas RLS.';

COMMENT ON FUNCTION public.handle_new_auth_user() IS
  'Cria automaticamente um registro em public.users ao criar usuário em auth.users.';
