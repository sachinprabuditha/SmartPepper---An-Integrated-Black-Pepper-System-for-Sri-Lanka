'use client';

import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect, useState, useRef } from 'react';
import Link from 'next/link';
import { agricultureApi } from '@/lib/api';
import toast from 'react-hot-toast';

interface CollectionStatus {
    exists: boolean;
    count: number;
}

interface AgricultureStatus {
    [key: string]: CollectionStatus;
}

export default function AgricultureDataPage() {
    const { user, loading } = useAuth();
    const router = useRouter();

    const [status, setStatus] = useState<AgricultureStatus>({});
    const [processing, setProcessing] = useState<string | null>(null);
    const [logs, setLogs] = useState<string[]>([]);
    const logEndRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        if (!loading && (!user || user.role !== 'admin')) {
            router.push('/login');
        }
        if (user) {
            fetchStatus();
        }
    }, [user, loading, router]);

    useEffect(() => {
        if (logs.length > 0) {
            logEndRef.current?.scrollIntoView({ behavior: 'smooth' });
        }
    }, [logs]);

    const fetchStatus = async () => {
        try {
            const res = await agricultureApi.getStatus();
            setStatus(res.data.status);
        } catch (err) {
            console.error('Failed to fetch agriculture status', err);
        }
    };

    if (loading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
            </div>
        );
    }

    if (!user) return null;

    const collections = [
        { id: 'soilTypes', label: 'Soil Types', icon: '🌱', description: 'Soil classifications and properties' },
        { id: 'districts', label: 'Districts', icon: '📍', description: 'Regional geographic data' },
        { id: 'pepperVarieties', label: 'Pepper Varieties', icon: '🌶️', description: 'Technical specs for pepper types' },
        { id: 'agronomyTemplates', label: 'Agronomy Templates', icon: '📝', description: 'Predefined task schedules' },
        { id: 'agronomyGuides', label: 'Agronomy Guides', icon: '📖', description: 'Detailed cultivation manuals' }
    ];

    const [customJson, setCustomJson] = useState('');
    const [selectedCollection, setSelectedCollection] = useState('soilTypes');
    const fileInputRef = useRef<HTMLInputElement>(null);

    const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = (event) => {
            try {
                const content = event.target?.result as string;
                JSON.parse(content); // Validate JSON
                setCustomJson(content);
                toast.success('JSON file loaded successfully');
            } catch (err) {
                toast.error('Invalid JSON file');
            }
        };
        reader.readAsText(file);
    };

    const runCustomSeed = async () => {
        if (!customJson.trim()) {
            toast.error('Please provide JSON data');
            return;
        }

        try {
            const data = JSON.parse(customJson);
            const label = collections.find(c => c.id === selectedCollection)?.label || selectedCollection;

            if (!confirm(`Importing custom data into ${label}. This may overwrite existing records. Proceed?`)) return;

            setProcessing('custom');
            setLogs(prev => [...prev, `> Starting Custom Seed for: ${label}...`]);

            const res = await agricultureApi.seed(selectedCollection, data);
            setLogs(prev => [...prev, ...res.data.logs]);
            toast.success(`${label} custom sync complete`);
            setCustomJson('');
            fetchStatus();
        } catch (err: any) {
            toast.error(err.response?.data?.message || err.message || 'Invalid JSON format');
            setLogs(prev => [...prev, `❌ Error: ${err.message}`]);
        } finally {
            setProcessing(null);
        }
    };

    return (
        <div className="min-h-screen bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-gray-100 pb-12 transition-colors duration-200">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">

                {/* Header Section */}
                <div className="mb-8">
                    <Link
                        href="/dashboard/admin"
                        className="text-purple-600 hover:text-purple-700 dark:text-purple-400 dark:hover:text-purple-300 flex items-center gap-2 text-sm font-semibold mb-4 transition-colors"
                    >
                        ← Back to Dashboard
                    </Link>
                    <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                        <div className="flex items-center gap-4">
                            <div className="text-4xl bg-emerald-100 dark:bg-emerald-900/30 p-3 rounded-2xl shadow-sm">
                                🚜
                            </div>
                            <div>
                                <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100">
                                    Agriculture Data Manager
                                </h1>
                                <p className="text-gray-600 dark:text-gray-400 mt-1">
                                    Master Data Import & Synchronization
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 mb-12">
                    {/* Collections Status */}
                    <div className="lg:col-span-12">
                        <div className="flex items-center gap-4 mb-6">
                            <h2 className="text-sm font-bold uppercase tracking-widest text-emerald-600 dark:text-emerald-400 flex items-center gap-2">
                                <span className="w-1.5 h-1.5 bg-emerald-600 dark:bg-emerald-400 rounded-full"></span>
                                Current Data Status
                            </h2>
                            <div className="h-px flex-1 bg-gray-200 dark:bg-gray-800"></div>
                        </div>

                        <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
                            {collections.map((col) => (
                                <div key={col.id} className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-2xl p-4 shadow-sm transition-all text-center">
                                    <div className="text-2xl mb-2">{col.icon}</div>
                                    <h3 className="text-[10px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-1">{col.label}</h3>
                                    <div className="text-lg font-bold text-emerald-600 dark:text-emerald-400">
                                        {status[col.id]?.count || 0}
                                    </div>
                                    <div className={`mt-2 inline-block px-2 py-0.5 rounded-[4px] text-[8px] font-black uppercase ${status[col.id]?.exists ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400' : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'}`}>
                                        {status[col.id]?.exists ? 'Active' : 'Empty'}
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>

                    {/* Import Custom JSON */}
                    <div className="lg:col-span-12">
                        <div className="flex items-center gap-4 mb-6">
                            <h2 className="text-sm font-bold uppercase tracking-widest text-emerald-600 dark:text-emerald-400 flex items-center gap-2">
                                <span className="w-1.5 h-1.5 bg-emerald-600 dark:bg-emerald-400 rounded-full"></span>
                                Collection Import Tool
                            </h2>
                            <div className="h-px flex-1 bg-gray-200 dark:bg-gray-800"></div>
                        </div>
                        <div className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-3xl p-8 shadow-sm grid grid-cols-1 md:grid-cols-3 gap-8">
                            <div className="md:col-span-1">
                                <h4 className="text-sm font-bold text-gray-900 dark:text-white mb-6">Sync Configuration</h4>
                                <label className="block text-xs font-bold uppercase text-gray-400 mb-3 tracking-wider">Target Collection</label>
                                <select
                                    value={selectedCollection}
                                    onChange={(e) => setSelectedCollection(e.target.value)}
                                    className="w-full bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-700 rounded-xl px-4 py-3 text-sm mb-8 outline-none focus:ring-2 focus:ring-emerald-500/50 transition-all font-semibold"
                                >
                                    {collections.map(c => (
                                        <option key={c.id} value={c.id}>{c.label}</option>
                                    ))}
                                </select>

                                <div className="space-y-6">
                                    <div className="p-5 bg-gray-50 dark:bg-gray-900/50 rounded-2xl border border-gray-100 dark:border-gray-800">
                                        <h5 className="text-xs font-bold uppercase text-gray-400 mb-3 tracking-wider">Instructions</h5>
                                        <ul className="text-[11px] text-gray-600 dark:text-gray-400 space-y-2.5 leading-relaxed font-medium">
                                            <li>• Ensure JSON is an object with unique document IDs as keys.</li>
                                            <li>• File upload supports `<code className="text-emerald-600 dark:text-emerald-400">.json</code>` files.</li>
                                            <li>• Seeding will perform batch writes to Firestore.</li>
                                        </ul>
                                    </div>
                                    <button
                                        onClick={runCustomSeed}
                                        disabled={!!processing || !customJson.trim()}
                                        className="w-full py-4 bg-emerald-600 hover:bg-emerald-700 disabled:bg-gray-300 dark:disabled:bg-gray-700 text-white rounded-2xl font-bold text-sm shadow-xl shadow-emerald-500/20 transition-all flex items-center justify-center gap-3"
                                    >
                                        {processing === 'custom' ? 'Processing...' : (
                                            <>
                                                <span className="text-lg">🚀</span>
                                                Start Import
                                            </>
                                        )}
                                    </button>
                                </div>
                            </div>

                            <div className="md:col-span-2">
                                <div className="relative">
                                    <div className="flex justify-between items-end mb-3">
                                        <label className="text-xs font-bold uppercase text-gray-400 tracking-wider">JSON Editor</label>
                                        <button
                                            onClick={() => fileInputRef.current?.click()}
                                            className="px-4 py-2 bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400 rounded-xl text-xs font-bold hover:bg-emerald-200 dark:hover:bg-emerald-900/50 transition-all flex items-center gap-2 shadow-sm"
                                        >
                                            <span className="text-base">📁</span> Upload JSON File
                                        </button>
                                    </div>
                                    <textarea
                                        value={customJson}
                                        onChange={(e) => setCustomJson(e.target.value)}
                                        placeholder='{ "docId": { "field": "value" } }'
                                        className="w-full h-[360px] bg-gray-900 text-emerald-400 font-mono text-[11px] p-6 rounded-2xl border border-gray-700 outline-none scrollbar-thin scrollbar-thumb-gray-800 focus:ring-2 focus:ring-emerald-500/20 transition-all shadow-inner"
                                    />
                                    <input
                                        type="file"
                                        accept=".json"
                                        hidden
                                        ref={fileInputRef}
                                        onChange={handleFileUpload}
                                    />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Console Logs */}
                <div className="mb-8">
                    <div className="bg-gray-900 rounded-2xl flex flex-col min-h-[300px] shadow-2xl overflow-hidden border border-purple-900/30">
                        <div className="bg-gray-800/50 px-6 py-3 border-b border-white/5 flex justify-between items-center backdrop-blur-sm">
                            <h3 className="text-[10px] font-bold uppercase text-purple-300 tracking-widest flex items-center gap-2">
                                <span className="w-2 h-2 bg-purple-500 rounded-full animate-pulse"></span>
                                Synchronization Logs
                            </h3>
                            <button onClick={() => setLogs([])} className="text-[9px] font-bold uppercase text-gray-500 hover:text-white transition-colors">Clear Console</button>
                        </div>
                        <div className="flex-1 p-6 font-mono text-[11px] overflow-y-auto space-y-1.5 bg-black/40 leading-relaxed max-h-[400px] scrollbar-thin scrollbar-thumb-purple-900">
                            {logs.length === 0 ? (
                                <div className="text-gray-700 italic flex items-center gap-2">
                                    <span className="w-1.5 h-3 bg-purple-900 animate-pulse"></span>
                                    Ready for data operations...
                                </div>
                            ) : (
                                logs.map((log, i) => (
                                    <div key={i} className={`p-1.5 rounded transition-colors ${log.startsWith('>') ? 'text-purple-300 font-bold bg-purple-400/5 border-l-2 border-purple-500 pl-3' :
                                        log.startsWith('❌') ? 'text-red-400 bg-red-400/5' :
                                            log.startsWith('✅') ? 'text-emerald-400 bg-emerald-400/5 border-l-2 border-emerald-500 pl-3' :
                                                'text-purple-200/80 pl-3'
                                        }`}>
                                        {log}
                                    </div>
                                ))
                            )}
                            <div ref={logEndRef} />
                        </div>
                    </div>
                </div>

                {/* Info Footer */}
                <div className="p-6 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-3xl text-[10px] text-gray-500 flex flex-col md:flex-row items-center justify-between gap-4 shadow-sm">
                    <div className="flex flex-col gap-1">
                        <p className="uppercase tracking-[0.2em] font-bold text-gray-400">Security Notice</p>
                        <p>Seeding overwrites existing documents with matching IDs in Firestore. Ensure your JSON files are up to date.</p>
                    </div>
                    <div className="flex gap-6 uppercase font-bold tracking-widest shrink-0">
                        <div className="flex items-center gap-2 text-purple-600">
                            <span>Admin Control Suite</span>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    );
}
