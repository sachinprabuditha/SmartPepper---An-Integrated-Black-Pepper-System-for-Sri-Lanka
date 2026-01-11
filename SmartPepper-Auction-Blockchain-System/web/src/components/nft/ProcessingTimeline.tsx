'use client';

import { CheckCircle, Circle, Clock } from 'lucide-react';

interface ProcessingLog {
  stage: string;
  description: string;
  timestamp: Date;
  recordedBy: string;
  location: string;
}

interface ProcessingTimelineProps {
  logs: ProcessingLog[];
}

const stageIcons: { [key: string]: string } = {
  'Created': '🌱',
  'Harvest': '🌾',
  'Drying': '☀️',
  'Grading': '⭐',
  'Packaging': '📦',
  'Compliance Passed': '✅',
  'Auction Created': '🔨',
  'Auction Active': '🔥',
  'Auction Settled': '💰',
  'Shipment': '🚚',
  'Delivered': '✓',
  'Transferred': '🔄',
};

export function ProcessingTimeline({ logs }: ProcessingTimelineProps) {
  // Sort logs by timestamp
  const sortedLogs = [...logs].sort((a, b) => 
    new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
  );

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
      <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-6">
        Supply Chain Timeline
      </h3>

      <div className="space-y-4">
        {sortedLogs.map((log, index) => {
          const isLast = index === sortedLogs.length - 1;
          const icon = stageIcons[log.stage] || '📌';

          return (
            <div key={index} className="relative">
              {/* Timeline line */}
              {!isLast && (
                <div className="absolute left-6 top-12 bottom-0 w-0.5 bg-gray-200 dark:bg-gray-700" />
              )}

              <div className="flex items-start space-x-4">
                {/* Icon */}
                <div className={`
                  flex-shrink-0 w-12 h-12 rounded-full flex items-center justify-center text-xl
                  ${isLast 
                    ? 'bg-green-100 dark:bg-green-900/30 ring-4 ring-green-500/20' 
                    : 'bg-gray-100 dark:bg-gray-700'
                  }
                `}>
                  {icon}
                </div>

                {/* Content */}
                <div className="flex-1 pb-8">
                  <div className="flex items-center justify-between mb-1">
                    <h4 className="font-semibold text-gray-900 dark:text-white">
                      {log.stage}
                    </h4>
                    {isLast && (
                      <span className="px-2 py-1 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 text-xs font-medium rounded-full">
                        Current Stage
                      </span>
                    )}
                  </div>

                  <p className="text-sm text-gray-600 dark:text-gray-300 mb-2">
                    {log.description}
                  </p>

                  <div className="flex flex-wrap gap-4 text-xs text-gray-500 dark:text-gray-400">
                    <div className="flex items-center space-x-1">
                      <Clock className="w-3 h-3" />
                      <span>{new Date(log.timestamp).toLocaleString()}</span>
                    </div>

                    {log.location && (
                      <div className="flex items-center space-x-1">
                        <span>📍</span>
                        <span>{log.location}</span>
                      </div>
                    )}

                    {log.recordedBy && log.recordedBy !== '0x0000000000000000000000000000000000000000' && (
                      <div className="flex items-center space-x-1">
                        <span>👤</span>
                        <span className="font-mono">
                          {log.recordedBy.substring(0, 6)}...{log.recordedBy.substring(38)}
                        </span>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Summary */}
      <div className="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-600 dark:text-gray-400">
            Total Stages Completed
          </span>
          <span className="font-semibold text-gray-900 dark:text-white">
            {sortedLogs.length}
          </span>
        </div>
      </div>
    </div>
  );
}
