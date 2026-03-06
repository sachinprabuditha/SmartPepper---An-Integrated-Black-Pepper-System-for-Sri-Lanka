
import { db } from '../config/firebase.js';
import * as agronomyService from './agronomy.service.js';
import * as componentService from './component.service.js';

export const createFarm = async (userId, farmData) => {
    const farmsRef = db.collection('farms');
    const docRef = farmsRef.doc();

    const now = new Date();
    const farmStartDate = new Date(farmData.farmStartDate);

    const newFarm = {
        id: docRef.id,
        userId: userId,
        farmName: farmData.farmName,
        districtId: farmData.districtId, // integer or string depending on master data
        soilTypeId: farmData.soilTypeId,
        chosenVarietyId: farmData.chosenVarietyId,
        farmStartDate: farmStartDate,
        areaHectares: farmData.areaHectares,
        totalVines: farmData.totalVines,
        createdAt: now,
        updatedAt: now
    };

    await docRef.set(newFarm);

    // Generate schedule
    try {
        console.log(`Starting schedule generation for farm ${docRef.id}`);
        await generateScheduleForFarm(newFarm);
        console.log(`Successfully generated schedule for farm ${docRef.id}`);
    } catch (error) {
        console.error(`Failed to generate schedule for farm ${docRef.id}:`, error);
    }

    return newFarm;
};

export const getFarms = async (userId) => {
    const snapshot = await db.collection('farms')
        .where('userId', '==', userId)
        .orderBy('createdAt', 'desc')
        .get();

    const farms = [];
    for (const doc of snapshot.docs) {
        const data = doc.data();
        // Enrich with master data names if possible/needed, or just return IDs.
        // The original controller returned names via include.
        // We will fetch names individually or relies on client to have master data.
        // Ideally we should do a reliable 'join' here or denormalize names.
        // For simplicity and performance, efficient fetches:

        let districtName = '';
        let soilTypeName = '';
        let varietyName = '';

        if (data.districtId) {
            // Optimization: In a real app, cache these or denormalize 'districtName' on farm creation
            // For now, we fetch.
            const dists = await db.collection('districts').doc(String(data.districtId)).get();
            if (dists.exists) districtName = dists.data().name;
        }
        if (data.soilTypeId) {
            const soils = await db.collection('soilTypes').doc(String(data.soilTypeId)).get();
            if (soils.exists) soilTypeName = soils.data().typeName || soils.data().name;
        }

        if (data.chosenVarietyId) {
            const varieties = await db.collection('pepperVarieties').doc(String(data.chosenVarietyId)).get();
            if (varieties.exists) varietyName = varieties.data().name;
        }

        farms.push({
            ...data,
            id: doc.id,
            // Convert timestamps back to Dates if needed by frontend JSON serialization
            farmStartDate: data.farmStartDate.toDate ? data.farmStartDate.toDate() : data.farmStartDate,
            createdAt: data.createdAt.toDate ? data.createdAt.toDate() : data.createdAt,
            District: { name: districtName }, // Mock structure to match old response partially
            SoilType: { typeName: soilTypeName },
            PepperVariety: { name: varietyName }
        });
    }
    return farms;
};

export const getFarmById = async (farmId, userId) => {
    const docRef = db.collection('farms').doc(farmId);
    const doc = await docRef.get();

    if (!doc.exists) {
        throw new Error('Farm not found');
    }

    const data = doc.data();
    if (data.userId !== userId) {
        throw new Error('Unauthorized access to farm');
    }

    // Enrich details
    let districtName = '';
    let soilTypeName = '';
    let varietyName = '';

    if (data.districtId) {
        const d = await db.collection('districts').doc(String(data.districtId)).get();
        if (d.exists) districtName = d.data().name;
    }
    if (data.soilTypeId) {
        const s = await db.collection('soilTypes').doc(String(data.soilTypeId)).get();
        if (s.exists) soilTypeName = s.data().typeName || s.data().name; // Handle both schemas
    }
    if (data.chosenVarietyId) {
        const v = await db.collection('pepperVarieties').doc(String(data.chosenVarietyId)).get();
        if (v.exists) varietyName = v.data().name;
    }

    return {
        ...data,
        id: doc.id,
        farmStartDate: data.farmStartDate.toDate ? data.farmStartDate.toDate() : data.farmStartDate,
        createdAt: data.createdAt.toDate ? data.createdAt.toDate() : data.createdAt,
        District: { name: districtName },
        SoilType: { typeName: soilTypeName },
        PepperVariety: { name: varietyName }
    };
};

export const updateFarm = async (farmId, userId, updateData) => {
    const docRef = db.collection('farms').doc(farmId);
    const doc = await docRef.get();

    if (!doc.exists) throw new Error('Farm not found');
    if (doc.data().userId !== userId) throw new Error('Unauthorized access to farm');

    // Remove undefined/nulls if necessary or just pass updateData
    await docRef.update({
        ...updateData,
        updatedAt: new Date()
    });

    return { id: farmId, ...updateData };
};

export const deleteFarm = async (farmId, userId) => {
    const docRef = db.collection('farms').doc(farmId);
    const doc = await docRef.get();

    if (!doc.exists) throw new Error('Farm not found');
    if (doc.data().userId !== userId) throw new Error('Unauthorized access to farm');

    // Manual Cascade: Delete Sub-collections (tasks, seasons)
    // 1. Delete Tasks
    const tasksSnapshot = await docRef.collection('tasks').get();
    const batch = db.batch();
    tasksSnapshot.docs.forEach((t) => {
        batch.delete(t.ref);
    });

    // 2. Delete Seasons (and their sessions)
    const seasonsSnapshot = await docRef.collection('seasons').get();
    // This might be too big for one batch if many seasons/tasks, but normally fine for individual farm delete.
    // For deep nested subcollections (sessions), we need to fetch them too.
    for (const seasonDoc of seasonsSnapshot.docs) {
        const sessionsSnapshot = await seasonDoc.ref.collection('sessions').get();
        sessionsSnapshot.docs.forEach(s => batch.delete(s.ref));
        batch.delete(seasonDoc.ref);
    }

    // 3. Delete Farm
    batch.delete(docRef);

    await batch.commit();
    return true;
};

// --- Tasks ---

export const getTasksByFarmId = async (farmId, userId) => {
    // Verify ownership
    await getFarmById(farmId, userId);

    const snapshot = await db.collection('farms').doc(farmId).collection('tasks')
        .orderBy('dueDate', 'asc')
        .get();

    return snapshot.docs.map(doc => {
        const data = doc.data();
        return {
            ...data,
            id: doc.id,
            dueDate: data.dueDate.toDate ? data.dueDate.toDate() : data.dueDate,
            dateCompleted: data.dateCompleted && data.dateCompleted.toDate ? data.dateCompleted.toDate() : data.dateCompleted,
            createdAt: data.createdAt.toDate ? data.createdAt.toDate() : data.createdAt
        };
    });
};

export const createManualTask = async (userId, taskData) => {
    await getFarmById(taskData.farmId, userId);

    const tasksRef = db.collection('farms').doc(taskData.farmId).collection('tasks');
    const docRef = tasksRef.doc();

    const newTask = {
        id: docRef.id,
        farmId: taskData.farmId,
        taskName: { en: taskData.taskName, si: taskData.taskName },
        phase: taskData.phase || 'Maintenance',
        taskType: 'Manual',
        dueDate: new Date(taskData.dueDate),
        priority: taskData.priority || 'Medium',
        status: 'Scheduled',
        detailedSteps: (taskData.detailedSteps || []).map(step => ({ en: step, si: step })),
        reasonWhy: taskData.reasonWhy ? { en: taskData.reasonWhy, si: taskData.reasonWhy } : null,
        isManual: true,
        createdAt: new Date()
    };

    await docRef.set(newTask);
    return newTask;
};

// Helper to find task without Collection Group Index
const findTaskInUserFarms = async (userId, taskId) => {
    // 1. Get all farms for user
    const farmsSnapshot = await db.collection('farms').where('userId', '==', userId).get();

    if (farmsSnapshot.empty) return null;

    // 2. Check each farm for the task
    // Since we know the taskId, we can directly construct the path if we knew the farmId.
    // Without farmId, we have to check each farm's tasks subcollection.
    // Optimization: We can check them in parallel.

    const checkPromises = farmsSnapshot.docs.map(async (farmDoc) => {
        const taskDocRef = farmDoc.ref.collection('tasks').doc(taskId);
        const taskSnap = await taskDocRef.get();
        return taskSnap.exists ? taskSnap : null;
    });

    const results = await Promise.all(checkPromises);
    const foundTaskSnap = results.find(snap => snap !== null);

    return foundTaskSnap || null;
};

export const completeTask = async (taskId, userId, completionData) => {
    const taskDoc = await findTaskInUserFarms(userId, taskId);

    if (!taskDoc) throw new Error('Task not found');

    const taskData = taskDoc.data();
    // Ownership verified by findTaskInUserFarms logic (only searched user's farms)

    const inputDetails = {
        notes: completionData.notes,
        laborHours: completionData.laborHours,
        items: completionData.items || [],
        completedAt: new Date().toISOString()
    };

    const updates = {
        status: 'Completed',
        dateCompleted: new Date(),
        inputDetails: inputDetails
    };

    await taskDoc.ref.update(updates);
    return { ...taskData, ...updates };
};

export const updateTask = async (taskId, userId, updateData) => {
    const taskDoc = await findTaskInUserFarms(userId, taskId);

    if (!taskDoc) throw new Error('Task not found');

    const taskData = taskDoc.data();

    await taskDoc.ref.update(updateData);
    return { ...taskData, ...updateData };
};

export const deleteTask = async (taskId, userId) => {
    const taskDoc = await findTaskInUserFarms(userId, taskId);

    if (!taskDoc) throw new Error('Task not found');

    await taskDoc.ref.delete();
    return true;
};

// --- Generator ---

async function generateScheduleForFarm(farmRecord) {
    console.log(`Starting schedule generation for farm ${farmRecord.id}`);

    const varietyKey = farmRecord.chosenVarietyId || 'ALL';
    const varietyKeysToQuery = varietyKey === 'ALL' ? ['ALL'] : [varietyKey, 'ALL'];

    const templates = await agronomyService.getTemplatesByVarietyKeys(varietyKeysToQuery);

    if (templates.length === 0) {
        console.warn('No templates found');
        return;
    }

    const farmStartDate = farmRecord.farmStartDate instanceof Date ? farmRecord.farmStartDate : farmRecord.farmStartDate.toDate();
    const now = new Date();
    const batch = db.batch();
    const tasksRef = db.collection('farms').doc(farmRecord.id).collection('tasks');

    let taskCount = 0;

    // Determine Climate Zone based on district
    const getClimateZone = (districtId) => {
        if (!districtId) return 'wet';
        const dryZone = ['hambantota', 'anuradhapura', 'polonnaruwa', 'monaragala', 'trincomalee', 'batticaloa', 'ampara', 'vavuniya', 'mannar', 'mullaitivu', 'kilinochchi', 'jaffna', 'puttalam'];
        const wetZone = ['colombo', 'gampaha', 'kalutara', 'galle', 'matara', 'ratnapura', 'kegalle'];
        const intermediateZone = ['kurunegala', 'matale', 'kandy', 'badulla', 'nuwara_eliya'];

        const id = districtId.toLowerCase();
        if (dryZone.includes(id)) return 'dry';
        if (wetZone.includes(id)) return 'wet';
        if (intermediateZone.includes(id)) return 'intermediate';
        return 'wet'; // Default
    };

    const climateZone = getClimateZone(farmRecord.districtId);
    const soilType = farmRecord.soilTypeId;

    for (const template of templates) {
        // Apply filters
        if (template.climateZones && Array.isArray(template.climateZones) && !template.climateZones.includes(climateZone)) {
            continue; // Skip if climate zone does not match
        }
        if (template.soilTypes && Array.isArray(template.soilTypes) && soilType && !template.soilTypes.includes(soilType)) {
            continue; // Skip if soil type does not match
        }

        const timingMonths = template.timingMonthsAfterStarting || 0;
        const repeatMonths = template.repeatEveryMonths;
        const priority = template.priority || 'Medium';

        // Instructional details as a localized object in an array
        const detailedSteps = template.instructionalDetails ? [template.instructionalDetails] : [];

        // Tasks generation iterations
        const maxMonths = 36; // Generate schedule for up to 3 years
        let iterations = [];

        if (repeatMonths && repeatMonths > 0) {
            for (let m = timingMonths; m <= maxMonths; m += repeatMonths) {
                iterations.push(m);
            }
        } else {
            iterations.push(timingMonths);
        }

        for (const m of iterations) {
            let dueDate;
            if (m === 0) {
                dueDate = farmStartDate > now ? new Date(farmStartDate) : new Date(now);
            } else {
                dueDate = new Date(farmStartDate);
                dueDate.setMonth(dueDate.getMonth() + m);
            }

            const docRef = tasksRef.doc();
            batch.set(docRef, {
                id: docRef.id,
                farmId: farmRecord.id,
                taskName: template.taskName, // Expected to be an object {en:..., si:...} based on new template
                phase: template.phase || 'Maintenance',
                taskType: template.taskType || 'Maintenance',
                varietyKey: template.varietyKey || varietyKey,
                dueDate: dueDate,
                status: 'Scheduled',
                detailedSteps: detailedSteps, // [{en:..., si:...}]
                reasonWhy: null,
                isManual: false,
                priority: priority,
                createdAt: now
            });
            taskCount++;
        }
    }

    // Extracted Dry Zone Summer Irrigation Logic
    if (climateZone === 'dry') {
        const firstSeasonYear = farmStartDate.getMonth() < 2 ? farmStartDate.getFullYear() : farmStartDate.getFullYear() + 1;
        const summerMonths = [3, 4, 5]; // March-May

        // Create localized detailed steps for the custom irrigation task
        const irrigationSteps = [
            {
                en: "Inspect soil moisture at 15–20cm depth",
                si: "සෙන්ටිමීටර 15-20ක් ගැඹුරට පසෙහි තෙතමනය පරීක්ෂා කරන්න"
            },
            {
                en: "If soil is dry and no rain in last 5 days, schedule supplementary irrigation",
                si: "පස වියළි නම් සහ පසුගිය දින 5 තුළ වැසි නොලැබුණේ නම්, අමතර ජලය සැපයීමට කටයුතු කරන්න"
            },
            {
                en: "Check mulch cover around vines and repair any gaps",
                si: "වැල් වටා ඇති මල්ච් ආවරණය පරීක්ෂා කර හිඩැස් ඇත්නම් පුරවන්න"
            }
        ];

        for (const month of summerMonths) {
            const dueDate = new Date(Date.UTC(firstSeasonYear, month - 1, 15, 0, 0, 0));
            const docRef = tasksRef.doc();
            batch.set(docRef, {
                id: docRef.id,
                farmId: farmRecord.id,
                taskName: { en: 'Summer Irrigation Check', si: 'ගිම්හාන ජලසම්පාදන පරීක්ෂාව' },
                phase: 'Maintenance',
                taskType: 'Irrigation',
                varietyKey: 'ALL',
                dueDate: dueDate,
                status: 'Scheduled',
                detailedSteps: irrigationSteps,
                reasonWhy: { en: 'Dry-zone', si: 'වියළි කාලාපය' }, // String or object? Better keep it consistent
                isManual: false,
                priority: 'High',
                createdAt: now
            });
            taskCount++;
        }
    }

    await batch.commit();
    console.log(`Generated ${taskCount} tasks for farm ${farmRecord.id}`);
}
