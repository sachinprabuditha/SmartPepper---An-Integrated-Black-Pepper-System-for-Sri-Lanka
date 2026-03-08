
import { db } from '../config/firebase.js';

export const createSeason = async (farmId, userId, seasonData) => {
    // Verify farm ownership or existence? 
    // Ideally yes, but for speed we might trust the input or rely on security rules (which we don't have yet)
    // Let's assume farmId is valid or check it if we want to be strict.

    // We strictly need to ensure the user owns the farm
    const farmRef = db.collection('farms').doc(farmId);
    const farmDoc = await farmRef.get();
    if (!farmDoc.exists) throw new Error('Farm not found');
    if (farmDoc.data().userId !== userId) throw new Error('Unauthorized access to farm');

    const seasonsRef = farmRef.collection('seasons');
    const docRef = seasonsRef.doc();

    const newSeason = {
        id: docRef.id,
        farmId: farmId,
        seasonName: seasonData.seasonName || 'New Season',
        startMonth: seasonData.startMonth || new Date().getMonth() + 1,
        startYear: seasonData.startYear || new Date().getFullYear(),
        endMonth: seasonData.endMonth || null,
        endYear: seasonData.endYear || null,
        createdBy: userId,
        status: 'Active', // Default status
        createdAt: new Date()
    };

    await docRef.set(newSeason);
    return newSeason;
};

export const getSeasons = async (farmId) => {
    const snapshot = await db.collection('farms').doc(farmId).collection('seasons')
        .orderBy('startYear', 'desc')
        .orderBy('startMonth', 'desc')
        .get();

    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const getSeasonsByUser = async (userId) => {
    // Get all farms for user to avoid collectionGroup index requirement
    const farmsSnapshot = await db.collection('farms')
        .where('userId', '==', userId)
        .get();

    if (farmsSnapshot.empty) {
        return [];
    }

    const seasons = [];

    // Fetch seasons for each farm
    const checkPromises = farmsSnapshot.docs.map(async (farmDoc) => {
        const seasonsSnap = await farmDoc.ref.collection('seasons').get();
        seasonsSnap.forEach(doc => {
            seasons.push({ id: doc.id, ...doc.data() });
        });
    });

    await Promise.all(checkPromises);

    // Sort descending by startYear, then startMonth
    seasons.sort((a, b) => {
        if (a.startYear !== b.startYear) return (b.startYear || 0) - (a.startYear || 0);
        return (b.startMonth || 0) - (a.startMonth || 0);
    });

    return seasons;
};

const findSeasonInUserFarms = async (userId, seasonId) => {
    const farmsSnapshot = await db.collection('farms').where('userId', '==', userId).get();
    if (farmsSnapshot.empty) return null;

    const checkPromises = farmsSnapshot.docs.map(async (farmDoc) => {
        const seasonDocRef = farmDoc.ref.collection('seasons').doc(seasonId);
        const seasonSnap = await seasonDocRef.get();
        return seasonSnap.exists ? seasonSnap : null;
    });

    const results = await Promise.all(checkPromises);
    const found = results.find(snap => snap !== null);

    if (!found) throw new Error('Season not found');
    return found;
};

export const getSeasonById = async (seasonId, userId) => {
    const doc = await findSeasonInUserFarms(userId, seasonId);
    return { id: doc.id, ...doc.data() };
};

export const createSession = async (seasonId, userId, sessionData) => {
    const seasonDoc = await findSeasonInUserFarms(userId, seasonId);

    const sessionsRef = seasonDoc.ref.collection('sessions');
    const docRef = sessionsRef.doc();

    const newSession = {
        id: docRef.id,
        seasonId: seasonId,
        sessionName: sessionData.sessionName || 'New Session',
        date: sessionData.date ? new Date(sessionData.date) : new Date(),
        yieldKg: sessionData.yieldKg || 0,
        areaHarvested: sessionData.areaHarvested || 0,
        notes: sessionData.notes || '',
        createdAt: new Date()
    };

    await docRef.set(newSession);
    return newSession;
};

export const getSessions = async (seasonId, userId) => {
    const seasonDoc = await findSeasonInUserFarms(userId, seasonId);

    const snapshot = await seasonDoc.ref.collection('sessions')
        .orderBy('date', 'desc')
        .get();

    return snapshot.docs.map(doc => {
        const data = doc.data();
        return {
            id: doc.id,
            ...data,
            date: data.date.toDate ? data.date.toDate() : data.date
        };
    });
};

export const endSeason = async (seasonId, userId) => {
    const seasonDoc = await findSeasonInUserFarms(userId, seasonId);
    const data = seasonDoc.data();

    if (data.createdBy !== userId) {
        throw new Error('Unauthorized access to season');
    }

    const now = new Date();
    const updateData = {
        endMonth: now.getMonth() + 1,
        endYear: now.getFullYear(),
        status: 'season-end'
    };

    await seasonDoc.ref.update(updateData);
    return { ...data, ...updateData };
};

export const updateSeason = async (seasonId, userId, updateData) => {
    const seasonDoc = await findSeasonInUserFarms(userId, seasonId);
    const data = seasonDoc.data();

    if (data.createdBy !== userId) {
        throw new Error('Unauthorized access to season');
    }

    await seasonDoc.ref.update(updateData);
    return { ...data, ...updateData };
};

const findSessionInUserFarms = async (userId, sessionId) => {
    const farmsSnapshot = await db.collection('farms').where('userId', '==', userId).get();
    if (farmsSnapshot.empty) return null;

    const checkPromises = farmsSnapshot.docs.map(async (farmDoc) => {
        const seasonsSnap = await farmDoc.ref.collection('seasons').get();

        const sessionPromises = seasonsSnap.docs.map(async (seasonDoc) => {
            const sessionDocRef = seasonDoc.ref.collection('sessions').doc(sessionId);
            const sessionSnap = await sessionDocRef.get();
            return sessionSnap.exists ? sessionSnap : null;
        });

        const sessionResults = await Promise.all(sessionPromises);
        return sessionResults.find(snap => snap !== null) || null;
    });

    const results = await Promise.all(checkPromises);
    const found = results.find(snap => snap !== null);

    if (!found) throw new Error('Session not found');
    return found;
};

export const getSessionById = async (sessionId, userId) => {
    const doc = await findSessionInUserFarms(userId, sessionId);
    const data = doc.data();
    return {
        id: doc.id,
        ...data,
        date: data.date.toDate ? data.date.toDate() : data.date
    };
};

export const updateSession = async (sessionId, userId, updateData) => {
    const sessionDoc = await findSessionInUserFarms(userId, sessionId);
    // TODO: Add ownership check by traversing up to season->farm if needed. 
    // Skipping for now as strict parity with old code (which didn't check user explicitly in updateSession service, 
    // though controller might not have passed user).

    await sessionDoc.ref.update(updateData);
    return { ...sessionDoc.data(), ...updateData };
};

export const deleteSession = async (sessionId, userId) => {
    const sessionDoc = await findSessionInUserFarms(userId, sessionId);
    await sessionDoc.ref.delete();
    return true;
};
export const deleteSeason = async (seasonId, userId) => {
    const seasonDoc = await findSeasonInUserFarms(userId, seasonId);
    
    // 1. Delete all sessions within this season first
    const sessionsSnap = await seasonDoc.ref.collection('sessions').get();
    const deletePromises = sessionsSnap.docs.map(doc => doc.ref.delete());
    await Promise.all(deletePromises);

    // 2. Delete the season document
    await seasonDoc.ref.delete();
    return true;
};
