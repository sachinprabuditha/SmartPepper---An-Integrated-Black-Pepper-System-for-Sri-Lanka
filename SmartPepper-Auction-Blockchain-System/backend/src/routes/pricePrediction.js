const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const logger = require('../utils/logger');

const db = admin.firestore();

/**
 * GET /api/price-predictions/latest
 * Get latest price predictions for all districts and grades
 * Query params: district (optional), grade (optional)
 */
router.get('/latest', async (req, res) => {
  try {
    const { district, grade } = req.query;

    logger.info('Fetching latest price predictions', { district, grade });

    // Build query
    let query = db.collection('daily_price_predictions');

    // Apply filters
    if (district) {
      query = query.where('district', '==', district);
    }

    if (grade) {
      query = query.where('grade', '==', grade);
    }

    // Get all predictions
    const snapshot = await query.get();

    if (snapshot.empty) {
      return res.json({
        success: true,
        predictions: [],
        message: 'No price predictions available'
      });
    }

    const predictions = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      predictions.push({
        id: doc.id,
        date: data.date,
        district: data.district,
        grade: data.grade,
        highestPrice: data.highest_price,
        averagePrice: data.average_price,
        usdRate: data.usd_rate,
        avgTemp30d: data.avg_temp_30d,
        rain30d: data.rain_30d,
        createdAt: data.created_at?.toDate?.()?.toISOString() || null
      });
    });

    // Get today's date
    const todayStr = new Date().toISOString().split('T')[0];
    
    // Filter for today's predictions
    const todaysPredictions = predictions.filter(p => p.date === todayStr);

    logger.info(`Found ${todaysPredictions.length} predictions for today`);

    res.json({
      success: true,
      predictions: todaysPredictions,
      total: todaysPredictions.length,
      queryDate: todayStr
    });
  } catch (error) {
    logger.error('Error fetching price predictions:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch price predictions',
      details: error.message
    });
  }
});

/**
 * GET /api/price-predictions/by-lot/:lotId
 * Get price prediction for a specific lot based on its district and quality grade
 */
router.get('/by-lot/:lotId', async (req, res) => {
  try {
    const { lotId } = req.params;

    logger.info('Fetching price prediction for lot:', lotId);

    // Get lot details
    const lotSnapshot = await db.collection('pepper_lots')
      .where('lot_id', '==', lotId)
      .limit(1)
      .get();

    if (lotSnapshot.empty) {
      return res.status(404).json({
        success: false,
        error: 'Lot not found'
      });
    }

    const lot = lotSnapshot.docs[0].data();
    const district = lot.origin; // District/origin of the lot
    const quality = lot.quality; // Quality grade (A, AA, AAA, etc.)

    // Map quality grades to prediction grades
    // Quality grades: A, AA, AAA, B, etc.
    // Prediction grades: GR-1, GR-2, WHITE
    let predictionGrade = 'GR-1'; // Default
    
    if (quality === 'AAA' || quality === 'AA') {
      predictionGrade = 'GR-1'; // Premium grade
    } else if (quality === 'A' || quality === 'B') {
      predictionGrade = 'GR-2'; // Standard grade
    } else if (quality === 'White' || quality === 'WHITE') {
      predictionGrade = 'WHITE'; // White pepper
    }

    // Get today's date
    const todayStr = new Date().toISOString().split('T')[0];

    // Query price prediction
    const predictionSnapshot = await db.collection('daily_price_predictions')
      .where('district', '==', district)
      .where('grade', '==', predictionGrade)
      .where('date', '==', todayStr)
      .limit(1)
      .get();

    if (predictionSnapshot.empty) {
      // Try to get latest prediction for this district/grade combination
      const latestSnapshot = await db.collection('daily_price_predictions')
        .where('district', '==', district)
        .where('grade', '==', predictionGrade)
        .orderBy('created_at', 'desc')
        .limit(1)
        .get();

      if (latestSnapshot.empty) {
        return res.json({
          success: true,
          prediction: null,
          message: `No price prediction available for ${district} district with grade ${predictionGrade}`,
          lotInfo: {
            district,
            quality,
            mappedGrade: predictionGrade
          }
        });
      }

      const data = latestSnapshot.docs[0].data();
      return res.json({
        success: true,
        prediction: {
          date: data.date,
          district: data.district,
          grade: data.grade,
          highestPrice: data.highest_price,
          averagePrice: data.average_price,
          pricePerKg: data.average_price, // Average price is per kg
          usdRate: data.usd_rate,
          createdAt: data.created_at?.toDate?.()?.toISOString() || null,
          isLatest: true
        },
        lotInfo: {
          lotId: lot.lot_id,
          district,
          quality,
          mappedGrade: predictionGrade,
          quantity: lot.quantity
        }
      });
    }

    const data = predictionSnapshot.docs[0].data();

    res.json({
      success: true,
      prediction: {
        date: data.date,
        district: data.district,
        grade: data.grade,
        highestPrice: data.highest_price,
        averagePrice: data.average_price,
        pricePerKg: data.average_price, // Average price is per kg
        usdRate: data.usd_rate,
        createdAt: data.created_at?.toDate?.()?.toISOString() || null,
        isCurrent: true
      },
      lotInfo: {
        lotId: lot.lot_id,
        district,
        quality,
        mappedGrade: predictionGrade,
        quantity: lot.quantity
      },
      suggestedReservePrice: {
        perKg: Math.round(data.average_price * 0.95), // 95% of average for reserve
        total: Math.round(data.average_price * 0.95 * lot.quantity),
        explanation: 'Reserve price set at 95% of predicted average to ensure competitive bidding'
      }
    });
  } catch (error) {
    logger.error('Error fetching price prediction for lot:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch price prediction',
      details: error.message
    });
  }
});

/**
 * GET /api/price-predictions/history
 * Get historical price predictions
 * Query params: district, grade, days (default: 7)
 */
router.get('/history', async (req, res) => {
  try {
    const { district, grade, days = 7 } = req.query;

    logger.info('Fetching historical price predictions', { district, grade, days });

    // Build query
    let query = db.collection('previous_price_predictions');

    // Apply filters
    if (district) {
      query = query.where('district', '==', district);
    }

    if (grade) {
      query = query.where('grade', '==', grade);
    }

    // Get predictions and sort
    query = query.orderBy('date', 'desc').limit(parseInt(days) * 3); // Multiple per day

    const snapshot = await query.get();

    const predictions = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      predictions.push({
        id: doc.id,
        date: data.date,
        district: data.district,
        grade: data.grade,
        highestPrice: data.highest_price,
        averagePrice: data.average_price,
        usdRate: data.usd_rate
      });
    });

    res.json({
      success: true,
      predictions,
      total: predictions.length
    });
  } catch (error) {
    logger.error('Error fetching historical predictions:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch historical predictions',
      details: error.message
    });
  }
});

/**
 * GET /api/price-predictions/districts
 * Get list of districts with available predictions
 */
router.get('/districts', async (req, res) => {
  try {
    const todayStr = new Date().toISOString().split('T')[0];
    
    const snapshot = await db.collection('daily_price_predictions')
      .where('date', '==', todayStr)
      .get();

    const districts = new Set();
    snapshot.forEach(doc => {
      districts.add(doc.data().district);
    });

    res.json({
      success: true,
      districts: Array.from(districts).sort(),
      total: districts.size
    });
  } catch (error) {
    logger.error('Error fetching districts:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch districts',
      details: error.message
    });
  }
});

module.exports = router;
