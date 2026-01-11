'use client';

import { Shield, CheckCircle, XCircle, AlertCircle } from 'lucide-react';

interface Certification {
  certType: string;
  certId: string;
  issuedBy: string;
  issuedDate: Date;
  expiryDate: Date;
  documentHash: string;
  isValid: boolean;
}

interface CertificationBadgeProps {
  cert: Certification;
}

const certTypeColors: { [key: string]: string } = {
  'Organic': 'green',
  'Export': 'blue',
  'Quality': 'purple',
  'Fumigation': 'orange',
  'Phytosanitary': 'teal',
  'Origin': 'indigo',
};

export function CertificationBadge({ cert }: CertificationBadgeProps) {
  const isExpired = new Date(cert.expiryDate) < new Date();
  const isExpiringSoon = new Date(cert.expiryDate) < new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  const color = certTypeColors[cert.certType] || 'gray';

  const getStatusIcon = () => {
    if (!cert.isValid) return <XCircle className="w-5 h-5 text-red-500" />;
    if (isExpired) return <XCircle className="w-5 h-5 text-red-500" />;
    if (isExpiringSoon) return <AlertCircle className="w-5 h-5 text-yellow-500" />;
    return <CheckCircle className="w-5 h-5 text-green-500" />;
  };

  const getStatusText = () => {
    if (!cert.isValid) return 'Revoked';
    if (isExpired) return 'Expired';
    if (isExpiringSoon) return 'Expiring Soon';
    return 'Valid';
  };

  const getStatusColor = () => {
    if (!cert.isValid || isExpired) return 'red';
    if (isExpiringSoon) return 'yellow';
    return 'green';
  };

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center space-x-2">
          <Shield className={`w-6 h-6 text-${color}-500`} />
          <div>
            <h4 className="font-semibold text-gray-900 dark:text-white">
              {cert.certType} Certification
            </h4>
            <p className="text-sm text-gray-500 dark:text-gray-400 font-mono">
              {cert.certId}
            </p>
          </div>
        </div>
        <div className="flex items-center space-x-1">
          {getStatusIcon()}
        </div>
      </div>

      <div className="space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-gray-500 dark:text-gray-400">Issued By:</span>
          <span className="font-medium text-gray-900 dark:text-white">
            {cert.issuedBy}
          </span>
        </div>

        <div className="flex justify-between">
          <span className="text-gray-500 dark:text-gray-400">Issue Date:</span>
          <span className="font-medium text-gray-900 dark:text-white">
            {new Date(cert.issuedDate).toLocaleDateString()}
          </span>
        </div>

        <div className="flex justify-between">
          <span className="text-gray-500 dark:text-gray-400">Expiry Date:</span>
          <span className={`font-medium ${
            isExpired || isExpiringSoon 
              ? 'text-red-600 dark:text-red-400' 
              : 'text-gray-900 dark:text-white'
          }`}>
            {new Date(cert.expiryDate).toLocaleDateString()}
          </span>
        </div>

        <div className="pt-2 border-t border-gray-200 dark:border-gray-700">
          <div className="flex justify-between items-center">
            <span className="text-gray-500 dark:text-gray-400">Status:</span>
            <span className={`
              px-2 py-1 rounded-full text-xs font-medium
              ${getStatusColor() === 'green' ? 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400' : ''}
              ${getStatusColor() === 'yellow' ? 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-400' : ''}
              ${getStatusColor() === 'red' ? 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400' : ''}
            `}>
              {getStatusText()}
            </span>
          </div>
        </div>

        {cert.documentHash && cert.documentHash !== '0x0000000000000000000000000000000000000000000000000000000000000000' && (
          <div className="pt-2">
            <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">Document Hash:</p>
            <p className="font-mono text-xs text-gray-900 dark:text-white break-all">
              {cert.documentHash.substring(0, 30)}...
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

interface CertificationListProps {
  certifications: Certification[];
}

export function CertificationList({ certifications }: CertificationListProps) {
  if (certifications.length === 0) {
    return (
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-8 text-center">
        <Shield className="w-12 h-12 text-gray-400 mx-auto mb-3" />
        <p className="text-gray-500 dark:text-gray-400">No certifications available</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
        Certifications ({certifications.length})
      </h3>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {certifications.map((cert, index) => (
          <CertificationBadge key={index} cert={cert} />
        ))}
      </div>
    </div>
  );
}
