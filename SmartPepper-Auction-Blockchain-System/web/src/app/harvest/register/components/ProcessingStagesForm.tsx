'use client';

import { useState } from 'react';

interface ProcessingStagesFormProps {
  lotId: string;
  onComplete: () => void;
  onBack: () => void;
}

interface ProcessingStage {
  stageType: string;
  stageName: string;
  location: string;
  operatorName: string;
  qualityMetrics: Record<string, string>;
  notes: string;
}

export default function ProcessingStagesForm({ lotId, onComplete, onBack }: ProcessingStagesFormProps) {
  const [stages, setStages] = useState<ProcessingStage[]>([]);
  const [currentStage, setCurrentStage] = useState<ProcessingStage>({
    stageType: 'drying',
    stageName: '',
    location: '',
    operatorName: '',
    qualityMetrics: {},
    notes: '',
  });
  const [loading, setLoading] = useState(false);

  const stageTypes = [
    { value: 'harvest', label: 'Harvest', metrics: ['moisture', 'temperature'] },
    { value: 'drying', label: 'Drying', metrics: ['moisture', 'duration_hours', 'method'] },
    { value: 'grading', label: 'Grading', metrics: ['size', 'color', 'defects_percentage'] },
    { value: 'packaging', label: 'Packaging', metrics: ['package_material', 'package_type', 'weight', 'seal_number', 'labeling'] },
    { value: 'storage', label: 'Storage', metrics: ['temperature', 'humidity', 'location_code'] },
  ];

  const currentMetrics = stageTypes.find((st) => st.value === currentStage.stageType)?.metrics || [];

  const handleAddStage = async () => {
    setLoading(true);
    try {
      const response = await fetch('http://localhost:3002/api/processing/stages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          lotId,
          stageType: currentStage.stageType,
          stageName: currentStage.stageName,
          location: currentStage.location,
          operatorName: currentStage.operatorName,
          qualityMetrics: currentStage.qualityMetrics,
          notes: currentStage.notes,
        }),
      });

      const result = await response.json();

      if (result.success) {
        setStages([...stages, currentStage]);
        setCurrentStage({
          stageType: 'drying',
          stageName: '',
          location: '',
          operatorName: '',
          qualityMetrics: {},
          notes: '',
        });
      } else {
        alert('Failed to add stage: ' + result.message);
      }
    } catch (error) {
      console.error('Error adding stage:', error);
      alert('Failed to add processing stage');
    } finally {
      setLoading(false);
    }
  };

  const handleContinue = () => {
    if (stages.length === 0) {
      alert('Please add at least one processing stage');
      return;
    }
    onComplete();
  };

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Step 2: Processing Stages</h2>

      {/* Timeline of added stages */}
      {stages.length > 0 && (
        <div className="bg-green-50 rounded-lg p-4 mb-6">
          <h3 className="font-semibold text-green-900 mb-3">Added Stages ({stages.length})</h3>
          <div className="space-y-2">
            {stages.map((stage, index) => (
              <div key={index} className="flex items-center text-sm text-green-800">
                <span className="w-6 h-6 rounded-full bg-green-600 text-white flex items-center justify-center text-xs mr-3">
                  {index + 1}
                </span>
                <span className="font-medium">{stage.stageName}</span>
                <span className="mx-2">•</span>
                <span className="text-green-600">{stage.stageType}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Add new stage form */}
      <div className="bg-white border border-gray-200 rounded-lg p-6">
        <h3 className="font-semibold text-gray-900 mb-4">Add Processing Stage</h3>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Stage Type *</label>
            <select
              value={currentStage.stageType}
              onChange={(e) => setCurrentStage({ ...currentStage, stageType: e.target.value, qualityMetrics: {} })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            >
              {stageTypes.map((type) => (
                <option key={type.value} value={type.value}>
                  {type.label}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Stage Name *</label>
            <input
              type="text"
              value={currentStage.stageName}
              onChange={(e) => setCurrentStage({ ...currentStage, stageName: e.target.value })}
              placeholder="e.g., Sun Drying Phase 1"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Location *</label>
            <input
              type="text"
              value={currentStage.location}
              onChange={(e) => setCurrentStage({ ...currentStage, location: e.target.value })}
              placeholder="e.g., Farm Yard A"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Operator Name *</label>
            <input
              type="text"
              value={currentStage.operatorName}
              onChange={(e) => setCurrentStage({ ...currentStage, operatorName: e.target.value })}
              placeholder="e.g., John Doe"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            />
          </div>
        </div>

        {/* Quality Metrics */}
        <div className="mt-4">
          <label className="block text-sm font-medium text-gray-700 mb-2">Quality Metrics</label>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {currentMetrics.map((metric) => (
              <div key={metric}>
                <label className="block text-xs text-gray-600 mb-1">{metric.replace(/_/g, ' ')}</label>
                {metric === 'package_material' ? (
                  <select
                    value={currentStage.qualityMetrics[metric] || ''}
                    onChange={(e) =>
                      setCurrentStage({
                        ...currentStage,
                        qualityMetrics: { ...currentStage.qualityMetrics, [metric]: e.target.value },
                      })
                    }
                    className="w-full px-3 py-2 text-sm border border-gray-300 rounded focus:ring-2 focus:ring-green-500"
                  >
                    <option value="">Select material</option>
                    <option value="HDPE">HDPE (EU/FDA approved)</option>
                    <option value="PP">PP - Polypropylene (All markets)</option>
                    <option value="PET">PET (EU/FDA approved)</option>
                    <option value="Glass">Glass (FDA approved)</option>
                    <option value="Jute_with_liner">Jute with liner (Middle East preferred)</option>
                    <option value="Food_grade_plastic">Food grade plastic (All markets)</option>
                    <option value="FDA_approved_plastic">FDA approved plastic</option>
                  </select>
                ) : metric === 'method' && currentStage.stageType === 'drying' ? (
                  <select
                    value={currentStage.qualityMetrics[metric] || ''}
                    onChange={(e) =>
                      setCurrentStage({
                        ...currentStage,
                        qualityMetrics: { ...currentStage.qualityMetrics, [metric]: e.target.value },
                      })
                    }
                    className="w-full px-3 py-2 text-sm border border-gray-300 rounded focus:ring-2 focus:ring-green-500"
                  >
                    <option value="">Select method</option>
                    <option value="Sun">Sun Drying</option>
                    <option value="Mechanical">Mechanical Drying</option>
                    <option value="Shade">Shade Drying</option>
                    <option value="Hybrid">Hybrid (Sun + Mechanical)</option>
                  </select>
                ) : (
                  <input
                    type="text"
                    value={currentStage.qualityMetrics[metric] || ''}
                    onChange={(e) =>
                      setCurrentStage({
                        ...currentStage,
                        qualityMetrics: { ...currentStage.qualityMetrics, [metric]: e.target.value },
                      })
                    }
                    placeholder={
                      metric === 'moisture' 
                        ? 'e.g., 11.5 (EU≤12.5%, FDA≤13%, ME≤11%)' 
                        : metric === 'labeling'
                        ? 'e.g., Origin,Batch,Expiry (FDA required)'
                        : `Enter ${metric}`
                    }
                    className="w-full px-3 py-2 text-sm border border-gray-300 rounded focus:ring-2 focus:ring-green-500"
                  />
                )}
              </div>
            ))}
          </div>
          {currentStage.stageType === 'drying' && (
            <p className="mt-2 text-xs text-blue-600">
              💡 Moisture limits: EU ≤12.5%, FDA ≤13.0%, Middle East ≤11.0%
            </p>
          )}
          {currentStage.stageType === 'packaging' && (
            <p className="mt-2 text-xs text-blue-600">
              💡 Use food-grade materials for compliance. FDA requires origin, batch, and expiry labeling.
            </p>
          )}
        </div>

        <div className="mt-4">
          <label className="block text-sm font-medium text-gray-700 mb-2">Notes</label>
          <textarea
            value={currentStage.notes}
            onChange={(e) => setCurrentStage({ ...currentStage, notes: e.target.value })}
            rows={2}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            placeholder="Additional notes about this stage..."
          />
        </div>

        <button
          type="button"
          onClick={handleAddStage}
          disabled={loading || !currentStage.stageName || !currentStage.location || !currentStage.operatorName}
          className="mt-4 px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-400"
        >
          {loading ? 'Adding...' : 'Add Stage'}
        </button>
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
          onClick={handleContinue}
          disabled={stages.length === 0}
          className="px-8 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-400 font-medium"
        >
          Continue to Certifications
        </button>
      </div>
    </div>
  );
}
