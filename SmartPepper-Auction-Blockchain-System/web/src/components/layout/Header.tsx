'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import Link from 'next/link';
import { Leaf, Menu, X, User, LogOut, ChevronDown, Sun, Moon } from 'lucide-react';
import { useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { useTheme } from '@/contexts/ThemeContext';

export function Header() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const { user, isAuthenticated, logout } = useAuth();
  const { theme, toggleTheme } = useTheme();

  const handleLogout = async () => {
    await logout();
    setMobileMenuOpen(false);
    setUserMenuOpen(false);
  };

  // Get role color
  const getRoleColor = () => {
    if (user?.role === 'farmer') return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200';
    if (user?.role === 'exporter') return 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200';
    if (user?.role === 'admin') return 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200';
    return 'bg-gray-100 text-gray-800';
  };

  return (
    <header className="bg-gradient-to-r from-pepper-darkBrown to-pepper-mediumBrown dark:from-pepper-black dark:to-pepper-darkBrown shadow-lg sticky top-0 z-50 border-b-2 border-pepper-gold/30">
      <nav className="container mx-auto px-4 py-3">
        <div className="flex justify-between items-center">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2 text-2xl font-bold text-pepper-gold hover:text-pepper-harvest transition">
            <div className="bg-pepper-gold/20 backdrop-blur-sm rounded-lg p-1.5">
              <Leaf className="w-8 h-8 text-pepper-gold" />
            </div>
            <span className="hidden sm:inline text-white">SmartPepper</span>
            <span className="hidden lg:inline text-xs text-pepper-gold/80 font-normal ml-1">Ceylon Black Pepper</span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center gap-6">
            <Link
              href="/auctions"
              className="text-white/90 hover:text-pepper-gold font-medium transition-colors"
            >
              Auctions
            </Link>
            
            {isAuthenticated ? (
              <>
                {/* Role-specific links */}
                {user?.role === 'farmer' && (
                  <Link
                    href="/create"
                    className="text-white/90 hover:text-pepper-gold font-medium transition-colors"
                  >
                    Create Auction
                  </Link>
                )}
                
                <Link
                  href={`/dashboard/${user?.role}`}
                  className="text-white/90 hover:text-pepper-gold font-medium transition-colors"
                >
                  Dashboard
                </Link>

                {/* User Menu Dropdown */}
                <div className="relative">
                  <button
                    onClick={() => setUserMenuOpen(!userMenuOpen)}
                    className="flex items-center gap-2 text-white/90 hover:text-pepper-gold transition-colors"
                  >
                    <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-white/10 backdrop-blur-sm hover:bg-white/20">
                      <User className="w-4 h-4" />
                      <span className="font-medium max-w-[120px] truncate">{user?.name}</span>
                      <span className={`text-xs px-2 py-0.5 rounded-full ${getRoleColor()}`}>
                        {user?.role}
                      </span>
                      <ChevronDown className="w-4 h-4" />
                    </div>
                  </button>
                  
                  {userMenuOpen && (
                    <div className="absolute right-0 mt-2 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 py-2">
                      <div className="px-4 py-2 border-b border-gray-200 dark:border-gray-700">
                        <p className="text-sm font-medium text-gray-900 dark:text-gray-100">{user?.name}</p>
                        <p className="text-xs text-gray-500 dark:text-gray-400">{user?.email}</p>
                      </div>
                      <Link
                        href={`/dashboard/${user?.role}`}
                        className="block px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                        onClick={() => setUserMenuOpen(false)}
                      >
                        My Profile
                      </Link>
                      <button
                        onClick={handleLogout}
                        className="w-full text-left px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-gray-100 dark:hover:bg-gray-700 flex items-center gap-2"
                      >
                        <LogOut className="w-4 h-4" />
                        Logout
                      </button>
                    </div>
                  )}
                </div>
              </>
            ) : (
              <>
                {/* Not authenticated */}
                <Link
                  href="/login"
                  className="text-white/90 hover:text-pepper-gold font-medium transition-colors"
                >
                  Login
                </Link>
                <Link
                  href="/register"
                  className="btn bg-pepper-gold text-pepper-black hover:bg-pepper-harvest px-6 py-2 rounded-lg font-semibold transition-all transform hover:scale-105"
                >
                  Get Started
                </Link>
              </>
            )}
            
            {/* Theme Toggle */}
            <button
              onClick={toggleTheme}
              className="p-2 rounded-lg text-pepper-gold hover:bg-white/10 transition-colors backdrop-blur-sm"
              aria-label="Toggle theme"
            >
              {theme === 'light' ? (
                <Moon className="w-5 h-5" />
              ) : (
                <Sun className="w-5 h-5" />
              )}
            </button>
            
            <div className="border-l border-gray-300 dark:border-gray-600 pl-4">
              <ConnectButton />
            </div>
          </div>

          {/* Mobile Menu Button */}
          <button
            className="md:hidden text-pepper-gold hover:text-pepper-harvest p-2"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          >
            {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {/* Mobile Navigation */}
        {mobileMenuOpen && (
          <div className="md:hidden mt-4 pb-4 border-t border-pepper-gold/30 pt-4 bg-white/5 backdrop-blur-sm rounded-lg">
            <div className="flex flex-col gap-3">
              {isAuthenticated && (
                <div className="pb-3 mb-3 border-b border-pepper-gold/30">
                  <div className="flex items-center gap-2 mb-2">
                    <User className="w-4 h-4 text-pepper-gold" />
                    <span className="text-sm font-medium text-white">
                      {user?.name}
                    </span>
                  </div>
                  <p className="text-xs text-pepper-gold/70 mb-2">{user?.email}</p>
                  <span className={`inline-block text-xs px-2 py-1 rounded-full ${getRoleColor()}`}>
                    {user?.role}
                  </span>
                </div>
              )}
              
              <Link
                href="/auctions"
                className="text-white/90 hover:text-pepper-gold font-medium py-2"
                onClick={() => setMobileMenuOpen(false)}
              >
                Auctions
              </Link>
              
              {isAuthenticated ? (
                <>
                  {user?.role === 'farmer' && (
                    <Link
                      href="/create"
                      className="text-gray-700 dark:text-gray-300 hover:text-primary-600 dark:hover:text-primary-400 font-medium py-2"
                      onClick={() => setMobileMenuOpen(false)}
                    >
                      Create Auction
                    </Link>
                  )}
                  
                  <Link
                    href={`/dashboard/${user?.role}`}
                    className="text-gray-700 dark:text-gray-300 hover:text-primary-600 dark:hover:text-primary-400 font-medium py-2"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    Dashboard
                  </Link>

                  <button
                    onClick={handleLogout}
                    className="flex items-center gap-2 text-red-600 dark:text-red-400 hover:text-red-700 font-medium text-left py-2"
                  >
                    <LogOut className="w-4 h-4" />
                    Logout
                  </button>
                </>
              ) : (
                <>
                  <Link
                    href="/login"
                    className="text-gray-700 dark:text-gray-300 hover:text-primary-600 dark:hover:text-primary-400 font-medium py-2"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    Login
                  </Link>
                  <Link
                    href="/register"
                    className="btn-primary px-4 py-2 rounded-lg text-center font-medium"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    Get Started
                  </Link>
                </>
              )}
              
              {/* Theme Toggle */}
              <button
                onClick={toggleTheme}
                className="flex items-center gap-2 text-gray-700 dark:text-gray-300 hover:text-primary-600 dark:hover:text-primary-400 font-medium py-2"
              >
                {theme === 'light' ? (
                  <>
                    <Moon className="w-4 h-4" />
                    Dark Mode
                  </>
                ) : (
                  <>
                    <Sun className="w-4 h-4" />
                    Light Mode
                  </>
                )}
              </button>
              
              <div className="pt-3 mt-3 border-t border-gray-200 dark:border-gray-700">
                <ConnectButton />
              </div>
            </div>
          </div>
        )}
      </nav>
    </header>
  );
}
