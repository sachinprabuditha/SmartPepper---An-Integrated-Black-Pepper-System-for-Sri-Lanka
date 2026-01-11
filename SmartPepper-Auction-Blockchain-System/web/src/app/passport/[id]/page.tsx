'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import { PassportCard } from '@/components/nft/PassportCard';
import { ProcessingTimeline } from '@/components/nft/ProcessingTimeline';
import { CertificationList } from '@/components/nft/CertificationBadge';
import { CompactQRCode } from '@/components/nft/QRCodeDisplay';
import { Shield, ExternalLink, AlertCircle, CheckCircle, Info } from 'lucide-react';

interface PassportData {
  lotId: number;
  tokenId: number;
  farmer: string;
  origin: string;
  variety: string;
  quantity: number;
  harvestDate: Date;
  certificateHash: string;
  isActive: boolean;
  createdAt: Date;
}

interface ProcessingLog {
  stage: string;
  description: string;
  timestamp: Date;
  recordedBy: string;
  location: string;
}

interface Certification {
  certType: string;
  certId: string;
  issuedBy: string;
  issuedDate: Date;
  expiryDate: Date;
  documentHash: string;
  isValid: boolean;
}

interface PassportInfo {
  passportData: PassportData;
  processingLogs: ProcessingLog[];
  certifications: Certification[];
  owner: string;
}

export default function PassportViewerPage() {
  const params = useParams();
  const lotId = params?.id ? parseInt(params.id as string) : null;

  const [passportInfo, setPassportInfo] = useState<PassportInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (lotId) {
      fetchPassportInfo();
    }
  }, [lotId]);

  const fetchPassportInfo = async () => {
    try {
      setLoading(true);
      setError(null);

      const response = await fetch(`/api/nft-passport/lot/${lotId}`);
      
      if (!response.ok) {
        throw new Error('Passport not found');
      }

      const data = await response.json();
      setPassportInfo(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load passport');
    } finally {
      setLoading(false);
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-12 px-4">
        <div className="max-w-5xl mx-auto">
          <div className="animate-pulse space-y-6">
            <div className="h-12 bg-gray-200 dark:bg-gray-700 rounded w-1/3" />
            <div className="h-64 bg-gray-200 dark:bg-gray-700 rounded" />
            <div className="h-96 bg-gray-200 dark:bg-gray-700 rounded" />
          </div>
        </div>
      </div>
    );
  }

  if (error || !passportInfo) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-12 px-4">
        <div className="max-w-2xl mx-auto">
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-red-200 dark:border-red-900 p-8 text-center">
            <AlertCircle className="w-16 h-16 text-red-500 mx-auto mb-4" />
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
              Passport Not Found
            </h2>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              {error || `No digital passport found for Lot ID: ${lotId}`}
            </p>
            <button
              onClick={() => window.location.href = '/'}
              className="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors"
            >
              Return to Home
            </button>
          </div>
        </div>
      </div>
    );
  }

  const { passportData, processingLogs, certifications, owner } = passportInfo;

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4">
      <div className="max-w-6xl mx-auto">
        {/* Public Verification Notice */}
        <div className="mb-6 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-900 p-4">
          <div className="flex items-start space-x-3">
            <Info className="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" />
            <div className="flex-1">
              <h3 className="text-sm font-medium text-blue-900 dark:text-blue-300 mb-1">
                Public Verification View
              </h3>
              <p className="text-sm text-blue-800 dark:text-blue-400">
                This is a read-only public view for product verification. 
                Farmers can manage their passports from their dashboard.
              </p>
            </div>
          </div>
        </div>

        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center space-x-3">
              <Shield className="w-10 h-10 text-green-600 dark:text-green-400" />
              <div>
                <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                  Digital Product Passport
                </h1>
                <p className="text-gray-600 dark:text-gray-400">
                  Blockchain-verified pepper lot #{lotId}
                </p>
              </div>
            </div>
            {passportData.isActive && (
              <div className="flex items-center space-x-2 px-4 py-2 bg-green-100 dark:bg-green-900/30 rounded-lg">
                <CheckCircle className="w-5 h-5 text-green-600 dark:text-green-400" />
                <span className="text-green-700 dark:text-green-400 font-medium">
                  Active
                </span>
              </div>
            )}
          </div>
        </div>

        {/* Main Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left Column - Main Info */}
          <div className="lg:col-span-2 space-y-6">
            {/* Passport Card */}
            <PassportCard
              tokenId={String(passportData.tokenId)}
              passport={{
                lotId: String(passportData.lotId),
                farmer: passportData.farmer,
                createdAt: passportData.createdAt,
                origin: passportData.origin,
                variety: passportData.variety,
                quantity: String(passportData.quantity),
                harvestDate: String(passportData.harvestDate),
                certificateHash: passportData.certificateHash,
                isActive: passportData.isActive,
              }}
            />

            {/* Processing Timeline */}
            <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
              <ProcessingTimeline logs={processingLogs} />
            </div>

            {/* Certifications */}
            <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
              <CertificationList certifications={certifications} />
            </div>
          </div>

          {/* Right Column - QR & Blockchain Info */}
          <div className="space-y-6">
            {/* QR Code */}
            <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                Share Passport
              </h3>
              <div className="flex justify-center">
                <CompactQRCode lotId={passportData.lotId} size={200} />
              </div>
              <p className="text-xs text-gray-500 dark:text-gray-400 text-center mt-4">
                Scan to verify authenticity
              </p>
            </div>

            {/* Blockchain Verification */}
            <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                Blockchain Verification
              </h3>
              
              <div className="space-y-3">
                <div>
                  <p className="text-sm text-gray-500 dark:text-gray-400 mb-1">NFT Token ID</p>
                  <p className="font-mono text-sm text-gray-900 dark:text-white bg-gray-50 dark:bg-gray-900 rounded px-3 py-2">
                    #{passportData.tokenId}
                  </p>
                </div>

                <div>
                  <p className="text-sm text-gray-500 dark:text-gray-400 mb-1">Current Owner</p>
                  <div className="flex items-center space-x-2">
                    <p className="font-mono text-xs text-gray-900 dark:text-white bg-gray-50 dark:bg-gray-900 rounded px-3 py-2 flex-1 truncate">
                      {owner}
                    </p>
                    <button
                      onClick={() => copyToClipboard(owner)}
                      className="px-2 py-1 text-xs text-blue-600 hover:text-blue-700 dark:text-blue-400"
                    >
                      Copy
                    </button>
                  </div>
                </div>

                <div>
                  <p className="text-sm text-gray-500 dark:text-gray-400 mb-1">Created</p>
                  <p className="text-sm text-gray-900 dark:text-white">
                    {new Date(passportData.createdAt).toLocaleString()}
                  </p>
                </div>

                <div className="pt-3 border-t border-gray-200 dark:border-gray-700">
                  <a
                    href={`https://etherscan.io/token/${process.env.NEXT_PUBLIC_PASSPORT_CONTRACT_ADDRESS}?a=${passportData.tokenId}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex items-center justify-center space-x-2 w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors text-sm"
                  >
                    <span>View on Blockchain</span>
                    <ExternalLink className="w-4 h-4" />
                  </a>
                </div>
              </div>
            </div>

            {/* Stats */}
            <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                Summary
              </h3>
              
              <div className="space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-500 dark:text-gray-400">
                    Processing Stages
                  </span>
                  <span className="text-lg font-bold text-gray-900 dark:text-white">
                    {processingLogs.length}
                  </span>
                </div>

                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-500 dark:text-gray-400">
                    Certifications
                  </span>
                  <span className="text-lg font-bold text-gray-900 dark:text-white">
                    {certifications.length}
                  </span>
                </div>

                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-500 dark:text-gray-400">
                    Valid Certs
                  </span>
                  <span className="text-lg font-bold text-green-600 dark:text-green-400">
                    {certifications.filter(c => c.isValid && new Date(c.expiryDate) > new Date()).length}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Footer Info */}
        <div className="mt-8 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-900 p-4">
          <p className="text-sm text-blue-800 dark:text-blue-300 text-center">
            <Shield className="w-4 h-4 inline mr-2" />
            This digital passport is secured by blockchain technology and cannot be tampered with.
            All information is cryptographically verified and publicly auditable.
          </p>
        </div>
      </div>
    </div>
  );
}
