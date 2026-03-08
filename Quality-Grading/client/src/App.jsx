import { useState, useEffect } from 'react'
import './App.css'

function App() {
  const [file, setFile] = useState(null);
  const [preview, setPreview] = useState(null);
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  // Hardware State
  const [hwStatus, setHwStatus] = useState({ weight: 0, running: false, speed: 800, factor: 0, offline: true });
  // Local state for UI responsiveness
  const [localRunning, setLocalRunning] = useState(false);
  const [localSpeed, setLocalSpeed] = useState(800);
  const [hwLoading, setHwLoading] = useState(false);

  // Calibration State
  const [knownWeight, setKnownWeight] = useState('');
  const [showCalib, setShowCalib] = useState(false);

  // Weight Grade State
  const [capturedWeight, setCapturedWeight] = useState(null);
  const [weightGrade, setWeightGrade] = useState(null);

  // Calculate grade based on weight in grams
  const calculateWeightGrade = (weightKg) => {
    const grams = weightKg * 1000;
    if (grams >= 550) return 'Grade I';
    if (grams >= 450) return 'Grade II';
    return 'Grade III';
  };

  const handleCaptureWeight = () => {
    if (hwStatus.offline || hwStatus.weight === undefined) return;
    const weight = hwStatus.weight;
    setCapturedWeight(weight);
    setWeightGrade(calculateWeightGrade(weight));
  };

  const handleFileChange = (e) => {
    const selectedFile = e.target.files[0];
    if (selectedFile) {
      setFile(selectedFile);
      setPreview(URL.createObjectURL(selectedFile));
      setResult(null);
      setError(null);
    }
  };

  // Hardware Controls
  const fetchHwStatus = async () => {
    try {
      const res = await fetch('http://localhost:3001/hardware/status');
      const data = await res.json();
      setHwStatus(data);
      if (!hwLoading) {
        setLocalRunning(data.running);
        if (data.speed) setLocalSpeed(data.speed);
      }
    } catch (e) {
      setHwStatus(prev => ({ ...prev, offline: true }));
    }
  };

  useEffect(() => {
    fetchHwStatus();
    const interval = setInterval(fetchHwStatus, 2000);
    return () => clearInterval(interval);
  }, []);

  const updateHardware = async (running, speed) => {
    setHwLoading(true);
    try {
      await fetch('http://localhost:3001/hardware/control', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ running, speed })
      });
      fetchHwStatus();
    } catch (e) {
      console.error("Failed to update hardware", e);
    } finally {
      setHwLoading(false);
    }
  };

  const handleToggleRun = () => {
    const confirm = !localRunning;
    setLocalRunning(confirm);
    updateHardware(confirm, localSpeed);
  };

  const handleSpeedChange = (e) => {
    const val = parseInt(e.target.value, 10);
    setLocalSpeed(val);
  };

  const handleSpeedCommit = () => {
    updateHardware(localRunning, localSpeed);
  };

  const handleTare = async () => {
    if (!confirm("Remove all items from the scale first. Continue?")) return;
    setHwLoading(true);
    await fetch('http://localhost:3001/hardware/tare', { method: 'POST' });
    setHwLoading(false);
    fetchHwStatus();
  };

  const handleCalibrate = async () => {
    const weightKg = parseFloat(knownWeight);
    if (!weightKg || isNaN(weightKg)) return alert("Please enter a valid weight in grams.");

    setHwLoading(true);
    await fetch('http://localhost:3001/hardware/calibrate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ knownWeight: weightKg / 1000.0 })
    });
    setHwLoading(false);
    setKnownWeight('');
    fetchHwStatus();
  };

  const handleGrade = async () => {
    if (!file) return;

    setLoading(true);
    setError(null);

    const formData = new FormData();
    formData.append('image', file);

    try {
      const response = await fetch('http://localhost:3001/predict-multi', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error('Prediction failed');
      }

      const data = await response.json();
      setResult(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="app-shell">
      {/* Top Navigation Bar */}
      <header className="app-topbar">
        <div className="topbar-left">
          <span className="logo-icon">🌶️</span>
          <div className="start-group">
            <span className="logo-text">Smart Pepper</span>
            <span className="divider">/</span>
            <span className="page-title">Quality Control Station</span>
          </div>
        </div>

        <div className="topbar-right">
          <div className={`status-pill ${hwStatus.offline ? 'offline' : 'online'}`}>
            <span className="status-dot"></span>
            {hwStatus.offline ? 'Hardware Offline' : 'System Online'}
          </div>
          <div className="user-profile">
            <span className="user-initials">AD</span>
          </div>
        </div>
      </header>

      {/* Main Workspace */}
      <main className="main-workspace">
        <div className="workspace-grid">

          {/* Left Panel: Inspection & Results */}
          <div className="panel inspection-panel">
            <div className="panel-header">
              <h3>Inspection</h3>
            </div>

            <div className="panel-body">
              <div className="upload-zone">
                <input
                  type="file"
                  accept="image/*"
                  onChange={handleFileChange}
                  id="file-upload"
                  className="file-input"
                />
                <label htmlFor="file-upload" className="upload-label">
                  {file ? (
                    <div className="file-info">
                      <span className="file-name">{file.name}</span>
                      <span className="link">Change File</span>
                    </div>
                  ) : (
                    <div className="upload-placeholder">
                      <span>Click or Drag Image Here</span>
                    </div>
                  )}
                </label>
              </div>

              {preview && (
                <div className="preview-frame">
                  <img src={preview} alt="Inspection Preview" />
                </div>
              )}

              <div className="action-area">
                <button
                  onClick={handleGrade}
                  disabled={!file || loading}
                  className="btn-primary"
                >
                  {loading ? 'Processing...' : 'Analyze Quality'}
                </button>
              </div>
            </div>

            {error && <div className="error-banner">{error}</div>}

            {result && (
              <div className="results-section">
                <div className="result-header-simple">
                  <span className="seeds-count">{result.totalSeeds}</span>
                  <span className="seeds-label">Seeds Detected</span>
                </div>

                <div className="breakdown-section">
                  <h4>Quality Breakdown</h4>
                  <div className="breakdown-bars">
                    {result.labels && result.labels.map((label) => {
                      const data = result.breakdown[label] || { count: 0, percent: 0 };
                      return (
                        <div key={label} className="breakdown-bar-row">
                          <span className="bar-label">{label}</span>
                          <div className="bar-track">
                            <div className="bar-fill" style={{ width: `${data.percent}%` }}></div>
                          </div>
                          <span className="bar-stats">{data.count} ({data.percent}%)</span>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Right Panel: Machine Control */}
          <div className="panel control-panel">
            <div className="panel-header">
              <h3>Machine Control</h3>
              <div className={`status-indicator ${localRunning ? 'active' : 'idle'}`}>
                {localRunning ? 'RUNNING' : 'STOPPED'}
              </div>
            </div>

            <div className="panel-body">
              <div className="kpi-card">
                <span className="kpi-label">Current Weight</span>
                <div className="kpi-value-row">
                  <span className="kpi-number">{hwStatus.offline ? '--' : hwStatus.weight?.toFixed(3)}</span>
                  <span className="kpi-unit">kg</span>
                </div>
                <button
                  className="btn-capture"
                  onClick={handleCaptureWeight}
                  disabled={hwStatus.offline}
                >
                  Capture Weight
                </button>

                {capturedWeight !== null && (
                  <div className="weight-grade-result">
                    <div className="captured-weight">
                      <span className="cap-label">Captured:</span>
                      <span className="cap-value">{(capturedWeight * 1000).toFixed(0)}g</span>
                    </div>
                    <div className={`grade-badge grade-${weightGrade?.replace(' ', '-').toLowerCase()}`}>
                      {weightGrade}
                    </div>
                  </div>
                )}
              </div>

              <div className="control-section">
                <div className="control-item">
                  <label>Motor State</label>
                  <button
                    onClick={handleToggleRun}
                    className={`btn-block ${localRunning ? 'stop' : 'start'}`}
                    disabled={hwStatus.offline}
                  >
                    {localRunning ? 'Stop Conveyor' : 'Start Conveyor'}
                  </button>
                </div>

                <div className="control-item">
                  <label>Belt Speed</label>
                  <div className="slider-container">
                    <input
                      type="range"
                      min="200"
                      max="2000"
                      step="50"
                      value={localSpeed}
                      onChange={handleSpeedChange}
                      onMouseUp={handleSpeedCommit}
                      onTouchEnd={handleSpeedCommit}
                      disabled={hwStatus.offline}
                    />
                    <div className="slider-labels">
                      <span>Fast</span>
                      <span>Slow</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Calibration (Collapsible) */}
              <div className="calibration-box">
                <div className="calib-header" onClick={() => setShowCalib(!showCalib)}>
                  <span>⚖️ Calibration</span>
                  <span className="toggle-icon">{showCalib ? '−' : '+'}</span>
                </div>

                {showCalib && (
                  <div className="calib-body">
                    <button onClick={handleTare} disabled={hwStatus.offline || hwLoading} className="btn-small outline">
                      Tare Scale
                    </button>
                    <div className="calib-input-group">
                      <input
                        type="number"
                        placeholder="Known Weight (g)"
                        value={knownWeight}
                        onChange={(e) => setKnownWeight(e.target.value)}
                        disabled={hwStatus.offline || hwLoading}
                      />
                      <button onClick={handleCalibrate} disabled={hwStatus.offline || hwLoading} className="btn-small solid">
                        Calibrate
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>

        </div>
      </main>
    </div>
  )
}

export default App
