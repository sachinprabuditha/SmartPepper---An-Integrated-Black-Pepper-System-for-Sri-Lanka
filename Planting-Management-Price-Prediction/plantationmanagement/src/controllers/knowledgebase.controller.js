import { KnowledgeBaseService } from "../services/knowledgebase.service.js";

export const KnowledgeBaseController = {
    uploadFile: async (req, res) => {
        try {
            if (!req.files || req.files.length === 0) {
                return res.status(400).json({ status: "error", message: "No files uploaded" });
            }
            res.status(200).json({ status: "success", message: `Uploaded ${req.files.length} documents` });
        } catch (error) {
            console.error("Upload error:", error);
            res.status(500).json({ status: "error", message: error.message });
        }
    },

    getStatus: async (req, res) => {
        try {
            const status = await KnowledgeBaseService.getStatus();
            res.status(200).json({ status: "success", data: status });
        } catch (error) {
            res.status(500).json({ status: "error", message: error.message });
        }
    },

    getFiles: async (req, res) => {
        try {
            const files = await KnowledgeBaseService.getFiles();
            res.status(200).json({ status: "success", data: files });
        } catch (error) {
            res.status(500).json({ status: "error", message: error.message });
        }
    },

    processStep: async (req, res) => {
        const { step } = req.params;
        const { targetFiles } = req.body; // Array of filenames to process

        try {
            let logs = [];
            switch (step) {
                case "extract":
                    logs = await KnowledgeBaseService.extractText(targetFiles);
                    break;
                case "clean":
                    logs = await KnowledgeBaseService.cleanExtracted(targetFiles);
                    break;
                case "chunk":
                    logs = await KnowledgeBaseService.chunkCleaned(targetFiles);
                    break;
                case "index":
                    logs = await KnowledgeBaseService.indexToQdrant(targetFiles);
                    break;
                default:
                    return res.status(400).json({ status: "error", message: "Invalid step" });
            }
            res.status(200).json({ status: "success", logs });
        } catch (error) {
            res.status(500).json({ status: "error", message: error.message });
        }
    },

    deleteFile: async (req, res) => {
        const { filename } = req.params;
        try {
            const logs = await KnowledgeBaseService.deleteFile(filename);
            res.status(200).json({ status: "success", logs });
        } catch (error) {
            res.status(500).json({ status: "error", message: error.message });
        }
    },

    setupCollection: async (req, res) => {
        try {
            const logs = await KnowledgeBaseService.setupCollection();
            res.status(200).json({ status: "success", logs });
        } catch (error) {
            res.status(500).json({ status: "error", message: error.message });
        }
    },

    testConnection: async (req, res) => {
        try {
            const logs = await KnowledgeBaseService.testConnection();
            res.status(200).json({ status: "success", logs });
        } catch (error) {
            res.status(500).json({ status: "error", message: error.message });
        }
    },

    testSearch: async (req, res) => {
        const { query } = req.body;
        if (!query) return res.status(400).json({ status: "error", message: "Query is required" });
        try {
            const logs = await KnowledgeBaseService.search(query);
            res.status(200).json({ status: "success", logs });
        } catch (error) {
            res.status(500).json({ status: "error", message: error.message });
        }
    }
};
