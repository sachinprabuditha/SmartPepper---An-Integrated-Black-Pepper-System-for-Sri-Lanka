'use client';

import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { auctionApi, escrowApi } from '@/lib/api';
import { ethers } from 'ethers';

interface EscrowPageProps {
  params: {
    auctionId: string;
  };
}

export default function EscrowDepositPage({ params }: EscrowPageProps) {
  const { user, loading: authLoading } = useAuth();
  const router = useRouter();
  const [auction, setAuction] = useState<any>(null);
  const [escrowStatus, setEscrowStatus] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isDepositing, setIsDepositing] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [txHash, setTxHash] = useState('');
  const [walletConnected, setWalletConnected] = useState(false);
  const [walletAddress, setWalletAddress] = useState('');

  const auctionId = parseInt(params.auctionId);

  useEffect(() => {
    if (!authLoading && (!user || user.role !== 'exporter')) {
      router.push('/login');
    }
  }, [user, authLoading, router]);

  useEffect(() => {
    if (user) {
      loadData();
      checkWalletConnection();
    }
  }, [user, auctionId]);

  const loadData = async () => {
    try {
      setIsLoading(true);
      
      // Load auction details
      const auctionResponse = await auctionApi.getById(auctionId);
      setAuction(auctionResponse.data.auction);

      // Load escrow status
      const escrowResponse = await escrowApi.getStatus(auctionId);
      setEscrowStatus(escrowResponse.data.escrowStatus);
    } catch (error: any) {
      console.error('Failed to load data:', error);
      setError('Failed to load auction details');
    } finally {
      setIsLoading(false);
    }
  };

  const checkWalletConnection = async () => {
    if (typeof window.ethereum !== 'undefined') {
      try {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const accounts = await provider.listAccounts();
        if (accounts.length > 0) {
          setWalletConnected(true);
          setWalletAddress(accounts[0].address);
        }
      } catch (error) {
        console.error('Error checking wallet:', error);
      }
    }
  };

  const connectWallet = async () => {
    if (typeof window.ethereum === 'undefined') {
      setError('MetaMask is not installed. Please install MetaMask to continue.');
      return;
    }

    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      await provider.send('eth_requestAccounts', []);
      const signer = await provider.getSigner();
      const address = await signer.getAddress();
      
      setWalletConnected(true);
      setWalletAddress(address);
      setError('');
    } catch (error: any) {
      console.error('Failed to connect wallet:', error);
      setError('Failed to connect wallet: ' + error.message);
    }
  };

  const depositEscrow = async () => {
    if (!walletConnected) {
      setError('Please connect your wallet first');
      return;
    }

    if (!escrowStatus || !auction) {
      setError('Auction data not loaded');
      return;
    }

    setIsDepositing(true);
    setError('');
    setSuccess('');

    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();

      // Load contract ABI (you'll need to import this from your artifacts)
      const contractAddress = process.env.NEXT_PUBLIC_AUCTION_CONTRACT_ADDRESS;
      
      if (!contractAddress) {
        throw new Error('Contract address not configured');
      }

      // Simplified ABI - just the depositEscrow function
      const abi = [
        'function depositEscrow(uint256 auctionId) payable'
      ];

      const contract = new ethers.Contract(contractAddress, abi, signer);

      // Convert amount to Wei
      const amountInWei = ethers.parseEther(escrowStatus.requiredAmount.toString());

      // Call depositEscrow on smart contract
      const tx = await contract.depositEscrow(auctionId, {
        value: amountInWei
      });

      setSuccess('Transaction submitted! Waiting for confirmation...');
      setTxHash(tx.hash);

      // Wait for transaction confirmation
      const receipt = await tx.wait();

      if (receipt.status === 1) {
        // Record deposit in backend
        await escrowApi.deposit({
          auctionId,
          exporterAddress: walletAddress,
          amount: escrowStatus.requiredAmount,
          txHash: tx.hash,
          userId: user!.id
        });

        setSuccess('Escrow deposited successfully! Transaction confirmed.');
        
        // Reload data
        await loadData();
      } else {
        throw new Error('Transaction failed');
      }
    } catch (error: any) {
      console.error('Failed to deposit escrow:', error);
      setError('Failed to deposit escrow: ' + (error.message || 'Unknown error'));
    } finally {
      setIsDepositing(false);
    }
  };

  if (authLoading || isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600 dark:text-gray-400">Loading escrow details...</p>
        </div>
      </div>
    );
  }

  if (!user || !auction || !escrowStatus) {
    return null;
  }

  const isWinner = walletAddress.toLowerCase() === escrowStatus.winner?.toLowerCase();
  const isExpired = escrowStatus.isExpired;
  const alreadyDeposited = escrowStatus.escrowDeposited;

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <Link 
            href="/dashboard/exporter/won" 
            className="text-blue-600 hover:text-blue-700 text-sm mb-4 inline-block"
          >
            ← Back to Won Auctions
          </Link>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">💰 Deposit Escrow</h1>
          <p className="text-gray-600 dark:text-gray-400 mt-2">
            Secure your won auction by depositing escrow funds
          </p>
        </div>

        {/* Alerts */}
        {error && (
          <div className="mb-6 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
            <div className="flex items-center gap-2">
              <span className="text-red-600 dark:text-red-400 text-xl">⚠️</span>
              <p className="text-red-800 dark:text-red-300">{error}</p>
            </div>
          </div>
        )}

        {success && (
          <div className="mb-6 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4">
            <div className="flex items-center gap-2">
              <span className="text-green-600 dark:text-green-400 text-xl">✅</span>
              <div>
                <p className="text-green-800 dark:text-green-300">{success}</p>
                {txHash && (
                  <p className="text-sm text-green-600 dark:text-green-400 mt-1">
                    Transaction: <span className="font-mono">{txHash.substring(0, 10)}...{txHash.substring(txHash.length - 8)}</span>
                  </p>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Deadline Warning */}
        {!alreadyDeposited && !isExpired && (
          <div className="mb-6 bg-orange-50 dark:bg-orange-900/20 border border-orange-200 dark:border-orange-800 rounded-lg p-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="text-orange-600 dark:text-orange-400 text-xl">⏰</span>
                <div>
                  <p className="font-semibold text-orange-900 dark:text-orange-200">Time Remaining</p>
                  <p className="text-sm text-orange-700 dark:text-orange-300">
                    You have {escrowStatus.hoursRemaining} hours to deposit escrow
                  </p>
                </div>
              </div>
              <div className="text-right">
                <p className="text-2xl font-bold text-orange-600">{escrowStatus.hoursRemaining}h</p>
              </div>
            </div>
          </div>
        )}

        {/* Auction Details Card */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow border border-gray-200 dark:border-gray-700 p-6 mb-6">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">Auction Details</h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">Auction ID</p>
              <p className="font-semibold text-gray-900 dark:text-white">#{auctionId}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">Lot ID</p>
              <p className="font-semibold text-gray-900 dark:text-white">{auction.lot_id}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">Variety</p>
              <p className="font-semibold text-gray-900 dark:text-white">{auction.variety || 'N/A'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400">Status</p>
              <span className="px-2 py-1 text-xs font-semibold rounded-full bg-yellow-100 dark:bg-yellow-900 text-yellow-800 dark:text-yellow-200">
                {auction.status}
              </span>
            </div>
          </div>
        </div>

        {/* Escrow Amount Card */}
        <div className="bg-gradient-to-r from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 rounded-lg border border-blue-200 dark:border-blue-800 p-6 mb-6">
          <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-4">Required Escrow Amount</h2>
          <div className="text-center">
            <p className="text-5xl font-bold text-blue-600 mb-2">
              {parseFloat(escrowStatus.requiredAmount || '0').toFixed(4)} ETH
            </p>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              ≈ LKR {(parseFloat(escrowStatus.requiredAmount || '0') * 322580.65).toLocaleString()}
            </p>
          </div>
        </div>

        {/* Wallet Connection */}
        {!walletConnected ? (
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow border border-gray-200 dark:border-gray-700 p-6 mb-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Connect Your Wallet</h3>
            <p className="text-gray-600 dark:text-gray-400 mb-4">
              You need to connect your MetaMask wallet to deposit escrow funds.
            </p>
            <button
              onClick={connectWallet}
              className="w-full px-6 py-3 bg-orange-500 text-white font-semibold rounded-lg hover:bg-orange-600 transition"
            >
              🦊 Connect MetaMask
            </button>
          </div>
        ) : (
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow border border-gray-200 dark:border-gray-700 p-6 mb-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">Wallet Connected</h3>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Connected Address</p>
                <p className="font-mono text-gray-900 dark:text-white">{walletAddress}</p>
              </div>
              <span className="text-2xl">✅</span>
            </div>
            {!isWinner && (
              <div className="mt-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3">
                <p className="text-sm text-red-800 dark:text-red-300">
                  ⚠️ This wallet address is not the auction winner
                </p>
              </div>
            )}
          </div>
        )}

        {/* Deposit Button */}
        {alreadyDeposited ? (
          <div className="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-6 text-center">
            <span className="text-4xl mb-4 inline-block">✅</span>
            <h3 className="text-xl font-bold text-green-900 dark:text-green-200 mb-2">
              Escrow Already Deposited
            </h3>
            <p className="text-green-700 dark:text-green-300 mb-4">
              Your escrow funds have been successfully deposited and locked in the smart contract.
            </p>
            {escrowStatus.escrowTxHash && (
              <p className="text-sm text-green-600 dark:text-green-400 font-mono">
                TX: {escrowStatus.escrowTxHash}
              </p>
            )}
          </div>
        ) : isExpired ? (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-6 text-center">
            <span className="text-4xl mb-4 inline-block">⏰</span>
            <h3 className="text-xl font-bold text-red-900 dark:text-red-200 mb-2">
              Deposit Window Expired
            </h3>
            <p className="text-red-700 dark:text-red-300">
              The 24-hour deposit window has expired. This auction may be reassigned to the next highest bidder.
            </p>
          </div>
        ) : (
          <button
            onClick={depositEscrow}
            disabled={!walletConnected || !isWinner || isDepositing}
            className="w-full px-6 py-4 bg-blue-600 text-white text-lg font-semibold rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition"
          >
            {isDepositing ? (
              <>
                <span className="inline-block animate-spin mr-2">⏳</span>
                Depositing Escrow...
              </>
            ) : (
              <>💰 Deposit {parseFloat(escrowStatus.requiredAmount || '0').toFixed(4)} ETH</>
            )}
          </button>
        )}

        {/* How It Works */}
        <div className="mt-8 bg-gray-100 dark:bg-gray-800 rounded-lg p-6">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">📋 How Escrow Works</h3>
          <ol className="space-y-2 text-gray-700 dark:text-gray-300">
            <li>1. Connect your MetaMask wallet</li>
            <li>2. Deposit the required escrow amount (your winning bid)</li>
            <li>3. Funds are locked in the smart contract (not sent to anyone yet)</li>
            <li>4. Once compliance is approved and shipment is confirmed, funds will be released to the farmer</li>
            <li>5. If there are issues, escrow can be refunded to you</li>
          </ol>
        </div>
      </div>
    </div>
  );
}
