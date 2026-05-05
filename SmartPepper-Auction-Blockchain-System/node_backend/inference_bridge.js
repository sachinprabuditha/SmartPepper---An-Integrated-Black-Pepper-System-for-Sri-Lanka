const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const PYTHON_SCRIPT_PATH = path.join(__dirname, 'run_inference.py');

/**
 * Calls the Python inference script with the given image paths.
 * @param {string[]} imagePaths - Array of absolute paths to the uploaded images.
 * @param {string} timestamp - Timestamp for the analysis.
 * @returns {Promise<Object>} - The JSON result from the Python script.
 */
function runPythonInference(imagePaths, timestamp) {
    return new Promise((resolve, reject) => {
        // We pass the timestamp and then all the image paths
        const args = [PYTHON_SCRIPT_PATH, timestamp, ...imagePaths];

        // Spawn the python process. 
        // Note: Assuming 'python' is in the PATH and it refers to the correct environment.
        const pythonProcess = spawn('python', args);

        let outputData = '';
        let errorData = '';

        pythonProcess.stdout.on('data', (data) => {
            outputData += data.toString();
        });

        pythonProcess.stderr.on('data', (data) => {
            errorData += data.toString();
        });

        pythonProcess.on('close', (code) => {
            if (code !== 0) {
                console.error(`Python script exited with code ${code}`);
                console.error(`Stderr: ${errorData}`);
                const combinedOutput = [
                    errorData.trim() ? `stderr: ${errorData.trim()}` : null,
                    outputData.trim() ? `stdout: ${outputData.trim()}` : null,
                ].filter(Boolean).join(' | ');
                return reject(new Error(`Python inference failed: ${combinedOutput || 'no output captured'}`));
            }

            try {
                // The python script should print the final JSON result to stdout.
                // We might need to extract just the JSON part if there are other prints.
                // A safe way is to wrap the JSON in a specific marker or ensure it's the last line.
                const lines = outputData.trim().split('\n');
                const lastLine = lines[lines.length - 1];
                const result = JSON.parse(lastLine);
                resolve(result);
            } catch (err) {
                console.error("Failed to parse Python output:", err);
                console.error("Raw output was:", outputData);
                reject(new Error("Failed to parse Python inference result"));
            }
        });
    });
}

module.exports = {
    runPythonInference
};
