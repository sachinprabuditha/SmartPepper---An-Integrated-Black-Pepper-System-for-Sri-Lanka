'use client';

import { useAuth } from '@/contexts/AuthContext';
import { useRouter } from 'next/navigation';
import { useEffect, useState, useRef } from 'react';
import Link from 'next/link';
import { kgApi } from '@/lib/api';
import toast from 'react-hot-toast';

interface PipelineStatus {
    raw: number;
    extracted: number;
    cleaned: number;
    chunks: number;
    pending: {
        extract: number;
        clean: number;
        chunk: number;
        index: number;
    };
}

interface DocFile {
    name: string;
    extracted: boolean;
    cleaned: boolean;
    chunked: boolean;
}

export default function KnowledgebasePage() {
    const { user, loading } = useAuth();
    const router = useRouter();

    const [status, setStatus] = useState<PipelineStatus>({
        raw: 0, extracted: 0, cleaned: 0, chunks: 0,
        pending: { extract: 0, clean: 0, chunk: 0, index: 0 }
    });
    const [files, setFiles] = useState<DocFile[]>([]);
    const [selectedFiles, setSelectedFiles] = useState<Set<string>>(new Set());
    const [processing, setProcessing] = useState<string | null>(null);
    const [successMessage, setSuccessMessage] = useState<string | null>(null);
    const [searchQuery, setSearchQuery] = useState('');
    const [logs, setLogs] = useState<string[]>([]);
    const logEndRef = useRef<HTMLDivElement>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);

    useEffect(() => {
        if (!loading && (!user || user.role !== 'admin')) {
            router.push('/login');
        }
        if (user) {
            fetchStatus();
            fetchFiles();
        }
    }, [user, loading, router]);

    useEffect(() => {
        if (logs.length > 0) {
            logEndRef.current?.scrollIntoView({ behavior: 'smooth' });
        }
    }, [logs]);

    const fetchStatus = async () => {
        try {
            const res = await kgApi.getStatus();
            setStatus(res.data.data);
        } catch (err) {
            console.error('Failed to fetch status', err);
        }
    };

    const fetchFiles = async () => {
        try {
            const res = await kgApi.getFiles();
            setFiles(res.data.data);
        } catch (err) {
            console.error('Failed to fetch files', err);
        }
    };

    const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        if (!e.target.files) return;
        const formData = new FormData();
        for (let i = 0; i < e.target.files.length; i++) {
            formData.append('files', e.target.files[i]);
        }

        const t = toast.loading('Uploading documents...');
        try {
            await kgApi.upload(formData);
            toast.success('Documents uploaded successfully', { id: t });
            setSuccessMessage('Documents uploaded successfully! You can now use the Incremental Pipeline.');
            fetchStatus();
            fetchFiles();
            if (fileInputRef.current) fileInputRef.current.value = '';

            setTimeout(() => setSuccessMessage(null), 5000);
        } catch (err: any) {
            toast.error(err.response?.data?.message || 'Upload failed', { id: t });
        }
    };

    const runIncremental = async (step: 'extract' | 'clean' | 'chunk' | 'index', label: string) => {
        setProcessing(step + '_inc');
        setLogs(prev => [...prev, `> Starting Incremental ${label}...`]);

        try {
            const res = await kgApi.processStep(step);
            setLogs(prev => [...prev, ...res.data.logs]);
            toast.success(`${label} completed`);
            setSuccessMessage(`${label} completed successfully!`);
            fetchStatus();
            fetchFiles();
            setTimeout(() => setSuccessMessage(null), 5000);
        } catch (err: any) {
            toast.error(err.response?.data?.message || `${label} failed`);
            setLogs(prev => [...prev, `❌ Error: ${err.response?.data?.message || err.message}`]);
        } finally {
            setProcessing(null);
        }
    };

    const runReprocess = async (step: 'extract' | 'clean' | 'chunk' | 'index', label: string) => {
        if (selectedFiles.size === 0) {
            toast.error('Please select at least one document to reprocess');
            return;
        }

        setProcessing(step + '_repr');
        const targetFiles = Array.from(selectedFiles);
        setLogs(prev => [...prev, `> Reprocessing ${label} for ${targetFiles.length} files...`]);

        try {
            const res = await kgApi.processStep(step, targetFiles);
            setLogs(prev => [...prev, ...res.data.logs]);
            toast.success(`${label} re-processing completed`);
            fetchStatus();
            fetchFiles();
            setSelectedFiles(new Set());
        } catch (err: any) {
            toast.error(err.response?.data?.message || `${label} reprocessing failed`);
            setLogs(prev => [...prev, `❌ Error: ${err.response?.data?.message || err.message}`]);
        } finally {
            setProcessing(null);
        }
    };

    const handleDelete = async (filename: string) => {
        if (!confirm(`Are you sure you want to delete "${filename}" and all its processed data?`)) return;

        const loader = toast.loading(`Deleting ${filename}...`);
        try {
            const res = await kgApi.deleteFile(filename);
            setLogs(prev => [...prev, ...res.data.logs]);
            toast.success('File deleted', { id: loader });
            fetchStatus();
            fetchFiles();
            setSelectedFiles(prev => {
                const next = new Set(prev);
                next.delete(filename);
                return next;
            });
        } catch (err: any) {
            toast.error(err.response?.data?.message || 'Delete failed', { id: loader });
        }
    };

    const initDatabase = async () => {
        if (!confirm("This will DELETE the entire AI collection and recreate it. Existing vectors will be lost. Proceed?")) return;
        setProcessing('init_db');
        setLogs(prev => [...prev, "> Initializing Qdrant Collection..."]);
        try {
            const res = await kgApi.setupCollection();
            setLogs(prev => [...prev, ...res.data.logs]);
            toast.success("Database initialized");
        } catch (err: any) {
            toast.error("Initialization failed");
            setLogs(prev => [...prev, `❌ Error: ${err.response?.data?.message || err.message}`]);
        } finally {
            setProcessing(null);
        }
    };

    const testConnectivity = async () => {
        setProcessing('test_conn');
        setLogs(prev => [...prev, "> Testing Qdrant Connectivity..."]);
        try {
            const res = await kgApi.testCollection();
            setLogs(prev => [...prev, ...res.data.logs]);
            toast.success("Connectivity test passed");
        } catch (err: any) {
            toast.error("Connectivity test failed");
            setLogs(prev => [...prev, `❌ Error: ${err.response?.data?.message || err.message}`]);
        } finally {
            setProcessing(null);
        }
    };

    const runSearch = async () => {
        if (!searchQuery.trim()) return;
        setProcessing('search');
        setLogs(prev => [...prev, `> Running AI Search for: "${searchQuery}"`]);
        try {
            const res = await kgApi.search(searchQuery);
            setLogs(prev => [...prev, ...res.data.logs]);
            setSearchQuery('');
        } catch (err: any) {
            toast.error("Search failed");
            setLogs(prev => [...prev, `❌ Error: ${err.response?.data?.message || err.message}`]);
        } finally {
            setProcessing(null);
        }
    };

    if (loading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-900">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-500"></div>
            </div>
        );
    }

    if (!user) return null;

    const steps = [
        { id: 'extract', label: '1. Extraction', icon: '📄', description: 'Extract text from new PDFs', count: status.pending.extract },
        { id: 'clean', label: '2. Cleaning', icon: '✨', description: 'Clean new texts', count: status.pending.clean },
        { id: 'chunk', label: '3. Chunking', icon: '✂️', description: 'Segment new data', count: status.pending.chunk },
        { id: 'index', label: '4. Indexing', icon: '🧠', description: 'Upload to AI DB', count: status.pending.index }
    ];

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
                            <div className="text-4xl bg-purple-100 dark:bg-purple-900/30 p-3 rounded-2xl shadow-sm">
                                📚
                            </div>
                            <div>
                                <h1 className="text-3xl font-bold text-purple-900 dark:text-purple-100">
                                    Knowledgebase Manager
                                </h1>
                                <p className="text-gray-600 dark:text-gray-400 mt-1">
                                    RAG Pipeline & Document Control
                                </p>
                            </div>
                        </div>
                        <div className="flex items-center gap-3">
                            <input type="file" multiple accept=".pdf" className="hidden" ref={fileInputRef} onChange={handleUpload} />
                            <button
                                onClick={() => fileInputRef.current?.click()}
                                className="px-5 py-2.5 bg-purple-600 hover:bg-purple-700 text-white rounded-xl font-bold transition shadow-md shadow-purple-200 dark:shadow-purple-900/20 flex items-center gap-2"
                            >
                                📤 Upload New Docs
                            </button>
                        </div>
                    </div>
                </div>

                {/* Success Banner */}
                {successMessage && (
                    <div className="mb-8 animate-in slide-in-from-top duration-300">
                        <div className="bg-emerald-50 dark:bg-emerald-900/10 border border-emerald-200 dark:border-emerald-800 p-4 rounded-xl flex items-center justify-between">
                            <div className="flex items-center gap-3 font-semibold text-emerald-700 dark:text-emerald-400">
                                <span className="text-xl">✅</span>
                                {successMessage}
                            </div>
                            <button onClick={() => setSuccessMessage(null)} className="text-emerald-500 hover:text-emerald-700 dark:hover:text-white transition-colors">✕</button>
                        </div>
                    </div>
                )}

                {/* SECTION 1: INCREMENTAL PIPELINE */}
                <div className="mb-12">
                    <div className="flex items-center gap-4 mb-6">
                        <h2 className="text-sm font-bold uppercase tracking-widest text-purple-600 dark:text-purple-400 flex items-center gap-2">
                            <span className="w-1.5 h-1.5 bg-purple-600 dark:bg-purple-400 rounded-full"></span>
                            Section 1: Incremental Pipeline (New Files)
                        </h2>
                        <div className="h-px flex-1 bg-gray-200 dark:bg-gray-800"></div>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                        {steps.map((step) => (
                            <div key={step.id} className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-2xl p-6 shadow-sm hover:shadow-md transition-all">
                                <div className="flex items-start justify-between mb-4">
                                    <div className="text-3xl">{step.icon}</div>
                                    <div className="text-xl font-bold text-purple-600 dark:text-purple-400">{step.count}</div>
                                </div>
                                <h3 className="text-sm font-bold text-gray-900 dark:text-white uppercase tracking-wider mb-1">{step.label}</h3>
                                <p className="text-xs text-gray-500 dark:text-gray-400 mb-6">{step.description}</p>
                                <button
                                    onClick={() => runIncremental(step.id as any, step.label)}
                                    disabled={!!processing || (step.count === 0 && step.id !== 'extract')}
                                    className={`w-full py-3 rounded-xl font-bold uppercase text-xs transition-all ${processing === step.id + '_inc'
                                        ? 'bg-purple-600 text-white animate-pulse'
                                        : (step.count === 0 && step.id !== 'extract')
                                            ? 'bg-gray-100 dark:bg-gray-700 text-gray-400 dark:text-gray-500 cursor-not-allowed'
                                            : 'bg-purple-50 dark:bg-purple-900/20 text-purple-700 dark:text-purple-300 hover:bg-purple-600 hover:text-white'
                                        }`}
                                >
                                    {processing === step.id + '_inc' ? 'Working...' : `Run ${step.id}`}
                                </button>
                            </div>
                        ))}
                    </div>
                </div>

                {/* SECTION 2: REPROCESS MANAGER */}
                <div className="mb-12">
                    <div className="flex items-center gap-4 mb-6">
                        <h2 className="text-sm font-bold uppercase tracking-widest text-purple-600 dark:text-purple-400 flex items-center gap-2">
                            <span className="w-1.5 h-1.5 bg-purple-600 dark:bg-purple-400 rounded-full"></span>
                            Section 2: Reprocess Manager (Saved Docs)
                        </h2>
                        <div className="h-px flex-1 bg-gray-200 dark:bg-gray-800"></div>
                    </div>

                    <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                        {/* Table Column */}
                        <div className="lg:col-span-2">
                            <div className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-2xl overflow-hidden shadow-sm">
                                <div className="bg-gray-50 dark:bg-gray-800/50 px-6 py-4 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between">
                                    <div className="flex items-center gap-2">
                                        <h3 className="text-xs font-bold uppercase text-gray-900 dark:text-white tracking-widest">Saved Documents</h3>
                                        <span className="px-2 py-0.5 bg-purple-100 dark:bg-purple-900/30 text-[10px] text-purple-700 dark:text-purple-300 rounded-full font-bold">{files.length}</span>
                                    </div>
                                    <div className="flex gap-4">
                                        <button onClick={() => setSelectedFiles(new Set(files.map(f => f.name)))} className="text-[10px] font-bold uppercase text-purple-600 dark:text-purple-400 hover:underline">Select All</button>
                                        <button onClick={() => setSelectedFiles(new Set())} className="text-[10px] font-bold uppercase text-gray-500 hover:underline">Clear</button>
                                    </div>
                                </div>
                                <div className="max-h-[600px] overflow-y-auto">
                                    <table className="w-full text-left">
                                        <thead className="sticky top-0 bg-gray-50/90 dark:bg-gray-800/90 backdrop-blur text-[10px] uppercase font-bold text-gray-500 tracking-widest border-b border-gray-200 dark:border-gray-700">
                                            <tr>
                                                <th className="px-6 py-3 w-8"></th>
                                                <th className="px-6 py-3">File Name</th>
                                                <th className="px-6 py-3 text-center">Progress</th>
                                                <th className="px-6 py-3 text-right">Action</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-gray-100 dark:divide-gray-700">
                                            {files.length === 0 ? (
                                                <tr><td colSpan={4} className="px-6 py-12 text-center text-gray-500 italic">No documents found</td></tr>
                                            ) : (
                                                files.map(file => (
                                                    <tr key={file.name} className={`hover:bg-purple-50 dark:hover:bg-purple-900/5 transition-colors ${selectedFiles.has(file.name) ? 'bg-purple-50/50 dark:bg-purple-900/10' : ''}`}>
                                                        <td className="px-6 py-4">
                                                            <input
                                                                type="checkbox"
                                                                checked={selectedFiles.has(file.name)}
                                                                onChange={(e) => {
                                                                    const next = new Set(selectedFiles);
                                                                    if (e.target.checked) next.add(file.name);
                                                                    else next.delete(file.name);
                                                                    setSelectedFiles(next);
                                                                }}
                                                                className="w-4 h-4 rounded border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-purple-600 focus:ring-purple-500"
                                                            />
                                                        </td>
                                                        <td className="px-6 py-4">
                                                            <div className="text-xs font-medium text-gray-900 dark:text-gray-200 truncate max-w-[200px]">{file.name}</div>
                                                        </td>
                                                        <td className="px-6 py-4">
                                                            <div className="flex justify-center gap-1.5">
                                                                <div className={`w-2.5 h-2.5 rounded-full ${file.extracted ? 'bg-purple-500' : 'bg-gray-200 dark:bg-gray-700'}`} title="Extracted"></div>
                                                                <div className={`w-2.5 h-2.5 rounded-full ${file.cleaned ? 'bg-indigo-500' : 'bg-gray-200 dark:bg-gray-700'}`} title="Cleaned"></div>
                                                                <div className={`w-2.5 h-2.5 rounded-full ${file.chunked ? 'bg-blue-500' : 'bg-gray-200 dark:bg-gray-700'}`} title="Chunked"></div>
                                                            </div>
                                                        </td>
                                                        <td className="px-6 py-4 text-right">
                                                            <button
                                                                onClick={() => handleDelete(file.name)}
                                                                className="text-gray-400 hover:text-red-500 transition-colors p-1"
                                                                title="Delete file"
                                                            >
                                                                <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                                                </svg>
                                                            </button>
                                                        </td>
                                                    </tr>
                                                ))
                                            )}
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>

                        {/* Controls & Tools Column */}
                        <div className="lg:col-span-1 flex flex-col gap-6">
                            {/* Fast Reprocess Controls */}
                            <div className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-2xl p-6 shadow-sm">
                                <h3 className="text-xs font-bold uppercase text-purple-600 dark:text-purple-400 tracking-widest mb-4 flex items-center gap-2">
                                    🚀 Target Reprocess
                                    {selectedFiles.size > 0 && <span className="bg-purple-600 text-white px-2 py-0.5 rounded-full text-[10px]">{selectedFiles.size}</span>}
                                </h3>
                                <div className="grid grid-cols-2 gap-3">
                                    {steps.map((st) => (
                                        <button
                                            key={st.id}
                                            disabled={!!processing || selectedFiles.size === 0}
                                            onClick={() => runReprocess(st.id as any, st.label)}
                                            className={`py-2.5 rounded-lg text-[10px] font-bold uppercase transition-all border ${selectedFiles.size > 0
                                                ? 'border-purple-200 dark:border-purple-900/50 text-purple-700 dark:text-purple-300 hover:bg-purple-600 hover:text-white hover:border-purple-600'
                                                : 'border-gray-100 dark:border-gray-700 text-gray-300 dark:text-gray-600 cursor-not-allowed'
                                                }`}
                                        >
                                            {st.id}
                                        </button>
                                    ))}
                                </div>
                                {selectedFiles.size === 0 && (
                                    <p className="text-[10px] text-gray-400 dark:text-gray-500 mt-3 italic text-center">Select files in table to enable</p>
                                )}
                            </div>

                            {/* System Tools & AI Search */}
                            <div className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-2xl p-6 flex flex-col gap-6 shadow-sm">
                                <div>
                                    <h3 className="text-xs font-bold uppercase text-indigo-600 dark:text-indigo-400 tracking-widest mb-4 flex items-center gap-2">
                                        🛠️ System Tools
                                    </h3>
                                    <div className="flex flex-col gap-2">
                                        <button
                                            onClick={initDatabase}
                                            disabled={!!processing}
                                            className="w-full py-2.5 bg-white dark:bg-gray-700/50 hover:bg-red-50 dark:hover:bg-red-900/20 text-gray-600 dark:text-gray-300 hover:text-red-600 dark:hover:text-red-400 rounded-lg text-[10px] font-bold uppercase transition-colors border border-gray-200 dark:border-gray-600"
                                        >
                                            Initialize Database
                                        </button>
                                        <button
                                            onClick={testConnectivity}
                                            disabled={!!processing}
                                            className="w-full py-2.5 bg-white dark:bg-gray-700/50 hover:bg-indigo-50 dark:hover:bg-indigo-900/20 text-gray-600 dark:text-gray-300 hover:text-indigo-600 dark:hover:text-indigo-400 rounded-lg text-[10px] font-bold uppercase transition-colors border border-gray-200 dark:border-gray-600"
                                        >
                                            Test Connectivity
                                        </button>
                                    </div>
                                </div>

                                <div className="pt-4 border-t border-gray-100 dark:border-gray-700">
                                    <h3 className="text-xs font-bold uppercase text-gray-900 dark:text-white tracking-widest mb-4 flex items-center gap-2">
                                        🧠 AI Search Test
                                    </h3>
                                    <div className="space-y-3">
                                        <input
                                            type="text"
                                            value={searchQuery}
                                            onChange={(e) => setSearchQuery(e.target.value)}
                                            onKeyDown={(e) => e.key === 'Enter' && runSearch()}
                                            placeholder="Ask a question..."
                                            className="w-full bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-700 rounded-lg px-3 py-2 text-xs focus:ring-2 focus:ring-purple-500 outline-none transition-all dark:text-white"
                                        />
                                        <button
                                            onClick={runSearch}
                                            disabled={!!processing || !searchQuery.trim()}
                                            className="w-full py-2.5 bg-purple-600 hover:bg-purple-700 text-white rounded-lg text-[10px] font-bold uppercase transition-all shadow-sm shadow-purple-200 dark:shadow-purple-900/20 disabled:opacity-50"
                                        >
                                            {processing === 'search' ? 'Searching...' : 'Ask AI'}
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Console Logs */}
                <div className="mb-8">
                    <div className="bg-gray-900 rounded-2xl flex flex-col min-h-[400px] shadow-2xl overflow-hidden border border-purple-900/30">
                        <div className="bg-gray-800/50 px-6 py-3 border-b border-white/5 flex justify-between items-center backdrop-blur-sm">
                            <h3 className="text-[10px] font-bold uppercase text-purple-300 tracking-widest flex items-center gap-2">
                                <span className="w-2 h-2 bg-purple-500 rounded-full animate-pulse"></span>
                                Live System Logs
                            </h3>
                            <button onClick={() => setLogs([])} className="text-[9px] font-bold uppercase text-gray-500 hover:text-white transition-colors">Clear Console</button>
                        </div>
                        <div className="flex-1 p-6 font-mono text-[11px] overflow-y-auto space-y-1.5 bg-black/40 leading-relaxed max-h-[500px] scrollbar-thin scrollbar-thumb-purple-900">
                            {logs.length === 0 ? (
                                <div className="text-gray-700 italic flex items-center gap-2">
                                    <span className="w-1.5 h-3 bg-purple-900 animate-pulse"></span>
                                    System initialized. Ready for operations...
                                </div>
                            ) : (
                                logs.map((log, i) => (
                                    <div key={i} className={`p-1.5 rounded transition-colors ${log.startsWith('>') ? 'text-purple-300 font-bold bg-purple-400/5 border-l-2 border-purple-500 pl-3' :
                                        log.startsWith('❌') ? 'text-red-400 bg-red-400/5' :
                                            log.startsWith('🗑️') ? 'text-gray-500' :
                                                log.startsWith('🔎') ? 'text-indigo-300 font-bold border-l-2 border-indigo-500 pl-3' :
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

                {/* Footer Info */}
                <div className="p-6 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-3xl text-[10px] text-gray-500 flex flex-col md:flex-row items-center justify-between gap-4 shadow-sm">
                    <p className="uppercase tracking-[0.2em] font-medium">SmartPepper AI RAG Control Suite • 2026 Admin Edition</p>
                    <div className="flex gap-6 uppercase font-bold tracking-widest">
                        <div className="flex items-center gap-2">
                            <div className="w-2.5 h-2.5 bg-purple-500 rounded-full"></div>
                            <span className="text-gray-700 dark:text-gray-300">Extracted</span>
                        </div>
                        <div className="flex items-center gap-2">
                            <div className="w-2.5 h-2.5 bg-indigo-500 rounded-full"></div>
                            <span className="text-gray-700 dark:text-gray-300">Cleaned</span>
                        </div>
                        <div className="flex items-center gap-2">
                            <div className="w-2.5 h-2.5 bg-blue-500 rounded-full"></div>
                            <span className="text-gray-700 dark:text-gray-300">Chunked</span>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    );
}
