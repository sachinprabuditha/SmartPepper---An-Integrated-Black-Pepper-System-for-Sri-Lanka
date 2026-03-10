import onnx from 'onnxruntime-node';

const modelPath = 'src/models/multi_output_regressor_model.onnx';

async function testModel() {
    try {
        const session = await onnx.InferenceSession.create(modelPath);
        console.log("Input Names:", session.inputNames);
        const inputName = session.inputNames[0];

        // Try getting input info
        console.log("Input Info:", JSON.stringify(session.handler));

        // Let's try inserting different lengths to see the error message
        for (let len = 8; len <= 20; len++) {
            try {
                const tensor = new onnx.Tensor('float32', new Float32Array(len), [1, len]);
                await session.run({ [inputName]: tensor });
                console.log("SUCCESS WITH LENGTH:", len);
            } catch (e) {
                // Ignore errors
                if (!e.message.includes("Got invalid dimensions")) {
                    console.log("Error logic mapping for length:", len, e.message);
                }
            }
        }

    } catch (err) {
        console.error("Error loading model:", err);
    }
}
testModel();
