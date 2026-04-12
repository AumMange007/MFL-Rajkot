-- ============================================================
-- COACHING MANAGEMENT APP — COMPLETE SUPABASE SQL SCHEMA
-- ============================================================

-- 1. INSTITUTES
CREATE TABLE IF NOT EXISTS institutes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  slug       TEXT UNIQUE NOT NULL,
  latitude   DOUBLE PRECISION,
  longitude  DOUBLE PRECISION,
  radius_meters INTEGER DEFAULT 100, -- 100 meters default geofence
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. USERS (mirrors auth.users)
CREATE TABLE IF NOT EXISTS users (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  email        TEXT NOT NULL,
  username     TEXT UNIQUE,
  role         TEXT NOT NULL CHECK (role IN ('admin', 'tutor', 'student', 'staff')),
  institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
  avatar_url   TEXT,
  phone        TEXT,
  needs_password_reset BOOLEAN DEFAULT true,
  is_profile_complete BOOLEAN DEFAULT false,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- 3. BATCHES
CREATE TABLE IF NOT EXISTS batches (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL,
  tutor_id     UUID REFERENCES users(id) ON DELETE SET NULL,
  institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- 4. STUDENTS
CREATE TABLE IF NOT EXISTS students (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  batch_id     UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
  institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
  enrolled_at  TIMESTAMPTZ DEFAULT NOW(),
  
  -- Academic Progress
  language     TEXT DEFAULT 'German',
  level        TEXT DEFAULT 'A1',
  vocab_chap   TEXT DEFAULT '1',
  grammar_chap TEXT DEFAULT '1',
  kb_chap      TEXT DEFAULT '1',
  ub_chap      TEXT DEFAULT '1',
  
  -- Profile Data
  mobile        TEXT,
  parent_mobile TEXT,
  address       TEXT,
  dob           TEXT,
  progress_updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, batch_id)
);

-- 5. TUTORS (profile details)
CREATE TABLE IF NOT EXISTS tutors (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
  mobile       TEXT,
  address      TEXT,
  bio          TEXT,
  experience   TEXT,
  specialization TEXT,
  qualification TEXT,
  dob          TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- 6. ATTENDANCE
CREATE TABLE IF NOT EXISTS attendance (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id   UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  batch_id     UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
  date         DATE NOT NULL,
  status       TEXT NOT NULL CHECK (status IN ('present', 'absent', 'late')),
  institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
  marked_by    UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, batch_id, date)
);

-- 7. CONTENT LIBRARY
CREATE TABLE IF NOT EXISTS content_library (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title        TEXT NOT NULL,
  file_url     TEXT NOT NULL,
  type         TEXT NOT NULL CHECK (type IN ('pdf', 'image', 'video', 'other')),
  uploaded_by  UUID REFERENCES users(id) ON DELETE CASCADE,
  institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- 8. BATCH CONTENT
CREATE TABLE IF NOT EXISTS batch_content (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id   UUID NOT NULL REFERENCES content_library(id) ON DELETE CASCADE,
  batch_id     UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
  assigned_by  UUID REFERENCES users(id) ON DELETE SET NULL,
  assigned_at  TIMESTAMPTZ DEFAULT NOW(),
  institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
  UNIQUE(content_id, batch_id)
);

-- 9. ANNOUNCEMENTS
CREATE TABLE IF NOT EXISTS announcements (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title        TEXT NOT NULL,
  message      TEXT NOT NULL,
  institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
  created_by   UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- 10. TUTOR ATTENDANCE (Punch In/Out)
CREATE TABLE IF NOT EXISTS tutor_attendance (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tutor_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
  punch_in     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  punch_out    TIMESTAMPTZ,
  duration_minutes INTEGER,
  date         DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS staff_attendance (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
  date         DATE NOT NULL DEFAULT CURRENT_DATE,
  status       TEXT NOT NULL CHECK (status IN ('present', 'absent', 'late')),
  marked_by    UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE institutes      ENABLE ROW LEVEL SECURITY;
ALTER TABLE users           ENABLE ROW LEVEL SECURITY;
ALTER TABLE batches         ENABLE ROW LEVEL SECURITY;
ALTER TABLE students        ENABLE ROW LEVEL SECURITY;
ALTER TABLE tutors          ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance      ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_library ENABLE ROW LEVEL SECURITY;
ALTER TABLE batch_content   ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements   ENABLE ROW LEVEL SECURITY;
ALTER TABLE tutor_attendance ENABLE ROW LEVEL SECURITY;

-- Helper Functions
CREATE OR REPLACE FUNCTION get_my_institute_id() 
RETURNS UUID 
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT institute_id FROM public.users WHERE id = auth.uid();
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_my_role() 
RETURNS TEXT 
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$ LANGUAGE sql STABLE;

-- NEW: Helper to check if user has access (avoid recursion)
CREATE OR REPLACE FUNCTION has_role(required_roles TEXT[])
RETURNS BOOLEAN
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() 
    AND role = ANY(required_roles)
  );
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_email_from_username(uname TEXT)
RETURNS TEXT 
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT email FROM public.users WHERE username = uname LIMIT 1;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION delete_auth_user(target_uid UUID)
RETURNS VOID
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM auth.users WHERE id = target_uid;
END;
$$ LANGUAGE plpgsql;

-- 15. STAFF ATTENDANCE (Punch in/out)
CREATE TABLE IF NOT EXISTS staff_attendance (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
  punch_in_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  punch_out_at TIMESTAMPTZ,
  date         DATE NOT NULL DEFAULT CURRENT_DATE,
  location_lat DOUBLE PRECISION,
  location_lng DOUBLE PRECISION,
  is_on_premise BOOLEAN DEFAULT FALSE,
  status       TEXT DEFAULT 'present' -- present, late, on_duty
);

-- POLICIES

-- USERS
DROP POLICY IF EXISTS "Users: self read" ON users;
CREATE POLICY "Users: self read" ON users FOR SELECT USING (id = auth.uid());

DROP POLICY IF EXISTS "Users: read same institute" ON users;
-- Using a direct subquery that typically avoids recursion in most Supabase versions
-- but to be ultra-safe, we allow read if it's the SAME institute.
CREATE POLICY "Users: read same institute" ON users FOR SELECT USING (
  institute_id IN (SELECT institute_id FROM public.users WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "Users: admin can insert/update" ON users;
CREATE POLICY "Users: admin can insert/update" ON users FOR ALL USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

DROP POLICY IF EXISTS "Users: self update avatar" ON users;
CREATE POLICY "Users: self update avatar" ON users FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- TUTORS
DROP POLICY IF EXISTS "Tutors: read same institute" ON tutors;
CREATE POLICY "Tutors: read same institute" ON tutors FOR SELECT USING (institute_id = get_my_institute_id());

DROP POLICY IF EXISTS "Tutors: self update" ON tutors;
CREATE POLICY "Tutors: self update" ON tutors FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Tutors: self insert" ON tutors;
CREATE POLICY "Tutors: self insert" ON tutors FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Tutors: admin manage" ON tutors;
CREATE POLICY "Tutors: admin manage" ON tutors FOR ALL USING (has_role(ARRAY['admin']));

-- STUDENTS
DROP POLICY IF EXISTS "Students: read same institute" ON students;
CREATE POLICY "Students: read same institute" ON students FOR SELECT USING (institute_id = get_my_institute_id());

DROP POLICY IF EXISTS "Students: self update profile" ON students;
CREATE POLICY "Students: self update profile" ON students FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Students: admin manage" ON students;
CREATE POLICY "Students: admin manage" ON students FOR ALL USING (has_role(ARRAY['admin']));

-- STAFF ATTENDANCE
DROP POLICY IF EXISTS "StaffAttendance: read same institute" ON staff_attendance;
CREATE POLICY "StaffAttendance: read same institute" ON staff_attendance FOR SELECT USING (institute_id = get_my_institute_id());

DROP POLICY IF EXISTS "StaffAttendance: admin manage" ON staff_attendance;
CREATE POLICY "StaffAttendance: admin manage" ON staff_attendance FOR ALL USING (has_role(ARRAY['admin']));

-- BATCHES
DROP POLICY IF EXISTS "Batches: read same institute" ON batches;
CREATE POLICY "Batches: read same institute" ON batches FOR SELECT USING (institute_id = get_my_institute_id());

DROP POLICY IF EXISTS "Batches: admin manage" ON batches;
CREATE POLICY "Batches: admin manage" ON batches FOR ALL USING (has_role(ARRAY['admin']));

-- ATTENDANCE
DROP POLICY IF EXISTS "Attendance: read same institute" ON attendance;
CREATE POLICY "Attendance: read same institute" ON attendance FOR SELECT USING (institute_id = get_my_institute_id());

DROP POLICY IF EXISTS "Attendance: tutor/admin manage" ON attendance;
CREATE POLICY "Attendance: tutor/admin manage" ON attendance FOR ALL USING (has_role(ARRAY['admin', 'tutor']));

-- CONTENT/ANNOUNCEMENTS
DROP POLICY IF EXISTS "Content: read same institute" ON content_library;
CREATE POLICY "Content: read same institute" ON content_library FOR SELECT USING (institute_id = get_my_institute_id());

DROP POLICY IF EXISTS "Content: admin/tutor manage" ON content_library;
CREATE POLICY "Content: admin/tutor manage" ON content_library FOR ALL USING (has_role(ARRAY['admin', 'tutor']));

DROP POLICY IF EXISTS "Announcements: read same institute" ON announcements;
CREATE POLICY "Announcements: read same institute" ON announcements FOR SELECT USING (institute_id = get_my_institute_id());

DROP POLICY IF EXISTS "Announcements: admin/tutor manage" ON announcements;
CREATE POLICY "Announcements: admin/tutor manage" ON announcements FOR ALL USING (has_role(ARRAY['admin', 'tutor']));

-- ============================================================
-- TUTOR ATTENDANCE
DROP POLICY IF EXISTS "TutorAttendance: read same institute" ON tutor_attendance;
CREATE POLICY "TutorAttendance: read same institute" ON tutor_attendance FOR SELECT USING (institute_id = get_my_institute_id());

DROP POLICY IF EXISTS "TutorAttendance: self insert/update" ON tutor_attendance;
CREATE POLICY "TutorAttendance: self insert/update" ON tutor_attendance FOR ALL USING (tutor_id = auth.uid());

DROP POLICY IF EXISTS "TutorAttendance: admin manage" ON tutor_attendance;
CREATE POLICY "TutorAttendance: admin manage" ON tutor_attendance FOR ALL USING (has_role(ARRAY['admin']));

-- STORAGE (Profiles and Content Buckets)
-- ============================================================

-- Create buckets (needs to be run manually or via script if supported)
-- Profiles bucket: Public to read, Auth to upload
-- Content bucket: Private to read (authenticated), Admin/Tutor to upload

DROP POLICY IF EXISTS "Storage: Profile access" ON storage.objects;
CREATE POLICY "Storage: Profile access" ON storage.objects
  FOR SELECT USING (bucket_id = 'profiles');

DROP POLICY IF EXISTS "Storage: Profile upload self" ON storage.objects;
CREATE POLICY "Storage: Profile upload self" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'profiles' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Storage: Content read auth" ON storage.objects;
CREATE POLICY "Storage: Content read auth" ON storage.objects
  FOR SELECT USING (bucket_id = 'content' AND auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Storage: Content upload staff" ON storage.objects;
CREATE POLICY "Storage: Content upload staff" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'content' AND 
    (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'tutor')
  );
-- ============================================================
-- ROW LEVEL SECURITY (RLS) FIXES
-- ============================================================

-- RE-DEFINE Helper Functions to be more direct (SECURITY DEFINER bypasses RLS)
-- But we'll use direct subqueries in policies where possible for clarity.

-- USERS
-- ============================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users: self read" ON users;
CREATE POLICY "Users: self read" ON users FOR SELECT USING (id = auth.uid());

DROP POLICY IF EXISTS "Users: read same institute" ON users;
CREATE POLICY "Users: read same institute" ON users FOR SELECT USING (
  institute_id = (SELECT institute_id FROM public.users WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "Users: admin edit" ON users;
CREATE POLICY "Users: admin edit" ON users FOR ALL USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

DROP POLICY IF EXISTS "Users: self update avatar" ON users;
CREATE POLICY "Users: self update avatar" ON users FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- TUTORS
-- ============================================================
ALTER TABLE tutors ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Tutors: institute read" ON tutors;
CREATE POLICY "Tutors: institute read" ON tutors FOR SELECT USING (
  institute_id = (SELECT institute_id FROM public.users WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "Tutors: self update" ON tutors;
CREATE POLICY "Tutors: self update" ON tutors FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Tutors: self insert" ON tutors;
CREATE POLICY "Tutors: self insert" ON tutors FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Tutors: admin manage" ON tutors;
CREATE POLICY "Tutors: admin manage" ON tutors FOR ALL USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

-- STUDENTS
-- ============================================================
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Students: institute read" ON students;
CREATE POLICY "Students: institute read" ON students FOR SELECT USING (
  institute_id = (SELECT institute_id FROM public.users WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "Students: self update profile" ON students;
CREATE POLICY "Students: self update profile" ON students FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Students: admin manage" ON students;
CREATE POLICY "Students: admin manage" ON students FOR ALL USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

-- CONTENT LIBRARY
-- ============================================================
ALTER TABLE content_library ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Content: institute read" ON content_library;
CREATE POLICY "Content: institute read" ON content_library FOR SELECT USING (
  institute_id = (SELECT institute_id FROM public.users WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "Content: staff manage" ON content_library;
CREATE POLICY "Content: staff manage" ON content_library FOR ALL USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'staff', 'tutor')
);

-- BATCHES
-- ============================================================
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Batches: institute read" ON batches;
CREATE POLICY "Batches: institute read" ON batches FOR SELECT USING (
  institute_id = (SELECT institute_id FROM public.users WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "Batches: admin manage" ON batches;
CREATE POLICY "Batches: admin manage" ON batches FOR ALL USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) = 'admin'
);

-- ATTENDANCE
-- ============================================================
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Attendance: institute read" ON attendance;
CREATE POLICY "Attendance: institute read" ON attendance FOR SELECT USING (
  institute_id = (SELECT institute_id FROM public.users WHERE id = auth.uid())
);

DROP POLICY IF EXISTS "Attendance: staff edit" ON attendance;
CREATE POLICY "Attendance: staff edit" ON attendance FOR ALL USING (
  (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'tutor')
);
-- ============================================================
-- ROW LEVEL SECURITY (RLS) - FINAL STABLE VERSION
-- ============================================================

-- 1. Helper Functions (SECURITY DEFINER to bypass RLS and avoid recursion)
CREATE OR REPLACE FUNCTION get_my_institute_id() 
RETURNS UUID 
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT institute_id FROM public.users WHERE id = auth.uid();
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_my_role() 
RETURNS TEXT 
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$ LANGUAGE sql STABLE;

-- 2. Clean up old policies
-- We'll use the function approach which is the only reliable way to avoid recursion on the users table.

-- USERS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users: self read" ON users;
DROP POLICY IF EXISTS "Users: read same institute" ON users;
DROP POLICY IF EXISTS "Users: admin edit" ON users;
DROP POLICY IF EXISTS "Users: self update avatar" ON users;
DROP POLICY IF EXISTS "Users: selective access" ON users;

CREATE POLICY "Users: self access" ON users FOR ALL USING (id = auth.uid());
CREATE POLICY "Users: institute access" ON users FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Users: admin manage" ON users FOR ALL USING (get_my_role() = 'admin');

-- TUTORS
ALTER TABLE tutors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Tutors: institute read" ON tutors;
DROP POLICY IF EXISTS "Tutors: admin manage" ON tutors;
DROP POLICY IF EXISTS "Tutors: self update" ON tutors;
DROP POLICY IF EXISTS "Tutors: self insert" ON tutors;

CREATE POLICY "Tutors: institute read" ON tutors FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Tutors: self manage" ON tutors FOR ALL USING (user_id = auth.uid());
CREATE POLICY "Tutors: admin manage" ON tutors FOR ALL USING (get_my_role() = 'admin');

-- STUDENTS
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Students: institute read" ON students;
DROP POLICY IF EXISTS "Students: admin manage" ON students;
DROP POLICY IF EXISTS "Students: self update profile" ON students;

CREATE POLICY "Students: institute read" ON students FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Students: manage self" ON students FOR ALL USING (user_id = auth.uid());
CREATE POLICY "Students: admin manage" ON students FOR ALL USING (get_my_role() = 'admin');

-- CONTENT LIBRARY
ALTER TABLE content_library ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Content: institute read" ON content_library;
DROP POLICY IF EXISTS "Content: staff manage" ON content_library;

CREATE POLICY "Content: institute read" ON content_library FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Content: staff manage" ON content_library FOR ALL USING (get_my_role() IN ('admin', 'staff', 'tutor'));

-- BATCHES
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Batches: institute read" ON batches;
DROP POLICY IF EXISTS "Batches: admin manage" ON batches;

CREATE POLICY "Batches: institute read" ON batches FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Batches: admin manage" ON batches FOR ALL USING (get_my_role() = 'admin');

-- ATTENDANCE
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Attendance: institute read" ON attendance;
DROP POLICY IF EXISTS "Attendance: staff edit" ON attendance;

CREATE POLICY "Attendance: institute read" ON attendance FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Attendance: staff edit" ON attendance FOR ALL USING (get_my_role() IN ('admin', 'tutor'));
-- ============================================================
-- ROW LEVEL SECURITY (RLS) - FINAL STABLE VERSION (COMPATIBLE)
-- ============================================================

-- 1. Restore Helper Functions (SECURITY DEFINER to bypass RLS and avoid recursion)
CREATE OR REPLACE FUNCTION get_my_institute_id() 
RETURNS UUID 
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT institute_id FROM public.users WHERE id = auth.uid();
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_my_role() 
RETURNS TEXT 
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$ LANGUAGE sql STABLE;

-- 2. USERS Table Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users: self access" ON users;
DROP POLICY IF EXISTS "Users: institute access" ON users;
DROP POLICY IF EXISTS "Users: admin manage" ON users;
DROP POLICY IF EXISTS "Users: self read" ON users;
DROP POLICY IF EXISTS "Users: read same institute" ON users;
DROP POLICY IF EXISTS "Users: admin edit" ON users;

CREATE POLICY "Users: self_all" ON users FOR ALL USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY "Users: institute_read" ON users FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Users: admin_manage" ON users FOR ALL USING (get_my_role() = 'admin');

-- 3. TUTORS Table Policies
ALTER TABLE tutors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Tutors: institute read" ON tutors;
DROP POLICY IF EXISTS "Tutors: self manage" ON tutors;
DROP POLICY IF EXISTS "Tutors: admin manage" ON tutors;

CREATE POLICY "Tutors: self_all" ON tutors FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Tutors: institute_read" ON tutors FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Tutors: admin_manage" ON tutors FOR ALL USING (get_my_role() = 'admin');

-- 4. STUDENTS Table Policies
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Students: institute read" ON students;
DROP POLICY IF EXISTS "Students: manage self" ON students;
DROP POLICY IF EXISTS "Students: admin manage" ON students;

CREATE POLICY "Students: self_all" ON students FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Students: institute_read" ON students FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Students: admin_manage" ON students FOR ALL USING (get_my_role() = 'admin');

-- 5. CONTENT LIBRARY Table Policies
ALTER TABLE content_library ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Content: institute read" ON content_library;
DROP POLICY IF EXISTS "Content: staff manage" ON content_library;

CREATE POLICY "Content: institute_read" ON content_library FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Content: staff_manage" ON content_library FOR ALL USING (get_my_role() IN ('admin', 'staff', 'tutor'));

-- 6. BATCHES Table Policies
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Batches: institute read" ON batches;
DROP POLICY IF EXISTS "Batches: admin manage" ON batches;

CREATE POLICY "Batches: institute_read" ON batches FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Batches: admin_manage" ON batches FOR ALL USING (get_my_role() = 'admin');

-- 7. ATTENDANCE Table Policies
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Attendance: institute read" ON attendance;
DROP POLICY IF EXISTS "Attendance: staff edit" ON attendance;

CREATE POLICY "Attendance: institute_read" ON attendance FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Attendance: staff_edit" ON attendance FOR ALL USING (get_my_role() IN ('admin', 'tutor'));
-- ============================================================
-- ROW LEVEL SECURITY (RLS) - FINAL STABLE VERSION (COMPATIBLE)
-- ============================================================

-- 1. Restore Helper Functions (SECURITY DEFINER to bypass RLS and avoid recursion)
CREATE OR REPLACE FUNCTION get_my_institute_id() 
RETURNS UUID 
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT institute_id FROM public.users WHERE id = auth.uid();
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_my_role() 
RETURNS TEXT 
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$ LANGUAGE sql STABLE;

-- 2. USERS Table Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users: self_all" ON users;
DROP POLICY IF EXISTS "Users: institute_read" ON users;
DROP POLICY IF EXISTS "Users: admin_manage" ON users;

CREATE POLICY "Users: self_read" ON users FOR SELECT USING (id = auth.uid());
CREATE POLICY "Users: self_update" ON users FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY "Users: institute_read" ON users FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Users: admin_all" ON users FOR ALL USING (get_my_role() = 'admin');

-- 3. TUTORS Table Policies
ALTER TABLE tutors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Tutors: self_all" ON tutors;
DROP POLICY IF EXISTS "Tutors: institute_read" ON tutors;
DROP POLICY IF EXISTS "Tutors: admin_manage" ON tutors;

-- Allow tutor to do anything with their own profile row
CREATE POLICY "Tutors: self_insert" ON tutors FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Tutors: self_update" ON tutors FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Tutors: self_select" ON tutors FOR SELECT USING (auth.uid() = user_id);

-- Allow everyone in institute to see tutor profiles
CREATE POLICY "Tutors: institute_read" ON tutors FOR SELECT USING (institute_id = get_my_institute_id());

-- Allow admin total control
CREATE POLICY "Tutors: admin_all" ON tutors FOR ALL USING (get_my_role() = 'admin');

-- 4. STUDENTS Table Policies
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Students: self_all" ON students;
DROP POLICY IF EXISTS "Students: institute_read" ON students;
DROP POLICY IF EXISTS "Students: admin_manage" ON students;

CREATE POLICY "Students: self_insert" ON students FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Students: self_update" ON students FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Students: self_select" ON students FOR SELECT USING (auth.uid() = user_id);

-- Allow everyone in institute to see student list/profiles
CREATE POLICY "Students: institute_read" ON students FOR SELECT USING (institute_id = get_my_institute_id());

-- Allow admin total control
CREATE POLICY "Students: admin_all" ON students FOR ALL USING (get_my_role() = 'admin');

-- 5. CONTENT LIBRARY Table Policies
ALTER TABLE content_library ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Content: institute_read" ON content_library;
DROP POLICY IF EXISTS "Content: staff_manage" ON content_library;

CREATE POLICY "Content: institute_read" ON content_library FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Content: staff_all" ON content_library FOR ALL USING (get_my_role() IN ('admin', 'staff', 'tutor'));

-- 6. BATCHES Table Policies
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Batches: institute_read" ON batches;
DROP POLICY IF EXISTS "Batches: admin_manage" ON batches;

CREATE POLICY "Batches: institute_read" ON batches FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Batches: admin_all" ON batches FOR ALL USING (get_my_role() = 'admin');

-- 7. ATTENDANCE Table Policies
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Attendance: institute_read" ON attendance;
DROP POLICY IF EXISTS "Attendance: staff_edit" ON attendance;

CREATE POLICY "Attendance: institute_read" ON attendance FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Attendance: staff_all" ON attendance FOR ALL USING (get_my_role() IN ('admin', 'tutor'));
-- 1. Create junction table for multiple tutors per batch
CREATE TABLE IF NOT EXISTS batch_tutors (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id     UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
  tutor_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  institute_id UUID NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(batch_id, tutor_id)
);

-- 2. Enable RLS
ALTER TABLE batch_tutors ENABLE ROW LEVEL SECURITY;

-- 3. Policies for batch_tutors
DROP POLICY IF EXISTS "BatchTutors: institute_read" ON batch_tutors;
CREATE POLICY "BatchTutors: institute_read" ON batch_tutors FOR SELECT USING (institute_id = get_my_institute_id());

DROP POLICY IF EXISTS "BatchTutors: admin_manage" ON batch_tutors;
CREATE POLICY "BatchTutors: admin_manage" ON batch_tutors FOR ALL USING (get_my_role() = 'admin');

-- 4. Clean up old tutor_id column if redundant (Optional, keeping for compatibility but we will primarily use the junction)
-- ALTER TABLE batches DROP COLUMN IF EXISTS tutor_id; 
-- Keeping it for now to avoid breaking existing queries that might not have updated yet.
-- STORAGE POLICIES
-- Note: These must be run in the SQL editor, but the buckets themselves
-- must be created in the Supabase Dashboard -> Storage tab first.

-- 1. CONTENT BUCKET POLICIES
-- Allow authenticated users to upload to their institute folder
DROP POLICY IF EXISTS "Content: upload" ON storage.objects;
CREATE POLICY "Content: upload" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'content');

-- Allow anyone (public) to view if the bucket is public, or authenticated users if private
DROP POLICY IF EXISTS "Content: select" ON storage.objects;
CREATE POLICY "Content: select" ON storage.objects FOR SELECT TO public USING (bucket_id = 'content');

-- 2. PROFILES BUCKET POLICIES
DROP POLICY IF EXISTS "Profiles: upload" ON storage.objects;
CREATE POLICY "Profiles: upload" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'profiles');

DROP POLICY IF EXISTS "Profiles: select" ON storage.objects;
CREATE POLICY "Profiles: select" ON storage.objects FOR SELECT TO public USING (bucket_id = 'profiles');
-- 1. Content Library Policies for Tutors
DROP POLICY IF EXISTS "Content: tutor_insert" ON content_library;
CREATE POLICY "Content: tutor_insert" ON content_library FOR INSERT TO authenticated WITH CHECK (get_my_role() IN ('admin', 'tutor'));

DROP POLICY IF EXISTS "Content: tutor_all" ON content_library;
CREATE POLICY "Content: tutor_all" ON content_library FOR ALL TO authenticated USING (get_my_role() IN ('admin', 'tutor'));

-- 2. Batch Content Policies (Mapping content to batches)
ALTER TABLE batch_content ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "BatchContent: tutor_manage" ON batch_content;
CREATE POLICY "BatchContent: tutor_manage" ON batch_content FOR ALL TO authenticated USING (get_my_role() IN ('admin', 'tutor'));

-- 3. Batches Read for Tutors
-- (Already handled by institute_read, but ensuring tutors can see everything in their institute)
DROP POLICY IF EXISTS "Batches: institute_read" ON batches;
CREATE POLICY "Batches: institute_read" ON batches FOR SELECT USING (institute_id = get_my_institute_id());
