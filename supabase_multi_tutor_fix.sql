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
