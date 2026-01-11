-- Add escrow-related columns to auctions table
ALTER TABLE auctions 
ADD COLUMN IF NOT EXISTS escrow_deposited BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS escrow_amount NUMERIC(20, 8),
ADD COLUMN IF NOT EXISTS escrow_tx_hash VARCHAR(66),
ADD COLUMN IF NOT EXISTS escrow_deposited_at TIMESTAMPTZ;

-- Add missing columns to existing escrow_deposits table
ALTER TABLE escrow_deposits
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;

-- Rename depositor_address to exporter_address for consistency (only if not already renamed)
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'escrow_deposits' 
        AND column_name = 'depositor_address'
    ) THEN
        ALTER TABLE escrow_deposits 
        RENAME COLUMN depositor_address TO exporter_address;
    END IF;
END $$;

-- Rename transaction_hash to tx_hash for consistency (only if not already renamed)
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'escrow_deposits' 
        AND column_name = 'transaction_hash'
    ) THEN
        ALTER TABLE escrow_deposits 
        RENAME COLUMN transaction_hash TO tx_hash;
    END IF;
END $$;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_escrow_auction_id ON escrow_deposits(auction_id);
CREATE INDEX IF NOT EXISTS idx_escrow_user_id ON escrow_deposits(user_id);
CREATE INDEX IF NOT EXISTS idx_escrow_exporter_address ON escrow_deposits(exporter_address);
CREATE INDEX IF NOT EXISTS idx_escrow_status ON escrow_deposits(status);
CREATE INDEX IF NOT EXISTS idx_auctions_escrow ON auctions(escrow_deposited, auction_id);

-- Add comments
COMMENT ON COLUMN escrow_deposits.verified IS 'Whether the blockchain transaction has been verified';
COMMENT ON COLUMN escrow_deposits.user_id IS 'Reference to the user who deposited the escrow';
