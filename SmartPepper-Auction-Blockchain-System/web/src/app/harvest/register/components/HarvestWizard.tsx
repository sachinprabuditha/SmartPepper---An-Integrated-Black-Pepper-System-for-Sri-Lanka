'use client';

import { useState } from 'react';
import HarvestDetailsForm from './HarvestDetailsForm';
import ProcessingStagesForm from './ProcessingStagesForm';
import CertificateUploadForm from './CertificateUploadForm';
import ComplianceCheckPanel from './ComplianceCheckPanel';
import PassportConfirmation from './PassportConfirmation';

const steps = [
  { number: 1, name: 'Harvest Details', icon: '🌱' },
  { number: 2, name: 'Processing Stages', icon: '⚙️' },
  { number: 3, name: 'Certifications', icon: '📜' },
  { number: 4, name: 'Compliance Check', icon: '✓' },
  { number: 5, name: 'Create Passport', icon: '🎫' },
];

export default function HarvestWizard() {
  const [currentStep, setCurrentStep] = useState(1);
  const [lotId, setLotId] = useState<string>('');
  const [harvestData, setHarvestData] = useState<any>(null);

  const handleStepComplete = (stepNumber: number, data?: any) => {
    if (stepNumber === 1 && data?.lotId) {
      setLotId(data.lotId);
      setHarvestData(data);
    }
    setCurrentStep(stepNumber + 1);
  };

  const handleBack = () => {
    setCurrentStep(Math.max(1, currentStep - 1));
  };

  return (
    <div className="max-w-5xl mx-auto px-4 py-8">
      {/* Stepper */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          {steps.map((step, index) => (
            <div key={step.number} className="flex items-center flex-1">
              <div className="flex flex-col items-center">
                <div
                  className={`w-12 h-12 rounded-full flex items-center justify-center text-xl ${
                    currentStep === step.number
                      ? 'bg-green-600 text-white'
                      : currentStep > step.number
                      ? 'bg-green-500 text-white'
                      : 'bg-gray-300 text-gray-600'
                  }`}
                >
                  {step.icon}
                </div>
                <span
                  className={`mt-2 text-sm font-medium ${
                    currentStep === step.number
                      ? 'text-green-600'
                      : currentStep > step.number
                      ? 'text-green-500'
                      : 'text-gray-500'
                  }`}
                >
                  {step.name}
                </span>
              </div>
              {index < steps.length - 1 && (
                <div
                  className={`flex-1 h-1 mx-2 ${
                    currentStep > step.number ? 'bg-green-500' : 'bg-gray-300'
                  }`}
                />
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Step Content */}
      <div className="bg-white rounded-lg shadow-lg p-8">
        {currentStep === 1 && (
          <HarvestDetailsForm
            onComplete={(data) => handleStepComplete(1, data)}
          />
        )}
        {currentStep === 2 && (
          <ProcessingStagesForm
            lotId={lotId}
            onComplete={() => handleStepComplete(2)}
            onBack={handleBack}
          />
        )}
        {currentStep === 3 && (
          <CertificateUploadForm
            lotId={lotId}
            onComplete={() => handleStepComplete(3)}
            onBack={handleBack}
          />
        )}
        {currentStep === 4 && (
          <ComplianceCheckPanel
            lotId={lotId}
            onComplete={() => handleStepComplete(4)}
            onBack={handleBack}
          />
        )}
        {currentStep === 5 && (
          <PassportConfirmation
            lotId={lotId}
            harvestData={harvestData}
            onBack={handleBack}
          />
        )}
      </div>
    </div>
  );
}
