'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WagmiProvider, createConfig, http } from 'wagmi';
import { sepolia, localhost } from 'wagmi/chains';
import { RainbowKitProvider, getDefaultConfig } from '@rainbow-me/rainbowkit';
import '@rainbow-me/rainbowkit/styles.css';
import { useEffect } from 'react';
import { useAuctionStore } from '@/store/auctionStore';

const queryClient = new QueryClient();

const config = getDefaultConfig({
  appName: 'SmartPepper',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'YOUR_PROJECT_ID',
  chains: [sepolia, localhost],
  transports: {
    [sepolia.id]: http(),
    [localhost.id]: http('http://127.0.0.1:8545'),
  },
});

export function Providers({ children }: { children: React.ReactNode }) {
  const { connectWebSocket, disconnectWebSocket } = useAuctionStore();

  useEffect(() => {
    const wsUrl = process.env.NEXT_PUBLIC_WS_URL || 'http://localhost:3000';
    connectWebSocket(wsUrl);

    return () => {
      disconnectWebSocket();
    };
  }, [connectWebSocket, disconnectWebSocket]);

  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
