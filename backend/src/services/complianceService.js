const { create } = require('ipfs-http-client');
const logger = require('../utils/logger');
const crypto = require('crypto');

class ComplianceService {
  constructor() {
    this.ipfsClient = null;
    this.rules = this.initializeRules();
  }

  async initialize() {
    try {
      this.ipfsClient = create({
        host: process.env.IPFS_HOST || 'localhost',
        port: process.env.IPFS_PORT || 5001,
        protocol: process.env.IPFS_PROTOCOL || 'http'
      });

      logger.info('Compliance service initialized');
    } catch (error) {
      logger.warn('IPFS client initialization failed, continuing without IPFS:', error.message);
    }
  }

  initializeRules() {
    // V1: Single compliance rule - Certificate validation
    // V2 (Future): Will load from YAML/JSON configuration
    return [
      {
        name: 'IPFS Certificate Validation',
        type: 'certificate_check',
        enabled: true,
        validate: this.validateCertificate.bind(this)
      }
    ];
  }

  async validateCertificate(lotData) {
    try {
      const { certificateHash, certificateIpfsUrl } = lotData;

      // Check if certificate hash exists
      if (!certificateHash || certificateHash === '0x0000000000000000000000000000000000000000000000000000000000000000') {
        return {
          passed: false,
          message: 'Certificate hash is missing or invalid'
        };
      }

      // If IPFS URL is provided, verify the hash matches
      if (certificateIpfsUrl && this.ipfsClient) {
        try {
          // Fetch from IPFS
          const chunks = [];
          for await (const chunk of this.ipfsClient.cat(certificateIpfsUrl)) {
            chunks.push(chunk);
          }
          const content = Buffer.concat(chunks);

          // Calculate hash
          const calculatedHash = '0x' + crypto
            .createHash('sha256')
            .update(content)
            .digest('hex');

          if (calculatedHash !== certificateHash) {
            return {
              passed: false,
              message: 'Certificate hash mismatch',
              details: {
                expected: certificateHash,
                calculated: calculatedHash
              }
            };
          }
        } catch (ipfsError) {
          logger.warn('IPFS verification failed:', ipfsError.message);
          // Continue with basic validation if IPFS fails
        }
      }

      // Basic validation passed
      return {
        passed: true,
        message: 'Certificate validation passed'
      };

    } catch (error) {
      logger.error('Certificate validation error:', error);
      return {
        passed: false,
        message: 'Certificate validation failed',
        error: error.message
      };
    }
  }

  async checkCompliance(lotData) {
    try {
      const results = [];
      let overallPassed = true;

      for (const rule of this.rules) {
        if (!rule.enabled) continue;

        logger.info(`Running compliance rule: ${rule.name}`, { lotId: lotData.lotId });

        const result = await rule.validate(lotData);
        
        results.push({
          ruleName: rule.name,
          ruleType: rule.type,
          passed: result.passed,
          message: result.message,
          details: result.details || {}
        });

        if (!result.passed) {
          overallPassed = false;
        }
      }

      logger.info('Compliance check completed', {
        lotId: lotData.lotId,
        passed: overallPassed,
        rulesChecked: results.length
      });

      return {
        passed: overallPassed,
        results,
        timestamp: new Date()
      };

    } catch (error) {
      logger.error('Compliance check failed:', error);
      throw error;
    }
  }

  async uploadToIPFS(file) {
    try {
      if (!this.ipfsClient) {
        throw new Error('IPFS client not initialized');
      }

      const result = await this.ipfsClient.add(file);
      const ipfsUrl = `ipfs://${result.path}`;
      const httpUrl = `https://ipfs.io/ipfs/${result.path}`;

      // Calculate hash for blockchain storage
      const hash = '0x' + crypto
        .createHash('sha256')
        .update(file)
        .digest('hex');

      logger.info('File uploaded to IPFS', {
        ipfsUrl,
        hash,
        size: result.size
      });

      return {
        ipfsUrl,
        httpUrl,
        hash,
        size: result.size
      };

    } catch (error) {
      logger.error('IPFS upload failed:', error);
      throw error;
    }
  }

  // Future V2 methods (placeholders for expansion)
  
  async validatePesticideLimits(lotData) {
    // TODO: Implement EU/FDA pesticide residue checks
    return { passed: true, message: 'Not implemented yet' };
  }

  async validatePackagingStandards(lotData) {
    // TODO: Implement FDA packaging requirements
    return { passed: true, message: 'Not implemented yet' };
  }

  async validateFumigationCertificate(lotData) {
    // TODO: Implement fumigation certificate validity check
    return { passed: true, message: 'Not implemented yet' };
  }

  async validateExportLicense(lotData) {
    // TODO: Implement APEDA export license verification
    return { passed: true, message: 'Not implemented yet' };
  }

  async loadRulesFromConfig(configPath) {
    // TODO: Load compliance rules from YAML/JSON file
    // This will be implemented in V2 for advanced compliance engine
    logger.info('Advanced rule loading not yet implemented');
  }
}

module.exports = ComplianceService;
