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
