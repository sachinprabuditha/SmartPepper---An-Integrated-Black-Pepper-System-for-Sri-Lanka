const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const logger = require('../utils/logger');

const db = admin.firestore();

// Compliance rules definitions
const COMPLIANCE_RULES = {
  EU: [
    {
      code: 'EU_ORGANIC_CERT',
      name: 'EU Organic Certification Required',
      category: 'certification',
      severity: 'critical',
      check: async (lotId) => {
        const snapshot = await db.collection('certifications')
          .where('lot_id', '==', lotId)
          .where('cert_type', '==', 'organic')
          .where('is_valid', '==', true)
          .get();

        let passed = false;
        let details = 'Missing valid organic certification for EU export';

        for (const doc of snapshot.docs) {
          const cert = doc.data();
          const expiryDate = cert.expiry_date.toDate();
          if (expiryDate > new Date()) {
            passed = true;
            details = `Valid organic certificate found: ${cert.cert_number}`;
            break;
          }
        }

        return { passed, details };
      }
    },
    {
      code: 'EU_FUMIGATION_CERT',
      name: 'Fumigation Certificate Required',
      category: 'certification',
      severity: 'critical',
      check: async (lotId) => {
        const snapshot = await db.collection('certifications')
          .where('lot_id', '==', lotId)
          .where('cert_type', '==', 'fumigation')
          .where('is_valid', '==', true)
          .get();

        let passed = false;
        let details = 'Missing valid fumigation certification for EU export';

        for (const doc of snapshot.docs) {
          const cert = doc.data();
          const expiryDate = cert.expiry_date.toDate();
          if (expiryDate > new Date()) {
            passed = true;
            details = `Valid fumigation certificate found: ${cert.cert_number}`;
            break;
          }
        }

        return { passed, details };
      }
    },
    {
      code: 'EU_QUALITY_GRADE',
      name: 'EU Quality Standards',
      category: 'quality',
      severity: 'major',
      check: async (lotId) => {
        // Query by lot_id field, not document ID
        const snapshot = await db.collection('pepper_lots')
          .where('lot_id', '==', lotId)
          .limit(1)
          .get();
        
        if (snapshot.empty) {
          return { passed: false, details: 'Lot not found' };
        }

        const lot = snapshot.docs[0].data();
        const acceptableGrades = ['A', 'AA', 'AAA'];
        const quality = lot.quality;
        const passed = acceptableGrades.includes(quality);

        return {
          passed,
          details: passed 
            ? `Quality grade ${quality} meets EU standards`
            : `Quality grade ${quality || 'unknown'} does not meet EU standards (requires A, AA, or AAA)`
        };
      }
    },
    {
      code: 'EU_MOISTURE_LIMIT',
      name: 'Moisture Content Standard',
      category: 'quality',
      severity: 'major',
      check: async (lotId) => {
        const snapshot = await db.collection('processing_stages')
          .where('lot_id', '==', lotId)
          .where('stage_type', '==', 'drying')
          .orderBy('timestamp', 'desc')
          .limit(1)
          .get();
        
        if (snapshot.empty) {
          return {
            passed: false,
            details: 'No drying stage data found - moisture content unknown'
          };
        }
        
        const stage = snapshot.docs[0].data();
        const moisture = stage.quality_metrics?.moisture;

        if (!moisture || isNaN(parseFloat(moisture))) {
          return {
            passed: false,
            details: 'Moisture content not recorded in drying stage'
          };
        }
        
        const moistureValue = parseFloat(moisture);
        const passed = moistureValue <= 12.5;

        return {
          passed,
          details: passed
            ? `Moisture content ${moistureValue}% meets EU limit (≤12.5%)`
            : `Moisture content ${moistureValue}% exceeds EU limit of 12.5%`
        };
      }
    },
    {
      code: 'EU_PESTICIDE_RESIDUE',
      name: 'Pesticide Residue Limits',
      category: 'safety',
      severity: 'critical',
      check: async (lotId) => {
        const snapshot = await db.collection('certifications')
          .where('lot_id', '==', lotId)
          .where('cert_type', '==', 'pesticide_test')
          .where('is_valid', '==', true)
          .get();
        
        let passed = false;
        let details = 'Missing pesticide residue test certificate required for EU export';

        for (const doc of snapshot.docs) {
          const cert = doc.data();
          const expiryDate = cert.expiry_date.toDate();
          if (expiryDate > new Date()) {
            passed = true;
            details = `Valid pesticide residue test certificate: ${cert.cert_number}`;
            break;
          }
        }

        return { passed, details };
      }
    },
    {
      code: 'EU_PACKAGING_STANDARD',
      name: 'Food Grade Packaging Required',
      category: 'packaging',
      severity: 'major',
      check: async (lotId) => {
        const snapshot = await db.collection('processing_stages')
          .where('lot_id', '==', lotId)
          .where('stage_type', '==', 'packaging')
          .orderBy('timestamp', 'desc')
          .limit(1)
          .get();
        
        if (snapshot.empty) {
          return {
            passed: false,
            details: 'No packaging stage data found'
          };
        }
        
        const stage = snapshot.docs[0].data();
        const material = stage.quality_metrics?.package_material;
        const foodGradeMaterials = ['HDPE', 'PP', 'PET', 'Glass', 'Jute_with_liner', 'Food_grade_plastic'];
        const passed = material && foodGradeMaterials.includes(material);
        
        return {
          passed,
          details: passed
            ? `Package material '${material}' meets EU food grade standards`
            : `Package material '${material || 'unknown'}' does not meet EU requirements. Accepted: ${foodGradeMaterials.join(', ')}`
        };
      }
    },
    {
      code: 'EU_TRACEABILITY',
      name: 'Full Traceability Chain',
      category: 'documentation',
      severity: 'major',
      check: async (lotId) => {
        const snapshot = await db.collection('processing_stages')
          .where('lot_id', '==', lotId)
          .orderBy('timestamp')
          .get();
        
        const requiredStages = ['harvest', 'drying', 'grading', 'packaging'];
        const recordedStages = snapshot.docs.map(doc => doc.data().stage_type);
        const missingStages = requiredStages.filter(s => !recordedStages.includes(s));
        
        const passed = missingStages.length === 0;
        return {
          passed,
          details: passed
            ? `Complete traceability chain: ${recordedStages.join(' → ')}`
            : `Missing processing stages: ${missingStages.join(', ')}. Required: ${requiredStages.join(', ')}`
        };
      }
    }
  ],
  FDA: [
    {
      code: 'FDA_PHYTOSANITARY',
      name: 'Phytosanitary Certificate Required',
      category: 'certification',
      severity: 'critical',
      check: async (lotId) => {
        const snapshot = await db.collection('certifications')
          .where('lot_id', '==', lotId)
          .where('cert_type', '==', 'phytosanitary')
          .where('is_valid', '==', true)
          .get();

        let passed = false;
        let details = 'Missing phytosanitary certification for FDA approval';

        for (const doc of snapshot.docs) {
          const cert = doc.data();
          const expiryDate = cert.expiry_date.toDate();
          if (expiryDate > new Date()) {
            passed = true;
            details = 'Valid phytosanitary certificate found';
            break;
          }
        }

        return { passed, details };
      }
    },
    {
      code: 'FDA_FUMIGATION',
      name: 'Fumigation Documentation',
      category: 'certification',
      severity: 'critical',
      check: async (lotId) => {
        const snapshot = await db.collection('certifications')
          .where('lot_id', '==', lotId)
          .where('cert_type', '==', 'fumigation')
          .where('is_valid', '==', true)
          .get();

        return {
          passed: !snapshot.empty,
          details: !snapshot.empty 
            ? 'Fumigation documentation complete'
            : 'Missing fumigation documentation'
        };
      }
    },
    {
      code: 'FDA_MOISTURE_LIMIT',
      name: 'FDA Moisture Content Requirement',
      category: 'quality',
      severity: 'major',
      check: async (lotId) => {
        const snapshot = await db.collection('processing_stages')
          .where('lot_id', '==', lotId)
          .where('stage_type', '==', 'drying')
          .orderBy('timestamp', 'desc')
          .limit(1)
          .get();
        
        if (snapshot.empty) {
          return {
            passed: false,
            details: 'Moisture content not documented'
          };
        }
        
        const stage = snapshot.docs[0].data();
        const moisture = stage.quality_metrics?.moisture;

        if (!moisture || isNaN(parseFloat(moisture))) {
          return {
            passed: false,
            details: 'Moisture content not documented'
          };
        }
        
        const moistureValue = parseFloat(moisture);
        const passed = moistureValue <= 13.0;

        return {
          passed,
          details: passed
            ? `Moisture ${moistureValue}% meets FDA standards (≤13.0%)`
            : `Moisture ${moistureValue}% exceeds FDA limit of 13.0%`
        };
      }
    },
    {
      code: 'FDA_PACKAGING',
      name: 'FDA Packaging Requirements',
      category: 'packaging',
      severity: 'critical',
      check: async (lotId) => {
        const snapshot = await db.collection('processing_stages')
          .where('lot_id', '==', lotId)
          .where('stage_type', '==', 'packaging')
          .orderBy('timestamp', 'desc')
          .limit(1)
          .get();
        
        if (snapshot.empty) {
          return {
            passed: false,
            details: 'Packaging information not documented'
          };
        }
        
        const stage = snapshot.docs[0].data();
        const material = stage.quality_metrics?.package_material;
        const fdaApprovedMaterials = ['HDPE', 'PP', 'PET', 'Glass', 'FDA_approved_plastic'];
        const passed = material && fdaApprovedMaterials.includes(material);
        
        return {
          passed,
          details: passed
            ? `FDA-compliant packaging: ${material}`
            : `Packaging material '${material || 'unknown'}' not FDA approved. Accepted: ${fdaApprovedMaterials.join(', ')}`
        };
      }
    },
    {
      code: 'FDA_PESTICIDE_MRL',
      name: 'Pesticide Maximum Residue Levels',
      category: 'safety',
      severity: 'critical',
      check: async (lotId) => {
        const snapshot = await db.collection('certifications')
          .where('lot_id', '==', lotId)
          .where('cert_type', '==', 'pesticide_test')
          .where('is_valid', '==', true)
          .get();
        
        return {
          passed: !snapshot.empty,
          details: !snapshot.empty
            ? `Pesticide MRL test certificate on file: ${snapshot.docs[0].data().cert_number}`
            : 'Missing pesticide maximum residue level (MRL) test certificate'
        };
      }
    }
  ],
  MIDDLE_EAST: [
    {
      code: 'ME_HALAL_CERT',
      name: 'Halal Certification',
      category: 'certification',
      severity: 'major',
      check: async (lotId) => {
        const snapshot = await db.collection('certifications')
          .where('lot_id', '==', lotId)
          .where('cert_type', '==', 'halal')
          .where('is_valid', '==', true)
          .get();

        let passed = false;
        let details = 'Halal certification recommended for Middle East export';

        for (const doc of snapshot.docs) {
          const cert = doc.data();
          const expiryDate = cert.expiry_date.toDate();
          if (expiryDate > new Date()) {
            passed = true;
            details = 'Valid halal certificate found';
            break;
          }
        }

        return { passed, details };
      }
    },
    {
      code: 'ME_QUALITY_GRADE',
      name: 'Premium Quality Grade',
      category: 'quality',
      severity: 'major',
      check: async (lotId) => {
        // Query by lot_id field, not document ID
        const snapshot = await db.collection('pepper_lots')
          .where('lot_id', '==', lotId)
          .limit(1)
          .get();
        
        if (snapshot.empty) {
          return { passed: false, details: 'Lot not found' };
        }

        const lot = snapshot.docs[0].data();
        const premiumGrades = ['AA', 'AAA', 'Premium'];
        const quality = lot.quality;
        const passed = premiumGrades.includes(quality);

        return {
          passed,
          details: passed
            ? `Quality grade ${quality} meets Middle East premium standards`
            : `Quality grade ${quality || 'unknown'} does not meet premium requirements (requires AA, AAA, or Premium)`
        };
      }
    },
    {
      code: 'ME_MOISTURE_LIMIT',
      name: 'Middle East Moisture Standard',
      category: 'quality',
      severity: 'major',
      check: async (lotId) => {
        const snapshot = await db.collection('processing_stages')
          .where('lot_id', '==', lotId)
          .where('stage_type', '==', 'drying')
          .orderBy('timestamp', 'desc')
          .limit(1)
          .get();
        
        if (snapshot.empty) {
          return {
            passed: false,
            details: 'Moisture content not documented'
          };
        }
        
        const stage = snapshot.docs[0].data();
        const moisture = stage.quality_metrics?.moisture;

        if (!moisture || isNaN(parseFloat(moisture))) {
          return {
            passed: false,
            details: 'Moisture content not documented'
          };
        }
        
        const moistureValue = parseFloat(moisture);
        const passed = moistureValue <= 11.0;

        return {
          passed,
          details: passed
            ? `Moisture ${moistureValue}% meets Middle East premium standards (≤11.0%)`
            : `Moisture ${moistureValue}% exceeds Middle East premium limit of 11.0%`
        };
      }
    },
    {
      code: 'ME_PACKAGING',
      name: 'Middle East Packaging Standards',
      category: 'packaging',
      severity: 'major',
      check: async (lotId) => {
        const snapshot = await db.collection('processing_stages')
          .where('lot_id', '==', lotId)
          .where('stage_type', '==', 'packaging')
          .orderBy('timestamp', 'desc')
          .limit(1)
          .get();
        
        if (snapshot.empty) {
          return {
            passed: false,
            details: 'Packaging information not available'
          };
        }
        
        const stage = snapshot.docs[0].data();
        const material = stage.quality_metrics?.package_material;
        const acceptedMaterials = ['Jute_with_liner', 'PP', 'HDPE', 'Food_grade_plastic'];
        const passed = material && acceptedMaterials.includes(material);
        
        return {
          passed,
          details: passed
            ? `Package material '${material}' acceptable for Middle East market`
            : `Package material '${material || 'unknown'}' may not meet Middle East standards. Preferred: ${acceptedMaterials.join(', ')}`
        };
      }
    },
    {
      code: 'ME_ORIGIN_CERT',
      name: 'Certificate of Origin',
      category: 'certification',
      severity: 'major',
      check: async (lotId) => {
        const snapshot = await db.collection('certifications')
          .where('lot_id', '==', lotId)
          .where('cert_type', '==', 'origin')
          .where('is_valid', '==', true)
          .get();
        
        return {
          passed: !snapshot.empty,
          details: !snapshot.empty
            ? `Certificate of origin on file: ${snapshot.docs[0].data().cert_number}`
            : 'Certificate of origin recommended for Middle East customs'
        };
      }
    }
  ]
};

/**
 * POST /api/compliance/check/:lotId
 * Run compliance checks for a lot
 */
router.post('/check/:lotId', async (req, res) => {
  try {
    const { lotId } = req.params;
    const { destination } = req.body;

    if (!destination) {
      return res.status(400).json({
        success: false,
        error: 'Destination country is required'
      });
    }

    const rules = COMPLIANCE_RULES[destination] || [];
    if (rules.length === 0) {
      return res.status(400).json({
        success: false,
        error: `No compliance rules defined for destination: ${destination}`
      });
    }

    // Run all compliance checks
    const results = [];
    let allPassed = true;
    let criticalFailed = false;

    for (const rule of rules) {
      try {
        const checkResult = await rule.check(lotId);
        
        // Store result in database
        await db.collection('compliance_checks').add({
          lot_id: lotId,
          rule_name: rule.name,
          rule_type: rule.category,
          passed: checkResult.passed,
          details: JSON.stringify(checkResult.details),
          checked_at: admin.firestore.FieldValue.serverTimestamp()
        });

        results.push({
          code: rule.code,
          name: rule.name,
          category: rule.category,
          severity: rule.severity,
          passed: checkResult.passed,
          details: checkResult.details
        });

        if (!checkResult.passed) {
          allPassed = false;
          if (rule.severity === 'critical') {
            criticalFailed = true;
          }
        }
      } catch (error) {
        logger.error(`Error running compliance check ${rule.code}:`, error);
        results.push({
          code: rule.code,
          name: rule.name,
          category: rule.category,
          severity: rule.severity,
          passed: false,
          details: `Error running check: ${error.message}`
        });
        allPassed = false;
        if (rule.severity === 'critical') {
          criticalFailed = true;
        }
      }
    }

    // Update lot compliance status
    const complianceStatus = criticalFailed ? 'failed' : (allPassed ? 'passed' : 'failed');
    
    // Find lot by lot_id field (not document ID)
    const lotSnapshot = await db.collection('pepper_lots')
      .where('lot_id', '==', lotId)
      .limit(1)
      .get();
    
    if (!lotSnapshot.empty) {
      const lotRef = lotSnapshot.docs[0].ref;
      await lotRef.update({
        compliance_status: complianceStatus,
        compliance_checked_at: admin.firestore.FieldValue.serverTimestamp()
      });
    } else {
      logger.warn('Lot not found for compliance status update:', lotId);
    }

    logger.info('Compliance check completed:', { 
      lotId, 
      destination, 
      status: complianceStatus,
      totalChecks: results.length,
      passed: results.filter(r => r.passed).length
    });

    res.json({
      success: true,
      lotId,
      destination,
      complianceStatus,
      allPassed,
      criticalFailed,
      results,
      summary: {
        total: results.length,
        passed: results.filter(r => r.passed).length,
        failed: results.filter(r => !r.passed).length,
        critical: results.filter(r => r.severity === 'critical').length,
        criticalFailed: results.filter(r => r.severity === 'critical' && !r.passed).length
      }
    });
  } catch (error) {
    logger.error('Error running compliance check:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to run compliance check',
      details: error.message
    });
  }
});

/**
 * GET /api/compliance/history/:lotId
 * Get compliance check history for a lot
 */
router.get('/history/:lotId', async (req, res) => {
  try {
    const { lotId } = req.params;

    const snapshot = await db.collection('compliance_checks')
      .where('lot_id', '==', lotId)
      .orderBy('checked_at', 'desc')
      .get();

    const checks = [];
    snapshot.forEach(doc => {
      checks.push({ id: doc.id, ...doc.data() });
    });

    res.json({
      success: true,
      checks
    });
  } catch (error) {
    logger.error('Error fetching compliance history:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch compliance history'
    });
  }
});

/**
 * GET /api/compliance/rules
 * Get available compliance rules
 */
router.get('/rules', async (req, res) => {
  try {
    const { destination } = req.query;

    if (destination) {
      const rules = COMPLIANCE_RULES[destination] || [];
      res.json({
        success: true,
        destination,
        rules: rules.map(r => ({
          code: r.code,
          name: r.name,
          category: r.category,
          severity: r.severity
        }))
      });
    } else {
      // Return all destinations and their rules
      const allRules = {};
      for (const [dest, rules] of Object.entries(COMPLIANCE_RULES)) {
        allRules[dest] = rules.map(r => ({
          code: r.code,
          name: r.name,
          category: r.category,
          severity: r.severity
        }));
      }
      res.json({
        success: true,
        destinations: Object.keys(COMPLIANCE_RULES),
        rules: allRules
      });
    }
  } catch (error) {
    logger.error('Error fetching compliance rules:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch compliance rules'
    });
  }
});

module.exports = router;
