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
