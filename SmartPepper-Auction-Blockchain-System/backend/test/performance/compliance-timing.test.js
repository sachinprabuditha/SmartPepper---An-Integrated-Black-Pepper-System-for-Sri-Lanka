/**
 * Compliance Engine Performance Tests
 * 
 * Measures compliance validation duration to ensure:
 * 1. Fast validation times (target: <2 seconds)
 * 2. Consistent performance across rule sets
 * 3. Scalability with multiple certifications
 */

const axios = require('axios');
const { performance } = require('perf_hooks');

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3002';
const TEST_LOT_ID = 'TEST-LOT-PERF-001';
const TARGET_DURATION_MS = 2000; // 2 seconds max

// Metrics storage
const metrics = {
  compliance_check_duration_ms: [],
  destinations_tested: {},
  errors: []
};

/**
 * Create a test lot with sample data
 */
async function createTestLot() {
  try {
    const response = await axios.post(`${BACKEND_URL}/api/lots`, {
      lotId: TEST_LOT_ID,
      farmerAddress: '0xTestFarmer123',
      variety: 'Black Pepper',
      quantity: 500,
      quality: 'A',
      harvestDate: '2025-11-15',
      origin: 'Kerala, India',
      farmLocation: 'Wayanad District',
      organicCertified: true
    });
    
    console.log(`✓ Created test lot: ${TEST_LOT_ID}`);
    return response.data;
  } catch (error) {
    console.error('Failed to create test lot:', error.message);
    throw error;
  }
}

/**
 * Add processing stages to lot
 */
async function addProcessingStages() {
  const stages = [
    {
      stageType: 'harvest',
      stageName: 'Initial Harvest',
      location: 'Farm A',
      operatorName: 'Test Operator',
      qualityMetrics: {
        moisture: 15.0,
        temperature: 28
      }
    },
    {
      stageType: 'drying',
      stageName: 'Sun Drying',
      location: 'Drying Yard',
      operatorName: 'Test Operator',
      qualityMetrics: {
        moisture: 11.2,
        duration_hours: 48,
        method: 'Sun'
      }
    },
    {
      stageType: 'grading',
      stageName: 'Quality Grading',
      location: 'Grading Station',
      operatorName: 'Test Operator',
      qualityMetrics: {
        size: '4mm+',
        color: 'Black',
        defects_percentage: 2.1
      }
    }
  ];

  for (const stage of stages) {
    await axios.post(`${BACKEND_URL}/api/processing/stages`, {
      lotId: TEST_LOT_ID,
      ...stage
    });
  }
  
  console.log(`✓ Added ${stages.length} processing stages`);
}

/**
 * Add certifications to lot
 */
async function addCertifications() {
  const certs = [
    {
      certType: 'organic',
      certNumber: 'ORG-TEST-001',
      issuer: 'Test Certifier',
      issueDate: '2025-01-01',
      expiryDate: '2026-01-01'
    },
    {
      certType: 'fumigation',
      certNumber: 'FUM-TEST-001',
      issuer: 'Test Certifier',
      issueDate: '2025-11-01',
      expiryDate: '2026-11-01'
    },
    {
      certType: 'phytosanitary',
      certNumber: 'PHY-TEST-001',
      issuer: 'Test Certifier',
      issueDate: '2025-11-01',
      expiryDate: '2026-11-01'
    }
  ];

  for (const cert of certs) {
    await axios.post(`${BACKEND_URL}/api/certifications`, {
      lotId: TEST_LOT_ID,
      ...cert
    });
  }
  
  console.log(`✓ Added ${certs.length} certifications`);
}

/**
 * Test compliance check performance for a destination
 */
async function testComplianceCheck(destination) {
  const startTime = performance.now();
  
  try {
    const response = await axios.post(
      `${BACKEND_URL}/api/compliance/check/${TEST_LOT_ID}`,
      { destination }
    );
    
    const duration = performance.now() - startTime;
    
    metrics.compliance_check_duration_ms.push(duration);
    
    if (!metrics.destinations_tested[destination]) {
      metrics.destinations_tested[destination] = [];
    }
    metrics.destinations_tested[destination].push(duration);
    
    const { complianceStatus, results } = response.data;
    const rulesChecked = results?.length || 0;
    
    console.log(`\n${destination} Compliance Check:`);
    console.log(`   Duration:   ${duration.toFixed(2)}ms`);
    console.log(`   Status:     ${complianceStatus}`);
    console.log(`   Rules:      ${rulesChecked} checked`);
    
    return {
      destination,
      duration,
      status: complianceStatus,
      rulesChecked
    };
    
  } catch (error) {
    const duration = performance.now() - startTime;
    
    metrics.errors.push({
      destination,
      error: error.message,
      duration
    });
    
    console.error(`❌ ${destination} check failed:`, error.message);
    throw error;
  }
}

/**
 * Run multiple checks to test consistency
 */
async function testConsistency(destination, iterations = 5) {
  console.log(`\n🔄 Testing ${destination} consistency (${iterations} iterations)...`);
  
  const durations = [];
  
  for (let i = 0; i < iterations; i++) {
    const result = await testComplianceCheck(destination);
    durations.push(result.duration);
    
    // Small delay between checks
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  
  const avg = durations.reduce((a, b) => a + b, 0) / durations.length;
  const min = Math.min(...durations);
  const max = Math.max(...durations);
  const variance = Math.sqrt(
    durations.reduce((sum, d) => sum + Math.pow(d - avg, 2), 0) / durations.length
  );
  
  console.log(`\n📊 ${destination} Consistency Metrics:`);
  console.log(`   Average:    ${avg.toFixed(2)}ms`);
  console.log(`   Min:        ${min.toFixed(2)}ms`);
  console.log(`   Max:        ${max.toFixed(2)}ms`);
  console.log(`   Std Dev:    ${variance.toFixed(2)}ms`);
  console.log(`   Range:      ${(max - min).toFixed(2)}ms`);
  
  return { avg, min, max, variance };
}

/**
 * Print final results
 */
function printResults() {
  console.log('\n' + '='.repeat(60));
  console.log('📈 COMPLIANCE ENGINE PERFORMANCE RESULTS');
  console.log('='.repeat(60));

  const allDurations = metrics.compliance_check_duration_ms;
  
  if (allDurations.length === 0) {
    console.log('\n⚠️  No measurements collected');
    return false;
  }

  const avg = allDurations.reduce((a, b) => a + b, 0) / allDurations.length;
  const min = Math.min(...allDurations);
  const max = Math.max(...allDurations);

  console.log('\n⚡ Overall Performance:');
  console.log(`   Total Checks: ${allDurations.length}`);
  console.log(`   Average:      ${avg.toFixed(2)}ms`);
  console.log(`   Min:          ${min.toFixed(2)}ms`);
  console.log(`   Max:          ${max.toFixed(2)}ms`);

  console.log('\n📍 Per Destination:');
  Object.entries(metrics.destinations_tested).forEach(([dest, durations]) => {
    const destAvg = durations.reduce((a, b) => a + b, 0) / durations.length;
    console.log(`   ${dest.padEnd(15)} ${destAvg.toFixed(2)}ms (${durations.length} checks)`);
  });

  const passed = avg < TARGET_DURATION_MS;
  console.log('\n🎯 Performance Target:');
  console.log(`   Target:       ${TARGET_DURATION_MS}ms`);
  console.log(`   Actual:       ${avg.toFixed(2)}ms`);
  console.log(`   Status:       ${passed ? '✅ PASSED' : '❌ FAILED'}`);

  if (metrics.errors.length > 0) {
    console.log('\n⚠️  Errors Encountered:');
    metrics.errors.forEach(err => {
      console.log(`   - ${err.destination}: ${err.error}`);
    });
  }

  console.log('\n' + '='.repeat(60));

  return passed;
}

/**
 * Main test execution
 */
async function runTests() {
  console.log('🚀 Starting Compliance Engine Performance Tests\n');
  console.log(`Configuration:`);
  console.log(`   Backend:      ${BACKEND_URL}`);
  console.log(`   Test Lot:     ${TEST_LOT_ID}`);
  console.log(`   Target:       <${TARGET_DURATION_MS}ms\n`);

  try {
    // Setup: Create test lot with data
    console.log('📋 Setting up test data...');
    await createTestLot();
    await addProcessingStages();
    await addCertifications();
    console.log('✅ Test data ready\n');

    // Test each destination
    const destinations = ['EU', 'FDA', 'MIDDLE_EAST'];
    
    console.log('🧪 Testing compliance checks...');
    
    for (const dest of destinations) {
      await testConsistency(dest, 3);
    }

    // Print results
    const passed = printResults();

    // Cleanup
    console.log('\n🧹 Cleanup: Delete test lot via API if needed');
    // await axios.delete(`${BACKEND_URL}/api/lots/${TEST_LOT_ID}`);

    process.exit(passed ? 0 : 1);

  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    process.exit(1);
  }
}

// Run tests if executed directly
if (require.main === module) {
  runTests();
}

module.exports = { runTests };
