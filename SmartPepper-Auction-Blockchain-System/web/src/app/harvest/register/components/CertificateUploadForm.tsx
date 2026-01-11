'use client';

import { useState } from 'react';
import { uploadToIPFS, generateDocumentHash, validateFile } from '@/lib/ipfs';

interface CertificateUploadFormProps {
  lotId: string;
  onComplete: () => void;
  onBack: () => void;
}

interface Certificate {
  certType: string;
  certNumber: string;
  issuer: string;
  issueDate: string;
  expiryDate: string;
  documentHash?: string;
  ipfsUrl?: string;
  ipfsCid?: string;
}

export default function CertificateUploadForm({ lotId, onComplete, onBack }: CertificateUploadFormProps) {
  const [certificates, setCertificates] = useState<Certificate[]>([]);
  const [currentCert, setCurrentCert] = useState<Certificate>({
    certType: 'organic',
    certNumber: '',
    issuer: '',
    issueDate: new Date().toISOString().split('T')[0],
    expiryDate: '',
  });
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [uploadProgress, setUploadProgress] = useState<string>('');
  const [loading, setLoading] = useState(false);

  const certTypes = [
    { value: 'organic', label: 'Organic Certification', markets: 'EU (critical)' },
    { value: 'fumigation', label: 'Fumigation Certificate', markets: 'EU/FDA (critical)' },
    { value: 'phytosanitary', label: 'Phytosanitary Certificate', markets: 'FDA (critical)' },
    { value: 'pesticide_test', label: 'Pesticide Residue Test', markets: 'EU/FDA (critical)' },
    { value: 'halal', label: 'Halal Certification', markets: 'Middle East (major)' },
    { value: 'origin', label: 'Certificate of Origin', markets: 'Middle East (major)' },
    { value: 'export', label: 'Export License', markets: 'All markets' },
    { value: 'quality', label: 'Quality Certificate', markets: 'All markets' },
  ];

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    try {
      validateFile(file, 10); // Max 10MB
      setSelectedFile(file);
      setUploadProgress('');
    } catch (error) {
      alert(error instanceof Error ? error.message : 'Invalid file');
      e.target.value = ''; // Reset input
    }
  };

  const handleAddCertificate = async () => {
    setLoading(true);
    setUploadProgress('Preparing upload...');

    try {
      let documentHash = '';
      let ipfsUrl = '';
      let ipfsCid = '';

      // Upload document to IPFS if file selected
      if (selectedFile) {
        setUploadProgress('Generating document hash...');
        documentHash = await generateDocumentHash(selectedFile);

        setUploadProgress('Uploading to IPFS...');
        const ipfsResult = await uploadToIPFS(selectedFile);
        ipfsUrl = ipfsResult.ipfsUrl;
        ipfsCid = ipfsResult.cid;

        setUploadProgress('Upload complete! Saving to database...');
      } else {
        setUploadProgress('No document uploaded. Saving metadata...');
      }

      // Save certificate to database
      const response = await fetch('http://localhost:3002/api/certifications', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          lotId,
          certType: currentCert.certType,
          certNumber: currentCert.certNumber,
          issuer: currentCert.issuer,
          issueDate: currentCert.issueDate,
          expiryDate: currentCert.expiryDate,
          documentHash,
          ipfsUrl,
        }),
      });

      const result = await response.json();

      if (!response.ok) {
        alert('Failed to add certificate: ' + result.message);
        return;
      }

      // Add certificate to local state
      setCertificates([...certificates, { ...currentCert, documentHash, ipfsUrl, ipfsCid }]);

      // Reset form
      setCurrentCert({
        certType: 'organic',
        certNumber: '',
        issuer: '',
        issueDate: new Date().toISOString().split('T')[0],
        expiryDate: '',
      });
      setSelectedFile(null);
      const fileInput = document.getElementById('cert-file') as HTMLInputElement;
      if (fileInput) fileInput.value = '';

      setUploadProgress('✓ Certificate added successfully!');
    } catch (error) {
      console.error('Error adding certificate:', error);
      const errorMsg = error instanceof Error ? error.message : 'Failed to add certificate';
      alert(errorMsg);
      setUploadProgress(`❌ Error: ${errorMsg}`);
    } finally {
      setLoading(false);
    }
  };

  const handleContinue = () => {
    if (certificates.length === 0) {
      const confirmSkip = window.confirm(
        'No certificates added. This may affect compliance checks. Continue anyway?'
      );
      if (!confirmSkip) return;
    }
    onComplete();
  };

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Step 3: Certifications</h2>

      {/* Added certificates */}
      {certificates.length > 0 && (
        <div className="bg-blue-50 rounded-lg p-4 mb-6">
          <h3 className="font-semibold text-blue-900 mb-3">Added Certificates ({certificates.length})</h3>
          <div className="space-y-2">
            {certificates.map((cert, index) => (
              <div key={index} className="flex items-center justify-between text-sm bg-white rounded p-3">
                <div>
                  <span className="font-medium text-gray-900">{cert.certNumber}</span>
                  <span className="mx-2 text-gray-400">•</span>
                  <span className="text-gray-600">
                    {certTypes.find((t) => t.value === cert.certType)?.label}
                  </span>
                </div>
                <div className="text-xs text-gray-500">
                  Expires: {new Date(cert.expiryDate).toLocaleDateString()}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Add new certificate form */}
      <div className="bg-white border border-gray-200 rounded-lg p-6">
        <h3 className="font-semibold text-gray-900 mb-4">Add Certificate</h3>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Certificate Type *</label>
            <select
              value={currentCert.certType}
              onChange={(e) => setCurrentCert({ ...currentCert, certType: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            >
              {certTypes.map((type) => (
                <option key={type.value} value={type.value}>
                  {type.label} - {type.markets}
                </option>
              ))}
            </select>
            <p className="mt-1 text-xs text-gray-500">
              {certTypes.find(t => t.value === currentCert.certType)?.markets}
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Certificate Number *</label>
            <input
              type="text"
              value={currentCert.certNumber}
              onChange={(e) => setCurrentCert({ ...currentCert, certNumber: e.target.value })}
              placeholder="e.g., ORG-2025-001"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Issuing Authority *</label>
            <input
              type="text"
              value={currentCert.issuer}
              onChange={(e) => setCurrentCert({ ...currentCert, issuer: e.target.value })}
              placeholder="e.g., Control Union, USDA"
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Issue Date *</label>
            <input
              type="date"
              value={currentCert.issueDate}
              onChange={(e) => setCurrentCert({ ...currentCert, issueDate: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Expiry Date *</label>
            <input
              type="date"
              value={currentCert.expiryDate}
              onChange={(e) => setCurrentCert({ ...currentCert, expiryDate: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
            />
          </div>

          <div className="md:col-span-2">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Upload Certificate Document (Optional)
            </label>
            <input
              type="file"
              id="cert-file"
              accept=".pdf,.jpg,.jpeg,.png,.webp"
              onChange={handleFileSelect}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-green-50 file:text-green-700 hover:file:bg-green-100"
            />
            <p className="mt-1 text-xs text-gray-500">
              Accepted formats: PDF, JPEG, PNG, WebP. Max size: 10MB. Files uploaded to IPFS for immutability.
            </p>
            {selectedFile && (
              <div className="mt-2 text-sm text-green-700 bg-green-50 rounded px-3 py-2">
                ✓ Selected: <span className="font-medium">{selectedFile.name}</span>
                <span className="text-gray-600"> ({(selectedFile.size / 1024).toFixed(1)} KB)</span>
              </div>
            )}
          </div>
        </div>

        {uploadProgress && (
          <div className="mt-4 bg-blue-50 border border-blue-200 rounded-lg p-4">
            <p className="text-sm text-blue-800">
              {uploadProgress}
            </p>
          </div>
        )}

        <div className="mt-4 bg-green-50 border border-green-200 rounded-lg p-4">
          <p className="text-sm text-green-800">
            📄 <strong>IPFS Integration Active:</strong> Certificate documents are uploaded to IPFS (InterPlanetary File System) 
            for permanent, tamper-proof storage. Each document receives a unique Content Identifier (CID) verifiable on-chain.
          </p>
        </div>

        <button
          type="button"
          onClick={handleAddCertificate}
          disabled={
            loading || !currentCert.certNumber || !currentCert.issuer || !currentCert.expiryDate
          }
          className="mt-4 px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:bg-gray-400"
        >
          {loading ? 'Adding...' : 'Add Certificate'}
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
          className="px-8 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 font-medium"
        >
          Continue to Compliance Check
        </button>
      </div>
    </div>
  );
}
