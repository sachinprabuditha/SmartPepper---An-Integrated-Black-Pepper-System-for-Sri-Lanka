'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { Clock, ArrowLeft, RefreshCw, AlertCircle, FileText } from 'lucide-react';
import Link from 'next/link';

interface GradingRecord {
    id: string;
    density: number;
    weightGrams: number;
    visualPercentages: {
        pure: number;
        molded: number;
        discolored: number;
    };
    finalGrade: string;
    timestamp: string;
}

export default function QualityGradingHistoryPage() {
    const { user } = useAuth();
    const [data, setData] = useState<GradingRecord[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    const fetchHistory = async () => {
        setLoading(true);
        setError(null);
        try {
            const token = localStorage.getItem('token');
            const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3002';
            const response = await fetch(`${apiUrl}/api/quality-grading/history`, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });
            if (!response.ok) throw new Error('Failed to fetch history');
            const result = await response.json();
            if (result.success) {
                setData(result.data);
            } else {
                throw new Error(result.error || 'Parsing error');
            }
        } catch (err: any) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (user) {
            fetchHistory();
        }
    }, [user]);

    if (!user || user.role !== 'farmer') {
        return (
            <div className="min-h-screen flex items-center justify-center p-4">
                <p className="text-xl">Access Denied. Farmers only.</p>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-pepper-light dark:bg-pepper-dark p-6 transition-colors duration-300">
            <div className="max-w-6xl mx-auto space-y-6">

                {/* Header */}
                <div className="flex flex-col md:flex-row md:items-center justify-between bg-white dark:bg-pepper-black p-6 rounded-2xl shadow-lg border border-pepper-gold/20 gap-4">
                    <div>
                        <div className="flex items-center gap-3">
                            <Link href="/dashboard/farmer/quality-grading" className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition">
                                <ArrowLeft className="w-6 h-6 text-gray-500" />
                            </Link>
                            <h1 className="text-3xl font-bold text-pepper-darkBrown dark:text-pepper-gold flex items-center gap-3">
                                <Clock className="w-8 h-8 text-pepper-harvest" />
                                Grading Reports History
                            </h1>
                        </div>
                        <p className="mt-2 text-gray-600 dark:text-gray-400 ml-11">
                            Review all past quality machine gradings saved to the system.
                        </p>
                    </div>
                    <button
                        onClick={fetchHistory}
                        className="flex items-center gap-2 px-4 py-2 bg-pepper-gold/10 text-pepper-darkBrown dark:text-pepper-gold hover:bg-pepper-gold/20 rounded-xl transition font-medium"
                    >
                        <RefreshCw className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
                        Refresh
                    </button>
                </div>

                {/* Content */}
                {error && (
                    <div className="bg-red-50 dark:bg-red-900/30 border border-red-200 dark:border-red-800 text-red-800 dark:text-red-300 p-4 rounded-xl flex items-center gap-3">
                        <AlertCircle className="w-6 h-6" />
                        <p>{error}</p>
                    </div>
                )}

                {loading && data.length === 0 ? (
                    <div className="flex justify-center p-12">
                        <div className="w-12 h-12 border-4 border-pepper-gold border-t-transparent rounded-full animate-spin"></div>
                    </div>
                ) : data.length === 0 && !error ? (
                    <div className="text-center bg-white dark:bg-pepper-black p-12 rounded-2xl border border-pepper-gold/20 shadow-lg">
                        <FileText className="w-16 h-16 text-gray-300 dark:text-gray-600 mx-auto mb-4" />
                        <h3 className="text-xl font-bold text-gray-800 dark:text-white mb-2">No Reports Found</h3>
                        <p className="text-gray-500 dark:text-gray-400 mb-6">You haven't saved any machine gradings yet.</p>
                        <Link
                            href="/dashboard/farmer/quality-grading"
                            className="inline-block px-6 py-3 bg-pepper-gold text-pepper-black font-semibold rounded-xl hover:bg-pepper-harvest transition"
                        >
                            Start First Scan
                        </Link>
                    </div>
                ) : (
                    <div className="bg-white dark:bg-pepper-black rounded-2xl shadow-lg border border-pepper-gold/20 overflow-hidden">
                        <div className="overflow-x-auto">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="bg-gray-50 dark:bg-gray-900/50 text-gray-600 dark:text-gray-400 border-b border-gray-200 dark:border-gray-800">
                                        <th className="p-4 font-semibold">Date & Time</th>
                                        <th className="p-4 font-semibold">Density</th>
                                        <th className="p-4 font-semibold">Visual Breakdown</th>
                                        <th className="p-4 font-semibold text-right">Final Grade</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                                    {data.map((record) => (
                                        <tr key={record.id} className="hover:bg-gray-50 dark:hover:bg-gray-900/20 transition group">
                                            <td className="p-4 text-gray-800 dark:text-gray-200">
                                                {new Date(record.timestamp).toLocaleDateString()}
                                                <div className="text-sm text-gray-500 dark:text-gray-500">
                                                    {new Date(record.timestamp).toLocaleTimeString()}
                                                </div>
                                            </td>
                                            <td className="p-4">
                                                <span className="font-bold text-gray-800 dark:text-white">{record.density}</span>
                                                <span className="text-sm text-gray-500"> g/L</span>
                                            </td>
                                            <td className="p-4 text-sm">
                                                <div className="flex flex-col gap-1 min-w-[200px]">
                                                    <div className="flex items-center gap-2">
                                                        <span className="w-3 h-3 rounded-full bg-green-500"></span>
                                                        <span className="text-gray-600 dark:text-gray-400 w-20">Pure</span>
                                                        <span className="font-medium dark:text-white">{record.visualPercentages.pure}%</span>
                                                    </div>
                                                    <div className="flex items-center gap-2">
                                                        <span className="w-3 h-3 rounded-full bg-yellow-500"></span>
                                                        <span className="text-gray-600 dark:text-gray-400 w-20">Discolored</span>
                                                        <span className="font-medium dark:text-white">{record.visualPercentages.discolored}%</span>
                                                    </div>
                                                    <div className="flex items-center gap-2">
                                                        <span className="w-3 h-3 rounded-full bg-red-500"></span>
                                                        <span className="text-gray-600 dark:text-gray-400 w-20">Molded</span>
                                                        <span className="font-medium dark:text-white">{record.visualPercentages.molded}%</span>
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="p-4 text-right">
                                                <span className={`inline-block px-4 py-1.5 rounded-lg text-sm font-bold shadow-sm ${record.finalGrade.includes('Grade A') ? 'bg-green-100 text-green-800 border border-green-200 dark:bg-green-900/40 dark:text-green-300 dark:border-green-800' :
                                                    record.finalGrade.includes('Grade B') ? 'bg-blue-100 text-blue-800 border border-blue-200 dark:bg-blue-900/40 dark:text-blue-300 dark:border-blue-800' :
                                                        record.finalGrade.includes('Grade C') ? 'bg-yellow-100 text-yellow-800 border border-yellow-200 dark:bg-yellow-900/40 dark:text-yellow-300 dark:border-yellow-800' :
                                                            'bg-red-100 text-red-800 border border-red-200 dark:bg-red-900/40 dark:text-red-300 dark:border-red-800'
                                                    }`}>
                                                    {record.finalGrade.split('(')[0].trim()}
                                                </span>
                                                <div className="text-xs text-gray-500 mt-1 max-w-[150px] ml-auto truncate">
                                                    {record.finalGrade.includes('(') ? record.finalGrade.split('(')[1].replace(')', '') : ''}
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                )}

            </div>
        </div>
    );
}
