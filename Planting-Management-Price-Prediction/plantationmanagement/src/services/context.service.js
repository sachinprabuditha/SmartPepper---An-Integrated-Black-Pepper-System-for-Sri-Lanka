import District from '../models/District.js';
import PepperVariety from '../models/PepperVariety.js';

export const extractContext = async (message) => {
    const context = {
        districtName: null,
        varietyName: null,
        plantAgeMonths: null
    };

    const msgLower = message.toLowerCase();

    // 1. Extract District
    const districts = await District.findAll();
    for (const d of districts) {
        if (msgLower.includes(d.Name.toLowerCase())) {
            context.districtName = d.Name;
            break;
        }
    }

    // 2. Extract Variety
    const varieties = await PepperVariety.findAll();
    for (const v of varieties) {
        if (msgLower.includes(v.Name.toLowerCase())) {
            context.varietyName = v.Name;
            break;
        }
    }

    // 3. Extract Plant Age
    const monthMatch = msgLower.match(/(\d+)\s*month/);
    if (monthMatch) {
        context.plantAgeMonths = parseInt(monthMatch[1]);
    } else {
        const yearMatch = msgLower.match(/(\d+)\s*year/);
        if (yearMatch) {
            context.plantAgeMonths = parseInt(yearMatch[1]) * 12;
        }
    }

    return context;
};
