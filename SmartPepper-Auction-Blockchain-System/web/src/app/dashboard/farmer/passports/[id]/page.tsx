'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useAccount } from 'wagmi';
import { PassportCard } from '@/components/nft/PassportCard';
import { ProcessingTimeline } from '@/components/nft/ProcessingTimeline';
import { CertificationList } from '@/components/nft/CertificationBadge';
import { QRCodeDisplay } from '@/components/nft/QRCodeDisplay';
import { Shield, AlertCircle, Download, Plus, Edit, Gavel } from 'lucide-react';

interface PassportData {
  lotId: string; // e.g., "LOT-1733339456789"
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

export default function FarmerPassportDetailPage() {
  const params = useParams();
  const router = useRouter();
  const { user, loading: authLoading } = useAuth();
  const { address: connectedAddress } = useAccount();
  const lotId = params?.id as string || null; // Keep as string (e.g., "LOT-1733339456789")
  
  // Use connected wallet address or stored wallet address
  const walletAddress = user?.walletAddress || connectedAddress;

  const [passportInfo, setPassportInfo] = useState<PassportInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showAddLog, setShowAddLog] = useState(false);
  const [showAddCert, setShowAddCert] = useState(false);

  useEffect(() => {
    if (!authLoading && (!user || user.role !== 'farmer')) {
      router.push('/login');
    }
  }, [user, authLoading, router]);

  useEffect(() => {
    if (lotId && walletAddress) {
      fetchPassportInfo();
    }
  }, [lotId, walletAddress, connectedAddress]);

  const fetchPassportInfo = async () => {
    try {
      setLoading(true);
      setError(null);

      console.log('=== Fetching Passport Details ===');
      console.log('Lot ID:', lotId);
      console.log('User wallet (from auth):', user?.walletAddress);
      console.log('MetaMask address:', connectedAddress);
      console.log('Using wallet:', walletAddress);

      if (!walletAddress) {
        throw new Error('No wallet address found. Please connect your MetaMask wallet.');
      }

      const apiUrl = `http://localhost:3002/api/nft-passport/lot/${lotId}`;
      console.log('Fetching from:', apiUrl);
      
      const response = await fetch(apiUrl);
      console.log('Response status:', response.status);
      
      if (!response.ok) {
        const errorText = await response.text();
        console.error('API error:', errorText);
        throw new Error('Passport not found');
      }

      const result = await response.json();
      console.log('API result:', result);
      
      if (!result.success) {
        throw new Error(result.error || 'Failed to fetch passport');
      }
      
      const data = result.data;
      
      // Verify ownership with case-insensitive comparison
      if (data.passportData.farmer.toLowerCase() !== walletAddress.toLowerCase()) {
        console.error('Ownership mismatch:', {
          passportFarmer: data.passportData.farmer,
          userWallet: walletAddress
        });
        throw new Error('Access denied: You do not own this passport');
      }

      console.log('✅ Passport loaded successfully');
      setPassportInfo(data);
    } catch (err) {
      console.error('Error loading passport:', err);
      setError(err instanceof Error ? err.message : 'Failed to load passport');
    } finally {
      setLoading(false);
    }
  };

  const handleAddProcessingLog = async (logData: any) => {
    try {
      const response = await fetch('http://localhost:3002/api/nft-passport/processing-log', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          tokenId: passportInfo?.passportData.tokenId,
          stage: logData.stage,
          description: logData.description,
          location: logData.location,
        }),
      });

      if (!response.ok) throw new Error('Failed to add processing log');

      await fetchPassportInfo();
      setShowAddLog(false);
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to add log');
    }
  };

  const handleAddCertification = async (certData: any) => {
    try {
      const response = await fetch('http://localhost:3002/api/nft-passport/certification', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          tokenId: passportInfo?.passportData.tokenId,
          certType: certData.certType,
          certId: certData.certId,
          issuedBy: certData.issuedBy,
          expiryDate: certData.expiryDate,
          documentHash: certData.documentHash || '0x0000000000000000000000000000000000000000000000000000000000000000',
        }),
      });

      if (!response.ok) throw new Error('Failed to add certification');

      await fetchPassportInfo();
      setShowAddCert(false);
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to add certification');
    }
  };

  if (authLoading || loading) {
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
              Access Denied
            </h2>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              {error || `No access to passport for Lot ID: ${lotId}`}
            </p>
            <button
              onClick={() => router.push('/dashboard/farmer/passports')}
              className="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors"
            >
              Back to My Passports
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
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center space-x-3">
              <Shield className="w-10 h-10 text-green-600 dark:text-green-400" />
              <div>
                <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                  My NFT Passport
                </h1>
                <p className="text-gray-600 dark:text-gray-400">
                  Lot #{lotId} - NFT Token #{passportData.tokenId}
                </p>
              </div>
            </div>
            <button
              onClick={() => router.push('/dashboard/farmer/passports')}
              className="px-4 py-2 text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white"
            >
              ← Back to Passports
            </button>
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

            {/* Processing Timeline with Add Button */}
            <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                  Supply Chain Journey
                </h3>
                <button
                  onClick={() => setShowAddLog(true)}
                  className="flex items-center space-x-2 px-3 py-1.5 bg-green-600 hover:bg-green-700 text-white rounded-lg text-sm transition-colors"
                >
                  <Plus className="w-4 h-4" />
                  <span>Add Stage</span>
                </button>
              </div>
              <ProcessingTimeline logs={processingLogs} />
            </div>

            {/* Certifications with Add Button */}
            <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                  Certifications
                </h3>
                <button
                  onClick={() => setShowAddCert(true)}
                  className="flex items-center space-x-2 px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm transition-colors"
                >
                  <Plus className="w-4 h-4" />
                  <span>Add Certificate</span>
                </button>
              </div>
              <CertificationList certifications={certifications} />
            </div>
          </div>

          {/* Right Column - Actions & QR */}
          <div className="space-y-6">
            {/* QR Code */}
            <QRCodeDisplay lotId={passportData.lotId} size={200} showInstructions={true} />

            {/* Actions */}
            <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                Quick Actions
              </h3>
              
              <div className="space-y-3">
                <button
                  onClick={() => router.push(`/create?lotId=${lotId}`)}
                  className="flex items-center justify-center space-x-2 w-full px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors text-sm font-semibold"
                >
                  <Gavel className="w-4 h-4" />
                  <span>Create Auction</span>
                </button>

                <a
                  href={`/passport/${lotId}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center justify-center space-x-2 w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors text-sm"
                >
                  <Download className="w-4 h-4" />
                  <span>Public View</span>
                </a>

                <button
                  onClick={() => window.print()}
                  className="flex items-center justify-center space-x-2 w-full px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded-lg transition-colors text-sm"
                >
                  <Download className="w-4 h-4" />
                  <span>Download PDF</span>
                </button>
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
      </div>
    </div>
  );
}
