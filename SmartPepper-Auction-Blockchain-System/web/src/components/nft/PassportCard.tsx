'use client';

import { Package, MapPin, Calendar, Shield, Hash, User } from 'lucide-react';

interface PassportData {
  lotId: string;
  farmer: string;
  createdAt: Date;
  origin: string;
  variety: string;
  quantity: string;
  harvestDate: string;
  certificateHash: string;
  isActive: boolean;
}

interface PassportCardProps {
  tokenId: string;
  passport: PassportData;
  showQR?: boolean;
}

export function PassportCard({ tokenId, passport, showQR = true }: PassportCardProps) {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
      {/* Header */}
      <div className="bg-gradient-to-r from-green-500 to-green-600 p-6 text-white">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold mb-1">🌶️ Pepper Passport</h2>
            <p className="text-green-100">NFT Token #{tokenId}</p>
          </div>
          {passport.isActive && (
            <span className="px-3 py-1 bg-white bg-opacity-20 rounded-full text-sm font-medium">
              Active
            </span>
          )}
        </div>
      </div>

      {/* Main Content */}
      <div className="p-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Lot Information */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              Lot Information
            </h3>
            
            <div className="flex items-start space-x-3">
              <Package className="w-5 h-5 text-gray-400 mt-0.5" />
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Lot ID</p>
                <p className="font-medium text-gray-900 dark:text-white">{passport.lotId}</p>
              </div>
            </div>

            <div className="flex items-start space-x-3">
              <Package className="w-5 h-5 text-gray-400 mt-0.5" />
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Variety</p>
                <p className="font-medium text-gray-900 dark:text-white">{passport.variety}</p>
              </div>
            </div>

            <div className="flex items-start space-x-3">
              <Package className="w-5 h-5 text-gray-400 mt-0.5" />
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Quantity</p>
                <p className="font-medium text-gray-900 dark:text-white">{passport.quantity} kg</p>
              </div>
            </div>

            <div className="flex items-start space-x-3">
              <MapPin className="w-5 h-5 text-gray-400 mt-0.5" />
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Origin</p>
                <p className="font-medium text-gray-900 dark:text-white">{passport.origin}</p>
              </div>
            </div>
          </div>

          {/* Traceability Information */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              Traceability
            </h3>

            <div className="flex items-start space-x-3">
              <User className="w-5 h-5 text-gray-400 mt-0.5" />
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Farmer</p>
                <p className="font-mono text-sm text-gray-900 dark:text-white break-all">
                  {passport.farmer.substring(0, 10)}...{passport.farmer.substring(38)}
                </p>
              </div>
            </div>

            <div className="flex items-start space-x-3">
              <Calendar className="w-5 h-5 text-gray-400 mt-0.5" />
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Harvest Date</p>
                <p className="font-medium text-gray-900 dark:text-white">{passport.harvestDate}</p>
              </div>
            </div>

            <div className="flex items-start space-x-3">
              <Calendar className="w-5 h-5 text-gray-400 mt-0.5" />
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Registered</p>
                <p className="font-medium text-gray-900 dark:text-white">
                  {new Date(passport.createdAt).toLocaleDateString()}
                </p>
              </div>
            </div>

            <div className="flex items-start space-x-3">
              <Shield className="w-5 h-5 text-gray-400 mt-0.5" />
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Certificate Hash</p>
                <p className="font-mono text-xs text-gray-900 dark:text-white break-all">
                  {passport.certificateHash.substring(0, 20)}...
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Blockchain Verification */}
        <div className="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
          <div className="flex items-center space-x-2 text-green-600 dark:text-green-400">
            <Shield className="w-5 h-5" />
            <span className="text-sm font-medium">
              ✓ Verified on Blockchain
            </span>
          </div>
          <p className="mt-2 text-xs text-gray-500 dark:text-gray-400">
            This passport is secured by blockchain technology, ensuring authenticity and preventing fraud.
          </p>
        </div>
      </div>
    </div>
  );
}
