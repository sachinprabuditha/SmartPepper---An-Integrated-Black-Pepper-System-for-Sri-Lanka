import * as agronomyService from '../services/agronomy.service.js';
import * as componentService from '../services/component.service.js';

export const getGuides = async (req, res) => {
    try {
        const { districtId, soilTypeId, varietyId } = req.query;
        // Temporary: this still uses the old agronomyService which hits Postgres for Guides
        // We will migrate this in the next step
        const result = await agronomyService.getGuides(districtId, soilTypeId, varietyId);
        res.status(200).json({ success: true, message: 'Guides retrieved successfully', data: result });
    } catch (error) {
        console.error('Get guides error:', error);
        res.status(500).json({ success: false, message: 'Failed to retrieve agronomy guides' });
    }
};

export const getTemplates = async (req, res) => {
    try {
        const result = await agronomyService.getTemplates();
        res.status(200).json({ success: true, data: result });
    } catch (error) {
        console.error('Get templates error:', error);
        res.status(500).json({ success: false, message: 'Failed to retrieve agronomy templates' });
    }
};



export const getDistricts = async (req, res) => {
    try {
        const result = await componentService.getAllDistricts();
        res.status(200).json({ success: true, message: 'Districts retrieved successfully', data: result });
    } catch (error) {
        console.error('Get districts error:', error);
        res.status(500).json({ success: false, message: 'Failed to retrieve districts' });
    }
};

export const getSoilTypes = async (req, res) => {
    try {
        const result = await componentService.getAllSoilTypes();
        res.status(200).json({ success: true, message: 'Soil types retrieved successfully', data: result });
    } catch (error) {
        console.error('Get soil types error:', error);
        res.status(500).json({ success: false, message: 'Failed to retrieve soil types' });
    }
};

export const getSoilsByDistrict = async (req, res) => {
    try {
        const { districtId } = req.params;
        const result = await componentService.getSoilsForDistrict(districtId);
        res.status(200).json({ success: true, message: 'Soil types for district retrieved successfully', data: result });
    } catch (error) {
        console.error('Get soils by district error:', error);
        res.status(500).json({ success: false, message: 'Failed to retrieve soil types for district' });
    }
};

export const getVarietiesByContext = async (req, res) => {
    try {
        const { districtId, soilTypeId } = req.params;
        // Similar to above, relationship is complex. 
        // Returning all varieties for now as valid candidates.
        const result = await componentService.getAllVarieties();
        res.status(200).json({ success: true, message: 'Varieties retrieved successfully', data: result });
    } catch (error) {
        console.error('Get varieties by context error:', error);
        res.status(500).json({ success: false, message: 'Failed to retrieve varieties for context' });
    }
};

export const getVarieties = async (req, res) => {
    try {
        const result = await componentService.getAllVarieties();
        res.status(200).json({ success: true, message: 'Varieties retrieved successfully', data: result });
    } catch (error) {
        console.error('Get varieties error:', error);
        res.status(500).json({ success: false, message: 'Failed to retrieve pepper varieties' });
    }
};
