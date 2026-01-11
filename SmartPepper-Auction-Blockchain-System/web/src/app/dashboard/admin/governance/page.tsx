'use client';

import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { 
  Settings, Shield, Clock, DollarSign, AlertTriangle, 
  FileText, CheckCircle, XCircle, Plus, Edit2, Trash2,
  Activity, BookOpen
} from 'lucide-react';

interface AuctionRuleTemplate {
  id: string;
  name: string;
  description: string;
  minDuration: number; // hours
  maxDuration: number; // hours
  minBidIncrement: number; // percentage
  requiresApproval: boolean;
  maxReservePrice: number;
  createdAt: string;
  createdBy: string;
}

interface GovernanceLog {
  id: string;
  action: string;
  performedBy: string;
  details: string;
  blockchainTxHash?: string;
  timestamp: string;
}

interface EmergencyCancellationRequest {
  id: string;
  auctionId: string;
  lotId: string;
  requestedBy: string;
  reason: string;
  status: 'pending' | 'approved' | 'rejected';
  timestamp: string;
}

export default function AuctionGovernancePage() {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();
  
  // State for rule templates
  const [templates, setTemplates] = useState<AuctionRuleTemplate[]>([]);
  const [showTemplateModal, setShowTemplateModal] = useState(false);
  const [editingTemplate, setEditingTemplate] = useState<AuctionRuleTemplate | null>(null);
  
  // State for governance settings
  const [governanceSettings, setGovernanceSettings] = useState({
    defaultMinDuration: 24, // hours
    defaultMaxDuration: 168, // 7 days
    defaultBidIncrement: 5, // percentage
    allowedDurations: [24, 48, 72, 96, 168], // hours
    minReservePrice: 100,
    maxReservePrice: 1000000,
    requiresAdminApproval: false,
  });
  
  // State for emergency cancellations
  const [cancellationRequests, setCancellationRequests] = useState<EmergencyCancellationRequest[]>([]);
  
  // State for governance logs
  const [governanceLogs, setGovernanceLogs] = useState<GovernanceLog[]>([]);
  const [activeTab, setActiveTab] = useState<'templates' | 'settings' | 'cancellations' | 'logs'>('templates');
  
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!authLoading && (!user || user.role !== 'admin')) {
      router.push('/login');
    }
  }, [user, authLoading, router]);

  useEffect(() => {
    if (user && user.role === 'admin') {
      loadGovernanceData();
    }
  }, [user]);

  const loadGovernanceData = async () => {
    try {
      setLoading(true);
      // TODO: Replace with actual API calls
      
      // Mock data for templates
      setTemplates([
        {
          id: '1',
          name: 'Standard Auction',
          description: 'Default template for regular pepper auctions',
          minDuration: 24,
          maxDuration: 168,
          minBidIncrement: 5,
          requiresApproval: false,
          maxReservePrice: 100000,
          createdAt: new Date().toISOString(),
          createdBy: 'admin@smartpepper.com',
        },
        {
          id: '2',
          name: 'Premium Lot Auction',
          description: 'For high-value premium quality lots',
          minDuration: 48,
          maxDuration: 240,
          minBidIncrement: 10,
          requiresApproval: true,
          maxReservePrice: 500000,
          createdAt: new Date().toISOString(),
          createdBy: 'admin@smartpepper.com',
        },
      ]);
      
      // Mock data for cancellation requests
      setCancellationRequests([
        {
          id: '1',
          auctionId: '1766917103',
          lotId: 'LOT-1766820145306',
          requestedBy: '0x6f8d5dd2fe3766237492392ed71ae68c011e00fa',
          reason: 'Quality issue discovered after auction started',
          status: 'pending',
          timestamp: new Date().toISOString(),
        },
      ]);
      
      // Mock data for logs
      setGovernanceLogs([
        {
          id: '1',
          action: 'Template Created',
          performedBy: user?.email || 'admin',
          details: 'Created "Standard Auction" template',
          blockchainTxHash: '0x1234...5678',
          timestamp: new Date().toISOString(),
        },
        {
          id: '2',
          action: 'Settings Updated',
          performedBy: user?.email || 'admin',
          details: 'Updated default bid increment to 5%',
          blockchainTxHash: '0xabcd...efgh',
          timestamp: new Date().toISOString(),
        },
      ]);
      
    } catch (error) {
      console.error('Failed to load governance data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSaveTemplate = async (template: Partial<AuctionRuleTemplate>) => {
    try {
      // TODO: Call API to save template
      console.log('Saving template:', template);
      
      // Log the governance action on-chain
      await logGovernanceAction('Template Created', `Created template: ${template.name}`);
      
      // Refresh data
      await loadGovernanceData();
      setShowTemplateModal(false);
      setEditingTemplate(null);
    } catch (error) {
      console.error('Failed to save template:', error);
    }
  };

  const handleDeleteTemplate = async (templateId: string) => {
    if (!confirm('Are you sure you want to delete this template?')) return;
    
    try {
      // TODO: Call API to delete template
      console.log('Deleting template:', templateId);
      
      await logGovernanceAction('Template Deleted', `Deleted template ID: ${templateId}`);
      await loadGovernanceData();
    } catch (error) {
      console.error('Failed to delete template:', error);
    }
  };

  const handleUpdateSettings = async () => {
    try {
      // TODO: Call API to update governance settings
      console.log('Updating settings:', governanceSettings);
      
      await logGovernanceAction('Settings Updated', JSON.stringify(governanceSettings));
      alert('Settings updated successfully!');
    } catch (error) {
      console.error('Failed to update settings:', error);
    }
  };

  const handleCancellationRequest = async (requestId: string, approve: boolean) => {
    try {
      // TODO: Call API to approve/reject cancellation
      console.log(`${approve ? 'Approving' : 'Rejecting'} cancellation request:`, requestId);
      
      await logGovernanceAction(
        'Emergency Cancellation',
        `${approve ? 'Approved' : 'Rejected'} cancellation request ${requestId}`
      );
      
      await loadGovernanceData();
    } catch (error) {
      console.error('Failed to process cancellation request:', error);
    }
  };

  const logGovernanceAction = async (action: string, details: string) => {
    try {
      // TODO: Call blockchain service to log on-chain
      console.log('Logging governance action on-chain:', { action, details });
      
      // For now, just add to local logs
      const newLog: GovernanceLog = {
        id: Date.now().toString(),
        action,
        performedBy: user?.email || 'admin',
        details,
        blockchainTxHash: '0x' + Math.random().toString(16).substr(2, 40),
        timestamp: new Date().toISOString(),
      };
      
      setGovernanceLogs(prev => [newLog, ...prev]);
    } catch (error) {
      console.error('Failed to log governance action:', error);
    }
  };

  if (loading || authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Page Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-purple-900 dark:text-purple-300">
            <Shield className="inline mr-2" size={32} />
            Auction Governance
          </h1>
          <p className="text-gray-600 dark:text-gray-400 mt-2">
            Define auction rules, manage templates, and oversee emergency actions
          </p>
        </div>

        {/* Tabs */}
        <div className="mb-6 border-b border-gray-200 dark:border-gray-700">
          <nav className="flex space-x-8">
            <button
              onClick={() => setActiveTab('templates')}
              className={`pb-4 px-1 border-b-2 font-medium text-sm transition ${
                activeTab === 'templates'
                  ? 'border-purple-500 text-purple-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <FileText className="inline mr-2" size={18} />
              Rule Templates
            </button>
            <button
              onClick={() => setActiveTab('settings')}
              className={`pb-4 px-1 border-b-2 font-medium text-sm transition ${
                activeTab === 'settings'
                  ? 'border-purple-500 text-purple-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <Settings className="inline mr-2" size={18} />
              Global Settings
            </button>
            <button
              onClick={() => setActiveTab('cancellations')}
              className={`pb-4 px-1 border-b-2 font-medium text-sm transition ${
                activeTab === 'cancellations'
                  ? 'border-purple-500 text-purple-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <AlertTriangle className="inline mr-2" size={18} />
              Emergency Requests
              {cancellationRequests.filter(r => r.status === 'pending').length > 0 && (
                <span className="ml-2 bg-red-500 text-white text-xs px-2 py-1 rounded-full">
                  {cancellationRequests.filter(r => r.status === 'pending').length}
                </span>
              )}
            </button>
            <button
              onClick={() => setActiveTab('logs')}
              className={`pb-4 px-1 border-b-2 font-medium text-sm transition ${
                activeTab === 'logs'
                  ? 'border-purple-500 text-purple-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <BookOpen className="inline mr-2" size={18} />
              Audit Logs
            </button>
          </nav>
        </div>

        {/* Tab Content */}
        {activeTab === 'templates' && (
          <TemplatesTab
            templates={templates}
            onAdd={() => {
              setEditingTemplate(null);
              setShowTemplateModal(true);
            }}
            onEdit={(template) => {
              setEditingTemplate(template);
              setShowTemplateModal(true);
            }}
            onDelete={handleDeleteTemplate}
          />
        )}

        {activeTab === 'settings' && (
          <SettingsTab
            settings={governanceSettings}
            onChange={setGovernanceSettings}
            onSave={handleUpdateSettings}
          />
        )}

        {activeTab === 'cancellations' && (
          <CancellationsTab
            requests={cancellationRequests}
            onApprove={(id) => handleCancellationRequest(id, true)}
            onReject={(id) => handleCancellationRequest(id, false)}
          />
        )}

        {activeTab === 'logs' && (
          <AuditLogsTab logs={governanceLogs} />
        )}

        {/* Template Modal */}
        {showTemplateModal && (
          <TemplateModal
            template={editingTemplate}
            onSave={handleSaveTemplate}
            onClose={() => {
              setShowTemplateModal(false);
              setEditingTemplate(null);
            }}
          />
        )}
      </div>
    </div>
  );
}

// Templates Tab Component
function TemplatesTab({ 
  templates, 
  onAdd, 
  onEdit, 
  onDelete 
}: { 
  templates: AuctionRuleTemplate[];
  onAdd: () => void;
  onEdit: (template: AuctionRuleTemplate) => void;
  onDelete: (id: string) => void;
}) {
  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
          Auction Rule Templates
        </h2>
        <button
          onClick={onAdd}
          className="flex items-center px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition"
        >
          <Plus size={18} className="mr-2" />
          New Template
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {templates.map((template) => (
          <div
            key={template.id}
            className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6"
          >
            <div className="flex justify-between items-start mb-4">
              <div>
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                  {template.name}
                </h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  {template.description}
                </p>
              </div>
              <div className="flex space-x-2">
                <button
                  onClick={() => onEdit(template)}
                  className="p-2 text-blue-600 hover:bg-blue-50 rounded transition"
                >
                  <Edit2 size={18} />
                </button>
                <button
                  onClick={() => onDelete(template.id)}
                  className="p-2 text-red-600 hover:bg-red-50 rounded transition"
                >
                  <Trash2 size={18} />
                </button>
              </div>
            </div>

            <div className="space-y-3">
              <div className="flex items-center text-sm">
                <Clock size={16} className="text-gray-500 mr-2" />
                <span className="text-gray-600">Duration: {template.minDuration}h - {template.maxDuration}h</span>
              </div>
              <div className="flex items-center text-sm">
                <DollarSign size={16} className="text-gray-500 mr-2" />
                <span className="text-gray-600">Min Bid Increment: {template.minBidIncrement}%</span>
              </div>
              <div className="flex items-center text-sm">
                <DollarSign size={16} className="text-gray-500 mr-2" />
                <span className="text-gray-600">Max Reserve: LKR {template.maxReservePrice.toLocaleString()}</span>
              </div>
              <div className="flex items-center text-sm">
                {template.requiresApproval ? (
                  <>
                    <CheckCircle size={16} className="text-green-500 mr-2" />
                    <span className="text-gray-600">Requires Admin Approval</span>
                  </>
                ) : (
                  <>
                    <XCircle size={16} className="text-gray-500 mr-2" />
                    <span className="text-gray-600">Auto-approved</span>
                  </>
                )}
              </div>
            </div>

            <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
              <p className="text-xs text-gray-500">
                Created by {template.createdBy} on {new Date(template.createdAt).toLocaleDateString()}
              </p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// Settings Tab Component
function SettingsTab({ 
  settings, 
  onChange, 
  onSave 
}: { 
  settings: any;
  onChange: (settings: any) => void;
  onSave: () => void;
}) {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
      <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-6">
        Global Auction Settings
      </h2>

      <div className="space-y-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Default Minimum Duration (hours)
          </label>
          <input
            type="number"
            value={settings.defaultMinDuration}
            onChange={(e) => onChange({ ...settings, defaultMinDuration: parseInt(e.target.value) })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Default Maximum Duration (hours)
          </label>
          <input
            type="number"
            value={settings.defaultMaxDuration}
            onChange={(e) => onChange({ ...settings, defaultMaxDuration: parseInt(e.target.value) })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Default Bid Increment (%)
          </label>
          <input
            type="number"
            value={settings.defaultBidIncrement}
            onChange={(e) => onChange({ ...settings, defaultBidIncrement: parseInt(e.target.value) })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Allowed Durations (hours, comma-separated)
          </label>
          <input
            type="text"
            value={settings.allowedDurations.join(', ')}
            onChange={(e) => onChange({ 
              ...settings, 
              allowedDurations: e.target.value.split(',').map(v => parseInt(v.trim())).filter(v => !isNaN(v))
            })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
            placeholder="24, 48, 72, 168"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Minimum Reserve Price (LKR)
          </label>
          <input
            type="number"
            value={settings.minReservePrice}
            onChange={(e) => onChange({ ...settings, minReservePrice: parseInt(e.target.value) })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Maximum Reserve Price (LKR)
          </label>
          <input
            type="number"
            value={settings.maxReservePrice}
            onChange={(e) => onChange({ ...settings, maxReservePrice: parseInt(e.target.value) })}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
          />
        </div>

        <div className="flex items-center">
          <input
            type="checkbox"
            id="requiresApproval"
            checked={settings.requiresAdminApproval}
            onChange={(e) => onChange({ ...settings, requiresAdminApproval: e.target.checked })}
            className="h-4 w-4 text-purple-600 focus:ring-purple-500 border-gray-300 rounded"
          />
          <label htmlFor="requiresApproval" className="ml-2 block text-sm text-gray-700 dark:text-gray-300">
            Require admin approval for all auctions
          </label>
        </div>

        <button
          onClick={onSave}
          className="w-full py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition font-medium"
        >
          Save Settings
        </button>
      </div>
    </div>
  );
}

// Cancellations Tab Component
function CancellationsTab({ 
  requests, 
  onApprove, 
  onReject 
}: { 
  requests: EmergencyCancellationRequest[];
  onApprove: (id: string) => void;
  onReject: (id: string) => void;
}) {
  const pendingRequests = requests.filter(r => r.status === 'pending');
  const processedRequests = requests.filter(r => r.status !== 'pending');

  return (
    <div className="space-y-6">
      {/* Pending Requests */}
      <div>
        <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
          Pending Requests ({pendingRequests.length})
        </h2>
        {pendingRequests.length === 0 ? (
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-8 text-center">
            <CheckCircle size={48} className="mx-auto text-green-500 mb-4" />
            <p className="text-gray-600 dark:text-gray-400">No pending cancellation requests</p>
          </div>
        ) : (
          <div className="space-y-4">
            {pendingRequests.map((request) => (
              <div
                key={request.id}
                className="bg-white dark:bg-gray-800 rounded-lg border-2 border-orange-200 dark:border-orange-800 p-6"
              >
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                      Emergency Cancellation Request
                    </h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                      Submitted {new Date(request.timestamp).toLocaleString()}
                    </p>
                  </div>
                  <span className="px-3 py-1 bg-orange-100 text-orange-800 rounded-full text-sm font-medium">
                    Pending Review
                  </span>
                </div>

                <div className="space-y-2 mb-4">
                  <p><span className="font-medium">Auction ID:</span> {request.auctionId}</p>
                  <p><span className="font-medium">Lot ID:</span> {request.lotId}</p>
                  <p><span className="font-medium">Requested by:</span> {request.requestedBy}</p>
                  <p><span className="font-medium">Reason:</span> {request.reason}</p>
                </div>

                <div className="flex space-x-4">
                  <button
                    onClick={() => onApprove(request.id)}
                    className="flex-1 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition font-medium"
                  >
                    <CheckCircle className="inline mr-2" size={18} />
                    Approve Cancellation
                  </button>
                  <button
                    onClick={() => onReject(request.id)}
                    className="flex-1 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition font-medium"
                  >
                    <XCircle className="inline mr-2" size={18} />
                    Reject Request
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Processed Requests */}
      {processedRequests.length > 0 && (
        <div>
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
            Request History
          </h2>
          <div className="space-y-3">
            {processedRequests.map((request) => (
              <div
                key={request.id}
                className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4"
              >
                <div className="flex justify-between items-center">
                  <div>
                    <p className="font-medium text-gray-900 dark:text-white">
                      Auction {request.auctionId} / Lot {request.lotId}
                    </p>
                    <p className="text-sm text-gray-600 dark:text-gray-400">
                      {new Date(request.timestamp).toLocaleString()}
                    </p>
                  </div>
                  <span
                    className={`px-3 py-1 rounded-full text-sm font-medium ${
                      request.status === 'approved'
                        ? 'bg-green-100 text-green-800'
                        : 'bg-red-100 text-red-800'
                    }`}
                  >
                    {request.status === 'approved' ? 'Approved' : 'Rejected'}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

// Audit Logs Tab Component
function AuditLogsTab({ logs }: { logs: GovernanceLog[] }) {
  return (
    <div>
      <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-6">
        Governance Action Audit Trail
      </h2>

      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 dark:bg-gray-700">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Timestamp
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Action
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Performed By
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Details
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Blockchain TX
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
              {logs.map((log) => (
                <tr key={log.id} className="hover:bg-gray-50 dark:hover:bg-gray-700">
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-gray-300">
                    {new Date(log.timestamp).toLocaleString()}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className="flex items-center text-sm font-medium text-gray-900 dark:text-gray-300">
                      <Activity size={16} className="text-purple-600 mr-2" />
                      {log.action}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600 dark:text-gray-400">
                    {log.performedBy}
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-600 dark:text-gray-400">
                    {log.details}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm">
                    {log.blockchainTxHash ? (
                      <a
                        href={`http://localhost:8545/tx/${log.blockchainTxHash}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-purple-600 hover:text-purple-800 font-mono"
                      >
                        {log.blockchainTxHash.substring(0, 10)}...
                      </a>
                    ) : (
                      <span className="text-gray-400">-</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

// Template Modal Component
function TemplateModal({ 
  template, 
  onSave, 
  onClose 
}: { 
  template: AuctionRuleTemplate | null;
  onSave: (template: Partial<AuctionRuleTemplate>) => void;
  onClose: () => void;
}) {
  const [formData, setFormData] = useState<Partial<AuctionRuleTemplate>>(
    template || {
      name: '',
      description: '',
      minDuration: 24,
      maxDuration: 168,
      minBidIncrement: 5,
      requiresApproval: false,
      maxReservePrice: 100000,
    }
  );

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md w-full mx-4">
        <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
          {template ? 'Edit Template' : 'Create New Template'}
        </h2>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Template Name
            </label>
            <input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
              placeholder="e.g., Standard Auction"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Description
            </label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
              rows={3}
              placeholder="Describe when to use this template"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Min Duration (hrs)
              </label>
              <input
                type="number"
                value={formData.minDuration}
                onChange={(e) => setFormData({ ...formData, minDuration: parseInt(e.target.value) })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Max Duration (hrs)
              </label>
              <input
                type="number"
                value={formData.maxDuration}
                onChange={(e) => setFormData({ ...formData, maxDuration: parseInt(e.target.value) })}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Min Bid Increment (%)
            </label>
            <input
              type="number"
              value={formData.minBidIncrement}
              onChange={(e) => setFormData({ ...formData, minBidIncrement: parseInt(e.target.value) })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Max Reserve Price (LKR)
            </label>
            <input
              type="number"
              value={formData.maxReservePrice}
              onChange={(e) => setFormData({ ...formData, maxReservePrice: parseInt(e.target.value) })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500"
            />
          </div>

          <div className="flex items-center">
            <input
              type="checkbox"
              id="modalRequiresApproval"
              checked={formData.requiresApproval}
              onChange={(e) => setFormData({ ...formData, requiresApproval: e.target.checked })}
              className="h-4 w-4 text-purple-600 focus:ring-purple-500 border-gray-300 rounded"
            />
            <label htmlFor="modalRequiresApproval" className="ml-2 block text-sm text-gray-700 dark:text-gray-300">
              Require admin approval
            </label>
          </div>
        </div>

        <div className="flex space-x-4 mt-6">
          <button
            onClick={onClose}
            className="flex-1 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition"
          >
            Cancel
          </button>
          <button
            onClick={() => onSave(formData)}
            className="flex-1 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition"
          >
            Save Template
          </button>
        </div>
      </div>
    </div>
  );
}
