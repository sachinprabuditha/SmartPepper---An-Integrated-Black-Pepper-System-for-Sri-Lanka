'use client';

import { useState, useEffect } from 'react';
import { useAccount } from 'wagmi';
import { useRouter } from 'next/navigation';

interface Lot {
  lot_id: string;
  variety: string;
  quantity: number;
  quality: string;
  origin: string;
  farm_location: string;
  harvest_date: string;
  compliance_status: string;
  organic_certified: boolean;
  created_at: string;
}

export default function CreateAuctionPage() {
  const { address, isConnected } = useAccount();
  const router = useRouter();
  const [lots, setLots] = useState<Lot[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedLotId, setSelectedLotId] = useState<string>('');
  const [auctionData, setAuctionData] = useState({
    reservePrice: '',
    duration: '24',
    startTime: new Date().toISOString().slice(0, 16),
  });
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState({ type: '', text: '' });

  useEffect(() => {
    if (isConnected && address) {
      fetchCompliantLots();
    }
  }, [isConnected, address]);

  const fetchCompliantLots = async () => {
    setLoading(true);
    try {
      const response = await fetch(
        `http://localhost:3002/api/lots/farmer/${address}?compliance_status=passed`,
        {
          headers: {
            'Content-Type': 'application/json',
          },
        }
      );

      const result = await response.json();

      if (result.success) {
        setLots(result.lots || []);
      } else {
        console.error('Failed to fetch lots:', result.message);
      }
    } catch (error) {
      console.error('Error fetching compliant lots:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateAuction = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!selectedLotId) {
      setMessage({ type: 'error', text: 'Please select a lot to auction' });
      return;
    }

    setSubmitting(true);
    setMessage({ type: '', text: '' });

    try {
      const startTime = new Date(auctionData.startTime).getTime() / 1000;
      const endTime = startTime + parseInt(auctionData.duration) * 3600;

      const response = await fetch('http://localhost:3002/api/auctions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          lotId: selectedLotId,
          farmerAddress: address,
          reservePrice: parseFloat(auctionData.reservePrice),
          startTime: Math.floor(startTime),
          endTime: Math.floor(endTime),
        }),
      });

      const result = await response.json();

      if (result.success) {
        setMessage({
          type: 'success',
          text: 'Auction created successfully!',
        });
        setTimeout(() => {
          router.push('/dashboard/farmer');
        }, 2000);
      } else {
        setMessage({
          type: 'error',
          text: `Failed to create auction: ${result.message}`,
        });
      }
    } catch (error) {
      console.error('Error creating auction:', error);
      setMessage({
        type: 'error',
        text: 'Failed to create auction. Please try again.',
      });
    } finally {
      setSubmitting(false);
    }
  };

  const selectedLot = lots.find((lot) => lot.lot_id === selectedLotId);

  if (!isConnected) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="bg-white rounded-lg shadow-lg p-8 max-w-md w-full text-center">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Wallet Not Connected</h2>
          <p className="text-gray-600 mb-4">
            Please connect your wallet to create an auction.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-7xl mx-auto px-4">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Create Auction</h1>
          <p className="text-gray-600">
            Select a compliance-approved lot to list for auction
          </p>
        </div>

        {message.text && (
          <div
            className={`mb-6 p-4 rounded-lg ${
              message.type === 'success'
                ? 'bg-green-50 text-green-800 border border-green-200'
                : 'bg-red-50 text-red-800 border border-red-200'
            }`}
          >
            {message.text}
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Lot Selection */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-lg shadow-lg p-6">
              <h2 className="text-xl font-bold text-gray-900 mb-4">
                Step 1: Select Compliant Lot
              </h2>

              {loading ? (
                <div className="text-center py-12">
                  <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600 mx-auto"></div>
                  <p className="text-gray-600 mt-4">Loading compliant lots...</p>
                </div>
              ) : lots.length === 0 ? (
                <div className="text-center py-12">
                  <div className="text-6xl mb-4">📦</div>
                  <p className="text-gray-600 mb-4">
                    No compliance-approved lots available for auction
                  </p>
                  <button
                    onClick={() => router.push('/harvest/register')}
                    className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
                  >
                    Register New Harvest
                  </button>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {lots.map((lot) => (
                    <div
                      key={lot.lot_id}
                      onClick={() => setSelectedLotId(lot.lot_id)}
                      className={`cursor-pointer p-4 rounded-lg border-2 transition-all ${
                        selectedLotId === lot.lot_id
                          ? 'border-green-600 bg-green-50'
                          : 'border-gray-200 bg-white hover:border-green-400'
                      }`}
                    >
                      <div className="flex items-start justify-between mb-3">
                        <div>
                          <h3 className="font-semibold text-gray-900">{lot.variety}</h3>
                          <p className="text-sm text-gray-600">{lot.lot_id}</p>
                        </div>
                        <div className="flex items-center gap-2">
                          {lot.compliance_status === 'passed' && (
                            <span className="text-green-600 text-xl" title="Compliance Passed">
                              ✓
                            </span>
                          )}
                          {lot.organic_certified && (
                            <span className="text-blue-600 text-xl" title="Organic Certified">
                              🌱
                            </span>
                          )}
                        </div>
                      </div>

                      <div className="space-y-2 text-sm">
                        <div className="flex justify-between">
                          <span className="text-gray-600">Quantity:</span>
                          <span className="font-medium text-gray-900">{lot.quantity} kg</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Quality:</span>
                          <span className="font-medium text-gray-900">{lot.quality}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Origin:</span>
                          <span className="font-medium text-gray-900">{lot.origin}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Harvested:</span>
                          <span className="font-medium text-gray-900">
                            {new Date(lot.harvest_date).toLocaleDateString()}
                          </span>
                        </div>
                      </div>

                      <div className="mt-3 pt-3 border-t border-gray-200">
                        <div className="flex items-center gap-2">
                          <span className="px-2 py-1 text-xs rounded-full bg-green-100 text-green-800 font-medium">
                            ✓ Compliance Passed
                          </span>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Auction Details */}
          <div className="lg:col-span-1">
            <form onSubmit={handleCreateAuction} className="bg-white rounded-lg shadow-lg p-6 sticky top-6">
              <h2 className="text-xl font-bold text-gray-900 mb-4">
                Step 2: Auction Details
              </h2>

              {selectedLot && (
                <div className="mb-6 p-4 bg-green-50 rounded-lg border border-green-200">
                  <div className="text-sm text-green-800">
                    <div className="font-semibold mb-1">Selected Lot:</div>
                    <div>{selectedLot.variety}</div>
                    <div>{selectedLot.quantity} kg • Grade {selectedLot.quality}</div>
                  </div>
                </div>
              )}

              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Reserve Price (USD) *
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    min="0"
                    value={auctionData.reservePrice}
                    onChange={(e) =>
                      setAuctionData({ ...auctionData, reservePrice: e.target.value })
                    }
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
                    placeholder="0.00"
                    required
                  />
                  <p className="text-xs text-gray-500 mt-1">
                    Minimum bid amount to start the auction
                  </p>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Auction Duration (hours) *
                  </label>
                  <select
                    value={auctionData.duration}
                    onChange={(e) =>
                      setAuctionData({ ...auctionData, duration: e.target.value })
                    }
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
                    required
                  >
                    <option value="6">6 hours</option>
                    <option value="12">12 hours</option>
                    <option value="24">24 hours</option>
                    <option value="48">48 hours</option>
                    <option value="72">72 hours</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Start Time *
                  </label>
                  <input
                    type="datetime-local"
                    value={auctionData.startTime}
                    onChange={(e) =>
                      setAuctionData({ ...auctionData, startTime: e.target.value })
                    }
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
                    required
                  />
                  <p className="text-xs text-gray-500 mt-1">
                    Auction will start at this time
                  </p>
                </div>
              </div>

              <div className="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
                <p className="text-sm text-blue-800">
                  <strong>Important:</strong> Only compliance-passed lots can be auctioned.
                  Ensure all certifications are valid.
                </p>
              </div>

              <button
                type="submit"
                disabled={submitting || !selectedLotId}
                className="w-full mt-6 bg-green-600 text-white py-3 px-6 rounded-lg font-medium hover:bg-green-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors"
              >
                {submitting ? 'Creating Auction...' : '🔨 Create Auction'}
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}
