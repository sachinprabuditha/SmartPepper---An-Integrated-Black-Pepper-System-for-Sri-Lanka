const express = require('express');
const router = express.Router();
const logger = require('../utils/logger');
const notificationService = require('../services/notificationService');
const { authenticate } = require('../middleware/auth');

/**
 * GET /api/notifications
 * Get user notifications
 */
router.get('/', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    const limit = parseInt(req.query.limit) || 50;
    const unreadOnly = req.query.unreadOnly === 'true';

    // Fetch notifications from Firestore
    const notifications = await notificationService.getNotifications(userId, limit, unreadOnly);
    const unreadCount = await notificationService.getUnreadCount(userId);

    res.json({
      success: true,
      notifications,
      unreadCount
    });
  } catch (error) {
    logger.error('Error fetching notifications:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch notifications'
    });
  }
});

/**
 * POST /api/notifications/mark-read
 * Mark notifications as read
 */
router.post('/mark-read', authenticate, async (req, res) => {
  try {
    const { notificationIds } = req.body;
    
    if (!notificationIds || !Array.isArray(notificationIds) || notificationIds.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'notificationIds array is required'
      });
    }

    await notificationService.markAsRead(notificationIds);

    res.json({
      success: true,
      message: 'Notifications marked as read'
    });
  } catch (error) {
    logger.error('Error marking notifications as read:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to mark notifications as read'
    });
  }
});

/**
 * GET /api/notifications/unread-count
 * Get count of unread notifications
 */
router.get('/unread-count', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    const unreadCount = await notificationService.getUnreadCount(userId);

    res.json({
      success: true,
      unreadCount
    });
  } catch (error) {
    logger.error('Error getting unread count:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get unread count'
    });
  }
});

module.exports = router;
