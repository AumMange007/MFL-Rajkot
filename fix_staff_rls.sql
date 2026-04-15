-- 🚀 PATCH: Comprehensive Staff & Manager RLS Permissions

-- 1. ATTENDANCE TABLE (Used for Student Attendance)
-- Allow Staff to mark exactly like Tutors and Admins do
DROP POLICY IF EXISTS "Attendance: staff_edit" ON attendance;
DROP POLICY IF EXISTS "Attendance: tutor/admin manage" ON attendance;
DROP POLICY IF EXISTS "Attendance: staff_all" ON attendance;
CREATE POLICY "Attendance: manager_and_tutor_all" ON attendance 
  FOR ALL USING (get_my_role() IN ('admin', 'staff', 'tutor'));

-- 2. STAFF ATTENDANCE TABLE (Used for Punching In/Out)
-- Self policy
DROP POLICY IF EXISTS "StaffAttendance: self insert/update" ON staff_attendance;
CREATE POLICY "StaffAttendance: self insert/update" ON staff_attendance 
  FOR ALL USING (user_id = auth.uid());

-- Manager policy (Admin & Staff)
DROP POLICY IF EXISTS "StaffAttendance: admin manage" ON staff_attendance;
CREATE POLICY "StaffAttendance: manager_manage" ON staff_attendance 
  FOR ALL USING (get_my_role() IN ('admin', 'staff'));

-- 3. BATCHES TABLE
-- Staff need to be able to Manage Batches (create/delete)
DROP POLICY IF EXISTS "Batches: admin manage" ON batches;
CREATE POLICY "Batches: admin/staff manage" ON batches 
  FOR ALL USING (get_my_role() IN ('admin', 'staff'));

-- 4. STUDENTS TABLE
-- Staff need to be able to Manage/Add Students
DROP POLICY IF EXISTS "Students: admin manage" ON students;
CREATE POLICY "Students: admin/staff manage" ON students 
  FOR ALL USING (get_my_role() IN ('admin', 'staff'));

-- 5. USERS TABLE (Directory)
-- Staff need to be able to add/edit other Tutors or Staff
DROP POLICY IF EXISTS "Users: admin manage" ON users;
CREATE POLICY "Users: admin/staff manage" ON users 
  FOR ALL USING (get_my_role() IN ('admin', 'staff'));
