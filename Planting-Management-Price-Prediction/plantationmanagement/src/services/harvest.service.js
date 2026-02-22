
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
        seasonName: seasonData.seasonName,
        startMonth: seasonData.startMonth,
        startYear: seasonData.startYear,
        endMonth: seasonData.endMonth,
        endYear: seasonData.endYear,
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
    // Collection Group Query
    // Requires index on 'createdBy'
    const snapshot = await db.collectionGroup('seasons')
        .where('createdBy', '==', userId)
        .orderBy('startYear', 'desc')
        .orderBy('startMonth', 'desc')
        .get();

    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

const findSeasonDoc = async (seasonId) => {
    const snapshot = await db.collectionGroup('seasons').where('id', '==', seasonId).limit(1).get();
    if (snapshot.empty) throw new Error('Season not found');
    return snapshot.docs[0];
};

export const getSeasonById = async (seasonId) => {
    const doc = await findSeasonDoc(seasonId);
    return { id: doc.id, ...doc.data() };
};

export const createSession = async (seasonId, sessionData) => {
    const seasonDoc = await findSeasonDoc(seasonId);

    const sessionsRef = seasonDoc.ref.collection('sessions');
    const docRef = sessionsRef.doc();

    const newSession = {
        id: docRef.id,
        seasonId: seasonId,
        sessionName: sessionData.sessionName,
        date: new Date(sessionData.date),
        yieldKg: sessionData.yieldKg,
        areaHarvested: sessionData.areaHarvested,
        notes: sessionData.notes,
        createdAt: new Date()
    };

    await docRef.set(newSession);
    return newSession;
};

export const getSessions = async (seasonId) => {
    const seasonDoc = await findSeasonDoc(seasonId);

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
    const seasonDoc = await findSeasonDoc(seasonId);
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
    const seasonDoc = await findSeasonDoc(seasonId);
    const data = seasonDoc.data();

    if (data.createdBy !== userId) {
        throw new Error('Unauthorized access to season');
    }

    await seasonDoc.ref.update(updateData);
    return { ...data, ...updateData };
};

const findSessionDoc = async (sessionId) => {
    const snapshot = await db.collectionGroup('sessions').where('id', '==', sessionId).limit(1).get();
    if (snapshot.empty) throw new Error('Session not found');
    return snapshot.docs[0];
};

export const getSessionById = async (sessionId) => {
    const doc = await findSessionDoc(sessionId);
    const data = doc.data();
    return {
        id: doc.id,
        ...data,
        date: data.date.toDate ? data.date.toDate() : data.date
    };
};

export const updateSession = async (sessionId, updateData) => {
    const sessionDoc = await findSessionDoc(sessionId);
    // TODO: Add ownership check by traversing up to season->farm if needed. 
    // Skipping for now as strict parity with old code (which didn't check user explicitly in updateSession service, 
    // though controller might not have passed user).

    await sessionDoc.ref.update(updateData);
    return { ...sessionDoc.data(), ...updateData };
};

export const deleteSession = async (sessionId) => {
    const sessionDoc = await findSessionDoc(sessionId);
    await sessionDoc.ref.delete();
    return true;
};
