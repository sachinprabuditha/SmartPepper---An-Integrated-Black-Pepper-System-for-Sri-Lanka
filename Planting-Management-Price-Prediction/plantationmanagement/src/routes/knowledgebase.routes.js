import express from "express";
import multer from "multer";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import { KnowledgeBaseController } from "../controllers/knowledgebase.controller.js";

const router = express.Router();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const RAW_DIR = path.join(__dirname, "../../rag_data/raw_docs");

// Ensure upload directory exists
if (!fs.existsSync(RAW_DIR)) {
    fs.mkdirSync(RAW_DIR, { recursive: true });
}

// Multer storage
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, RAW_DIR);
    },
    filename: (req, file, cb) => {
        cb(null, `${Date.now()}-${file.originalname}`);
    }
});

const upload = multer({ storage });

// Routes
router.post("/upload", upload.array("files"), KnowledgeBaseController.uploadFile);
router.get("/status", KnowledgeBaseController.getStatus);
router.get("/files", KnowledgeBaseController.getFiles);
router.delete("/files/:filename", KnowledgeBaseController.deleteFile);
router.post("/process/:step", KnowledgeBaseController.processStep);


// System Tools
router.post("/collection/setup", KnowledgeBaseController.setupCollection);
router.get("/collection/test", KnowledgeBaseController.testConnection);
router.post("/search", KnowledgeBaseController.testSearch);

export default router;
