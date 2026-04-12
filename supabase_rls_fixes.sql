-- ============================================================
-- ROW LEVEL SECURITY (RLS) - FINAL STABLE VERSION (COMPATIBLE)
-- ============================================================

-- 1. Helper Functions
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
DROP POLICY IF EXISTS "Users: self_read" ON users;
DROP POLICY IF EXISTS "Users: self_update" ON users;
DROP POLICY IF EXISTS "Users: institute_read" ON users;
DROP POLICY IF EXISTS "Users: admin_all" ON users;

CREATE POLICY "Users: self_read" ON users FOR SELECT USING (id = auth.uid());
CREATE POLICY "Users: self_update" ON users FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY "Users: institute_read" ON users FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Users: admin_all" ON users FOR ALL USING (get_my_role() = 'admin');

-- 3. TUTORS Table Policies
ALTER TABLE tutors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Tutors: self_insert" ON tutors;
DROP POLICY IF EXISTS "Tutors: self_update" ON tutors;
DROP POLICY IF EXISTS "Tutors: self_select" ON tutors;
DROP POLICY IF EXISTS "Tutors: institute_read" ON tutors;
DROP POLICY IF EXISTS "Tutors: admin_all" ON tutors;

CREATE POLICY "Tutors: self_insert" ON tutors FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Tutors: self_update" ON tutors FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Tutors: self_select" ON tutors FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Tutors: institute_read" ON tutors FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Tutors: admin_all" ON tutors FOR ALL USING (get_my_role() = 'admin');

-- 4. STUDENTS Table Policies
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Students: self_insert" ON students;
DROP POLICY IF EXISTS "Students: self_update" ON students;
DROP POLICY IF EXISTS "Students: self_select" ON students;
DROP POLICY IF EXISTS "Students: institute_read" ON students;
DROP POLICY IF EXISTS "Students: admin_all" ON students;

CREATE POLICY "Students: self_insert" ON students FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Students: self_update" ON students FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Students: self_select" ON students FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Students: institute_read" ON students FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Students: admin_all" ON students FOR ALL USING (get_my_role() = 'admin');

-- 5. STAFF ATTENDANCE Table Policies
ALTER TABLE staff_attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "StaffAttendance: self_manage" ON staff_attendance;
DROP POLICY IF EXISTS "StaffAttendance: institute_read" ON staff_attendance;
DROP POLICY IF EXISTS "StaffAttendance: admin_all" ON staff_attendance;

-- Tutors/Staff can mark their own attendance
CREATE POLICY "StaffAttendance: self_manage" ON staff_attendance FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "StaffAttendance: institute_read" ON staff_attendance FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "StaffAttendance: admin_all" ON staff_attendance FOR ALL USING (get_my_role() = 'admin');

-- 6. TUTOR ATTENDANCE (Punch In/Out) Table Policies
ALTER TABLE tutor_attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "TutorAttendance: self_manage" ON tutor_attendance;
DROP POLICY IF EXISTS "TutorAttendance: admin_all" ON tutor_attendance;

CREATE POLICY "TutorAttendance: self_manage" ON tutor_attendance FOR ALL USING (tutor_id = auth.uid()) WITH CHECK (tutor_id = auth.uid());
CREATE POLICY "TutorAttendance: admin_all" ON tutor_attendance FOR ALL USING (get_my_role() = 'admin');

-- 7. ATTENDANCE (Students) Table Policies
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Attendance: institute_read" ON attendance;
DROP POLICY IF EXISTS "Attendance: staff_all" ON attendance;

CREATE POLICY "Attendance: institute_read" ON attendance FOR SELECT USING (institute_id = get_my_institute_id());
CREATE POLICY "Attendance: staff_all" ON attendance FOR ALL USING (get_my_role() IN ('admin', 'tutor'));
