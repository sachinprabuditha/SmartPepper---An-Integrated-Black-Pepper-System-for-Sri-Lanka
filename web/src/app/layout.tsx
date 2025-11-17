import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import '../styles/globals.css';
import { Providers } from './providers';
import { Header } from '@/components/layout/Header';
import { Toaster } from 'react-hot-toast';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'SmartPepper - Blockchain Pepper Auction Platform',
  description: 'Real-time blockchain-based pepper auction with supply chain traceability',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <Providers>
          <div className="min-h-screen flex flex-col">
            <Header />
            <main className="flex-1">
              {children}
            </main>
            <footer className="bg-gray-900 text-white py-6 mt-auto">
              <div className="container mx-auto px-4 text-center">
                <p>&copy; 2025 SmartPepper. Blockchain-powered pepper auctions.</p>
              </div>
            </footer>
          </div>
          <Toaster position="top-right" />
        </Providers>
      </body>
    </html>
  );
}
