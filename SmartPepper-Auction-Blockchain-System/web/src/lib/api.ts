import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3002';

const api = axios.create({
  baseURL: `${API_URL}/api`,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add token to requests if available
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle token expiration
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        const refreshToken = localStorage.getItem('refreshToken');
        if (refreshToken) {
          const response = await axios.post(`${API_URL}/api/auth/refresh`, { refreshToken });
          const { token } = response.data;
          localStorage.setItem('token', token);
          originalRequest.headers.Authorization = `Bearer ${token}`;
          return api(originalRequest);
        }
      } catch (refreshError) {
        // Refresh failed, logout user
        localStorage.removeItem('token');
        localStorage.removeItem('refreshToken');
        localStorage.removeItem('user');
        window.location.href = '/login';
      }
    }

    return Promise.reject(error);
  }
);

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
    bidderName?: string;
    amount: string;
  }) =>
    api.post(`/auctions/${id}/bid`, data),
  
  getBids: (id: number) =>
    api.get(`/auctions/${id}/bids`),
  
  getUserBids: (userId: string) =>
    api.get(`/auctions/bids/user/${userId}`),
  
  lockEscrow: (id: number, data: {
    winnerAddress: string;
    amount: string;
    txHash: string;
  }) =>
    api.post(`/auctions/${id}/escrow/lock`, data),
  
  settle: (id: number, data: {
    settlerAddress: string;
    txHash: string;
  }) =>
    api.post(`/auctions/${id}/settle`, data),
  
  cancel: (id: number, data: {
    cancellerAddress: string;
    reason: string;
    detailedReason?: string;
    refundTxHash?: string;
  }) =>
    api.post(`/auctions/${id}/cancel`, data),
  
  end: (id: number) =>
    api.post(`/auctions/${id}/end`),
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

// Escrow
export const escrowApi = {
  deposit: (data: {
    auctionId: number;
    exporterAddress: string;
    amount: string;
    txHash: string;
    userId: string;
  }) =>
    api.post('/escrow/deposit', data),
  
  getStatus: (auctionId: number) =>
    api.get(`/escrow/status/${auctionId}`),
  
  verify: (data: {
    auctionId: number;
    txHash: string;
  }) =>
    api.post('/escrow/verify', data),
  
  getUserDeposits: (userId: string) =>
    api.get(`/escrow/user/${userId}`),
};

// Admin
export const adminApi = {
  getRecentActivity: (limit?: number) =>
    api.get('/admin/recent-activity', { params: { limit } }),
  
  getStats: () =>
    api.get('/admin/stats'),
  
  getPendingLots: () =>
    api.get('/admin/lots/pending'),
  
  getLotById: (lotId: string) =>
    api.get(`/admin/lots/${lotId}`),
  
  approveLot: (lotId: string, data: { adminId?: string; adminName?: string }) =>
    api.post(`/admin/lots/${lotId}/approve`, data),
  
  rejectLot: (lotId: string, data: { reason: string; adminId?: string; adminName?: string }) =>
    api.post(`/admin/lots/${lotId}/reject`, data),
  
  // User management
  getPendingUsers: () =>
    api.get('/admin/users/pending'),
  
  getUsers: (params?: { role?: string; approval_status?: string; limit?: number; offset?: number }) =>
    api.get('/admin/users', { params }),
  
  approveUser: (userId: string, data: { adminId?: string; adminName?: string }) =>
    api.post(`/admin/users/${userId}/approve`, data),
  
  rejectUser: (userId: string, data: { reason: string; adminId?: string; adminName?: string }) =>
    api.post(`/admin/users/${userId}/reject`, data),
  
  // System health
  getSystemHealth: () =>
    api.get('/admin/health'),
};

// Health Check
export const healthApi = {
  checkBackend: () =>
    api.get('/health'),
  
  checkDatabase: () =>
    api.get('/health/database'),
};

export default api;
