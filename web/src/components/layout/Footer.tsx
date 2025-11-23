'use client';

import Link from 'next/link';
import { useAuth } from '@/contexts/AuthContext';
import { Leaf, Mail, Phone, MapPin, Facebook, Twitter, Linkedin, Instagram } from 'lucide-react';

export function Footer() {
  const { user, isAuthenticated } = useAuth();

  return (
    <footer className="bg-gray-900 text-white mt-auto">
      <div className="container mx-auto px-4 py-12">
        <div className="grid md:grid-cols-4 gap-8">
          {/* Brand Section */}
          <div>
            <div className="flex items-center gap-2 mb-4">
              <Leaf className="w-8 h-8 text-primary-400" />
              <span className="text-xl font-bold">SmartPepper</span>
            </div>
            <p className="text-gray-400 text-sm mb-4">
              Blockchain-powered pepper auction platform connecting farmers and exporters worldwide.
            </p>
            <div className="flex gap-3">
              <a href="#" className="text-gray-400 hover:text-primary-400 transition">
                <Facebook className="w-5 h-5" />
              </a>
              <a href="#" className="text-gray-400 hover:text-primary-400 transition">
                <Twitter className="w-5 h-5" />
              </a>
              <a href="#" className="text-gray-400 hover:text-primary-400 transition">
                <Linkedin className="w-5 h-5" />
              </a>
              <a href="#" className="text-gray-400 hover:text-primary-400 transition">
                <Instagram className="w-5 h-5" />
              </a>
            </div>
          </div>

          {/* Quick Links - Role-based */}
          <div>
            <h3 className="font-semibold mb-4">Quick Links</h3>
            <ul className="space-y-2 text-sm">
              <li>
                <Link href="/auctions" className="text-gray-400 hover:text-primary-400 transition">
                  Browse Auctions
                </Link>
              </li>
              {isAuthenticated ? (
                <>
                  {user?.role === 'farmer' && (
                    <>
                      <li>
                        <Link href="/dashboard/farmer" className="text-gray-400 hover:text-primary-400 transition">
                          My Dashboard
                        </Link>
                      </li>
                      <li>
                        <Link href="/create" className="text-gray-400 hover:text-primary-400 transition">
                          Create Auction
                        </Link>
                      </li>
                    </>
                  )}
                  {user?.role === 'exporter' && (
                    <li>
                      <Link href="/dashboard/exporter" className="text-gray-400 hover:text-primary-400 transition">
                        My Dashboard
                      </Link>
                    </li>
                  )}
                  {user?.role === 'admin' && (
                    <li>
                      <Link href="/dashboard/admin" className="text-gray-400 hover:text-primary-400 transition">
                        Admin Dashboard
                      </Link>
                    </li>
                  )}
                </>
              ) : (
                <>
                  <li>
                    <Link href="/register" className="text-gray-400 hover:text-primary-400 transition">
                      Register
                    </Link>
                  </li>
                  <li>
                    <Link href="/login" className="text-gray-400 hover:text-primary-400 transition">
                      Login
                    </Link>
                  </li>
                </>
              )}
              <li>
                <Link href="/about" className="text-gray-400 hover:text-primary-400 transition">
                  About Us
                </Link>
              </li>
            </ul>
          </div>

          {/* Resources */}
          <div>
            <h3 className="font-semibold mb-4">Resources</h3>
            <ul className="space-y-2 text-sm">
              <li>
                <Link href="#" className="text-gray-400 hover:text-primary-400 transition">
                  How It Works
                </Link>
              </li>
              <li>
                <Link href="#" className="text-gray-400 hover:text-primary-400 transition">
                  Quality Standards
                </Link>
              </li>
              <li>
                <Link href="#" className="text-gray-400 hover:text-primary-400 transition">
                  Blockchain Guide
                </Link>
              </li>
              <li>
                <Link href="#" className="text-gray-400 hover:text-primary-400 transition">
                  FAQ
                </Link>
              </li>
              <li>
                <Link href="#" className="text-gray-400 hover:text-primary-400 transition">
                  Support
                </Link>
              </li>
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h3 className="font-semibold mb-4">Contact Us</h3>
            <ul className="space-y-3 text-sm text-gray-400">
              <li className="flex items-start gap-2">
                <MapPin className="w-4 h-4 mt-1 flex-shrink-0" />
                <span>Sri Lanka Institution of Information Technology<br />Malabe, Sri Lanka</span>
              </li>
              <li className="flex items-center gap-2">
                <Mail className="w-4 h-4 flex-shrink-0" />
                <a href="mailto:info@smartpepper.lk" className="hover:text-primary-400 transition">
                  info@smartpepper.lk
                </a>
              </li>
              <li className="flex items-center gap-2">
                <Phone className="w-4 h-4 flex-shrink-0" />
                <a href="tel:+94112650301" className="hover:text-primary-400 transition">
                  +94 11 265 0301
                </a>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="border-t border-gray-800 mt-8 pt-6">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4 text-sm text-gray-400">
            <p>
              &copy; 2025 SmartPepper. All rights reserved. | Research Project IT4010
            </p>
            <div className="flex gap-6">
              <Link href="#" className="hover:text-primary-400 transition">
                Privacy Policy
              </Link>
              <Link href="#" className="hover:text-primary-400 transition">
                Terms of Service
              </Link>
              <Link href="#" className="hover:text-primary-400 transition">
                Cookie Policy
              </Link>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}
