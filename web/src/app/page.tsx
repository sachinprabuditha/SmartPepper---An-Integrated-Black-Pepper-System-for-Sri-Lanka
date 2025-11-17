import Link from 'next/link';
import { AuctionList } from '@/components/auction/AuctionList';
import { Leaf, TrendingUp, Shield, Zap } from 'lucide-react';

export default function Home() {
  return (
    <div>
      {/* Hero Section */}
      <section className="bg-gradient-to-r from-primary-600 to-primary-800 text-white py-20">
        <div className="container mx-auto px-4">
          <div className="max-w-4xl mx-auto text-center">
            <div className="flex justify-center mb-6">
              <Leaf className="w-16 h-16" />
            </div>
            <h1 className="text-5xl font-bold mb-6">
              SmartPepper Blockchain Auction
            </h1>
            <p className="text-xl mb-8 text-primary-100">
              Real-time pepper auctions powered by blockchain technology.
              Transparent, secure, and compliant trading from farm to export.
            </p>
            <div className="flex gap-4 justify-center">
              <Link href="/auctions" className="btn-primary text-lg px-8 py-3">
                View Live Auctions
              </Link>
              <Link href="/create" className="btn bg-white text-primary-600 hover:bg-gray-100 text-lg px-8 py-3">
                Create Auction
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-16 bg-gray-50 dark:bg-gray-900">
        <div className="container mx-auto px-4">
          <h2 className="text-3xl font-bold text-center mb-12">
            Why Choose SmartPepper?
          </h2>
          <div className="grid md:grid-cols-3 gap-8">
            <div className="card text-center">
              <div className="flex justify-center mb-4">
                <Zap className="w-12 h-12 text-primary-600" />
              </div>
              <h3 className="text-xl font-semibold mb-3">Real-Time Bidding</h3>
              <p className="text-gray-600 dark:text-gray-400">
                Live WebSocket-powered auctions with instant updates. See bids as they happen.
              </p>
            </div>

            <div className="card text-center">
              <div className="flex justify-center mb-4">
                <Shield className="w-12 h-12 text-primary-600" />
              </div>
              <h3 className="text-xl font-semibold mb-3">Blockchain Security</h3>
              <p className="text-gray-600 dark:text-gray-400">
                Immutable smart contracts with automated escrow and transparent transactions.
              </p>
            </div>

            <div className="card text-center">
              <div className="flex justify-center mb-4">
                <TrendingUp className="w-12 h-12 text-primary-600" />
              </div>
              <h3 className="text-xl font-semibold mb-3">Compliance Automation</h3>
              <p className="text-gray-600 dark:text-gray-400">
                Automated certificate validation and regulatory compliance checks.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Active Auctions Section */}
      <section className="py-16">
        <div className="container mx-auto px-4">
          <div className="flex justify-between items-center mb-8">
            <h2 className="text-3xl font-bold">Active Auctions</h2>
            <Link href="/auctions" className="btn-primary">
              View All
            </Link>
          </div>
          <AuctionList limit={6} status="active" />
        </div>
      </section>

      {/* Stats Section */}
      <section className="bg-primary-600 text-white py-12">
        <div className="container mx-auto px-4">
          <div className="grid md:grid-cols-4 gap-8 text-center">
            <div>
              <div className="text-4xl font-bold mb-2">1,234</div>
              <div className="text-primary-200">Total Auctions</div>
            </div>
            <div>
              <div className="text-4xl font-bold mb-2">567</div>
              <div className="text-primary-200">Active Farmers</div>
            </div>
            <div>
              <div className="text-4xl font-bold mb-2">89</div>
              <div className="text-primary-200">Verified Buyers</div>
            </div>
            <div>
              <div className="text-4xl font-bold mb-2">₹12.5M</div>
              <div className="text-primary-200">Total Trading Volume</div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
