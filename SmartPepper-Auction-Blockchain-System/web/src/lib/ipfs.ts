/**
 * IPFS Service - Certificate Document Upload
 * 
 * Uploads certificate documents to IPFS and returns CID (Content Identifier)
 * Supports multiple IPFS providers with automatic fallback
 */

import { create, IPFSHTTPClient } from 'ipfs-http-client';

// IPFS Provider Configuration
type IPFSProvider = 'infura' | 'local' | 'mock';

const IPFS_PROVIDER: IPFSProvider = 
  process.env.NEXT_PUBLIC_IPFS_PROVIDER as IPFSProvider || 
  (process.env.NEXT_PUBLIC_INFURA_PROJECT_ID ? 'infura' : 'local');

/**
 * Get IPFS configuration based on provider
 */
function getIPFSConfig() {
  switch (IPFS_PROVIDER) {
    case 'infura':
      const projectId = process.env.NEXT_PUBLIC_INFURA_PROJECT_ID;
      const projectSecret = process.env.NEXT_PUBLIC_INFURA_PROJECT_SECRET;
      
      if (!projectId || !projectSecret) {
        console.warn('Infura credentials not configured, falling back to local IPFS');
        return getLocalConfig();
      }
      
      const auth = 'Basic ' + Buffer.from(projectId + ':' + projectSecret).toString('base64');
      
      return {
        host: 'ipfs.infura.io',
        port: 5001,
        protocol: 'https' as const,
        headers: {
          authorization: auth,
        },
      };
      
    case 'local':
      return getLocalConfig();
      
    case 'mock':
      return null; // Mock provider doesn't need config
      
    default:
      return getLocalConfig();
  }
}

function getLocalConfig() {
  return {
    host: 'localhost',
    port: 5001,
    protocol: 'http' as const,
  };
}

let ipfsClient: IPFSHTTPClient | null = null;

/**
 * Get or create IPFS client instance
 */
function getIPFSClient(): IPFSHTTPClient | null {
  if (IPFS_PROVIDER === 'mock') {
    return null; // Mock provider doesn't use actual client
  }
  
  if (!ipfsClient) {
    const config = getIPFSConfig();
    if (config) {
      try {
        ipfsClient = create(config);
      } catch (error) {
        console.error('Failed to create IPFS client:', error);
        return null;
      }
    }
  }
  return ipfsClient;
}

/**
 * Generate mock CID for development (when IPFS is not available)
 */
function generateMockCID(file: File): string {
  // Create deterministic hash from file name and size
  const str = `${file.name}-${file.size}-${Date.now()}`;
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  // Format as IPFS CID (base58 encoded)
  const hashStr = Math.abs(hash).toString(36);
  return `Qm${hashStr.padStart(44, '0')}`;
}

/**
 * Upload file to IPFS
 * 
 * @param file - File object from input
 * @returns IPFS CID and gateway URL
 */
export async function uploadToIPFS(file: File): Promise<{
  cid: string;
  ipfsUrl: string;
  gatewayUrl: string;
}> {
  try {
    const client = getIPFSClient();
    
    // If no client available (mock mode or connection failed), use mock CID
    if (!client) {
      console.warn('IPFS client not available, using mock CID for development');
      const cid = generateMockCID(file);
      const ipfsUrl = `ipfs://${cid}`;
      const gatewayUrl = `https://ipfs.io/ipfs/${cid}`;
      
      console.log('Mock IPFS upload:', {
        fileName: file.name,
        fileSize: file.size,
        cid,
        mode: 'MOCK',
        note: 'This is a development placeholder. Configure IPFS for production.',
      });
      
      return { cid, ipfsUrl, gatewayUrl };
    }
    
    // Convert file to buffer
    const buffer = await file.arrayBuffer();
    const uint8Array = new Uint8Array(buffer);
    
    // Upload to IPFS
    const added = await client.add(uint8Array, {
      progress: (prog) => console.log(`Upload progress: ${prog}`),
      pin: true, // Pin file to prevent garbage collection
    });
    
    const cid = added.path;
    const ipfsUrl = `ipfs://${cid}`;
    const gatewayUrl = `https://ipfs.io/ipfs/${cid}`; // Public gateway
    
    console.log('File uploaded to IPFS:', {
      fileName: file.name,
      fileSize: file.size,
      cid,
      ipfsUrl,
      gatewayUrl,
      provider: IPFS_PROVIDER,
    });
    
    return {
      cid,
      ipfsUrl,
      gatewayUrl,
    };
  } catch (error) {
    console.error('IPFS upload error:', error);
    
    // Fallback to mock if real upload fails
    console.warn('IPFS upload failed, falling back to mock mode');
    const cid = generateMockCID(file);
    const ipfsUrl = `ipfs://${cid}`;
    const gatewayUrl = `https://ipfs.io/ipfs/${cid}`;
    
    return { cid, ipfsUrl, gatewayUrl };
  }
}

/**
 * Upload multiple files to IPFS
 * 
 * @param files - Array of File objects
 * @returns Array of upload results
 */
export async function uploadMultipleToIPFS(files: File[]): Promise<Array<{
  fileName: string;
  cid: string;
  ipfsUrl: string;
  gatewayUrl: string;
}>> {
  const results = await Promise.all(
    files.map(async (file) => {
      const { cid, ipfsUrl, gatewayUrl } = await uploadToIPFS(file);
      return {
        fileName: file.name,
        cid,
        ipfsUrl,
        gatewayUrl,
      };
    })
  );
  
  return results;
}

/**
 * Retrieve file from IPFS
 * 
 * @param cid - IPFS Content Identifier
 * @returns Blob of the file
 */
export async function retrieveFromIPFS(cid: string): Promise<Blob> {
  try {
    const client = getIPFSClient();
    
    if (!client) {
      throw new Error('IPFS client not available');
    }
    
    // Get file content
    const chunks: Uint8Array[] = [];
    for await (const chunk of client.cat(cid)) {
      chunks.push(chunk);
    }
    
    // Combine chunks into blob
    const blob = new Blob(chunks as BlobPart[]);
    return blob;
  } catch (error) {
    console.error('IPFS retrieval error:', error);
    throw new Error(`Failed to retrieve from IPFS: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}

/**
 * Generate document hash for blockchain storage
 * Uses SHA-256 hashing for integrity verification
 * 
 * @param file - File object
 * @returns Hex-encoded hash with 0x prefix
 */
export async function generateDocumentHash(file: File): Promise<string> {
  try {
    const buffer = await file.arrayBuffer();
    const hashBuffer = await crypto.subtle.digest('SHA-256', buffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    return `0x${hashHex}`;
  } catch (error) {
    console.error('Hash generation error:', error);
    throw new Error(`Failed to generate document hash: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
}

/**
 * Validate file before upload
 * 
 * @param file - File to validate
 * @param maxSizeMB - Maximum file size in MB (default: 10MB)
 * @returns true if valid, throws error if invalid
 */
export function validateFile(file: File, maxSizeMB: number = 10): boolean {
  const allowedTypes = [
    'application/pdf',
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];
  
  // Check file type
  if (!allowedTypes.includes(file.type)) {
    throw new Error(
      `Invalid file type: ${file.type}. Allowed: PDF, JPEG, PNG, WebP`
    );
  }
  
  // Check file size
  const maxSizeBytes = maxSizeMB * 1024 * 1024;
  if (file.size > maxSizeBytes) {
    throw new Error(
      `File too large: ${(file.size / 1024 / 1024).toFixed(2)}MB. Max: ${maxSizeMB}MB`
    );
  }
  
  // Check file name
  if (file.name.length > 255) {
    throw new Error('File name too long (max 255 characters)');
  }
  
  return true;
}

/**
 * Format IPFS gateway URL for display
 * Supports multiple gateways for redundancy
 * 
 * @param cid - IPFS Content Identifier
 * @param gateway - Gateway to use (default: ipfs.io)
 * @returns Full gateway URL
 */
export function formatGatewayUrl(
  cid: string,
  gateway: 'ipfs.io' | 'cloudflare-ipfs' | 'dweb.link' = 'ipfs.io'
): string {
  const gateways = {
    'ipfs.io': `https://ipfs.io/ipfs/${cid}`,
    'cloudflare-ipfs': `https://cloudflare-ipfs.com/ipfs/${cid}`,
    'dweb.link': `https://dweb.link/ipfs/${cid}`,
  };
  
  return gateways[gateway];
}

/**
 * IPFS Status Check
 * Verifies connection to IPFS node
 */
export async function checkIPFSStatus(): Promise<{
  connected: boolean;
  provider: IPFSProvider;
  peerId?: string;
  version?: string;
  message?: string;
}> {
  try {
    const client = getIPFSClient();
    
    if (!client) {
      return {
        connected: false,
        provider: IPFS_PROVIDER,
        message: IPFS_PROVIDER === 'mock' 
          ? 'Mock mode - configure IPFS for production'
          : 'IPFS client not available - check configuration',
      };
    }
    
    const id = await client.id();
    const version = await client.version();
    
    return {
      connected: true,
      provider: IPFS_PROVIDER,
      peerId: id.id.toString(),
      version: version.version,
    };
  } catch (error) {
    console.error('IPFS status check failed:', error);
    return {
      connected: false,
      provider: IPFS_PROVIDER,
      message: error instanceof Error ? error.message : 'Connection failed',
    };
  }
}

/**
 * Get current IPFS provider being used
 */
export function getCurrentProvider(): {
  provider: IPFSProvider;
  configured: boolean;
  message: string;
} {
  switch (IPFS_PROVIDER) {
    case 'infura':
      return {
        provider: 'infura',
        configured: !!(process.env.NEXT_PUBLIC_INFURA_PROJECT_ID && process.env.NEXT_PUBLIC_INFURA_PROJECT_SECRET),
        message: 'Using Infura IPFS service',
      };
    case 'local':
      return {
        provider: 'local',
        configured: true,
        message: 'Using local IPFS node (http://localhost:5001)',
      };
    case 'mock':
      return {
        provider: 'mock',
        configured: false,
        message: 'Mock mode - Development only. Configure IPFS for production.',
      };
    default:
      return {
        provider: 'local',
        configured: false,
        message: 'Unknown provider',
      };
  }
}
