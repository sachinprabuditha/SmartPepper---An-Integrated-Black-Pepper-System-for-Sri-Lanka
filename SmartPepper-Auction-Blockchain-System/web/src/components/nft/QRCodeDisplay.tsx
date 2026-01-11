'use client';

import { useState, useEffect } from 'react';
import { QrCode, Download, Smartphone } from 'lucide-react';

interface QRCodeDisplayProps {
  lotId: string | number;
  size?: number;
  showInstructions?: boolean;
}

export function QRCodeDisplay({ 
  lotId, 
  size = 256, 
  showInstructions = true 
}: QRCodeDisplayProps) {
  const [qrCodeUrl, setQrCodeUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchQRCode();
  }, [lotId]);

  const fetchQRCode = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await fetch(`/api/nft-passport/qr/${lotId}`);
      
      if (!response.ok) {
        throw new Error('Failed to generate QR code');
      }

      const data = await response.json();
      setQrCodeUrl(data.qrCode);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load QR code');
    } finally {
      setLoading(false);
    }
  };

  const downloadQRCode = () => {
    if (!qrCodeUrl) return;

    const link = document.createElement('a');
    link.href = qrCodeUrl;
    link.download = `pepper-passport-lot-${lotId}.png`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  if (loading) {
    return (
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
        <div className="flex flex-col items-center justify-center space-y-3">
          <div className="w-64 h-64 bg-gray-100 dark:bg-gray-700 rounded-lg animate-pulse" />
          <p className="text-sm text-gray-500 dark:text-gray-400">Generating QR Code...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-red-200 dark:border-red-900 p-6">
        <div className="flex flex-col items-center justify-center space-y-3">
          <QrCode className="w-12 h-12 text-red-500" />
          <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
          <button
            onClick={fetchQRCode}
            className="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300"
          >
            Try Again
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
      <div className="flex flex-col items-center space-y-4">
        {/* QR Code Header */}
        <div className="flex items-center space-x-2 mb-2">
          <QrCode className="w-6 h-6 text-blue-600 dark:text-blue-400" />
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
            Digital Passport QR Code
          </h3>
        </div>

        {/* QR Code Image */}
        {qrCodeUrl && (
          <div className="bg-white p-4 rounded-lg border-2 border-gray-200 dark:border-gray-600">
            <img
              src={qrCodeUrl}
              alt={`QR Code for Lot ${lotId}`}
              width={size}
              height={size}
              className="block"
            />
          </div>
        )}

        {/* Lot ID */}
        <p className="text-sm text-gray-500 dark:text-gray-400">
          Lot ID: <span className="font-mono font-semibold text-gray-900 dark:text-white">#{lotId}</span>
        </p>

        {/* Download Button */}
        <button
          onClick={downloadQRCode}
          className="flex items-center space-x-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors"
        >
          <Download className="w-4 h-4" />
          <span>Download QR Code</span>
        </button>

        {/* Instructions */}
        {showInstructions && (
          <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700 w-full">
            <div className="flex items-start space-x-3">
              <Smartphone className="w-5 h-5 text-gray-400 mt-0.5 flex-shrink-0" />
              <div className="flex-1">
                <h4 className="text-sm font-medium text-gray-900 dark:text-white mb-2">
                  How to Use
                </h4>
                <ul className="text-sm text-gray-600 dark:text-gray-400 space-y-1">
                  <li>• Scan this QR code with any smartphone camera</li>
                  <li>• View complete product history and certifications</li>
                  <li>• Verify blockchain authenticity in real-time</li>
                  <li>• Share with buyers for transparency</li>
                </ul>
              </div>
            </div>
          </div>
        )}

        {/* Public Link */}
        <div className="w-full pt-2">
          <p className="text-xs text-gray-500 dark:text-gray-400 text-center mb-2">
            Public Verification Link:
          </p>
          <div className="bg-gray-50 dark:bg-gray-900 rounded px-3 py-2 font-mono text-xs text-gray-900 dark:text-white break-all text-center">
            {typeof window !== 'undefined' && `${window.location.origin}/passport/${lotId}`}
          </div>
        </div>
      </div>
    </div>
  );
}

interface CompactQRCodeProps {
  lotId: number;
  size?: number;
}

export function CompactQRCode({ lotId, size = 128 }: CompactQRCodeProps) {
  const [qrCodeUrl, setQrCodeUrl] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchQRCode = async () => {
      try {
        const response = await fetch(`/api/nft-passport/qr/${lotId}`);
        const data = await response.json();
        setQrCodeUrl(data.qrCode);
      } catch (err) {
        console.error('Failed to load QR code:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchQRCode();
  }, [lotId]);

  if (loading) {
    return (
      <div 
        className="bg-gray-100 dark:bg-gray-700 rounded animate-pulse"
        style={{ width: size, height: size }}
      />
    );
  }

  if (!qrCodeUrl) return null;

  return (
    <div className="inline-block bg-white p-2 rounded border border-gray-200 dark:border-gray-600">
      <img
        src={qrCodeUrl}
        alt={`QR Code for Lot ${lotId}`}
        width={size}
        height={size}
        className="block"
      />
    </div>
  );
}
