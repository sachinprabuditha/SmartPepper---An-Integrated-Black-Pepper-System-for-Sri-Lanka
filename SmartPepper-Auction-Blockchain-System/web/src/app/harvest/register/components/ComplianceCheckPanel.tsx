'use client';

import { useState } from 'react';

interface ComplianceCheckPanelProps {
  lotId: string;
  onComplete: () => void;
  onBack: () => void;
}

interface ComplianceResult {
  code: string;
  name: string;
  passed: boolean;
  severity: 'critical' | 'major' | 'minor';
  message: string;
}

export default function ComplianceCheckPanel({ lotId, onComplete, onBack }: ComplianceCheckPanelProps) {
  const [destination, setDestination] = useState('EU');
  const [results, setResults] = useState<ComplianceResult[]>([]);
  const [summary, setSummary] = useState<any>(null);
  const [complianceStatus, setComplianceStatus] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [checked, setChecked] = useState(false);

  const destinations = [
    { value: 'EU', label: 'European Union (EU)' },
    { value: 'FDA', label: 'United States (FDA)' },
    { value: 'MIDDLE_EAST', label: 'Middle East' },
  ];

  const handleRunCheck = async () => {
    setLoading(true);
    setChecked(false);
    try {
      const response = await fetch(`http://localhost:3002/api/compliance/check/${lotId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ destination }),
      });

      const result = await response.json();

      if (result.success) {
        setResults(result.results || []);
        setSummary(result.summary || {});
        setComplianceStatus(result.complianceStatus || 'unknown');
        setChecked(true);
      } else {
        alert('Failed to run compliance check: ' + result.message);
      }
    } catch (error) {
      console.error('Error running compliance check:', error);
      alert('Failed to run compliance check');
    } finally {
      setLoading(false);
    }
  };

  const handleContinue = () => {
    if (!checked) {
      const confirmSkip = window.confirm(
        'Compliance check not run. This lot may not be eligible for auction. Continue anyway?'
      );
      if (!confirmSkip) return;
    }
    if (complianceStatus === 'failed') {
      const confirmFailed = window.confirm(
        'Compliance check FAILED. This lot cannot be auctioned until issues are resolved. Continue to passport creation anyway?'
      );
      if (!confirmFailed) return;
    }
    onComplete();
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical':
        return 'text-red-700 bg-red-100 border-red-300';
      case 'major':
        return 'text-orange-700 bg-orange-100 border-orange-300';
      case 'minor':
        return 'text-yellow-700 bg-yellow-100 border-yellow-300';
      default:
        return 'text-gray-700 bg-gray-100 border-gray-300';
    }
  };

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Step 4: Compliance Check</h2>

      <div className="bg-white border border-gray-200 rounded-lg p-6">
        <h3 className="font-semibold text-gray-900 mb-4">Select Destination Market</h3>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
          {destinations.map((dest) => (
            <button
              key={dest.value}
              type="button"
              onClick={() => setDestination(dest.value)}
              className={`p-4 rounded-lg border-2 text-left transition-all ${
                destination === dest.value
                  ? 'border-green-600 bg-green-50'
                  : 'border-gray-300 bg-white hover:border-green-400'
              }`}
            >
              <div className="font-medium text-gray-900">{dest.label}</div>
              <div className="text-sm text-gray-500 mt-1">
                {dest.value === 'EU' && 'Organic, fumigation, quality checks'}
                {dest.value === 'FDA' && 'Phytosanitary, fumigation checks'}
                {dest.value === 'MIDDLE_EAST' && 'Halal certification checks'}
              </div>
            </button>
          ))}
        </div>

        <button
          type="button"
          onClick={handleRunCheck}
          disabled={loading}
          className="w-full px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 font-medium"
        >
          {loading ? 'Running Compliance Check...' : 'Run Compliance Check'}
        </button>
      </div>

      {/* Results */}
      {checked && (
        <div className="bg-white border border-gray-200 rounded-lg p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-gray-900">Compliance Results</h3>
            <div
              className={`px-4 py-2 rounded-full font-medium ${
                complianceStatus === 'passed'
                  ? 'bg-green-100 text-green-800'
                  : 'bg-red-100 text-red-800'
              }`}
            >
              {complianceStatus === 'passed' ? '✓ PASSED' : '✗ FAILED'}
            </div>
          </div>

          {summary && (
            <div className="grid grid-cols-4 gap-4 mb-6 p-4 bg-gray-50 rounded-lg">
              <div className="text-center">
                <div className="text-2xl font-bold text-gray-900">{summary.total || 0}</div>
                <div className="text-sm text-gray-600">Total Checks</div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-green-600">{summary.passed || 0}</div>
                <div className="text-sm text-gray-600">Passed</div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-red-600">{summary.failed || 0}</div>
                <div className="text-sm text-gray-600">Failed</div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-orange-600">{summary.criticalFailed || 0}</div>
                <div className="text-sm text-gray-600">Critical Failures</div>
              </div>
            </div>
          )}

          <div className="space-y-3">
            {results.map((result, index) => (
              <div
                key={index}
                className={`p-4 rounded-lg border ${
                  result.passed ? 'bg-green-50 border-green-200' : getSeverityColor(result.severity)
                }`}
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className="text-lg">
                        {result.passed ? '✓' : '✗'}
                      </span>
                      <span className="font-medium">{result.name}</span>
                      <span
                        className={`text-xs px-2 py-1 rounded ${
                          result.severity === 'critical'
                            ? 'bg-red-200 text-red-800'
                            : result.severity === 'major'
                            ? 'bg-orange-200 text-orange-800'
                            : 'bg-yellow-200 text-yellow-800'
                        }`}
                      >
                        {result.severity.toUpperCase()}
                      </span>
                    </div>
                    <div className="text-sm mt-1 text-gray-600">{result.message}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {complianceStatus === 'failed' && (
            <div className="mt-6 p-4 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-sm text-red-800">
                <strong>⚠️ Critical Compliance Failure:</strong> This lot cannot be listed for auction until all
                critical compliance issues are resolved. Please add the required certifications and re-run the
                check.
              </p>
            </div>
          )}
        </div>
      )}

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
          onClick={handleContinue}
          className="px-8 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium"
        >
          Continue to Create Passport
        </button>
      </div>
    </div>
  );
}
