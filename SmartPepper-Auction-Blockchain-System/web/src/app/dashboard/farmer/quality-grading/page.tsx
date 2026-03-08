'use client';

import { useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { Scale, Microscope, Save, Activity, CheckCircle, Clock } from 'lucide-react';
import Link from 'next/link';

export default function QualityGradingPage() {
    const { user } = useAuth();

    // Simulation States
    const [isWeighing, setIsWeighing] = useState(false);
    const [isScanning, setIsScanning] = useState(false);
    const [isSaving, setIsSaving] = useState(false);
    const [saveSuccess, setSaveSuccess] = useState(false);

    // Data States
    const [weight, setWeight] = useState<number | null>(null);
    const [densityMsg, setDensityMsg] = useState<string | null>(null);
    const [visualData, setVisualData] = useState<{ pure: number; molded: number; discolored: number } | null>(null);
    const [finalGrade, setFinalGrade] = useState<string | null>(null);

    // Core Simulation Logic
    const simulateWeighing = () => {
        setIsWeighing(true);
        setSaveSuccess(false);

        // Simulate 2s delay for hardware
        setTimeout(() => {
            // Random density between 400 and 650
            const randomWeight = Math.floor(Math.random() * (650 - 400 + 1)) + 400;
            setWeight(randomWeight);

            if (randomWeight >= 570) setDensityMsg('High Density');
            else if (randomWeight >= 550) setDensityMsg('Medium Density');
            else if (randomWeight >= 500) setDensityMsg('Lightweight');
            else setDensityMsg('Low Density');

            setIsWeighing(false);
            calculateFinalGradeIfReady(randomWeight, visualData);
        }, 1500);
    };

    const simulateScanning = () => {
        setIsScanning(true);
        setSaveSuccess(false);

        // Simulate 3s delay for AI vision scanning
        setTimeout(() => {
            // Randomize percentages ensuring they sum to 100
            let pure = Math.floor(Math.random() * 30) + 70; // 70 to 100%
            let remaining = 100 - pure;
            let molded = Math.floor(Math.random() * (remaining + 1));
            let discolored = remaining - molded;

            const newVisualData = { pure, molded, discolored };
            setVisualData(newVisualData);
            setIsScanning(false);
            calculateFinalGradeIfReady(weight, newVisualData);
        }, 2000);
    };

    const calculateFinalGradeIfReady = (currentWeight: number | null, currentVisual: { pure: number } | null) => {
        if (!currentWeight || !currentVisual) return;

        const pure = currentVisual.pure;
        if (currentWeight >= 570 && pure >= 90) setFinalGrade('Grade A (Premium High Density)');
        else if (currentWeight >= 550 && pure >= 80) setFinalGrade('Grade B (Standard High Quality)');
        else if (currentWeight >= 500 && pure >= 70) setFinalGrade('Grade C (Lightweight / Industrial)');
        else setFinalGrade('Grade D (Low Density / Waste)');
    };

    const handleSaveResult = async () => {
        if (!weight || !visualData || !finalGrade) return;

        setIsSaving(true);
        try {
            const token = localStorage.getItem('token');
            const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3002';
            const response = await fetch(`${apiUrl}/api/quality-grading`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({
                    weightGrams: weight,
                    density: weight, // We treat weight reading natively as g/L density
                    visualPercentages: visualData
                })
            });

            if (!response.ok) throw new Error('Failed to save');

            setSaveSuccess(true);
            // Reset after success to allow next batch
            setTimeout(() => {
                setWeight(null);
                setDensityMsg(null);
                setVisualData(null);
                setFinalGrade(null);
                setSaveSuccess(false);
            }, 3000);

        } catch (error) {
            console.error(error);
            alert('Failed to save grading data');
        } finally {
            setIsSaving(false);
        }
    };

    if (!user || user.role !== 'farmer') {
        return (
            <div className="min-h-screen flex items-center justify-center bg-pepper-light dark:bg-pepper-dark text-pepper-darkBrown dark:text-pepper-light">
                <div className="text-center bg-white dark:bg-pepper-black p-8 rounded-2xl shadow-xl max-w-md w-full">
                    <Activity className="w-16 h-16 text-red-500 mx-auto mb-4" />
                    <h2 className="text-2xl font-bold mb-2">Access Denied</h2>
                    <p className="text-gray-600 dark:text-gray-400">Only farmers can access the Quality Grading system.</p>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-pepper-light dark:bg-pepper-dark p-6 transition-colors duration-300">
            <div className="max-w-6xl mx-auto space-y-6">

                {/* Header Section */}
                <div className="flex flex-col md:flex-row md:items-center justify-between bg-white dark:bg-pepper-black p-6 rounded-2xl shadow-lg border border-pepper-gold/20">
                    <div>
                        <h1 className="text-3xl font-bold text-pepper-darkBrown dark:text-pepper-gold flex items-center gap-3">
                            <Microscope className="w-8 h-8 text-pepper-harvest" />
                            Machine Control & Quality Station
                        </h1>
                        <p className="mt-2 text-gray-600 dark:text-gray-400">
                            Run physical density and visual checks on your pepper batch.
                        </p>
                    </div>
                    <Link
                        href="/dashboard/farmer/quality-grading/history"
                        className="mt-4 md:mt-0 flex items-center justify-center gap-2 px-6 py-3 bg-pepper-mediumBrown dark:bg-gray-800 text-white rounded-xl hover:bg-pepper-darkBrown dark:hover:bg-gray-700 transition"
                    >
                        <Clock className="w-5 h-5" />
                        View History
                    </Link>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    {/* Density Scan Panel */}
                    <div className="bg-white dark:bg-pepper-black p-6 rounded-2xl shadow-lg border border-pepper-gold/20 flex flex-col h-full relative overflow-hidden">
                        <div className="absolute top-0 right-0 w-32 h-32 bg-pepper-gold/10 rounded-bl-full -z-10 blur-2xl"></div>

                        <div className="flex items-center gap-3 mb-6">
                            <div className="p-3 bg-blue-100 dark:bg-blue-900/30 rounded-xl">
                                <Scale className="w-6 h-6 text-blue-600 dark:text-blue-400" />
                            </div>
                            <h2 className="text-2xl font-semibold text-gray-800 dark:text-white">Density Analysis</h2>
                        </div>

                        <div className="flex-1 flex flex-col justify-center items-center mb-6 min-h-[160px] bg-gray-50 dark:bg-gray-900/50 rounded-xl border border-gray-100 dark:border-gray-800">
                            {isWeighing ? (
                                <div className="flex flex-col items-center animate-pulse">
                                    <div className="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mb-4"></div>
                                    <p className="text-blue-600 dark:text-blue-400 font-medium">Capturing density logic...</p>
                                </div>
                            ) : weight ? (
                                <div className="text-center space-y-2">
                                    <span className="text-5xl font-bold text-gray-800 dark:text-white">{weight} <span className="text-2xl text-gray-500">g/L</span></span>
                                    <div className={`inline-block px-4 py-1.5 rounded-full text-sm font-medium ${weight >= 550 ? 'bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-300' :
                                        weight >= 500 ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/50 dark:text-yellow-300' :
                                            'bg-red-100 text-red-800 dark:bg-red-900/50 dark:text-red-300'
                                        }`}>
                                        {densityMsg}
                                    </div>
                                </div>
                            ) : (
                                <p className="text-gray-400 text-center px-4">Scale idle. Insert sample and click button to weigh.</p>
                            )}
                        </div>

                        <button
                            onClick={simulateWeighing}
                            disabled={isWeighing}
                            className="w-full py-4 bg-blue-600 hover:bg-blue-700 text-white rounded-xl font-semibold transition shadow-md shadow-blue-500/20 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            Start Weighing Routine
                        </button>
                    </div>

                    {/* Visual Scan Panel */}
                    <div className="bg-white dark:bg-pepper-black p-6 rounded-2xl shadow-lg border border-pepper-gold/20 flex flex-col h-full relative overflow-hidden">
                        <div className="absolute top-0 right-0 w-32 h-32 bg-purple-500/10 rounded-bl-full -z-10 blur-2xl"></div>

                        <div className="flex items-center gap-3 mb-6">
                            <div className="p-3 bg-purple-100 dark:bg-purple-900/30 rounded-xl">
                                <Microscope className="w-6 h-6 text-purple-600 dark:text-purple-400" />
                            </div>
                            <h2 className="text-2xl font-semibold text-gray-800 dark:text-white">Visual Grading</h2>
                        </div>

                        <div className="flex-1 flex flex-col justify-center mb-6 min-h-[160px] bg-gray-50 dark:bg-gray-900/50 rounded-xl border border-gray-100 dark:border-gray-800 p-6">
                            {isScanning ? (
                                <div className="flex flex-col items-center animate-pulse">
                                    <div className="w-12 h-12 border-4 border-purple-500 border-t-transparent rounded-full animate-spin mb-4"></div>
                                    <p className="text-purple-600 dark:text-purple-400 font-medium">Running Computer Vision Model...</p>
                                </div>
                            ) : visualData ? (
                                <div className="w-full space-y-4">
                                    <div>
                                        <div className="flex justify-between mb-1 text-sm font-medium">
                                            <span className="text-green-600 dark:text-green-400">Pure Pepper</span>
                                            <span className="text-gray-800 dark:text-gray-200">{visualData.pure}%</span>
                                        </div>
                                        <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2.5">
                                            <div className="bg-green-500 h-2.5 rounded-full" style={{ width: `${visualData.pure}%` }}></div>
                                        </div>
                                    </div>
                                    <div>
                                        <div className="flex justify-between mb-1 text-sm font-medium">
                                            <span className="text-yellow-600 dark:text-yellow-400">Discolored</span>
                                            <span className="text-gray-800 dark:text-gray-200">{visualData.discolored}%</span>
                                        </div>
                                        <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2.5">
                                            <div className="bg-yellow-500 h-2.5 rounded-full" style={{ width: `${visualData.discolored}%` }}></div>
                                        </div>
                                    </div>
                                    <div>
                                        <div className="flex justify-between mb-1 text-sm font-medium">
                                            <span className="text-red-600 dark:text-red-400">Molded</span>
                                            <span className="text-gray-800 dark:text-gray-200">{visualData.molded}%</span>
                                        </div>
                                        <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2.5">
                                            <div className="bg-red-500 h-2.5 rounded-full" style={{ width: `${visualData.molded}%` }}></div>
                                        </div>
                                    </div>
                                </div>
                            ) : (
                                <p className="text-gray-400 text-center">Camera idle. Awaiting scan command.</p>
                            )}
                        </div>

                        <button
                            onClick={simulateScanning}
                            disabled={isScanning}
                            className="w-full py-4 bg-purple-600 hover:bg-purple-700 text-white rounded-xl font-semibold transition shadow-md shadow-purple-500/20 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            Run Hardware Camera Scan
                        </button>
                    </div>
                </div>

                {/* Final Grade & Submission Panel */}
                <div className={`p-8 rounded-2xl shadow-xl transition-all duration-500 border
          ${finalGrade ? 'bg-gradient-to-br from-pepper-darkBrown to-pepper-black border-pepper-gold translate-y-0 opacity-100' : 'bg-white dark:bg-pepper-black border-gray-200 dark:border-gray-800 opacity-50'}`}>
                    <div className="flex flex-col md:flex-row items-center justify-between gap-6 text-center md:text-left">
                        <div>
                            <h3 className="text-lg font-medium text-gray-500 dark:text-gray-400 mb-1">Calculated Final Batch Grade</h3>
                            <p className={`text-4xl font-extrabold ${finalGrade ? 'text-pepper-gold' : 'text-gray-300 dark:text-gray-700'}`}>
                                {finalGrade || 'Waiting for machine inputs...'}
                            </p>
                        </div>
                        <button
                            onClick={handleSaveResult}
                            disabled={!finalGrade || isSaving || saveSuccess}
                            className={`flex items-center gap-3 px-8 py-4 rounded-xl font-bold text-lg shadow-lg transition-transform ${saveSuccess ? 'bg-green-500 text-white hover:bg-green-600' :
                                'bg-pepper-gold text-pepper-black hover:bg-pepper-harvest hover:scale-105 disabled:bg-gray-300 disabled:text-gray-500 disabled:hover:scale-100 disabled:cursor-not-allowed'
                                }`}
                        >
                            {saveSuccess ? (
                                <><CheckCircle className="w-6 h-6" /> Saved!</>
                            ) : isSaving ? (
                                <><div className="w-6 h-6 border-4 border-pepper-black border-t-transparent rounded-full animate-spin"></div> Saving...</>
                            ) : (
                                <><Save className="w-6 h-6" /> Save to System</>
                            )}
                        </button>
                    </div>
                </div>

            </div>
        </div>
    );
}
