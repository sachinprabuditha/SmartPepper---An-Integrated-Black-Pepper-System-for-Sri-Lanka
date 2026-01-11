'use client';

import { useState } from 'react';
import { X, FileCheck } from 'lucide-react';

interface AddCertificationModalProps {
  lotId: string;
  onClose: () => void;
  onSuccess: () => void;
}

const certTypes = [
  { value: 'organic', label: 'Organic Certification' },
  { value: 'fumigation', label: 'Fumigation Certificate' },
  { value: 'quality', label: 'Quality Certificate' },
  { value: 'export', label: 'Export License' },
  { value: 'phytosanitary', label: 'Phytosanitary Certificate' },
  { value: 'pesticide_test', label: 'Pesticide Test Report' },
  { value: 'halal', label: 'Halal Certification' },
  { value: 'origin', label: 'Certificate of Origin' },
];

export default function AddCertificationModal({ lotId, onClose, onSuccess }: AddCertificationModalProps) {
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    certType: 'organic',
    certNumber: '',
    issuer: '',
    issueDate: new Date().toISOString().split('T')[0],
    expiryDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (new Date(formData.expiryDate) < new Date(formData.issueDate)) {
      alert('Expiry date must be after issue date');
      return;
    }

    setLoading(true);

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/certifications`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          lotId,
          ...formData,
        }),
      });

      const data = await response.json();

      if (data.success) {
        alert('✓ Certification added successfully');
        onSuccess();
        onClose();
      } else {
        throw new Error(data.error || 'Failed to add certification');
      }
    } catch (error: any) {
      alert(`Error: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b">
          <div className="flex items-center space-x-3">
            <FileCheck className="w-6 h-6 text-green-600" />
            <h2 className="text-2xl font-bold">Add Certification</h2>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Info */}
        <div className="p-6 bg-blue-50 border-b">
          <p className="text-sm text-blue-800">
            Add certifications to improve compliance status and blockchain traceability
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          {/* Certificate Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Certificate Type *
            </label>
            <select
              value={formData.certType}
              onChange={(e) => setFormData({ ...formData, certType: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500"
              required
            >
              {certTypes.map((type) => (
                <option key={type.value} value={type.value}>
                  {type.label}
                </option>
              ))}
            </select>
          </div>

          {/* Certificate Number */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Certificate Number *
            </label>
            <input
              type="text"
              value={formData.certNumber}
              onChange={(e) => setFormData({ ...formData, certNumber: e.target.value })}
              placeholder="e.g., ORG-2025-001"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500"
              required
            />
          </div>

          {/* Issuer */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Issuing Authority *
            </label>
            <input
              type="text"
              value={formData.issuer}
              onChange={(e) => setFormData({ ...formData, issuer: e.target.value })}
              placeholder="e.g., Sri Lanka Organic Certification"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500"
              required
            />
          </div>

          {/* Dates */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Issue Date *
              </label>
              <input
                type="date"
                value={formData.issueDate}
                onChange={(e) => setFormData({ ...formData, issueDate: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Expiry Date *
              </label>
              <input
                type="date"
                value={formData.expiryDate}
                onChange={(e) => setFormData({ ...formData, expiryDate: e.target.value })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500"
                required
              />
            </div>
          </div>

          {/* Actions */}
          <div className="flex space-x-4 pt-4 border-t">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
              disabled={loading}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50"
              disabled={loading}
            >
              {loading ? 'Adding...' : 'Add Certification'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
