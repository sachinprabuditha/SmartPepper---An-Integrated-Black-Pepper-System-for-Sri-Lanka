'use client';

import { useState } from 'react';
import { useAccount } from 'wagmi';

interface HarvestDetailsFormProps {
  onComplete: (data: any) => void;
}

export default function HarvestDetailsForm({ onComplete }: HarvestDetailsFormProps) {
  const { address } = useAccount();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    variety: 'Black Pepper',
    quantity: '',
    quality: 'A',
    harvestDate: new Date().toISOString().split('T')[0],
    origin: '',
    farmLocation: '',
    organicCertified: false,
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const lotId = `LOT-${Date.now()}`;

      const response = await fetch('http://localhost:3002/api/lots', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          lotId,
          farmerAddress: address,
          variety: formData.variety,
          quantity: parseFloat(formData.quantity),
          quality: formData.quality,
          harvestDate: formData.harvestDate,
          origin: formData.origin,
          farmLocation: formData.farmLocation,
          organicCertified: formData.organicCertified,
          certificateHash: '',
          certificateIpfsUrl: '',
          blockchainTxHash: '',
        }),
      });

      const result = await response.json();

      if (result.success) {
        onComplete({ lotId, ...formData });
      } else {
        alert('Failed to create lot: ' + result.message);
      }
    } catch (error) {
      console.error('Error creating lot:', error);
      alert('Failed to create lot');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Step 1: Harvest Details</h2>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Pepper Variety *
          </label>
          <select
            value={formData.variety}
            onChange={(e) => setFormData({ ...formData, variety: e.target.value })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            required
          >
            <option value="Black Pepper">Black Pepper</option>
            <option value="White Pepper">White Pepper</option>
            <option value="Red Pepper">Red Pepper</option>
            <option value="Green Pepper">Green Pepper</option>
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Quantity (kg) *
          </label>
          <input
            type="number"
            step="0.01"
            min="0"
            value={formData.quantity}
            onChange={(e) => setFormData({ ...formData, quantity: e.target.value })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            required
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Quality Grade *
          </label>
          <select
            value={formData.quality}
            onChange={(e) => setFormData({ ...formData, quality: e.target.value })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            required
          >
            <option value="AAA">AAA - Premium</option>
            <option value="AA">AA - High Quality</option>
            <option value="A">A - Standard</option>
            <option value="B">B - Commercial</option>
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Harvest Date *
          </label>
          <input
            type="date"
            value={formData.harvestDate}
            onChange={(e) => setFormData({ ...formData, harvestDate: e.target.value })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            required
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Origin (Region) *
          </label>
          <input
            type="text"
            value={formData.origin}
            onChange={(e) => setFormData({ ...formData, origin: e.target.value })}
            placeholder="e.g., Matale, Sri Lanka"
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            required
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Farm Location *
          </label>
          <input
            type="text"
            value={formData.farmLocation}
            onChange={(e) => setFormData({ ...formData, farmLocation: e.target.value })}
            placeholder="GPS coordinates or address"
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            required
          />
        </div>
      </div>

      <div className="flex items-center">
        <input
          type="checkbox"
          id="organic"
          checked={formData.organicCertified}
          onChange={(e) => setFormData({ ...formData, organicCertified: e.target.checked })}
          className="w-4 h-4 text-green-600 border-gray-300 rounded focus:ring-green-500"
        />
        <label htmlFor="organic" className="ml-2 text-sm text-gray-700">
          Organic Certified (Will require certificate upload in Step 3)
        </label>
      </div>

      <div className="pt-6 flex justify-end">
        <button
          type="submit"
          disabled={loading}
          className="px-8 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-400 font-medium"
        >
          {loading ? 'Creating Lot...' : 'Continue to Processing Stages'}
        </button>
      </div>
    </form>
  );
}
