'use client';

import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { Shield, Search, CheckCircle, XCircle, AlertTriangle, FileText } from 'lucide-react';

interface ComplianceCheck {
  id: string;
  lotId: string;
  lotDetails?: {
    variety: string;
    quantity: number;
    farmerName: string;
  };
  checkType: string;
  status: string;
  result?: string;
  issues?: string[];
  certificate?: string;
  checkedBy?: string;
  checkedAt?: string;
  createdAt: string;
}

export default function CompliancePage() {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();
  const [checks, setChecks] = useState<ComplianceCheck[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [filterType, setFilterType] = useState('all');

  useEffect(() => {
    if (!authLoading && (!user || user.role !== 'admin')) {
      router.push('/login');
    }
  }, [user, authLoading, router]);

  useEffect(() => {
    if (user && user.role === 'admin') {
      fetchComplianceChecks();
    }
  }, [user]);

  const fetchComplianceChecks = async () => {
    try {
      setLoading(true);
      const response = await fetch('http://localhost:3002/api/compliance');
      
      if (!response.ok) {
        throw new Error('Failed to fetch compliance checks');
      }

      const data = await response.json();
      setChecks(data.checks || []);
    } catch (error) {
      console.error('Error fetching compliance checks:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'passed':
        return <CheckCircle className="w-5 h-5 text-green-600 dark:text-green-400" />;
      case 'failed':
        return <XCircle className="w-5 h-5 text-red-600 dark:text-red-400" />;
      case 'pending':
        return <AlertTriangle className="w-5 h-5 text-yellow-600 dark:text-yellow-400" />;
      default:
        return <Shield className="w-5 h-5 text-gray-600 dark:text-gray-400" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'passed':
        return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200';
      case 'failed':
        return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200';
      case 'pending':
        return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200';
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200';
    }
  };

  const filteredChecks = checks.filter(check => {
    const matchesSearch = (check.lotId || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (check.checkType || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (check.lotDetails?.farmerName || '').toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = filterStatus === 'all' || check.status === filterStatus;
    const matchesType = filterType === 'all' || check.checkType === filterType;
    return matchesSearch && matchesStatus && matchesType;
  });

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <button
            onClick={() => router.push('/dashboard/admin')}
            className="text-purple-600 hover:text-purple-700 mb-4"
          >
            ← Back to Dashboard
          </button>
          <div className="flex items-center space-x-3 mb-4">
            <Shield className="w-10 h-10 text-purple-600" />
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                Compliance Management
              </h1>
              <p className="text-gray-600 dark:text-gray-400">
                Review and manage compliance checks
              </p>
            </div>
          </div>
        </div>

        {/* Filters */}
        <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6 mb-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Search
              </label>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="Search by lot ID, check type, farmer..."
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-purple-500 dark:bg-gray-700 dark:text-white"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Status
              </label>
              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-purple-500 dark:bg-gray-700 dark:text-white"
              >
                <option value="all">All Status</option>
                <option value="pending">Pending</option>
                <option value="passed">Passed</option>
                <option value="failed">Failed</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Check Type
              </label>
              <select
                value={filterType}
                onChange={(e) => setFilterType(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-purple-500 dark:bg-gray-700 dark:text-white"
              >
                <option value="all">All Types</option>
                <option value="quality">Quality Check</option>
                <option value="pesticide">Pesticide Test</option>
                <option value="organic">Organic Certification</option>
                <option value="export">Export Compliance</option>
              </select>
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400">Total Checks</div>
            <div className="text-2xl font-bold text-gray-900 dark:text-white">{checks.length}</div>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400">Pending</div>
            <div className="text-2xl font-bold text-yellow-600">{checks.filter(c => c.status === 'pending').length}</div>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400">Passed</div>
            <div className="text-2xl font-bold text-green-600">{checks.filter(c => c.status === 'passed').length}</div>
          </div>
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
            <div className="text-sm text-gray-600 dark:text-gray-400">Failed</div>
            <div className="text-2xl font-bold text-red-600">{checks.filter(c => c.status === 'failed').length}</div>
          </div>
        </div>

        {/* Compliance Checks Table */}
        <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
              <thead className="bg-gray-50 dark:bg-gray-700">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Lot & Farmer
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Check Type
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Result
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Date
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                {filteredChecks.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-12 text-center text-gray-500 dark:text-gray-400">
                      No compliance checks found
                    </td>
                  </tr>
                ) : (
                  filteredChecks.map((check) => (
                    <tr key={check.id} className="hover:bg-gray-50 dark:hover:bg-gray-700">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div>
                          <div className="text-sm font-medium text-gray-900 dark:text-white">
                            {check.lotId}
                          </div>
                          {check.lotDetails && (
                            <>
                              <div className="text-sm text-gray-600 dark:text-gray-400">
                                {check.lotDetails.farmerName}
                              </div>
                              <div className="text-xs text-gray-500 dark:text-gray-500">
                                {check.lotDetails.variety} • {check.lotDetails.quantity} kg
                              </div>
                            </>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900 dark:text-white capitalize">
                          {check.checkType.replace('_', ' ')}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 inline-flex items-center text-xs leading-5 font-semibold rounded-full ${getStatusColor(check.status)}`}>
                          {getStatusIcon(check.status)}
                          <span className="ml-1 capitalize">{check.status}</span>
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <div className="text-sm">
                          {check.result && (
                            <div className="text-gray-900 dark:text-white mb-1">
                              {check.result}
                            </div>
                          )}
                          {check.issues && check.issues.length > 0 && (
                            <div className="text-red-600 dark:text-red-400 text-xs">
                              {check.issues.length} issue(s) found
                            </div>
                          )}
                          {check.certificate && (
                            <div className="flex items-center text-green-600 dark:text-green-400 text-xs mt-1">
                              <FileText className="w-3 h-3 mr-1" />
                              Certificate available
                            </div>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900 dark:text-white">
                          {new Date(check.createdAt).toLocaleDateString()}
                        </div>
                        {check.checkedAt && (
                          <div className="text-xs text-gray-500 dark:text-gray-400">
                            Checked: {new Date(check.checkedAt).toLocaleDateString()}
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm">
                        <div className="flex flex-col space-y-1">
                          <button
                            onClick={() => router.push(`/nft/passport/${check.lotId}`)}
                            className="text-purple-600 hover:text-purple-900 dark:text-purple-400 dark:hover:text-purple-300"
                          >
                            View Lot
                          </button>
                          {check.certificate && (
                            <a
                              href={check.certificate}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="text-green-600 hover:text-green-900 dark:text-green-400 dark:hover:text-green-300"
                            >
                              View Certificate
                            </a>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
