
import dotenv from 'dotenv';
dotenv.config();

import { db } from '../src/config/firebase.js';
import { PepperKnowledge } from '../src/models/index.js';
import * as authService from '../src/services/auth.service.js';
import * as farmService from '../src/services/farm.service.js';
import * as chatService from '../src/services/chat.service.js';

const runVerification = async () => {
    console.log("---------------------------------------------------------");
    console.log("🚀 Starting Hybrid Migration Verification");
    console.log("---------------------------------------------------------");

    let userId = null;
    let farmId = null;

    try {
        // 1. Verify Firestore Connection & Auth
        console.log("\n1️⃣  Testing Firestore Auth...");
        const email = `test.user.${Date.now()}@example.com`;
        const user = await authService.signUp({
            email,
            password: 'password123',
            fullName: 'Test User',
            phoneNumber: '0771234567'
        });
        console.log(`✅ User created: ${user.email} (ID: ${user.userId})`);
        userId = user.userId;

        // 2. Verify Farm Creation (Firestore)
        console.log("\n2️⃣  Testing Farm Creation...");
        const farm = await farmService.createFarm(userId, {
            farmName: 'Hybrid Test Farm',
            districtId: '1', // Assuming ID 1 exists or using arbitrary string
            soilTypeId: '1',
            chosenVarietyId: 'var_kuching',
            farmStartDate: new Date(),
            areaHectares: 1.5,
            totalVines: 500
        });
        console.log(`✅ Farm created: ${farm.farmName} (ID: ${farm.id})`);
        farmId = farm.id;

        // 3. Verify Tasks Generation (Sub-collection)
        console.log("\n3️⃣  Verifying Task Generation...");
        const tasks = await farmService.getTasksByFarmId(farmId, userId);
        if (tasks.length > 0) {
            console.log(`✅ Tasks generated: ${tasks.length} tasks found.`);
            console.log(`   Sample Task: ${tasks[0].taskName}`);
        } else {
            console.warn("⚠️  No tasks generated. Check template availability?");
        }

        // 4. Verify PostgreSQL functionality (RAG)
        console.log("\n4️⃣  Testing PostgreSQL Connection (RAG)...");
        try {
            const count = await PepperKnowledge.count();
            console.log(`✅ PostgreSQL connected. PepperKnowledge count: ${count}`);
        } catch (dbError) {
            console.error("❌ PostgreSQL Error:", dbError.message);
        }

        // 5. Verify Hybrid Chat
        console.log("\n5️⃣  Testing Hybrid Chat Service...");
        try {
            // Using the farm we just created as context
            const response = await chatService.processMessage(userId, farmId, "How often should I water my vines?");
            console.log(`✅ Chat Response: ${response.reply.substring(0, 100)}...`);
            console.log(`   Sources: ${response.sources.join(', ')}`);
        } catch (chatError) {
            console.error("❌ Chat Error:", chatError.message);
        }

        // Cleanup (Optional - strict cleanup might fail if strict rules apply)
        console.log("\n🧹 Cleaning up...");
        await farmService.deleteFarm(farmId, userId);
        console.log("✅ Farm deleted (Manual Cascade Check required via Console)");

    } catch (error) {
        console.error("\n❌ Verification Failed:", error);
    } finally {
        console.log("\n---------------------------------------------------------");
        console.log("🏁 Verification Complete");
        console.log("---------------------------------------------------------");
        process.exit(0);
    }
};

runVerification();
