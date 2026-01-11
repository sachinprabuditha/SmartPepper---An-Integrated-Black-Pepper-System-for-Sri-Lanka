const express = require('express');
const router = express.Router();
const db = require('../db/database');
const logger = require('../utils/logger');

// Compliance rules definitions
const COMPLIANCE_RULES = {
  EU: [
    {
      code: 'EU_ORGANIC_CERT',
      name: 'EU Organic Certification Required',
      category: 'certification',
      severity: 'critical',
      check: async (lotId) => {
        const result = await db.query(
          `SELECT * FROM certifications 
           WHERE lot_id = $1 AND cert_type = 'organic' 
           AND is_valid = true AND expiry_date > NOW()`,
          [lotId]
        );
        return {
          passed: result.rows.length > 0,
          details: result.rows.length > 0 
            ? `Valid organic certificate found: ${result.rows[0].cert_number}`
            : 'Missing valid organic certification for EU export'
        };
      }
    },
    {
      code: 'EU_FUMIGATION_CERT',
      name: 'Fumigation Certificate Required',
      category: 'certification',
      severity: 'critical',
      check: async (lotId) => {
        const result = await db.query(
          `SELECT * FROM certifications 
           WHERE lot_id = $1 AND cert_type = 'fumigation' 
           AND is_valid = true AND expiry_date > NOW()`,
          [lotId]
        );
        return {
          passed: result.rows.length > 0,
          details: result.rows.length > 0 
            ? `Valid fumigation certificate found: ${result.rows[0].cert_number}`
            : 'Missing valid fumigation certification for EU export'
        };
      }
    },
    {
      code: 'EU_QUALITY_GRADE',
      name: 'EU Quality Standards',
      category: 'quality',
      severity: 'major',
      check: async (lotId) => {
        const result = await db.query(
          `SELECT quality FROM pepper_lots WHERE lot_id = $1`,
          [lotId]
        );
        const acceptableGrades = ['A', 'AA', 'AAA'];
        const passed = result.rows.length > 0 && acceptableGrades.includes(result.rows[0].quality);
        return {
          passed,
          details: passed 
            ? `Quality grade ${result.rows[0].quality} meets EU standards`
            : `Quality grade ${result.rows[0]?.quality || 'unknown'} does not meet EU standards (requires A, AA, or AAA)`
        };
      }
    },
    {
      code: 'EU_MOISTURE_LIMIT',
      name: 'Moisture Content Standard',
      category: 'quality',
      severity: 'major',
      check: async (lotId) => {
        const result = await db.query(
          `SELECT quality_metrics->>'moisture' as moisture
           FROM processing_stages
           WHERE lot_id = $1 AND stage_type = 'drying'
           ORDER BY timestamp DESC LIMIT 1`,
          [lotId]
        );
        
        if (result.rows.length === 0) {
          return {
            passed: false,
            details: 'No drying stage data found - moisture content unknown'
          };
        }
        
        const moisture = parseFloat(result.rows[0].moisture);
        if (isNaN(moisture)) {
          return {
            passed: false,
            details: 'Moisture content not recorded in drying stage'
          };
        }
        
        const passed = moisture <= 12.5;
        return {
          passed,
          details: passed
            ? `Moisture content ${moisture}% meets EU limit (≤12.5%)`
            : `Moisture content ${moisture}% exceeds EU limit of 12.5%`
        };
      }
    },
    {
      code: 'EU_PESTICIDE_RESIDUE',
      name: 'Pesticide Residue Limits',
      category: 'safety',
      severity: 'critical',
      check: async (lotId) => {
        const result = await db.query(
          `SELECT * FROM certifications 
           WHERE lot_id = $1 AND cert_type = 'pesticide_test' 
           AND is_valid = true AND expiry_date > NOW()`,
          [lotId]
        );
        
        return {
          passed: result.rows.length > 0,
          details: result.rows.length > 0
            ? `Valid pesticide residue test certificate: ${result.rows[0].cert_number}`
            : 'Missing pesticide residue test certificate required for EU export'
        };
      }
    },
    {
      code: 'EU_PACKAGING_STANDARD',
      name: 'Food Grade Packaging Required',
      category: 'packaging',
      severity: 'major',
      check: async (lotId) => {
        const result = await db.query(
          `SELECT quality_metrics->>'package_material' as material
           FROM processing_stages
           WHERE lot_id = $1 AND stage_type = 'packaging'
           ORDER BY timestamp DESC LIMIT 1`,
          [lotId]
        );
        
        if (result.rows.length === 0) {
          return {
            passed: false,
            details: 'No packaging stage data found'
          };
        }
        
        const material = result.rows[0].material;
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
        const result = await db.query(
          `SELECT stage_type FROM processing_stages 
           WHERE lot_id = $1 
           ORDER BY timestamp`,
          [lotId]
        );
        
        const requiredStages = ['harvest', 'drying', 'grading', 'packaging'];
        const recordedStages = result.rows.map(r => r.stage_type);
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
        const result = await db.query(
          `SELECT * FROM certifications 
           WHERE lot_id = $1 AND cert_type = 'phytosanitary' 
           AND is_valid = true AND expiry_date > NOW()`,
          [lotId]
        );
        return {
          passed: result.rows.length > 0,
          details: result.rows.length > 0 
            ? `Valid phytosanitary certificate found`
            : 'Missing phytosanitary certification for FDA approval'
        };
      }
    },
    {
      code: 'FDA_FUMIGATION',
      name: 'Fumigation Documentation',
      category: 'certification',
      severity: 'critical',
      check: async (lotId) => {
        const result = await db.query(
          `SELECT * FROM certifications 
           WHERE lot_id = $1 AND cert_type = 'fumigation' 
           AND is_valid = true`,
          [lotId]
        );
        return {
          passed: result.rows.length > 0,
          details: result.rows.length > 0 
            ? `Fumigation documentation complete`
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
        const result = await db.query(
          `SELECT quality_metrics->>'moisture' as moisture
           FROM processing_stages
           WHERE lot_id = $1 AND stage_type = 'drying'
           ORDER BY timestamp DESC LIMIT 1`,
          [lotId]
        );
        
        if (result.rows.length === 0 || !result.rows[0].moisture) {
          return {
            passed: false,
            details: 'Moisture content not documented'
          };
        }
        
        const moisture = parseFloat(result.rows[0].moisture);
        const passed = moisture <= 13.0;
        return {
          passed,
          details: passed
            ? `Moisture ${moisture}% meets FDA standards (≤13.0%)`
            : `Moisture ${moisture}% exceeds FDA limit of 13.0%`
        };
      }
    },
    {
      code: 'FDA_PACKAGING',
      name: 'FDA Packaging Requirements',
      category: 'packaging',
      severity: 'critical',
      check: async (lotId) => {
        const result = await db.query(
          `SELECT quality_metrics->>'package_material' as material,
                  quality_metrics->>'labeling' as labeling
           FROM processing_stages
           WHERE lot_id = $1 AND stage_type = 'packaging'
           ORDER BY timestamp DESC LIMIT 1`,
          [lotId]
        );
        
        if (result.rows.length === 0) {
          return {
            passed: false,
            details: 'Packaging information not documented'
          };
        }
        
        const material = result.rows[0].material;
        const fdaApprovedMaterials = ['HDPE', 'PP', 'PET', 'Glass', 'FDA_approved_plastic'];
        const materialOk = material && fdaApprovedMaterials.includes(material);
        
        // Check labeling (should include origin, batch, expiry)
        const labeling = result.rows[0].labeling;
        const labelingOk = labeling && typeof labeling === 'string';
        
        const passed = materialOk;
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
        const result = await db.query(
          `SELECT * FROM certifications 
           WHERE lot_id = $1 AND cert_type = 'pesticide_test' 
           AND is_valid = true`,
          [lotId]
        );
        
        return {
          passed: result.rows.length > 0,
          details: result.rows.length > 0
            ? `Pesticide MRL test certificate on file: ${result.rows[0].cert_number}`
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
        const result = await db.query(
          `SELECT * FROM certifications 
           WHERE lot_id = $1 AND cert_type = 'halal' 
           AND is_valid = true AND expiry_date > NOW()`,
          [lotId]
        );
        return {
          passed: result.rows.length > 0,
          details: result.rows.length > 0 
            ? `Valid halal certificate found`
            : 'Halal certification recommended for Middle East export'
        };
      }
    },
    {
      code: 'ME_QUALITY_GRADE',
      name: 'Premium Quality Grade',
      category: 'quality',
      severity: 'major',
      check: async (lotId) => {
        const result = await db.query(
          `SELECT quality FROM pepper_lots WHERE lot_id = $1`,
          [lotId]
        );
        const premiumGrades = ['AA', 'AAA', 'Premium'];
        const passed = result.rows.length > 0 && premiumGrades.includes(result.rows[0].quality);
        return {
          passed,
          details: passed
            ? `Quality grade ${result.rows[0].quality} meets Middle East premium standards`
            : `Quality grade ${result.rows[0]?.quality || 'unknown'} does not meet premium requirements (requires AA, AAA, or Premium)`
        };
      }
    },
    {
      code: 'ME_MOISTURE_LIMIT',
      name: 'Middle East Moisture Standard',
      category: 'quality',
      severity: 'major',
      check: async (lotId) => {
        const result = await db.query(
          `SELECT quality_metrics->>'moisture' as moisture
           FROM processing_stages
           WHERE lot_id = $1 AND stage_type = 'drying'
           ORDER BY timestamp DESC LIMIT 1`,
          [lotId]
        );
        
        if (result.rows.length === 0 || !result.rows[0].moisture) {
          return {
            passed: false,
            details: 'Moisture content not documented'
          };
        }
        
        const moisture = parseFloat(result.rows[0].moisture);
        const passed = moisture <= 11.0;
        return {
          passed,
          details: passed
            ? `Moisture ${moisture}% meets Middle East premium standards (≤11.0%)`
            : `Moisture ${moisture}% exceeds Middle East premium limit of 11.0%`
        };
      }
    },
    {
      code: 'ME_PACKAGING',
      name: 'Middle East Packaging Standards',
      category: 'packaging',
      severity: 'major',
      check: async (lotId) => {
        const result = await db.query(
          `SELECT quality_metrics->>'package_material' as material
           FROM processing_stages
           WHERE lot_id = $1 AND stage_type = 'packaging'
           ORDER BY timestamp DESC LIMIT 1`,
          [lotId]
        );
        
        if (result.rows.length === 0) {
          return {
            passed: false,
            details: 'Packaging information not available'
          };
        }
        
        const material = result.rows[0].material;
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
        const result = await db.query(
          `SELECT * FROM certifications 
           WHERE lot_id = $1 AND cert_type = 'origin' 
           AND is_valid = true`,
          [lotId]
        );
        
        return {
          passed: result.rows.length > 0,
          details: result.rows.length > 0
            ? `Certificate of origin on file: ${result.rows[0].cert_number}`
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
        await db.query(
          `INSERT INTO compliance_checks (lot_id, rule_name, rule_type, passed, details)
           VALUES ($1, $2, $3, $4, $5)`,
          [lotId, rule.name, rule.category, checkResult.passed, JSON.stringify(checkResult.details)]
        );

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
    await db.query(
      `UPDATE pepper_lots 
       SET compliance_status = $1, compliance_checked_at = NOW()
       WHERE lot_id = $2`,
      [complianceStatus, lotId]
    );

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
    const { lotId} = req.params;

    const result = await db.query(
      `SELECT * FROM compliance_checks 
       WHERE lot_id = $1 
       ORDER BY checked_at DESC`,
      [lotId]
    );

    res.json({
      success: true,
      checks: result.rows
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
