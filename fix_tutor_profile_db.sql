-- ============================================================
-- ADD TUTORS TABLE FOR PROFILE DATA
-- ============================================================

CREATE TABLE IF NOT EXISTS tutors (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
  mobile       TEXT,
  address      TEXT,
  bio          TEXT,
  experience   TEXT, -- e.g. "5 years"
  specialization TEXT, -- e.g. "A1-B2 German"
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- RLS POLICIES FOR TUTORS
-- ============================================================

ALTER TABLE tutors ENABLE ROW LEVEL SECURITY;

-- 1. Read: Tutors can see their own profile. Admins can see all.
CREATE POLICY "Tutors: read own/admin" ON tutors
  FOR SELECT USING (
    user_id = auth.uid() OR 
    (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
  );

-- 2. Insert: A tutor or admin can create a profile entry
CREATE POLICY "Tutors: self/admin insert" ON tutors
  FOR INSERT WITH CHECK (
    user_id = auth.uid() OR 
    (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
  );

-- 3. Update: A tutor can update their own profile, admin can update any
CREATE POLICY "Tutors: self/admin update" ON tutors
  FOR UPDATE USING (
    user_id = auth.uid() OR 
    (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
  );

-- 4. Delete: Admin only
CREATE POLICY "Tutors: admin delete" ON tutors
  FOR DELETE USING (
    (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
  );
