
import { db } from '../config/firebase.js';

// --- Districts ---
export const getAllDistricts = async () => {
    const snapshot = await db.collection('districts').get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const createDistrict = async (data) => {
    const docRef = db.collection('districts').doc(); // Auto ID or use custom if provided
    await docRef.set(data);
    return { id: docRef.id, ...data };
};

// --- Soil Types ---
export const getAllSoilTypes = async () => {
    const snapshot = await db.collection('soilTypes').get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const getSoilsForDistrict = async (districtId) => {
    const districtDoc = await db.collection('districts').doc(districtId).get();
    if (!districtDoc.exists) return [];

    const districtData = districtDoc.data();
    const soilTypeIds = districtData.soilTypes || []; // Array of strings e.g. ["loamy", "clay_loam"]

    if (soilTypeIds.length === 0) return [];

    // Fetch all soil types and filter (efficient for small master data)
    // Alternatively for large datasets, fetch by IDs individually
    const allSoilsSnapshot = await db.collection('soilTypes').get();
    const allSoils = allSoilsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

    return allSoils.filter(soil => soilTypeIds.includes(soil.id));
};

export const createSoilType = async (data) => {
    const docRef = db.collection('soilTypes').doc();
    await docRef.set(data);
    return { id: docRef.id, ...data };
};

// --- Varieties ---
export const getAllVarieties = async () => {
    const snapshot = await db.collection('pepperVarieties').get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const createVariety = async (data) => {
    // defined ID is preferred for varieties if they are keys (e.g. 'var_kuching')
    const id = data.id || db.collection('pepperVarieties').doc().id;
    const docRef = db.collection('pepperVarieties').doc(id);
    // remove id from data body if present to avoid duplication, or keep it. keeping it is fine.
    await docRef.set(data);
    return { id, ...data };
};

export const getVarietyById = async (id) => {
    const doc = await db.collection('pepperVarieties').doc(id).get();
    if (!doc.exists) return null;
    return { id: doc.id, ...doc.data() };
};
