import * as farmService from '../services/farm.service.js';

export const createFarm = async (req, res) => {
    try {
        // Assuming user ID is attached to req.user by auth middleware
        const userId = req.user.nameid;

        // Validate inputs
        if (req.body.totalVines && req.body.totalVines > 2147483647) {
            return res.status(400).json({ success: false, message: 'Total vines cannot exceed 2,147,483,647' });
        }

        const result = await farmService.createFarm(userId, req.body);
        res.status(201).json({ success: true, message: 'Farm created successfully', data: result });
    } catch (error) {
        console.error('Create farm error:', error);
        res.status(500).json({ success: false, message: 'Failed to create farm' });
    }
};

export const getFarms = async (req, res) => {
    try {
        const userId = req.user.nameid;
        const result = await farmService.getFarms(userId);
        res.status(200).json({ success: true, message: 'Farms retrieved successfully', data: result });
    } catch (error) {
        console.error('Get farms error:', error);
        res.status(500).json({ success: false, message: 'Failed to retrieve farms' });
    }
};

export const getFarmById = async (req, res) => {
    try {
        const userId = req.user.nameid;
        const { id } = req.params;
        const result = await farmService.getFarmById(id, userId);
        res.status(200).json({ success: true, message: 'Farm retrieved successfully', data: result });
    } catch (error) {
        if (error.message === 'Farm not found') {
            return res.status(404).json({ success: false, message: error.message });
        }
        console.error('Get farm error:', error);
        res.status(500).json({ success: false, message: 'Failed to retrieve farm' });
    }
};

export const updateFarm = async (req, res) => {
    try {
        const userId = req.user.nameid;
        const { id } = req.params;
        const result = await farmService.updateFarm(id, userId, req.body);
        res.status(200).json({ success: true, message: 'Farm updated successfully', data: result });
    } catch (error) {
        if (error.message === 'Farm not found') {
            return res.status(404).json({ success: false, message: error.message });
        }
        console.error('Update farm error:', error);
        res.status(500).json({ success: false, message: 'Failed to update farm' });
    }
};

export const deleteFarm = async (req, res) => {
    try {
        const userId = req.user.nameid;
        const { id } = req.params;
        await farmService.deleteFarm(id, userId);
        res.status(200).json({ success: true, message: 'Farm deleted successfully' });
    } catch (error) {
        if (error.message === 'Farm not found') {
            return res.status(404).json({ success: false, message: error.message });
        }
        console.error('Delete farm error:', error);
        res.status(500).json({ success: false, message: 'Failed to delete farm' });
    }
};

export const getTasksByFarmId = async (req, res) => {
    try {
        const userId = req.user.nameid;
        const { farmId } = req.params;
        const result = await farmService.getTasksByFarmId(farmId, userId);
        res.status(200).json({ success: true, message: 'Tasks retrieved successfully', data: result });
    } catch (error) {
        if (error.message === 'Farm not found') {
            return res.status(404).json({ success: false, message: error.message });
        }
        console.error('Get tasks error:', error);
        res.status(500).json({ success: false, message: 'Failed to retrieve tasks' });
    }
};

export const completeTask = async (req, res) => {
    try {
        const userId = req.user.nameid;
        const { id } = req.params;
        const completionData = req.body;
        const result = await farmService.completeTask(id, userId, completionData);
        res.status(200).json({ success: true, message: 'Task completed successfully', data: result });
    } catch (error) {
        if (error.message === 'Task not found') {
            return res.status(404).json({ success: false, message: error.message });
        }
        if (error.message === 'Unauthorized access to task') {
            return res.status(403).json({ success: false, message: error.message });
        }
        console.error('Complete task error:', error);
        res.status(500).json({ success: false, message: 'Failed to complete task' });
    }
};

export const createManualTask = async (req, res) => {
    try {
        const userId = req.user.nameid;
        const result = await farmService.createManualTask(userId, req.body);
        res.status(201).json({ success: true, message: 'Manual task created successfully', data: result });
    } catch (error) {
        if (error.message === 'Farm not found') {
            return res.status(404).json({ success: false, message: error.message });
        }
        console.error('Create manual task error:', error);
        res.status(500).json({ success: false, message: 'Failed to create manual task' });
    }
};

export const updateTask = async (req, res) => {
    try {
        const userId = req.user.nameid;
        const { id } = req.params;
        const result = await farmService.updateTask(id, userId, req.body);
        res.status(200).json({ success: true, message: 'Task updated successfully', data: result });
    } catch (error) {
        if (error.message === 'Task not found') {
            return res.status(404).json({ success: false, message: error.message });
        }
        if (error.message === 'Unauthorized access to task') {
            return res.status(403).json({ success: false, message: error.message });
        }
        console.error('Update task error:', error);
        res.status(500).json({ success: false, message: 'Failed to update task' });
    }
};

export const deleteTask = async (req, res) => {
    try {
        const userId = req.user.nameid;
        const { id } = req.params;
        await farmService.deleteTask(id, userId);
        res.status(200).json({ success: true, message: 'Task deleted successfully' });
    } catch (error) {
        if (error.message === 'Task not found') {
            return res.status(404).json({ success: false, message: error.message });
        }
        if (error.message === 'Unauthorized access to task') {
            return res.status(403).json({ success: false, message: error.message });
        }
        console.error('Delete task error:', error);
        res.status(500).json({ success: false, message: 'Failed to delete task' });
    }
};
