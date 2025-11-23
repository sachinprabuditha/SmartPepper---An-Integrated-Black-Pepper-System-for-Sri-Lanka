import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3002';

const authApi = axios.create({
  baseURL: `${API_URL}/api/auth`,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add token to requests if available
authApi.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle token expiration
authApi.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        const refreshToken = localStorage.getItem('refreshToken');
        if (refreshToken) {
          const response = await authApi.post('/refresh', { refreshToken });
          const { token } = response.data;
          localStorage.setItem('token', token);
          originalRequest.headers.Authorization = `Bearer ${token}`;
          return authApi(originalRequest);
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

export const auth = {
  // Register new user
  register: (data: {
    email: string;
    password: string;
    name: string;
    role: 'farmer' | 'exporter' | 'admin';
    walletAddress?: string;
    phone?: string;
    address?: string;
    city?: string;
    language?: string;
  }) => authApi.post('/register', data),

  // Login user
  login: (email: string, password: string) =>
    authApi.post('/login', { email, password }),

  // Logout user
  logout: () => authApi.post('/logout'),

  // Get current user
  getCurrentUser: () => authApi.get('/me'),

  // Update profile
  updateProfile: (data: {
    name?: string;
    phone?: string;
    address?: string;
    city?: string;
    language?: string;
    walletAddress?: string;
  }) => authApi.put('/profile', data),

  // Refresh token
  refreshToken: (refreshToken: string) =>
    authApi.post('/refresh', { refreshToken }),
};

export default authApi;
