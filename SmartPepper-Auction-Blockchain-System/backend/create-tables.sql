-- Create processing_stages table
CREATE TABLE IF NOT EXISTS processing_stages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lot_id VARCHAR(50) REFERENCES pepper_lots(lot_id) ON DELETE CASCADE,
    stage_type VARCHAR(50) NOT NULL CHECK (stage_type IN ('harvest', 'drying', 'grading', 'packaging', 'storage')),
    stage_name VARCHAR(100) NOT NULL,
    location TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    operator_name VARCHAR(255),
    quality_metrics JSONB,
    notes TEXT,
    blockchain_tx_hash VARCHAR(66),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create certifications table
CREATE TABLE IF NOT EXISTS certifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lot_id VARCHAR(50) REFERENCES pepper_lots(lot_id) ON DELETE CASCADE,
    cert_type VARCHAR(50) NOT NULL CHECK (cert_type IN ('organic', 'fumigation', 'export', 'quality', 'phytosanitary')),
    cert_number VARCHAR(100) NOT NULL,
    issuer VARCHAR(255) NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    document_hash VARCHAR(66),
    ipfs_url TEXT,
    is_valid BOOLEAN DEFAULT true,
    verification_status VARCHAR(20) DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
    verified_by VARCHAR(255),
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create compliance_rules table
CREATE TABLE IF NOT EXISTS compliance_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_code VARCHAR(50) UNIQUE NOT NULL,
    rule_name VARCHAR(255) NOT NULL,
    destination_country VARCHAR(100),
    rule_category VARCHAR(50) CHECK (rule_category IN ('certification', 'packaging', 'labeling', 'quality', 'documentation')),
    rule_definition JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    severity VARCHAR(20) DEFAULT 'critical' CHECK (severity IN ('critical', 'major', 'minor', 'warning')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create compliance_checks table
CREATE TABLE IF NOT EXISTS compliance_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lot_id VARCHAR(50) REFERENCES pepper_lots(lot_id) ON DELETE CASCADE,
    destination VARCHAR(100) NOT NULL,
    check_timestamp TIMESTAMPTZ DEFAULT NOW(),
    overall_status VARCHAR(20) CHECK (overall_status IN ('passed', 'failed', 'pending')),
    results JSONB NOT NULL,
    checked_by VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_processing_stages_lot ON processing_stages(lot_id);
CREATE INDEX IF NOT EXISTS idx_processing_stages_type ON processing_stages(stage_type);
CREATE INDEX IF NOT EXISTS idx_processing_stages_timestamp ON processing_stages(timestamp);
CREATE INDEX IF NOT EXISTS idx_certifications_lot ON certifications(lot_id);
CREATE INDEX IF NOT EXISTS idx_certifications_type ON certifications(cert_type);
CREATE INDEX IF NOT EXISTS idx_certifications_valid ON certifications(is_valid);
CREATE INDEX IF NOT EXISTS idx_compliance_checks_lot ON compliance_checks(lot_id);
CREATE INDEX IF NOT EXISTS idx_compliance_rules_code ON compliance_rules(rule_code);
CREATE INDEX IF NOT EXISTS idx_compliance_rules_destination ON compliance_rules(destination_country);

-- Add compliance columns to pepper_lots if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='pepper_lots' AND column_name='compliance_status') THEN
        ALTER TABLE pepper_lots ADD COLUMN compliance_status VARCHAR(20) DEFAULT 'pending' 
        CHECK (compliance_status IN ('pending', 'checking', 'passed', 'failed'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='pepper_lots' AND column_name='compliance_checked_at') THEN
        ALTER TABLE pepper_lots ADD COLUMN compliance_checked_at TIMESTAMPTZ;
    END IF;
END $$;

-- Update pepper_lots status constraint to include 'available'
DO $$
BEGIN
    -- Drop old constraint if exists
    ALTER TABLE pepper_lots DROP CONSTRAINT IF EXISTS pepper_lots_status_check;
    
    -- Add new constraint
    ALTER TABLE pepper_lots ADD CONSTRAINT pepper_lots_status_check 
    CHECK (status IN ('created', 'available', 'pending_compliance', 'approved', 'rejected', 'auctioned'));
END $$;

COMMIT;
