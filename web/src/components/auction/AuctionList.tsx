'use client';

import { useEffect, useState } from 'react';
import { auctionApi } from '@/lib/api';
import { Auction } from '@/store/auctionStore';
import { AuctionCard } from './AuctionCard';
import { Loader2 } from 'lucide-react';

interface AuctionListProps {
  status?: string;
  farmer?: string;
  limit?: number;
}

export function AuctionList({ status, farmer, limit = 50 }: AuctionListProps) {
  const [auctions, setAuctions] = useState<Auction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchAuctions() {
      try {
        setLoading(true);
        const response = await auctionApi.getAll({ status, farmer, limit });
        setAuctions(response.data.auctions);
      } catch (err) {
        console.error('Failed to fetch auctions:', err);
        setError('Failed to load auctions');
      } finally {
        setLoading(false);
      }
    }

    fetchAuctions();
  }, [status, farmer, limit]);

  if (loading) {
    return (
      <div className="flex justify-center items-center py-12">
        <Loader2 className="w-8 h-8 animate-spin text-primary-600" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="card text-center py-12">
        <p className="text-red-600 dark:text-red-400">{error}</p>
      </div>
    );
  }

  if (auctions.length === 0) {
    return (
      <div className="card text-center py-12">
        <p className="text-gray-600 dark:text-gray-400">No auctions found</p>
      </div>
    );
  }

  return (
    <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
      {auctions.map((auction) => (
        <AuctionCard key={auction.id} auction={auction} />
      ))}
    </div>
  );
}
