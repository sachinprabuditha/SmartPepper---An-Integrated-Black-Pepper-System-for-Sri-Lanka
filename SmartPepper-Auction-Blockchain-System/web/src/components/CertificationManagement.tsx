'use client';

import { useState } from 'react';
import { FileCheck, CheckCircle, Plus } from 'lucide-react';
import AddCertificationModal from '@/components/AddCertificationModal';

interface CertificationManagementProps {
  lotId: string;
  onRefresh?: () => void;
}

export default function CertificationManagement({ lotId, onRefresh }: CertificationManagementProps) {
  const [showAddModal, setShowAddModal] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleRunComplianceCheck = async () => {
    const destination = prompt('Select destination market:\n1. EU\n2. FDA\n3. MIDDLE_EAST\n\nEnter (1/2/3):');
    
    const destinationMap: Record<string, string> = {
      '1': 'EU',
      '2': 'FDA',
      '3': 'MIDDLE_EAST',
    };

    const selectedDestination = destinationMap[destination || ''];
    if (!selectedDestination) {
      alert('Invalid selection');
      return;
    }

    setLoading(true);

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/api/compliance/check/${lotId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ destination: selectedDestination }),
      });

      const data = await response.json();

      if (data.success) {
        const status = data.complianceStatus;
        const passedCount = data.passedCount || 0;
        const failedCount = data.failedCount || 0;
        const totalCount = data.results?.length || 0;

        alert(`Compliance ${status === 'passed' ? 'Passed ✓' : 'Failed ✗'}\n\nTotal Checks: ${totalCount}\nPassed: ${passedCount}\nFailed: ${failedCount}\n\nView full details in the traceability page.`);
        
        if (onRefresh) onRefresh();
      } else {
        throw new Error(data.error || 'Compliance check failed');
      }
    } catch (error: any) {
      alert(`Error: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <div className="bg-white rounded-lg shadow-sm border p-6 mb-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center space-x-3">
            <div className="p-2 bg-blue-50 rounded-lg">
              <FileCheck className="w-6 h-6 text-blue-600" />
            </div>
            <div>
              <h3 className="text-lg font-semibold">Certifications & Compliance</h3>
              <p className="text-sm text-gray-600">Manage certificates and run compliance checks</p>
            </div>
          </div>
        </div>

        <div className="flex space-x-4">
          <button
            onClick={() => setShowAddModal(true)}
            className="flex-1 flex items-center justify-center space-x-2 px-4 py-3 border-2 border-blue-500 text-blue-600 rounded-lg hover:bg-blue-50 transition-colors"
          >
            <Plus className="w-5 h-5" />
            <span>Add Certificate</span>
          </button>

          <button
            onClick={handleRunComplianceCheck}
            disabled={loading}
            className="flex-1 flex items-center justify-center space-x-2 px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50"
          >
            {loading ? (
              <>
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white" />
                <span>Checking...</span>
              </>
            ) : (
              <>
                <CheckCircle className="w-5 h-5" />
                <span>Run Compliance Check</span>
              </>
            )}
          </button>
        </div>
      </div>

      {showAddModal && (
        <AddCertificationModal
          lotId={lotId}
          onClose={() => setShowAddModal(false)}
          onSuccess={() => {
            if (onRefresh) onRefresh();
          }}
        />
      )}
    </>
  );
}
