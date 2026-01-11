'use client';

import Link from 'next/link';
import { AuctionList } from '@/components/auction/AuctionList';
import { Leaf, TrendingUp, Shield, Zap, Users, ShoppingCart, Settings, Award, BarChart3, Package } from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';

export default function Home() {
  const { user, isAuthenticated } = useAuth();

  return (
    <div>
      {/* Hero Section - Role-aware */}
      <section className="bg-gradient-to-br from-pepper-darkBrown via-pepper-mediumBrown to-pepper-cinnamon text-white py-20 relative overflow-hidden">
        {/* Decorative overlay */}
        <div className="absolute inset-0 bg-black/10"></div>
        
        <div className="container mx-auto px-4 relative z-10">
          <div className="max-w-4xl mx-auto text-center">
            <div className="flex justify-center mb-6">
              <div className="bg-white/10 backdrop-blur-sm rounded-full p-4">
                <Leaf className="w-16 h-16 text-pepper-gold" />
              </div>
            </div>
            
            {isAuthenticated ? (
              <>
                <h1 className="text-5xl font-bold mb-4 text-shadow">
                  Welcome back, {user?.name}! 🌶️
                </h1>
                <p className="text-xl mb-8 text-pepper-gold">
                  {user?.role === 'farmer' && 'List your premium Sri Lankan black pepper lots and reach global buyers through our blockchain-powered auction platform.'}
                  {user?.role === 'exporter' && 'Browse quality Ceylon pepper lots, place bids, and secure the finest spices in real-time.'}
                  {user?.role === 'admin' && 'Monitor and manage the SmartPepper ecosystem - ensuring quality and compliance for Sri Lankan pepper exports.'}
                </p>
                <div className="flex gap-4 justify-center flex-wrap">
                  {user?.role === 'farmer' && (
                    <>
                      <Link href="/dashboard/farmer" className="btn bg-pepper-gold text-pepper-black hover:bg-pepper-harvest font-semibold text-lg px-8 py-3">
                        My Dashboard
                      </Link>
                      <Link href="/create" className="btn bg-white/20 backdrop-blur-sm text-white border-2 border-white/50 hover:bg-white/30 text-lg px-8 py-3">
                        Create Auction
                      </Link>
                    </>
                  )}
                  {user?.role === 'exporter' && (
                    <>
                      <Link href="/dashboard/exporter" className="btn bg-pepper-gold text-pepper-black hover:bg-pepper-harvest font-semibold text-lg px-8 py-3">
                        My Dashboard
                      </Link>
                      <Link href="/auctions" className="btn bg-white/20 backdrop-blur-sm text-white border-2 border-white/50 hover:bg-white/30 text-lg px-8 py-3">
                        Browse Auctions
                      </Link>
                    </>
                  )}
                  {user?.role === 'admin' && (
                    <>
                      <Link href="/dashboard/admin" className="btn bg-pepper-gold text-pepper-black hover:bg-pepper-harvest font-semibold text-lg px-8 py-3">
                        Admin Dashboard
                      </Link>
                      <Link href="/auctions" className="btn bg-white/20 backdrop-blur-sm text-white border-2 border-white/50 hover:bg-white/30 text-lg px-8 py-3">
                        View All Auctions
                      </Link>
                    </>
                  )}
                </div>
              </>
            ) : (
              <>
                <h1 className="text-5xl font-bold mb-6">
                  SmartPepper - Ceylon Black Pepper Auction
                </h1>
                <p className="text-xl mb-4 text-pepper-gold">
                  Real-time auctions for premium Sri Lankan black pepper.
                </p>
                <p className="text-lg mb-8 text-white/90">
                  Transparent, secure, and compliant trading from farm to export - powered by blockchain technology.
                </p>
                <div className="flex gap-4 justify-center flex-wrap">
                  <Link href="/register" className="btn bg-pepper-gold text-pepper-black hover:bg-pepper-harvest font-semibold text-lg px-8 py-3">
                    Get Started
                  </Link>
                  <Link href="/auctions" className="btn bg-white/20 backdrop-blur-sm text-white border-2 border-white/50 hover:bg-white/30 text-lg px-8 py-3">
                    Browse Auctions
                  </Link>
                  <Link href="/login" className="btn bg-transparent border-2 border-pepper-gold text-pepper-gold hover:bg-pepper-gold hover:text-pepper-black text-lg px-8 py-3">
                    Login
                  </Link>
                </div>
              </>
            )}
          </div>
        </div>
      </section>

      {/* Role-specific Quick Actions */}
      {isAuthenticated && (
        <section className="py-12 bg-gradient-to-b from-amber-50 to-white dark:from-pepper-black dark:to-gray-800">
          <div className="container mx-auto px-4">
            <h2 className="text-2xl font-bold mb-6 text-center text-pepper-darkBrown dark:text-pepper-gold">Quick Actions</h2>
            <div className="grid md:grid-cols-3 gap-6 max-w-4xl mx-auto">
              {user?.role === 'farmer' && (
                <>
                  <Link href="/create" className="card hover:shadow-lg transition-shadow p-6 text-center border-t-4 border-farmer-600">
                    <Package className="w-10 h-10 mx-auto mb-3 text-farmer-600" />
                    <h3 className="font-semibold mb-2">Create Auction</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400">List your pepper lots</p>
                  </Link>
                  <Link href="/dashboard/farmer" className="card hover:shadow-lg transition-shadow p-6 text-center">
                    <BarChart3 className="w-10 h-10 mx-auto mb-3 text-green-600" />
                    <h3 className="font-semibold mb-2">View Analytics</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400">Track your performance</p>
                  </Link>
                  <Link href="/auctions" className="card hover:shadow-lg transition-shadow p-6 text-center">
                    <Award className="w-10 h-10 mx-auto mb-3 text-green-600" />
                    <h3 className="font-semibold mb-2">My Auctions</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400">Manage active auctions</p>
                  </Link>
                </>
              )}
              {user?.role === 'exporter' && (
                <>
                  <Link href="/auctions" className="card hover:shadow-lg transition-shadow p-6 text-center">
                    <ShoppingCart className="w-10 h-10 mx-auto mb-3 text-blue-600" />
                    <h3 className="font-semibold mb-2">Browse Auctions</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400">Find pepper lots</p>
                  </Link>
                  <Link href="/dashboard/exporter" className="card hover:shadow-lg transition-shadow p-6 text-center">
                    <BarChart3 className="w-10 h-10 mx-auto mb-3 text-blue-600" />
                    <h3 className="font-semibold mb-2">My Bids</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400">Track your bids</p>
                  </Link>
                  <Link href="/dashboard/exporter" className="card hover:shadow-lg transition-shadow p-6 text-center">
                    <Award className="w-10 h-10 mx-auto mb-3 text-blue-600" />
                    <h3 className="font-semibold mb-2">Won Auctions</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400">View your wins</p>
                  </Link>
                </>
              )}
              {user?.role === 'admin' && (
                <>
                  <Link href="/dashboard/admin" className="card hover:shadow-lg transition-shadow p-6 text-center">
                    <Users className="w-10 h-10 mx-auto mb-3 text-purple-600" />
                    <h3 className="font-semibold mb-2">Manage Users</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400">User management</p>
                  </Link>
                  <Link href="/dashboard/admin" className="card hover:shadow-lg transition-shadow p-6 text-center">
                    <Settings className="w-10 h-10 mx-auto mb-3 text-purple-600" />
                    <h3 className="font-semibold mb-2">System Settings</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400">Configure platform</p>
                  </Link>
                  <Link href="/auctions" className="card hover:shadow-lg transition-shadow p-6 text-center">
                    <BarChart3 className="w-10 h-10 mx-auto mb-3 text-purple-600" />
                    <h3 className="font-semibold mb-2">Analytics</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400">Platform insights</p>
                  </Link>
                </>
              )}
            </div>
          </div>
        </section>
      )}

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
