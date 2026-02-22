
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
        // ... similar for others if critical. 
        // Skipping full enrichment for every list item to avoid N+1 reads loop delay, 
        // BUT current UI might expect it.
        // Let's assume we proceed without names or add simple lookups if strictly required by UI.
        // The original code included them. Let's try to include if feasible or denormalize in future.
        // For now: basic data.

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
        taskName: taskData.taskName,
        phase: taskData.phase || 'Maintenance',
        taskType: 'Manual',
        dueDate: new Date(taskData.dueDate),
        priority: taskData.priority || 'Medium',
        status: 'Scheduled',
        detailedSteps: taskData.detailedSteps || [],
        reasonWhy: taskData.reasonWhy,
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

    for (const template of templates) {
        // Sort Logic roughly same as SQL
        const timingMonths = template.timingMonthsAfterStarting || 0;
        let initialDueDate;

        if (timingMonths === 0) {
            initialDueDate = farmStartDate > now ? farmStartDate : now;
        } else {
            initialDueDate = new Date(farmStartDate);
            initialDueDate.setMonth(initialDueDate.getMonth() + timingMonths);
        }

        const detailedSteps = template.instructionalDetails
            ? template.instructionalDetails.split(/[\r\n]+/).filter(s => s.trim()).map(s => s.trim())
            : [];

        const docRef = tasksRef.doc();
        batch.set(docRef, {
            id: docRef.id,
            farmId: farmRecord.id,
            taskName: template.taskName,
            phase: template.phase || 'Maintenance',
            taskType: template.taskType,
            varietyKey: template.varietyKey,
            dueDate: initialDueDate,
            status: 'Scheduled',
            detailedSteps: detailedSteps,
            reasonWhy: '',
            isManual: false,
            priority: 'Medium',
            createdAt: now
        });
        taskCount++;
    }

    // Dry zone logic
    // Need to fetch district Name
    let districtName = '';
    if (farmRecord.districtId) {
        // We might have it in farmRecord if we enriched it, but here we passed the raw object
        // So fetch it
        const d = await db.collection('meta_districts').doc(String(farmRecord.districtId)).get();
        if (d.exists) districtName = d.data().name;
    }

    const dryZoneDistricts = ['Hambantota', 'Anuradhapura', 'Polonnaruwa', 'Kurunegala', 'Monaragala'];
    if (districtName && dryZoneDistricts.includes(districtName)) {
        const firstSeasonYear = farmStartDate.getMonth() < 2 ? farmStartDate.getFullYear() : farmStartDate.getFullYear() + 1;
        const summerMonths = [3, 4, 5]; // March-May

        for (const month of summerMonths) {
            const dueDate = new Date(Date.UTC(firstSeasonYear, month - 1, 15, 0, 0, 0));
            const docRef = tasksRef.doc();
            batch.set(docRef, {
                id: docRef.id,
                farmId: farmRecord.id,
                taskName: 'Summer Irrigation Check',
                phase: 'Maintenance',
                taskType: 'Irrigation',
                varietyKey: 'ALL',
                dueDate: dueDate,
                status: 'Scheduled',
                detailedSteps: [
                    'Inspect soil moisture at 15–20cm depth',
                    'If soil is dry and no rain in last 5 days, schedule supplementary irrigation',
                    'Check mulch cover around vines and repair any gaps'
                ],
                reasonWhy: 'Dry-zone',
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
