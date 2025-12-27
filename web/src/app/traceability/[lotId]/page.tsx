'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { 
  Clock, 
  CheckCircle, 
  XCircle, 
  Link2, 
  Award, 
  Settings, 
  FileCheck, 
  Gavel,
  TrendingUp,
  Copy,
  Download,
  ArrowLeft
} from 'lucide-react';

interface TimelineEvent {
  type: string;
  timestamp: string;
  description: string;
  actor: string;
  actor_name: string;
  blockchain_tx: string | null;
  data: any;
}

interface TraceabilityData {
  success: boolean;
  lot_id: string;
  lot_info: any;
  blockchain_info: any;
  current_status: any;
  stakeholders: any;
  processing_stages: any[];
  certifications: any[];
  compliance_checks: any[];
  auctions: any[];
  bids: any[];
  timeline: TimelineEvent[];
  statistics: any;
}

export default function TraceabilityPage() {
  const params = useParams();
  const router = useRouter();
  const lotId = params.lotId as string;

  const [data, setData] = useState<TraceabilityData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('timeline');

  useEffect(() => {
    fetchTraceability();
  }, [lotId]);

  const fetchTraceability = async () => {
    try {
      setLoading(true);
      const response = await fetch(`http://192.168.8.116:3002/api/traceability/${lotId}`);
      const result = await response.json();
      
      if (result.success) {
        setData(result);
      } else {
        setError(result.error || 'Failed to load traceability data');
      }
    } catch (err: any) {
      setError(err.message || 'Network error');
    } finally {
      setLoading(false);
    }
  };

  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    alert(`${label} copied to clipboard`);
  };

  const exportData = () => {
    const dataStr = JSON.stringify(data, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `traceability-${lotId}.json`;
    link.click();
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-green-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading blockchain traceability records...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <XCircle className="w-16 h-16 text-red-500 mx-auto mb-4" />
          <p className="text-red-600 mb-4">{error}</p>
          <button
            onClick={fetchTraceability}
            className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  if (!data) return null;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-green-700 to-yellow-600 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <button
            onClick={() => router.back()}
            className="flex items-center space-x-2 text-white/90 hover:text-white mb-4"
          >
            <ArrowLeft className="w-5 h-5" />
            <span>Back</span>
          </button>
          
          <div className="flex justify-between items-start">
            <div>
              <h1 className="text-3xl font-bold mb-2">Blockchain Traceability</h1>
              <p className="text-white/90 text-lg">Lot ID: {lotId}</p>
              <p className="text-white/80 text-sm mt-1">
                Complete audit trail with {data.statistics.blockchain_transactions} blockchain transactions
              </p>
            </div>
            
            <button
              onClick={exportData}
              className="flex items-center space-x-2 px-4 py-2 bg-white/20 hover:bg-white/30 rounded-lg transition-colors"
            >
              <Download className="w-5 h-5" />
              <span>Export JSON</span>
            </button>
          </div>

          {/* Statistics Cards */}
          <div className="grid grid-cols-4 gap-4 mt-6">
            <StatCard label="Total Events" value={data.statistics.total_events} />
            <StatCard label="Blockchain TX" value={data.statistics.blockchain_transactions} />
            <StatCard label="Processing Stages" value={data.statistics.processing_stages} />
            <StatCard label="Days in System" value={data.statistics.days_in_system} />
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex space-x-8">
            <TabButton
              active={activeTab === 'timeline'}
              onClick={() => setActiveTab('timeline')}
              icon={<Clock className="w-5 h-5" />}
              label="Timeline"
            />
            <TabButton
              active={activeTab === 'processing'}
              onClick={() => setActiveTab('processing')}
              icon={<Settings className="w-5 h-5" />}
              label="Processing"
            />
            <TabButton
              active={activeTab === 'certificates'}
              onClick={() => setActiveTab('certificates')}
              icon={<Award className="w-5 h-5" />}
              label="Certificates"
            />
            <TabButton
              active={activeTab === 'compliance'}
              onClick={() => setActiveTab('compliance')}
              icon={<FileCheck className="w-5 h-5" />}
              label="Compliance"
            />
            <TabButton
              active={activeTab === 'blockchain'}
              onClick={() => setActiveTab('blockchain')}
              icon={<Link2 className="w-5 h-5" />}
              label="Blockchain"
            />
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {activeTab === 'timeline' && <TimelineView data={data} copyToClipboard={copyToClipboard} />}
        {activeTab === 'processing' && <ProcessingView data={data} copyToClipboard={copyToClipboard} />}
        {activeTab === 'certificates' && <CertificatesView data={data} />}
        {activeTab === 'compliance' && <ComplianceView data={data} copyToClipboard={copyToClipboard} />}
        {activeTab === 'blockchain' && <BlockchainView data={data} copyToClipboard={copyToClipboard} />}
      </div>
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="bg-white/10 backdrop-blur-sm rounded-lg p-4">
      <div className="text-3xl font-bold text-white">{value}</div>
      <div className="text-white/80 text-sm mt-1">{label}</div>
    </div>
  );
}

function TabButton({ active, onClick, icon, label }: any) {
  return (
    <button
      onClick={onClick}
      className={`flex items-center space-x-2 px-4 py-4 border-b-2 transition-colors ${
        active
          ? 'border-green-600 text-green-600'
          : 'border-transparent text-gray-600 hover:text-gray-900'
      }`}
    >
      {icon}
      <span className="font-medium">{label}</span>
    </button>
  );
}

function TimelineView({ data, copyToClipboard }: any) {
  const timeline = [...data.timeline].reverse(); // Show newest first

  return (
    <div className="space-y-4">
      {timeline.map((event: TimelineEvent, index: number) => (
        <TimelineItem
          key={index}
          event={event}
          isLast={index === timeline.length - 1}
          copyToClipboard={copyToClipboard}
        />
      ))}
    </div>
  );
}

function TimelineItem({ event, isLast, copyToClipboard }: any) {
  const iconMap: any = {
    lot_created: <CheckCircle className="w-6 h-6" />,
    processing_stage: <Settings className="w-6 h-6" />,
    certification_added: <Award className="w-6 h-6" />,
    compliance_check: <FileCheck className="w-6 h-6" />,
    auction_created: <Gavel className="w-6 h-6" />,
    auction_ended: <Clock className="w-6 h-6" />,
    auction_settled: <CheckCircle className="w-6 h-6" />,
    bid_placed: <TrendingUp className="w-6 h-6" />,
  };

  const colorMap: any = {
    lot_created: 'bg-green-500',
    processing_stage: 'bg-blue-500',
    certification_added: 'bg-yellow-500',
    compliance_check: 'bg-purple-500',
    auction_created: 'bg-pink-500',
    auction_ended: 'bg-gray-500',
    auction_settled: 'bg-green-600',
    bid_placed: 'bg-orange-500',
  };

  return (
    <div className="flex">
      <div className="flex flex-col items-center mr-4">
        <div className={`${colorMap[event.type] || 'bg-gray-500'} rounded-full p-2 text-white`}>
          {iconMap[event.type] || <CheckCircle className="w-6 h-6" />}
        </div>
        {!isLast && <div className="w-0.5 h-full bg-gray-300 mt-2"></div>}
      </div>

      <div className="flex-1 bg-white rounded-lg shadow-sm border p-6 mb-4">
        <div className="flex justify-between items-start mb-2">
          <div>
            <h3 className="text-lg font-semibold text-gray-900">{event.description}</h3>
            <p className="text-sm text-gray-600">By: {event.actor_name}</p>
          </div>
          {event.blockchain_tx && (
            <div className="flex items-center space-x-1 text-green-600 text-sm">
              <CheckCircle className="w-4 h-4" />
              <span>Blockchain Verified</span>
            </div>
          )}
        </div>

        <p className="text-sm text-gray-500 mb-4">
          {new Date(event.timestamp).toLocaleString()}
        </p>

        {event.blockchain_tx && (
          <div
            onClick={() => copyToClipboard(event.blockchain_tx, 'Transaction hash')}
            className="flex items-center space-x-2 p-3 bg-gray-50 rounded-lg cursor-pointer hover:bg-gray-100"
          >
            <Link2 className="w-4 h-4 text-blue-600" />
            <code className="text-sm flex-1 font-mono text-blue-600">
              {event.blockchain_tx.substring(0, 20)}...{event.blockchain_tx.substring(event.blockchain_tx.length - 20)}
            </code>
            <Copy className="w-4 h-4 text-gray-400" />
          </div>
        )}

        {event.data && Object.keys(event.data).length > 0 && (
          <div className="mt-4 p-3 bg-gray-50 rounded-lg">
            <p className="text-xs font-semibold text-gray-700 mb-2">Event Data:</p>
            <pre className="text-xs text-gray-600 overflow-x-auto">
              {JSON.stringify(event.data, null, 2)}
            </pre>
          </div>
        )}
      </div>
    </div>
  );
}

function ProcessingView({ data, copyToClipboard }: any) {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {data.processing_stages.map((stage: any, index: number) => (
        <div key={index} className="bg-white rounded-lg shadow-sm border p-6">
          <div className="flex items-center space-x-3 mb-4">
            <Settings className="w-6 h-6 text-green-600" />
            <h3 className="text-lg font-semibold">{stage.stage_name}</h3>
          </div>
          
          <div className="space-y-2 text-sm">
            <InfoRow label="Type" value={stage.stage_type} />
            <InfoRow label="Location" value={stage.location || 'N/A'} />
            <InfoRow label="Operator" value={stage.operator_name || 'N/A'} />
            <InfoRow label="Timestamp" value={new Date(stage.timestamp).toLocaleString()} />
            {stage.notes && <InfoRow label="Notes" value={stage.notes} />}
          </div>

          {stage.blockchain_tx_hash && (
            <div className="mt-4 p-3 bg-green-50 rounded-lg">
              <div className="flex items-center space-x-2 text-green-700 text-sm">
                <CheckCircle className="w-4 h-4" />
                <span>Verified on Blockchain</span>
              </div>
            </div>
          )}
        </div>
      ))}
    </div>
  );
}

function CertificatesView({ data }: any) {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {data.certifications.map((cert: any, index: number) => (
        <div key={index} className="bg-white rounded-lg shadow-sm border p-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center space-x-3">
              <Award className="w-6 h-6 text-yellow-600" />
              <h3 className="text-lg font-semibold">{cert.cert_type}</h3>
            </div>
            {cert.verified && (
              <div className="flex items-center space-x-1 text-green-600 text-sm bg-green-50 px-3 py-1 rounded-full">
                <CheckCircle className="w-4 h-4" />
                <span>Verified</span>
              </div>
            )}
          </div>
          
          <div className="space-y-2 text-sm">
            <InfoRow label="Certificate Number" value={cert.cert_number} />
            <InfoRow label="Issued By" value={cert.issued_by} />
            <InfoRow label="Issue Date" value={new Date(cert.issue_date).toLocaleDateString()} />
            <InfoRow label="Expiry Date" value={new Date(cert.expiry_date).toLocaleDateString()} />
            {cert.verified && (
              <>
                <InfoRow label="Verified By" value={cert.verified_by} />
                <InfoRow label="Verified At" value={new Date(cert.verified_at).toLocaleString()} />
              </>
            )}
          </div>
        </div>
      ))}
    </div>
  );
}

function ComplianceView({ data, copyToClipboard }: any) {
  return (
    <div className="grid grid-cols-1 gap-6">
      {data.compliance_checks.map((check: any, index: number) => {
        const isPassed = check.passed === true;
        
        return (
          <div key={index} className="bg-white rounded-lg shadow-sm border p-6">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center space-x-3">
                <FileCheck className={`w-6 h-6 ${isPassed ? 'text-green-600' : 'text-red-600'}`} />
                <div>
                  <h3 className="text-lg font-semibold">{check.rule_name}</h3>
                  {check.rule_type && (
                    <span className="text-sm text-gray-500 uppercase">{check.rule_type}</span>
                  )}
                </div>
              </div>
              <div className={`px-4 py-2 rounded-full text-sm font-medium ${
                isPassed
                  ? 'bg-green-100 text-green-800'
                  : 'bg-red-100 text-red-800'
              }`}>
                {isPassed ? 'PASSED' : 'FAILED'}
              </div>
            </div>

            <InfoRow label="Checked At" value={new Date(check.checked_at).toLocaleString()} />

            {check.details && (
              <div className="mt-4 p-4 bg-gray-50 rounded-lg border border-gray-200">
                <div className="text-sm font-medium text-gray-700 mb-2">Details:</div>
                <div className="text-sm text-gray-600">
                  {typeof check.details === 'string' 
                    ? check.details 
                    : JSON.stringify(check.details, null, 2)}
                </div>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}

function BlockchainView({ data, copyToClipboard }: any) {
  return (
    <div className="space-y-6">
      {/* NFT Passport Card */}
      <div className="bg-white rounded-lg shadow-sm border p-6">
        <h3 className="text-xl font-bold mb-4 flex items-center space-x-2">
          <Link2 className="w-6 h-6 text-green-600" />
          <span>NFT Passport Information</span>
        </h3>
        
        <div className="space-y-3">
          <BlockchainRow
            label="Lot ID"
            value={data.lot_info.lot_id}
            copyToClipboard={copyToClipboard}
          />
          <BlockchainRow
            label="Primary TX Hash"
            value={data.blockchain_info.primary_tx_hash || 'Not yet recorded'}
            copyToClipboard={data.blockchain_info.primary_tx_hash ? copyToClipboard : undefined}
          />
          <BlockchainRow
            label="Certificate Hash"
            value={data.blockchain_info.certificate_hash || 'N/A'}
            copyToClipboard={copyToClipboard}
          />
          <BlockchainRow
            label="Metadata URI"
            value={data.blockchain_info.metadata_uri || 'N/A'}
            copyToClipboard={copyToClipboard}
          />
        </div>
      </div>

      {/* Current Status */}
      <div className="bg-white rounded-lg shadow-sm border p-6">
        <h3 className="text-xl font-bold mb-4">Current Status</h3>
        <div className="space-y-2 text-sm">
          <InfoRow label="Stage" value={data.current_status.description} />
          <InfoRow label="Current Owner" value={data.current_status.current_owner_name} />
          <InfoRow label="Compliance" value={data.current_status.compliance_status} />
          <InfoRow label="In Auction" value={data.current_status.is_in_auction ? 'Yes' : 'No'} />
        </div>
      </div>

      {/* Blockchain Statistics */}
      <div className="bg-white rounded-lg shadow-sm border p-6">
        <h3 className="text-xl font-bold mb-4">Blockchain Statistics</h3>
        <div className="space-y-2 text-sm">
          <InfoRow label="Total Transactions" value={data.blockchain_info.total_transactions} />
          <InfoRow label="Network" value="Hardhat Local (Chain ID: 1337)" />
          <InfoRow label="RPC URL" value="http://192.168.8.116:8545" />
        </div>
      </div>
    </div>
  );
}

function BlockchainRow({ label, value, copyToClipboard }: any) {
  return (
    <div>
      <div className="text-sm text-gray-600 mb-1">{label}</div>
      <div
        onClick={() => copyToClipboard && copyToClipboard(value, label)}
        className={`p-3 bg-gray-50 rounded-lg font-mono text-sm ${
          copyToClipboard ? 'cursor-pointer hover:bg-gray-100' : ''
        }`}
      >
        <div className="flex items-center justify-between">
          <span className="break-all">
            {value.length > 60
              ? `${value.substring(0, 30)}...${value.substring(value.length - 30)}`
              : value}
          </span>
          {copyToClipboard && <Copy className="w-4 h-4 text-gray-400 ml-2 flex-shrink-0" />}
        </div>
      </div>
    </div>
  );
}

function InfoRow({ label, value }: any) {
  return (
    <div className="flex justify-between items-start py-2 border-b border-gray-100 last:border-0">
      <span className="text-gray-600 font-medium">{label}:</span>
      <span className="text-gray-900 text-right ml-4">{value || 'N/A'}</span>
    </div>
  );
}
