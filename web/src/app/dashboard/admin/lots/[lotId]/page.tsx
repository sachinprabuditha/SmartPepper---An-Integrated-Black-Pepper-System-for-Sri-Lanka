'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';
import { ArrowLeft, CheckCircle, XCircle, Loader2, ExternalLink, FileText, AlertTriangle, Image as ImageIcon } from 'lucide-react';

interface LotDetail {
  lot_id: string;
  farmer_name: string;
  farmer_email: string;
  farmer_phone: string;
  farmer_address: string;
  variety: string;
  quantity: number;
  quality: string;
  harvest_date: string;
  origin: string;
  farm_location: string;
  organic_certified: boolean;
  lot_pictures: string[];
  certificate_images: string[];
  metadata_uri?: string;
  certificate_ipfs_url?: string;
  blockchain_tx_hash?: string;
  status: string;
  compliance_status: string;
  rejection_reason?: string;
  created_at: string;
}

export default function LotReviewPage({ params }: { params: { lotId: string } }) {
  const router = useRouter();
  const [lot, setLot] = useState<LotDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState(false);
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [showMetadataModal, setShowMetadataModal] = useState(false);
  const [metadataContent, setMetadataContent] = useState<any>(null);
  const [loadingMetadata, setLoadingMetadata] = useState(false);
  const [showCertificateModal, setShowCertificateModal] = useState(false);
  const [certificateUrl, setCertificateUrl] = useState<string>('');

  const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://192.168.8.116:3002';
  const IPFS_GATEWAY = process.env.NEXT_PUBLIC_IPFS_GATEWAY || 'http://192.168.8.116:8080/ipfs';

  useEffect(() => {
    fetchLotDetails();
  }, [params.lotId]);

  const fetchLotDetails = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_BASE}/api/admin/lots/${params.lotId}`);
      const data = await response.json();
      
      if (data.success) {
        setLot(data.lot);
      } else {
        alert('Failed to load lot details');
      }
    } catch (error) {
      console.error('Error fetching lot:', error);
      alert('Error loading lot details');
    } finally {
      setLoading(false);
    }
  };

  const getIPFSUrl = (url: string) => {
    if (!url) return '';
    if (url.startsWith('http')) return url;
    if (url.startsWith('ipfs://')) {
      return url.replace('ipfs://', `${IPFS_GATEWAY}/`);
    }
    return `${IPFS_GATEWAY}/${url}`;
  };

  const fetchMetadata = async (metadataUri: string) => {
    try {
      setLoadingMetadata(true);
      setShowMetadataModal(true);
      const url = getIPFSUrl(metadataUri);
      const response = await fetch(url);
      const data = await response.json();
      setMetadataContent(data);
    } catch (error) {
      console.error('Error fetching metadata:', error);
      alert('Failed to fetch metadata from IPFS');
      setShowMetadataModal(false);
    } finally {
      setLoadingMetadata(false);
    }
  };

  const viewCertificate = (certUrl: string) => {
    setCertificateUrl(getIPFSUrl(certUrl));
    setShowCertificateModal(true);
  };

  const approveLot = async () => {
    if (!confirm('Are you sure you want to approve this lot?')) return;
    
    try {
      setProcessing(true);
      const response = await fetch(`${API_BASE}/api/admin/lots/${params.lotId}/compliance`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          status: 'approved',
          adminId: 'admin-user', // TODO: Get from auth context
          adminName: 'Admin'
        })
      });
      
      const data = await response.json();
      
      if (data.success) {
        let message = '✅ Lot approved successfully!\n\n';
        
        if (data.blockchainTxHash) {
          message += `✓ Blockchain Updated\nTransaction: ${data.blockchainTxHash.substring(0, 20)}...\n\n`;
          message += 'The compliance status has been recorded on the blockchain.';
        } else if (data.blockchainError) {
          message += '⚠️ Database Updated Successfully\n';
          message += '❌ Blockchain Update Failed\n\n';
          message += `Error: ${data.blockchainError}\n\n`;
          message += 'The lot status has been updated in the database, but the blockchain transaction failed. ';
          message += 'You may need to update the blockchain manually or check the backend configuration (PRIVATE_KEY, contract deployment).';
        } else {
          message += '⚠️ Blockchain update is pending\n\n';
          message += 'The lot has been approved in the database. The blockchain update may have failed or is processing. ';
          message += 'Check backend logs for more details.';
        }
        
        alert(message);
        router.push('/dashboard/admin/lots');
      } else {
        alert('Failed to approve lot: ' + data.error);
      }
    } catch (error) {
      console.error('Error approving lot:', error);
      alert('Error approving lot');
    } finally {
      setProcessing(false);
    }
  };

  const rejectLot = async () => {
    if (!rejectionReason.trim()) {
      alert('Please provide a rejection reason');
      return;
    }
    
    if (rejectionReason.trim().length < 10) {
      alert('Rejection reason must be at least 10 characters');
      return;
    }
    
    try {
      setProcessing(true);
      const response = await fetch(`${API_BASE}/api/admin/lots/${params.lotId}/compliance`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          status: 'rejected',
          reason: rejectionReason,
          adminId: 'admin-user', // TODO: Get from auth context
          adminName: 'Admin'
        })
      });
      
      const data = await response.json();
      
      if (data.success) {
        let message = '❌ Lot rejected successfully\n\n';
        
        if (data.blockchainTxHash) {
          message += `✓ Blockchain Updated\nTransaction: ${data.blockchainTxHash.substring(0, 20)}...\n\n`;
          message += 'The rejection has been recorded on the blockchain.';
        } else if (data.blockchainError) {
          message += '⚠️ Database Updated Successfully\n';
          message += '❌ Blockchain Update Failed\n\n';
          message += `Error: ${data.blockchainError}\n\n`;
          message += 'The lot status has been updated in the database, but the blockchain transaction failed.';
        }
        
        alert(message);
        router.push('/dashboard/admin/lots');
      } else {
        alert('Failed to reject lot: ' + data.error);
      }
    } catch (error) {
      console.error('Error rejecting lot:', error);
      alert('Error rejecting lot');
    } finally {
      setProcessing(false);
      setShowRejectModal(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200';
      case 'approved': return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200';
      case 'rejected': return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200';
      default: return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200';
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
        <Loader2 className="w-12 h-12 animate-spin text-purple-600" />
      </div>
    );
  }

  if (!lot) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
        <div className="text-center">
          <p className="text-gray-600 dark:text-gray-400 mb-4">Lot not found</p>
          <button
            onClick={() => router.push('/dashboard/admin/lots')}
            className="text-purple-600 hover:text-purple-700"
          >
            ← Back to Lots
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <button
          onClick={() => router.push('/dashboard/admin/lots')}
          className="flex items-center text-purple-600 hover:text-purple-700 mb-6"
        >
          <ArrowLeft className="w-5 h-5 mr-2" />
          Back to All Lots
        </button>

        {/* Main Content */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg overflow-hidden">
          {/* Header Section */}
          <div className="bg-gradient-to-r from-purple-600 to-purple-700 px-8 py-6">
            <div className="flex justify-between items-start">
              <div>
                <h1 className="text-3xl font-bold text-white mb-2">{lot.variety}</h1>
                <p className="text-purple-100">Lot ID: {lot.lot_id}</p>
              </div>
              <span className={`px-4 py-2 rounded-full text-sm font-semibold ${getStatusColor(lot.compliance_status)}`}>
                {lot.compliance_status.toUpperCase()}
              </span>
            </div>
          </div>

          {/* Content */}
          <div className="p-8">
            {/* Farmer Information */}
            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Farmer Information</h2>
              <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-6 grid grid-cols-2 gap-6">
                <div>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Name</p>
                  <p className="text-lg font-medium text-gray-900 dark:text-white">{lot.farmer_name}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Email</p>
                  <p className="text-lg font-medium text-gray-900 dark:text-white">{lot.farmer_email}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Phone</p>
                  <p className="text-lg font-medium text-gray-900 dark:text-white">{lot.farmer_phone}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600 dark:text-gray-400">Wallet Address</p>
                  <p className="text-sm font-mono text-gray-900 dark:text-white">
                    {lot.farmer_address ? `${lot.farmer_address.slice(0, 12)}...${lot.farmer_address.slice(-8)}` : 'N/A'}
                  </p>
                </div>
              </div>
            </section>

            {/* Lot Details */}
            <section className="mb-8">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Lot Details</h2>
              <div className="grid grid-cols-3 gap-6">
                <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                  <p className="text-sm text-gray-600 dark:text-gray-400">Quantity</p>
                  <p className="text-2xl font-bold text-gray-900 dark:text-white">{lot.quantity} kg</p>
                </div>
                <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                  <p className="text-sm text-gray-600 dark:text-gray-400">Quality Grade</p>
                  <p className="text-2xl font-bold text-gray-900 dark:text-white">{lot.quality}</p>
                </div>
                <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                  <p className="text-sm text-gray-600 dark:text-gray-400">Harvest Date</p>
                  <p className="text-lg font-bold text-gray-900 dark:text-white">
                    {new Date(lot.harvest_date).toLocaleDateString()}
                  </p>
                </div>
              </div>
              <div className="mt-4 grid grid-cols-2 gap-6">
                <div>
                  <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">Origin</p>
                  <p className="text-lg text-gray-900 dark:text-white">{lot.origin}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">Farm Location</p>
                  <p className="text-lg text-gray-900 dark:text-white">{lot.farm_location}</p>
                </div>
              </div>
              {lot.organic_certified && (
                <div className="mt-4">
                  <span className="inline-flex items-center px-4 py-2 rounded-full text-sm font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                    🌿 Organic Certified
                  </span>
                </div>
              )}
            </section>

            {/* Blockchain Traceability */}
            {lot.blockchain_tx_hash && (
              <section className="mb-8">
                <div className="flex items-center justify-between mb-4">
                  <h2 className="text-xl font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                    <svg className="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                    Blockchain Traceability
                  </h2>
                  <button
                    onClick={() => router.push(`/traceability/${params.lotId}`)}
                    className="flex items-center gap-2 px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors text-sm font-medium"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                    </svg>
                    View Full Traceability
                  </button>
                </div>
                <div className="bg-gradient-to-br from-purple-50 to-blue-50 dark:from-gray-800 dark:to-gray-700 rounded-xl p-6 border-2 border-purple-200 dark:border-purple-800">
                  <div className="flex items-start gap-4 mb-4">
                    <div className="flex-shrink-0 w-12 h-12 bg-green-100 dark:bg-green-900 rounded-full flex items-center justify-center">
                      <CheckCircle className="w-6 h-6 text-green-600 dark:text-green-400" />
                    </div>
                    <div className="flex-1">
                      <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                        Verified on Blockchain
                      </h3>
                      <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                        This lot has been permanently recorded on the blockchain, ensuring complete transparency and immutability.
                      </p>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {/* Transaction Hash */}
                    <div className="bg-white dark:bg-gray-600 rounded-lg p-4">
                      <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2">TRANSACTION HASH</p>
                      <div className="flex items-center gap-2">
                        <code className="text-xs font-mono text-gray-900 dark:text-white break-all">
                          {lot.blockchain_tx_hash}
                        </code>
                        <button
                          onClick={() => {
                            navigator.clipboard.writeText(lot.blockchain_tx_hash!);
                            alert('Transaction hash copied!');
                          }}
                          className="flex-shrink-0 p-1.5 hover:bg-gray-100 dark:hover:bg-gray-500 rounded transition-colors"
                          title="Copy transaction hash"
                        >
                          <svg className="w-4 h-4 text-gray-600 dark:text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                          </svg>
                        </button>
                      </div>
                    </div>

                    {/* Network */}
                    <div className="bg-white dark:bg-gray-600 rounded-lg p-4">
                      <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2">BLOCKCHAIN NETWORK</p>
                      <div className="flex items-center gap-2">
                        <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
                        <div>
                          <p className="text-sm font-semibold text-gray-900 dark:text-white">Hardhat Local Network</p>
                          <code className="text-xs text-gray-600 dark:text-gray-400">http://127.0.0.1:8545</code>
                        </div>
                      </div>
                    </div>

                    {/* Farmer Address */}
                    {lot.farmer_address && (
                      <div className="bg-white dark:bg-gray-600 rounded-lg p-4">
                        <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2">FARMER WALLET</p>
                        <div className="flex items-center gap-2">
                          <code className="text-xs font-mono text-gray-900 dark:text-white break-all">
                            {lot.farmer_address}
                          </code>
                          <button
                            onClick={() => {
                              navigator.clipboard.writeText(lot.farmer_address);
                              alert('Wallet address copied!');
                            }}
                            className="flex-shrink-0 p-1.5 hover:bg-gray-100 dark:hover:bg-gray-500 rounded transition-colors"
                            title="Copy wallet address"
                          >
                            <svg className="w-4 h-4 text-gray-600 dark:text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                            </svg>
                          </button>
                        </div>
                      </div>
                    )}

                    {/* Smart Contract */}
                    <div className="bg-white dark:bg-gray-600 rounded-lg p-4">
                      <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 mb-2">SMART CONTRACT</p>
                      <div className="flex items-center gap-2">
                        <code className="text-xs font-mono text-gray-900 dark:text-white break-all">
                          {process.env.NEXT_PUBLIC_PASSPORT_CONTRACT_ADDRESS || '0x5FC8d32690cc91D4c39d9d3abcBD16989F875707'}
                        </code>
                        <button
                          onClick={() => {
                            const contractAddress = process.env.NEXT_PUBLIC_PASSPORT_CONTRACT_ADDRESS || '0x5FC8d32690cc91D4c39d9d3abcBD16989F875707';
                            navigator.clipboard.writeText(contractAddress);
                            alert('Contract address copied!');
                          }}
                          className="flex-shrink-0 p-1.5 hover:bg-gray-100 dark:hover:bg-gray-500 rounded transition-colors"
                          title="Copy contract address"
                        >
                          <svg className="w-4 h-4 text-gray-600 dark:text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                          </svg>
                        </button>
                      </div>
                    </div>
                  </div>

                  <div className="mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                    <div className="flex items-start gap-2">
                      <svg className="w-5 h-5 text-blue-600 dark:text-blue-400 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                      <p className="text-sm text-blue-800 dark:text-blue-300">
                        <strong>Immutable Record:</strong> This transaction is permanently stored on the blockchain and cannot be altered, deleted, or tampered with, ensuring complete transparency and traceability.
                      </p>
                    </div>
                  </div>
                </div>
              </section>
            )}

            {/* Lot Pictures */}
            {lot.lot_pictures && lot.lot_pictures.length > 0 && (
              <section className="mb-8">
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
                  Lot Pictures ({lot.lot_pictures.length})
                </h2>
                <div className="grid grid-cols-3 gap-4">
                  {lot.lot_pictures.map((url, index) => (
                    <div 
                      key={index} 
                      className="relative h-64 rounded-lg overflow-hidden bg-gray-100 dark:bg-gray-700 cursor-pointer hover:opacity-90 transition-opacity"
                      onClick={() => setSelectedImage(getIPFSUrl(url))}
                    >
                      <Image
                        src={getIPFSUrl(url)}
                        alt={`Lot picture ${index + 1}`}
                        fill
                        className="object-cover"
                      />
                      <div className="absolute bottom-2 right-2 bg-black bg-opacity-50 text-white px-2 py-1 rounded text-sm">
                        Photo {index + 1}
                      </div>
                    </div>
                  ))}
                </div>
              </section>
            )}

            {/* Certificate Images */}
            {lot.certificate_images && lot.certificate_images.length > 0 && (
              <section className="mb-8">
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
                  Certification Documents ({lot.certificate_images.length})
                </h2>
                <div className="grid grid-cols-3 gap-4">
                  {lot.certificate_images.map((url, index) => (
                    <div 
                      key={index} 
                      className="relative h-64 rounded-lg overflow-hidden bg-gray-100 dark:bg-gray-700 cursor-pointer hover:opacity-90 transition-opacity"
                      onClick={() => setSelectedImage(getIPFSUrl(url))}
                    >
                      <Image
                        src={getIPFSUrl(url)}
                        alt={`Certificate ${index + 1}`}
                        fill
                        className="object-cover"
                      />
                      <div className="absolute bottom-2 right-2 bg-black bg-opacity-50 text-white px-2 py-1 rounded text-sm">
                        Certificate {index + 1}
                      </div>
                    </div>
                  ))}
                </div>
              </section>
            )}

            {/* Rejection Reason (if rejected) */}
            {lot.rejection_reason && (
              <section className="mb-8">
                <div className="bg-red-50 dark:bg-red-900 border border-red-200 dark:border-red-700 rounded-lg p-6">
                  <h3 className="text-lg font-semibold text-red-800 dark:text-red-200 mb-2">Rejection Reason</h3>
                  <p className="text-red-700 dark:text-red-300">{lot.rejection_reason}</p>
                </div>
              </section>
            )}

            {/* Action Buttons */}
            {lot.compliance_status === 'pending' && (
              <section className="flex gap-4 pt-6 border-t border-gray-200 dark:border-gray-700">
                <button
                  onClick={approveLot}
                  disabled={processing}
                  className="flex-1 flex items-center justify-center gap-2 bg-green-600 text-white py-4 px-6 rounded-lg hover:bg-green-700 transition-colors font-semibold text-lg disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {processing ? (
                    <>
                      <Loader2 className="w-5 h-5 animate-spin" />
                      Processing...
                    </>
                  ) : (
                    <>
                      <CheckCircle className="w-5 h-5" />
                      Approve Lot
                    </>
                  )}
                </button>
                <button
                  onClick={() => setShowRejectModal(true)}
                  disabled={processing}
                  className="flex-1 flex items-center justify-center gap-2 bg-red-600 text-white py-4 px-6 rounded-lg hover:bg-red-700 transition-colors font-semibold text-lg disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <XCircle className="w-5 h-5" />
                  Reject Lot
                </button>
              </section>
            )}

            {/* IPFS Resources */}
            {(lot.metadata_uri || lot.certificate_ipfs_url || lot.lot_pictures || lot.certificate_images) && (
              <section className="mt-8 pt-6 border-t border-gray-200 dark:border-gray-700">
                <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-6 flex items-center gap-2">
                  <FileText className="w-6 h-6 text-purple-600" />
                  IPFS Resources
                </h3>
                
                <div className="space-y-6">
                  {/* Image Gallery */}
                  {(lot.lot_pictures?.length > 0 || lot.certificate_images?.length > 0) && (
                    <div className="bg-gradient-to-br from-purple-50 to-pink-50 dark:from-gray-800 dark:to-gray-700 rounded-xl p-6">
                      <h4 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
                        <ImageIcon className="w-5 h-5" />
                        Image Gallery
                      </h4>
                      
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                        {/* Lot Pictures */}
                        {lot.lot_pictures?.map((url, index) => (
                          <div 
                            key={`lot-${index}`}
                            className="group relative aspect-square rounded-lg overflow-hidden bg-white dark:bg-gray-600 shadow-md hover:shadow-xl transition-all cursor-pointer transform hover:scale-105"
                            onClick={() => setSelectedImage(getIPFSUrl(url))}
                          >
                            <img
                              src={getIPFSUrl(url)}
                              alt={`Lot picture ${index + 1}`}
                              className="w-full h-full object-cover"
                            />
                            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity">
                              <div className="absolute bottom-0 left-0 right-0 p-3">
                                <p className="text-white text-sm font-medium">📸 Lot Photo {index + 1}</p>
                                <p className="text-purple-200 text-xs">Click to enlarge</p>
                              </div>
                            </div>
                            <div className="absolute top-2 right-2">
                              <span className="bg-purple-600 text-white px-2 py-1 rounded-full text-xs font-medium">
                                #{index + 1}
                              </span>
                            </div>
                          </div>
                        ))}
                        
                        {/* Certificate Images */}
                        {lot.certificate_images?.map((url, index) => (
                          <div 
                            key={`cert-${index}`}
                            className="group relative aspect-square rounded-lg overflow-hidden bg-white dark:bg-gray-600 shadow-md hover:shadow-xl transition-all cursor-pointer transform hover:scale-105"
                            onClick={() => setSelectedImage(getIPFSUrl(url))}
                          >
                            <img
                              src={getIPFSUrl(url)}
                              alt={`Certificate ${index + 1}`}
                              className="w-full h-full object-cover"
                            />
                            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity">
                              <div className="absolute bottom-0 left-0 right-0 p-3">
                                <p className="text-white text-sm font-medium">📜 Certificate {index + 1}</p>
                                <p className="text-green-200 text-xs">Click to view details</p>
                              </div>
                            </div>
                            <div className="absolute top-2 right-2">
                              <span className="bg-green-600 text-white px-2 py-1 rounded-full text-xs font-medium">
                                CERT
                              </span>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* IPFS Links & Documents */}
                  {(lot.metadata_uri || lot.certificate_ipfs_url) && (
                    <div className="bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-800 dark:to-gray-700 rounded-xl p-6">
                      <h4 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
                        <FileText className="w-5 h-5" />
                        Documents & Metadata
                      </h4>
                      
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {lot.metadata_uri && (
                          <button
                            onClick={() => lot.metadata_uri && fetchMetadata(lot.metadata_uri)}
                            className="group flex items-start gap-4 p-4 bg-white dark:bg-gray-600 rounded-lg border-2 border-blue-200 dark:border-blue-800 hover:border-blue-400 dark:hover:border-blue-600 hover:shadow-lg transition-all text-left w-full"
                          >
                            <div className="flex-shrink-0 w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-lg flex items-center justify-center group-hover:scale-110 transition-transform">
                              <FileText className="w-6 h-6 text-blue-600 dark:text-blue-400" />
                            </div>
                            <div className="flex-1 min-w-0">
                              <p className="text-sm font-semibold text-gray-900 dark:text-white mb-1">
                                Lot Metadata (JSON)
                              </p>
                              <p className="text-xs text-gray-600 dark:text-gray-400 truncate mb-2">
                                {lot.metadata_uri}
                              </p>
                              <div className="flex items-center gap-2">
                                <ExternalLink className="w-4 h-4 text-blue-600 dark:text-blue-400" />
                                <span className="text-xs font-medium text-blue-600 dark:text-blue-400">
                                  Click to view JSON content
                                </span>
                              </div>
                            </div>
                          </button>
                        )}
                        
                        {lot.certificate_ipfs_url && (
                          <button
                            onClick={() => lot.certificate_ipfs_url && viewCertificate(lot.certificate_ipfs_url)}
                            className="group flex items-start gap-4 p-4 bg-white dark:bg-gray-600 rounded-lg border-2 border-green-200 dark:border-green-800 hover:border-green-400 dark:hover:border-green-600 hover:shadow-lg transition-all text-left w-full"
                          >
                            <div className="flex-shrink-0 w-12 h-12 bg-green-100 dark:bg-green-900 rounded-lg flex items-center justify-center group-hover:scale-110 transition-transform">
                              <CheckCircle className="w-6 h-6 text-green-600 dark:text-green-400" />
                            </div>
                            <div className="flex-1 min-w-0">
                              <p className="text-sm font-semibold text-gray-900 dark:text-white mb-1">
                                Certificate Hash
                              </p>
                              <p className="text-xs text-gray-600 dark:text-gray-400 truncate mb-2">
                                {lot.certificate_ipfs_url}
                              </p>
                              <div className="flex items-center gap-2">
                                <ExternalLink className="w-4 h-4 text-green-600 dark:text-green-400" />
                                <span className="text-xs font-medium text-green-600 dark:text-green-400">
                                  Click to view certificate
                                </span>
                              </div>
                            </div>
                          </button>
                        )}
                      </div>
                      
                      {/* Additional Info */}
                      <div className="mt-4 p-3 bg-blue-100 dark:bg-blue-900/30 rounded-lg">
                        <p className="text-xs text-blue-800 dark:text-blue-300 flex items-center gap-2">
                          <AlertTriangle className="w-4 h-4" />
                          All resources are stored on IPFS (InterPlanetary File System) for permanent, tamper-proof storage
                        </p>
                      </div>
                    </div>
                  )}
                </div>
              </section>
            )}
          </div>
        </div>
      </div>

      {/* Metadata JSON Modal */}
      {showMetadataModal && (
        <div className="fixed inset-0 bg-black bg-opacity-70 flex items-center justify-center p-4 z-50" onClick={() => setShowMetadataModal(false)}>
          <div className="bg-white dark:bg-gray-800 rounded-xl max-w-3xl w-full max-h-[80vh] overflow-hidden shadow-2xl" onClick={(e) => e.stopPropagation()}>
            <div className="bg-gradient-to-r from-blue-600 to-purple-600 px-6 py-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <FileText className="w-6 h-6 text-white" />
                <h3 className="text-xl font-semibold text-white">Lot Metadata (JSON)</h3>
              </div>
              <button
                onClick={() => setShowMetadataModal(false)}
                className="text-white hover:bg-white/20 rounded-lg p-2 transition-colors"
              >
                <XCircle className="w-6 h-6" />
              </button>
            </div>
            
            <div className="p-6 overflow-y-auto max-h-[calc(80vh-80px)]">
              {loadingMetadata ? (
                <div className="flex items-center justify-center py-12">
                  <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
                  <span className="ml-3 text-gray-600 dark:text-gray-400">Loading metadata from IPFS...</span>
                </div>
              ) : metadataContent ? (
                <div className="space-y-4">
                  <div className="bg-gray-50 dark:bg-gray-900 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
                    <pre className="text-sm text-gray-800 dark:text-gray-200 overflow-x-auto">
                      {JSON.stringify(metadataContent, null, 2)}
                    </pre>
                  </div>
                  
                  <div className="flex gap-3">
                    <button
                      onClick={() => {
                        navigator.clipboard.writeText(JSON.stringify(metadataContent, null, 2));
                        alert('✓ JSON copied to clipboard!');
                      }}
                      className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                    >
                      <FileText className="w-4 h-4" />
                      Copy JSON
                    </button>
                    <a
                      href={getIPFSUrl(lot?.metadata_uri || '')}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                    >
                      <ExternalLink className="w-4 h-4" />
                      Open in IPFS
                    </a>
                  </div>
                </div>
              ) : (
                <div className="text-center py-12">
                  <p className="text-red-600 dark:text-red-400">Failed to load metadata</p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Certificate Viewer Modal */}
      {showCertificateModal && (
        <div className="fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center p-4 z-50" onClick={() => setShowCertificateModal(false)}>
          <div className="relative max-w-6xl w-full max-h-[90vh] bg-white dark:bg-gray-800 rounded-xl overflow-hidden shadow-2xl" onClick={(e) => e.stopPropagation()}>
            {/* Header */}
            <div className="bg-gradient-to-r from-green-600 to-emerald-600 px-6 py-4 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <CheckCircle className="w-6 h-6 text-white" />
                <h3 className="text-xl font-semibold text-white">Certificate Preview</h3>
              </div>
              <button
                onClick={() => setShowCertificateModal(false)}
                className="text-white hover:bg-white/20 rounded-lg p-2 transition-colors"
              >
                <XCircle className="w-6 h-6" />
              </button>
            </div>

            {/* Content */}
            <div className="p-6 overflow-auto max-h-[calc(90vh-140px)]">
              <div className="bg-gray-100 dark:bg-gray-900 rounded-lg overflow-hidden">
                {/* Check if it's an image or PDF */}
                {certificateUrl && (
                  certificateUrl.match(/\.(jpg|jpeg|png|gif|webp)$/i) ? (
                    <img
                      src={certificateUrl}
                      alt="Certificate"
                      className="w-full h-auto"
                    />
                  ) : certificateUrl.match(/\.pdf$/i) ? (
                    <iframe
                      src={certificateUrl}
                      className="w-full h-[600px]"
                      title="Certificate PDF"
                    />
                  ) : (
                    // Default: Try to display as image, fallback to iframe
                    <img
                      src={certificateUrl}
                      alt="Certificate"
                      className="w-full h-auto"
                      onError={(e) => {
                        // If image fails to load, try iframe
                        const img = e.target as HTMLImageElement;
                        const iframe = document.createElement('iframe');
                        iframe.src = certificateUrl;
                        iframe.className = 'w-full h-[600px]';
                        iframe.title = 'Certificate Document';
                        img.parentNode?.replaceChild(iframe, img);
                      }}
                    />
                  )
                )}
              </div>

              {/* Action Buttons */}
              <div className="mt-6 flex gap-3">
                <a
                  href={certificateUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium"
                >
                  <ExternalLink className="w-5 h-5" />
                  Open in New Tab
                </a>
                <a
                  href={certificateUrl}
                  download
                  className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
                >
                  <FileText className="w-5 h-5" />
                  Download Certificate
                </a>
              </div>

              {/* IPFS Info */}
              <div className="mt-4 p-4 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800">
                <p className="text-sm text-green-800 dark:text-green-300 font-medium mb-1">
                  📌 IPFS Hash
                </p>
                <p className="text-xs text-green-700 dark:text-green-400 font-mono break-all">
                  {lot?.certificate_ipfs_url}
                </p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Rejection Modal */}
      {showRejectModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-lg max-w-md w-full p-6">
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Rejection Reason</h3>
            <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
              Please provide a detailed reason for rejecting this lot. The farmer will see this message.
            </p>
            <textarea
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              placeholder="e.g., Quality certificates are expired. Please upload current certificates and resubmit."
              className="w-full h-32 px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-transparent bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
              maxLength={500}
            />
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">
              {rejectionReason.length}/500 characters (minimum 10)
            </p>
            <div className="flex gap-3 mt-6">
              <button
                onClick={() => {
                  setShowRejectModal(false);
                  setRejectionReason('');
                }}
                className="flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 text-gray-700 dark:text-gray-300"
              >
                Cancel
              </button>
              <button
                onClick={rejectLot}
                disabled={processing || rejectionReason.trim().length < 10}
                className="flex-1 bg-red-600 text-white py-2 px-4 rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium"
              >
                {processing ? 'Processing...' : 'Confirm Rejection'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Image Lightbox */}
      {selectedImage && (
        <div 
          className="fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center p-4 z-50"
          onClick={() => setSelectedImage(null)}
        >
          <div className="relative max-w-6xl max-h-[90vh]">
            <Image
              src={selectedImage}
              alt="Full size"
              width={1200}
              height={800}
              className="object-contain max-h-[90vh]"
            />
            <button
              onClick={() => setSelectedImage(null)}
              className="absolute top-4 right-4 text-white bg-black bg-opacity-50 rounded-full p-2 hover:bg-opacity-75"
            >
              <XCircle className="w-6 h-6" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
