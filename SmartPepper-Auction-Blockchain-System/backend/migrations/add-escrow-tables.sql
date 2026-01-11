-- Add escrow columns to auctions table
ALTER TABLE auctions 
ADD COLUMN IF NOT EXISTS escrow_deposited BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS escrow_amount NUMERIC(20, 8),
ADD COLUMN IF NOT EXISTS escrow_tx_hash VARCHAR(66),
ADD COLUMN IF NOT EXISTS escrow_deposited_at TIMESTAMPTZ;

-- Create escrow_deposits table
CREATE TABLE IF NOT EXISTS escrow_deposits (
    id SERIAL PRIMARY KEY,
    auction_id INTEGER NOT NULL,
    user_id UUID REFERENCES users(id),
    exporter_address VARCHAR(42) NOT NULL,
    amount NUMERIC(20, 8) NOT NULL,
    tx_hash VARCHAR(66) NOT NULL UNIQUE,
    status VARCHAR(20) DEFAULT 'deposited' CHECK (status IN ('deposited', 'locked', 'released', 'refunded')),
    verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMPTZ,
    deposited_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_escrow_auction_id ON escrow_deposits(auction_id);
CREATE INDEX IF NOT EXISTS idx_escrow_user_id ON escrow_deposits(user_id);
CREATE INDEX IF NOT EXISTS idx_escrow_exporter_address ON escrow_deposits(exporter_address);
CREATE INDEX IF NOT EXISTS idx_escrow_status ON escrow_deposits(status);
CREATE INDEX IF NOT EXISTS idx_auctions_escrow ON auctions(escrow_deposited, auction_id);

COMMENT ON TABLE escrow_deposits IS 'Tracks escrow deposits for won auctions';
COMMENT ON COLUMN escrow_deposits.status IS 'Escrow status: deposited (initial), locked (in escrow), released (paid to farmer), refunded (returned to exporter)';
COMMENT ON COLUMN escrow_deposits.verified IS 'Whether the blockchain transaction has been verified';
