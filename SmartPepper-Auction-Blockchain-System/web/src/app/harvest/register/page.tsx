'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import HarvestWizard from './components/HarvestWizard';

export default function HarvestRegistrationPage() {
  const router = useRouter();
  const { user } = useAuth();

  // Redirect if not farmer
  useEffect(() => {
    if (user && user.role !== 'farmer') {
      router.push('/dashboard');
    }
  }, [user, router]);

  if (!user) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="bg-white rounded-lg shadow-lg p-8 max-w-md w-full text-center">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Please Log In</h2>
          <p className="text-gray-600 mb-4">
            You need to be logged in as a farmer to register harvest data.
          </p>
          <button
            onClick={() => router.push('/login')}
            className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
          >
            Go to Login
          </button>
        </div>
      </div>
    );
  }

  if (user.role !== 'farmer') {
    return null; // Will redirect via useEffect
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8">
      <HarvestWizard />
    </div>
  );
}
