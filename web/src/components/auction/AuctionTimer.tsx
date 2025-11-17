'use client';

import { useState, useEffect } from 'react';
import { Clock } from 'lucide-react';

interface AuctionTimerProps {
  endTime: string;
}

export function AuctionTimer({ endTime }: AuctionTimerProps) {
  const [timeRemaining, setTimeRemaining] = useState<{
    days: number;
    hours: number;
    minutes: number;
    seconds: number;
  } | null>(null);
  const [isUrgent, setIsUrgent] = useState(false);

  useEffect(() => {
    const calculateTimeRemaining = () => {
      const end = new Date(endTime).getTime();
      const now = new Date().getTime();
      const difference = end - now;

      if (difference <= 0) {
        setTimeRemaining(null);
        return;
      }

      const days = Math.floor(difference / (1000 * 60 * 60 * 24));
      const hours = Math.floor((difference % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
      const minutes = Math.floor((difference % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((difference % (1000 * 60)) / 1000);

      setTimeRemaining({ days, hours, minutes, seconds });
      setIsUrgent(difference < 5 * 60 * 1000); // Less than 5 minutes
    };

    calculateTimeRemaining();
    const interval = setInterval(calculateTimeRemaining, 1000);

    return () => clearInterval(interval);
  }, [endTime]);

  if (!timeRemaining) {
    return (
      <div className="text-center py-8">
        <Clock className="w-12 h-12 mx-auto mb-4 text-gray-400" />
        <p className="text-xl font-semibold text-gray-600 dark:text-gray-400">Auction Ended</p>
      </div>
    );
  }

  return (
    <div className={`text-center ${isUrgent ? 'countdown-urgent' : ''}`}>
      <div className="grid grid-cols-4 gap-4">
        <div className="bg-gray-50 dark:bg-gray-900 rounded-lg p-4">
          <p className="text-3xl font-bold text-primary-600">{timeRemaining.days}</p>
          <p className="text-sm text-gray-500 dark:text-gray-400">Days</p>
        </div>
        <div className="bg-gray-50 dark:bg-gray-900 rounded-lg p-4">
          <p className="text-3xl font-bold text-primary-600">{timeRemaining.hours}</p>
          <p className="text-sm text-gray-500 dark:text-gray-400">Hours</p>
        </div>
        <div className="bg-gray-50 dark:bg-gray-900 rounded-lg p-4">
          <p className="text-3xl font-bold text-primary-600">{timeRemaining.minutes}</p>
          <p className="text-sm text-gray-500 dark:text-gray-400">Min</p>
        </div>
        <div className="bg-gray-50 dark:bg-gray-900 rounded-lg p-4">
          <p className="text-3xl font-bold text-primary-600">{timeRemaining.seconds}</p>
          <p className="text-sm text-gray-500 dark:text-gray-400">Sec</p>
        </div>
      </div>
      {isUrgent && (
        <p className="mt-4 text-sm font-semibold text-red-600 animate-pulse">
          ⚠️ Auction ending soon!
        </p>
      )}
    </div>
  );
}
