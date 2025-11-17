import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

const api = axios.create({
  baseURL: `${API_URL}/api`,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Auctions
export const auctionApi = {
  getAll: (params?: { status?: string; farmer?: string; limit?: number; offset?: number }) =>
    api.get('/auctions', { params }),
  
  getById: (id: number) =>
    api.get(`/auctions/${id}`),
  
  create: (data: {
    lotId: string;
    farmerAddress: string;
    startPrice: string;
    reservePrice: string;
    duration: number;
  }) =>
    api.post('/auctions', data),
  
  placeBid: (id: number, data: {
    bidderAddress: string;
    amount: string;
    txHash: string;
  }) =>
    api.post(`/auctions/${id}/bid`, data),
  
  end: (id: number) =>
    api.post(`/auctions/${id}/end`),
  
  settle: (id: number) =>
    api.post(`/auctions/${id}/settle`),
};

// Lots
export const lotApi = {
  getAll: (params?: { status?: string; farmer?: string; limit?: number; offset?: number }) =>
    api.get('/lots', { params }),
  
  getById: (lotId: string) =>
    api.get(`/lots/${lotId}`),
  
  create: (data: {
    lotId: string;
    farmerAddress: string;
    variety: string;
    quantity: string;
    quality: string;
    harvestDate: string;
    certificateHash: string;
    certificateIpfsUrl: string;
    txHash: string;
  }) =>
    api.post('/lots', data),
};

// Users
export const userApi = {
  getByAddress: (address: string) =>
    api.get(`/users/${address}`),
  
  create: (data: {
    walletAddress: string;
    userType: string;
    name?: string;
    email?: string;
    phone?: string;
    location?: any;
  }) =>
    api.post('/users', data),
};

// Compliance
export const complianceApi = {
  check: (lotId: string) =>
    api.post('/compliance/check', { lotId }),
  
  getHistory: (lotId: string) =>
    api.get(`/compliance/${lotId}`),
  
  uploadCertificate: (file: string) =>
    api.post('/compliance/upload', { file }),
};

export default api;
