import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/lot_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../localization/app_localizations.dart';
import 'add_certification_screen.dart';
import 'add_processing_stage_screen.dart';
import 'create_auction_screen.dart';

class LotDetailsScreen extends StatelessWidget {
  final Lot lot;

  const LotDetailsScreen({super.key, required this.lot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.forestGreen,
        elevation: 0,
        title: Text(
          context.tr('label_lot_details'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(context.tr('message_share_coming_soon'))),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.forestGreen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lot.lotId,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.pepperGold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lot.variety,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(lot.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          lot.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Digital Passport QR Code
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.green.shade50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.forestGreen.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.qr_code_2,
                        color: AppTheme.forestGreen,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.tr('label_digital_passport'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.forestGreen.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: QrImageView(
                      data: _generateQRData(lot),
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppTheme.forestGreen,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Scan to view complete traceability',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(10),
                    shadowColor: AppTheme.forestGreen.withOpacity(0.3),
                    color: Colors.transparent,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: lot.lotId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.tr('message_lot_id_copied')),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(
                        context.tr('button_copy_lot_id'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.forestGreen,
                        side: BorderSide(
                          color: AppTheme.forestGreen,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: AppTheme.forestGreen.withOpacity(0.05),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lot Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('label_lot_information'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(context),
                  const SizedBox(height: 20),
                  // ML Quality Grading Section (only show for ML-detected grades)
                  if (['AAA', 'AA', 'A', 'B'].contains(lot.quality)) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.forestGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.science,
                            color: AppTheme.forestGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'ML Quality Grading',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.forestGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildMLQualityCard(context),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.forestGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.person,
                          color: AppTheme.forestGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.tr('label_farmer_details'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFarmerCard(context),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.forestGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.verified_user,
                          color: AppTheme.forestGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.tr('label_compliance_status'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildComplianceCard(context),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.forestGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.link,
                          color: AppTheme.forestGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.tr('label_blockchain_traceability'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.forestGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCertificationManagementCard(context),
                  const SizedBox(height: 16),
                  _buildTraceabilityCard(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateQRData(Lot lot) {
    // Generate JSON data for QR code containing all lot information including blockchain data
    return '''
{
  "lotId": "${lot.lotId}",
  "variety": "${lot.variety}",
  "quantity": ${lot.quantity},
  "harvestDate": "${lot.harvestDate.toIso8601String()}",
  "quality": "${lot.quality ?? 'N/A'}",
  "farmerName": "${lot.farmerName}",
  "farmerAddress": "${lot.farmerAddress}",
  "status": "${lot.status}",
  "complianceStatus": "${lot.complianceStatus}",
  "createdAt": "${lot.createdAt?.toIso8601String() ?? ''}",
  "blockchainTxHash": "${lot.blockchainTxHash ?? ''}",
  "certificateHash": "${lot.certificateHash ?? ''}",
  "certificateIpfsUrl": "${lot.certificateIpfsUrl ?? ''}",
  "origin": "${lot.origin ?? ''}",
  "farmLocation": "${lot.farmLocation ?? ''}",
  "organicCertified": ${lot.organicCertified ?? false}
}
''';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'auction':
        return Colors.orange;
      case 'sold':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoCard(BuildContext context) {
    final harvestDate =
        '${lot.harvestDate.year}-${lot.harvestDate.month.toString().padLeft(2, '0')}-${lot.harvestDate.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.scale,
            context.tr('label_quantity'),
            '${lot.quantity.toStringAsFixed(0)} kg',
          ),
          const Divider(height: 24),
          // Enhanced Quality Grade Display
          _buildQualityGradeRow(context),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.calendar_today,
            context.tr('label_harvest_date'),
            harvestDate,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.access_time,
            context.tr('label_created'),
            _getTimeAgo(lot.createdAt ?? DateTime.now()),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityGradeRow(BuildContext context) {
    final quality = lot.quality ?? 'N/A';
    final isMLGrade = ['AAA', 'AA', 'A', 'B'].contains(quality);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.forestGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isMLGrade ? Icons.science : Icons.star,
            color: AppTheme.forestGreen,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.tr('label_quality_grade'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isMLGrade) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.green.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 12,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'ML Detected',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    quality,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.forestGreen,
                    ),
                  ),
                  if (isMLGrade) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.lock,
                      size: 14,
                      color: AppTheme.pepperGold,
                    ),
                  ],
                ],
              ),
              if (isMLGrade)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Grade determined by ML quality system',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMLQualityCard(BuildContext context) {
    final quality = lot.quality ?? 'N/A';

    // Map the grade to ML classification
    String getMLClassification(String grade) {
      switch (grade) {
        case 'AAA':
          return 'Grade A (Premium High Density)';
        case 'AA':
          return 'Grade B (Standard High Quality)';
        case 'A':
          return 'Grade C (Lightweight / Industrial)';
        case 'B':
          return 'Grade D (Low Density / Waste)';
        default:
          return 'Unknown Classification';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.green.shade100.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.pepperGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.pepperGold,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.verified,
                  color: AppTheme.pepperGold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.science,
                          size: 16,
                          color: AppTheme.forestGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ML-Detected Quality',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quality,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.forestGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.green.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ML Classification',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  getMLClassification(quality),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This grade was determined by the ML quality grading system using density analysis and visual inspection',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[900],
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.lock,
                size: 14,
                color: AppTheme.pepperGold,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Grade locked and cannot be modified',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.person,
            context.tr('label_farmer_name'),
            lot.farmerName,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.account_balance_wallet,
            context.tr('label_wallet_address'),
            lot.farmerAddress.length > 18
                ? '${lot.farmerAddress.substring(0, 10)}...${lot.farmerAddress.substring(lot.farmerAddress.length - 8)}'
                : lot.farmerAddress,
            copyable: lot.farmerAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceCard(BuildContext context) {
    final statusLower = lot.complianceStatus.toLowerCase();
    final complianceColor =
        (statusLower == 'approved' || statusLower == 'passed')
            ? Colors.green
            : statusLower == 'pending'
                ? Colors.orange
                : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            complianceColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: complianceColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: complianceColor.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: complianceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              (statusLower == 'approved' || statusLower == 'passed')
                  ? Icons.check_circle
                  : statusLower == 'pending'
                      ? Icons.pending
                      : Icons.cancel,
              color: complianceColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lot.complianceStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: complianceColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getComplianceMessage(lot.complianceStatus),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationManagementCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('label_certifications_compliance'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('subtitle_manage_certificates'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(12),
                    shadowColor: Colors.blue.withOpacity(0.3),
                    color: Colors.transparent,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddCertificationScreen(lotId: lot.lotId),
                          ),
                        );
                        if (result == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  context.tr('message_refresh_certifications'),
                                  style: const TextStyle(color: Colors.white)),
                              backgroundColor: AppTheme.forestGreen,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: Text(
                        context.tr('button_add_certificate'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue, width: 2),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.blue.withOpacity(0.05),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    shadowColor: AppTheme.forestGreen.withOpacity(0.4),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.forestGreen,
                            AppTheme.forestGreen.withOpacity(0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _runComplianceCheck(context),
                        icon: const Icon(Icons.fact_check, size: 20),
                        label: Text(
                          context.tr('button_check_compliance'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(12),
              shadowColor: AppTheme.forestGreen.withOpacity(0.3),
              color: Colors.transparent,
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddProcessingStageScreen(lotId: lot.lotId),
                      ),
                    );
                    if (result == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              context.tr('message_processing_stage_added'),
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: AppTheme.forestGreen,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.factory, size: 20),
                  label: Text(
                    context.tr('button_add_processing_stage'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.forestGreen,
                    side: BorderSide(
                      color: AppTheme.forestGreen,
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppTheme.forestGreen.withOpacity(0.05),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildCreateAuctionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAuctionButton(BuildContext context) {
    // Get current user's wallet address
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserAddress = authProvider.user?.walletAddress?.toLowerCase();
    final lotOwnerAddress = lot.farmerAddress.toLowerCase();

    // Only show button if:
    // 1. User is authenticated
    // 2. User is the lot owner
    // 3. Lot status is approved, available, or passed
    final isOwner =
        currentUserAddress != null && currentUserAddress == lotOwnerAddress;
    final normalizedStatus = lot.complianceStatus.toLowerCase().trim();
    final canCreateAuction = isOwner &&
        (normalizedStatus == 'approved' || normalizedStatus == 'passed');

    if (!canCreateAuction) {
      return const SizedBox.shrink();
    } else {
      return Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(12),
        shadowColor: AppTheme.pepperGold.withOpacity(0.5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.pepperGold,
                AppTheme.pepperGold.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.pepperGold.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateAuctionScreen(
                      preselectedLot: lot,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.gavel, size: 22),
              label: Text(
                context.tr('button_create_auction_lot'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppTheme.forestGreen,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _runComplianceCheck(BuildContext context) async {
    // Show destination selection dialog
    final destination = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('dialog_select_destination_market')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('subtitle_choose_export_market')),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.public, color: Colors.blue),
              title: Text(context.tr('market_eu')),
              onTap: () => Navigator.pop(context, 'EU'),
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: Text(context.tr('market_us_fda')),
              onTap: () => Navigator.pop(context, 'FDA'),
            ),
            ListTile(
              leading: const Icon(Icons.landscape, color: Colors.orange),
              title: Text(context.tr('market_middle_east')),
              onTap: () => Navigator.pop(context, 'MIDDLE_EAST'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('button_cancel')),
          ),
        ],
      ),
    );

    if (destination == null || !context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(context.tr('message_running_compliance_check')),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final apiService = ApiService();
      final response = await apiService.post(
        '/compliance/check/${lot.lotId}',
        {'destination': destination},
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        if (response['success'] == true) {
          final status = response['complianceStatus'];
          final passedCount = response['passedCount'] ?? 0;
          final failedCount = response['failedCount'] ?? 0;
          final totalCount = response['results']?.length ?? 0;

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(
                    status == 'passed' ? Icons.check_circle : Icons.cancel,
                    color: status == 'passed' ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                      'Compliance ${status == 'passed' ? 'Passed' : 'Failed'}'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${context.tr('label_total_checks')} $totalCount'),
                  Text('${context.tr('label_passed')} $passedCount',
                      style: const TextStyle(color: Colors.green)),
                  Text('${context.tr('label_failed')} $failedCount',
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('message_view_full_traceability'),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    context.tr('button_close'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.forestGreen,
                          AppTheme.forestGreen.withOpacity(0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/traceability/${lot.lotId}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        context.tr('button_view_details'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          throw Exception(response['error'] ?? 'Compliance check failed');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('label_error')} ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTraceabilityCard(BuildContext context) {
    final hasBlockchainData =
        lot.blockchainTxHash != null && lot.blockchainTxHash!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.green.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasBlockchainData
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasBlockchainData ? Icons.verified : Icons.pending,
                  color: hasBlockchainData ? Colors.green : Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasBlockchainData
                          ? 'Blockchain Verified'
                          : 'Pending Blockchain',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasBlockchainData
                          ? 'Immutable on-chain record'
                          : 'Awaiting blockchain confirmation',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasBlockchainData) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Transaction Hash
            _buildTraceabilityRow(
              icon: Icons.receipt_long,
              label: context.tr('label_transaction_hash'),
              value: lot.blockchainTxHash!.length > 20
                  ? '${lot.blockchainTxHash!.substring(0, 10)}...${lot.blockchainTxHash!.substring(lot.blockchainTxHash!.length - 8)}'
                  : lot.blockchainTxHash!,
              fullValue: lot.blockchainTxHash,
              context: context,
            ),

            const SizedBox(height: 16),

            // Certificate Hash
            if (lot.certificateHash != null &&
                lot.certificateHash!.isNotEmpty) ...[
              _buildTraceabilityRow(
                icon: Icons.fingerprint,
                label: 'Certificate Hash',
                value: lot.certificateHash!.length > 20
                    ? '${lot.certificateHash!.substring(0, 10)}...${lot.certificateHash!.substring(lot.certificateHash!.length - 8)}'
                    : lot.certificateHash!,
                fullValue: lot.certificateHash,
                context: context,
              ),
              const SizedBox(height: 16),
            ],

            // IPFS URL
            if (lot.certificateIpfsUrl != null &&
                lot.certificateIpfsUrl!.isNotEmpty) ...[
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${context.tr('label_ipfs')} ${lot.certificateIpfsUrl}'),
                      action: SnackBarAction(
                        label: context.tr('button_copy'),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: lot.certificateIpfsUrl!));
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'IPFS Certificate',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to view details',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new,
                          color: Colors.blue, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Origin & Farm Location
            if (lot.origin != null || lot.farmLocation != null) ...[
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: AppTheme.forestGreen, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Origin Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (lot.origin != null)
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(
                    'Origin: ${lot.origin}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              if (lot.farmLocation != null)
                Padding(
                  padding: const EdgeInsets.only(left: 28, top: 4),
                  child: Text(
                    'Farm: ${lot.farmLocation}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              if (lot.organicCertified == true)
                Padding(
                  padding: const EdgeInsets.only(left: 28, top: 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Organic Certified',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Action Buttons
            if (lot.blockchainTxHash != null) ...[
              Row(
                children: [
                  // View Full Traceability Button
                  Expanded(
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      shadowColor: AppTheme.forestGreen.withOpacity(0.4),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.forestGreen,
                              AppTheme.forestGreen.withOpacity(0.85),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push('/traceability/${lot.lotId}');
                          },
                          icon: const Icon(Icons.timeline, size: 20),
                          label: Text(
                            context.tr('button_full_traceability'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // View on Blockchain Button (Quick Info)
                  Expanded(
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(12),
                      shadowColor: Colors.green.withOpacity(0.3),
                      color: Colors.transparent,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final blockchainUrl = 'http://192.168.8.173:8545';
                          // Show blockchain details dialog
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Row(
                                  children: [
                                    const Icon(Icons.link,
                                        color: AppTheme.forestGreen),
                                    const SizedBox(width: 8),
                                    Text(context
                                        .tr('label_blockchain_traceability')),
                                  ],
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr(
                                            'message_blockchain_registered'),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Transaction Hash:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: SelectableText(
                                                lot.blockchainTxHash!,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.copy,
                                                  size: 18),
                                              onPressed: () {
                                                Clipboard.setData(
                                                  ClipboardData(
                                                      text: lot
                                                          .blockchainTxHash!),
                                                );
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Transaction hash copied!'),
                                                    duration:
                                                        Duration(seconds: 1),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Blockchain Network:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.green.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Hardhat Local Network',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    blockchainUrl,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey.shade700,
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.blue.shade200),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'This transaction is permanently recorded and cannot be altered, ensuring complete transparency.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(context.tr('button_close')),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.open_in_new, size: 20),
                        label: Text(
                          context.tr('button_quick_info'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color.fromARGB(255, 48, 110, 50),
                          side: BorderSide(
                              color: const Color.fromARGB(255, 45, 105, 47),
                              width: 2),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: const Color.fromARGB(255, 38, 88, 40)
                              .withOpacity(0.05),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This lot will be recorded on blockchain once approved',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTraceabilityRow({
    required IconData icon,
    required String label,
    required String value,
    String? fullValue,
    required BuildContext context,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.forestGreen, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        if (fullValue != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: fullValue));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {String? copyable}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.forestGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (copyable != null)
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: copyable));
            },
            color: AppTheme.forestGreen,
          ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getComplianceMessage(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'passed':
        return 'All compliance checks passed';
      case 'pending':
        return 'Awaiting compliance verification';
      case 'rejected':
      case 'failed':
        return 'Compliance issues detected';
      case 'partial':
        return 'Some compliance checks pending';
      default:
        return 'Status unknown';
    }
  }
}
