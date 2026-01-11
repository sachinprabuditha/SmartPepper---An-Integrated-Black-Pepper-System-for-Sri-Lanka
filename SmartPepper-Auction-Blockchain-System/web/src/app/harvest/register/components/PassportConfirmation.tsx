'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

interface PassportConfirmationProps {
  lotId: string;
  harvestData: any;
  onBack: () => void;
}

export default function PassportConfirmation({ lotId, harvestData, onBack }: PassportConfirmationProps) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  const handleCreatePassport = async () => {
    setLoading(true);
    try {
      // In a full implementation, this would:
      // 1. Generate metadata JSON
      // 2. Upload to IPFS
      // 3. Mint NFT on blockchain
      // 4. Update lot with metadata_uri and blockchain tx hash

      // For now, we'll simulate success
      setTimeout(() => {
        alert('NFT Passport created successfully!');
        router.push('/dashboard/farmer/passports');
      }, 2000);
    } catch (error) {
      console.error('Error creating passport:', error);
      alert('Failed to create NFT passport');
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Step 5: Create NFT Passport</h2>

      <div className="bg-gradient-to-br from-green-50 to-blue-50 rounded-lg p-8 border-2 border-green-200">
        <div className="text-center mb-6">
          <div className="text-6xl mb-4">🎫</div>
          <h3 className="text-2xl font-bold text-gray-900 mb-2">NFT Digital Passport</h3>
          <p className="text-gray-600">
            Create a blockchain-verified digital passport for your pepper lot
          </p>
        </div>

        <div className="bg-white rounded-lg p-6 shadow-sm">
          <h4 className="font-semibold text-gray-900 mb-4">Lot Summary</h4>
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <span className="text-gray-600">Lot ID:</span>
              <div className="font-medium text-gray-900">{lotId}</div>
            </div>
            <div>
              <span className="text-gray-600">Variety:</span>
              <div className="font-medium text-gray-900">{harvestData?.variety}</div>
            </div>
            <div>
              <span className="text-gray-600">Quantity:</span>
              <div className="font-medium text-gray-900">{harvestData?.quantity} kg</div>
            </div>
            <div>
              <span className="text-gray-600">Quality:</span>
              <div className="font-medium text-gray-900">{harvestData?.quality}</div>
            </div>
            <div>
              <span className="text-gray-600">Origin:</span>
              <div className="font-medium text-gray-900">{harvestData?.origin}</div>
            </div>
            <div>
              <span className="text-gray-600">Harvest Date:</span>
              <div className="font-medium text-gray-900">
                {harvestData?.harvestDate && new Date(harvestData.harvestDate).toLocaleDateString()}
              </div>
            </div>
          </div>

          {harvestData?.organicCertified && (
            <div className="mt-4 p-3 bg-green-50 rounded-lg border border-green-200">
              <span className="text-green-800 font-medium">✓ Organic Certified</span>
            </div>
          )}
        </div>

        <div className="mt-6 space-y-3">
          <div className="flex items-start gap-3">
            <span className="text-green-600 text-xl">✓</span>
            <div className="flex-1">
              <div className="font-medium text-gray-900">Harvest details recorded</div>
              <div className="text-sm text-gray-600">Basic lot information stored on-chain</div>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <span className="text-green-600 text-xl">✓</span>
            <div className="flex-1">
              <div className="font-medium text-gray-900">Processing stages logged</div>
              <div className="text-sm text-gray-600">Complete traceability timeline</div>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <span className="text-green-600 text-xl">✓</span>
            <div className="flex-1">
              <div className="font-medium text-gray-900">Certifications uploaded</div>
              <div className="text-sm text-gray-600">Export compliance documentation</div>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <span className="text-green-600 text-xl">✓</span>
            <div className="flex-1">
              <div className="font-medium text-gray-900">Compliance checked</div>
              <div className="text-sm text-gray-600">Market-specific validation completed</div>
            </div>
          </div>
        </div>

        <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
          <p className="text-sm text-blue-800">
            <strong>📱 What happens next:</strong> Your NFT passport will be minted on the blockchain with a
            unique QR code. This passport can be scanned throughout the supply chain to verify authenticity and
            compliance.
          </p>
        </div>
      </div>

      <div className="pt-6 flex justify-between">
        <button
          type="button"
          onClick={onBack}
          className="px-8 py-3 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 font-medium"
        >
          Back
        </button>
        <button
          type="button"
          onClick={handleCreatePassport}
          disabled={loading}
          className="px-8 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-400 font-medium text-lg"
        >
          {loading ? 'Creating NFT Passport...' : '🎫 Create NFT Passport'}
        </button>
      </div>
    </div>
  );
}
