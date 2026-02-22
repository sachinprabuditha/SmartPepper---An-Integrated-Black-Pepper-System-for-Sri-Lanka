import * as harvestService from '../services/harvest.service.js';

export const createSeason = async (req, res) => {
    try {
        const userId = req.user.nameid;
        const { farmId } = req.body;
        const result = await harvestService.createSeason(farmId, userId, req.body);
        res.status(201).json({ success: true, message: 'Harvest season created', data: result });
    } catch (error) {
        console.error('Create season error:', error);
        res.status(500).json({ success: false, message: 'Failed to create season' });
    }
};

export const getSeasons = async (req, res) => {
    try {
        const { farmId } = req.params;
        const result = await harvestService.getSeasons(farmId);
        res.status(200).json({ success: true, message: 'Seasons retrieved successfully', data: result });
    } catch (error) {
        console.error('Get seasons error:', error);
        res.status(500).json({ success: false, message: 'Failed to get seasons' });
    }
};

export const getSeasonsByUser = async (req, res) => {
    try {
        const { userId } = req.params;
        const result = await harvestService.getSeasonsByUser(userId);
        res.status(200).json({ success: true, message: 'Seasons retrieved successfully', data: result });
    } catch (error) {
        console.error('Get seasons by user error:', error);
        res.status(500).json({ success: false, message: 'Failed to get seasons for user' });
    }
};

export const createSession = async (req, res) => {
    try {
        const { seasonId } = req.body;
        const result = await harvestService.createSession(seasonId, req.body);
        res.status(201).json({ success: true, message: 'Harvest session recorded', data: result });
    } catch (error) {
        console.error('Create session error:', error);
        res.status(500).json({ success: false, message: 'Failed to record session' });
    }
};

export const getSessions = async (req, res) => {
    try {
        const { seasonId } = req.params;
        const result = await harvestService.getSessions(seasonId);
        res.status(200).json({ success: true, message: 'Sessions retrieved successfully', data: result });
    } catch (error) {
        console.error('Get sessions error:', error);
        res.status(500).json({ success: false, message: 'Failed to get sessions' });
    }
};

export const getSeasonById = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await harvestService.getSeasonById(id);
        res.status(200).json({ success: true, message: 'Season retrieved successfully', data: result });
    } catch (error) {
        if (error.message === 'Season not found') {
            return res.status(404).json({ success: false, message: error.message });
        }
        console.error('Get season error:', error);
        res.status(500).json({ success: false, message: 'Failed to get season' });
    }
};

export const endSeason = async (req, res) => {
    try {
        const userId = req.user.nameid;
        const { id } = req.params;
        const result = await harvestService.endSeason(id, userId);
        res.status(200).json({ success: true, message: 'Season ended successfully', data: result });
    } catch (error) {
        if (error.message === 'Season not found') {
            return res.status(404).json({ success: false, message: error.message });
        }
        if (error.message === 'Unauthorized access to season') {
            return res.status(403).json({ success: false, message: error.message });
        }
        console.error('End season error:', error);
        res.status(500).json({ success: false, message: 'Failed to end season' });
    }
};

export const updateSeason = async (req, res) => {
    try {
        const userId = req.user.nameid;
        const { id } = req.params;
        const result = await harvestService.updateSeason(id, userId, req.body);
        res.status(200).json({ success: true, message: 'Season updated successfully', data: result });
    } catch (error) {
        if (error.message === 'Season not found') {
            return res.status(404).json({ success: false, message: error.message });
        }
        if (error.message === 'Unauthorized access to season') {
            return res.status(403).json({ success: false, message: error.message });
        }
        console.error('Update season error:', error);
        res.status(500).json({ success: false, message: 'Failed to update season' });
    }
};

export const getSessionById = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await harvestService.getSessionById(id);
        res.status(200).json({ success: true, message: 'Session retrieved successfully', data: result });
    } catch (error) {
        if (error.message === 'Session not found') {
            return res.status(404).json({ success: false, message: error.message });
        }
        console.error('Get session error:', error);
        res.status(500).json({ success: false, message: 'Failed to get session' });
    }
};

export const updateSession = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await harvestService.updateSession(id, req.body);
        res.status(200).json({ success: true, message: 'Session updated successfully', data: result });
    } catch (error) {
        if (error.message === 'Session not found') {
            return res.status(404).json({ success: false, message: error.message });
        }
        console.error('Update session error:', error);
        res.status(500).json({ success: false, message: 'Failed to update session' });
    }
};

export const deleteSession = async (req, res) => {
    try {
        const { id } = req.params;
        await harvestService.deleteSession(id);
        res.status(200).json({ success: true, message: 'Session deleted successfully' });
    } catch (error) {
        if (error.message === 'Session not found') {
            return res.status(404).json({ success: false, message: error.message });
        }
        console.error('Delete session error:', error);
        res.status(500).json({ success: false, message: 'Failed to delete session' });
    }
};
