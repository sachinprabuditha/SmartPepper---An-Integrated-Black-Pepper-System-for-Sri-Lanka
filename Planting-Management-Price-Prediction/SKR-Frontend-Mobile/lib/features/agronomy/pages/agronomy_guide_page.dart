import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/district_model.dart';
import '../models/soil_type_model.dart';
import '../models/variety_model.dart';
import '../models/guide_step_model.dart';
import '../models/agronomy_guide_response_model.dart';
import '../services/agronomy_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/loading_spinner.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/dropdown_field.dart';

// Provider for AgronomyService
final agronomyServiceProvider = Provider<AgronomyService>((ref) {
  return AgronomyService(ApiClient());
});

// Provider for all districts
final districtsProvider = FutureProvider<List<District>>((ref) async {
  final service = ref.read(agronomyServiceProvider);
  return await service.fetchAllDistricts();
});

// Provider for soil types by district
final soilsByDistrictProvider = FutureProvider.family<List<SoilType>, String>(
  (ref, districtId) async {
    final service = ref.read(agronomyServiceProvider);
    return await service.fetchSoilsByDistrict(districtId);
  },
);

// Provider for all guides (with variety details and steps) by district and soil type
// Using a custom key class to ensure stable comparison
class DistrictSoilKey {
  final String districtId;
  final String? soilTypeId; // Made optional

  DistrictSoilKey(this.districtId, this.soilTypeId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistrictSoilKey &&
          runtimeType == other.runtimeType &&
          districtId == other.districtId &&
          soilTypeId == other.soilTypeId;

  @override
  int get hashCode => districtId.hashCode ^ soilTypeId.hashCode;
}

final allGuidesByDistrictAndSoilProvider = FutureProvider.family<List<AgronomyGuideResponse>, DistrictSoilKey>(
  (ref, key) async {
    final service = ref.read(agronomyServiceProvider);
    return await service.searchGuides(
      key.districtId,
      key.soilTypeId,
    );
  },
);

// Provider for agronomy guide
// Using a custom key class to ensure stable comparison
class GuideKey {
  final String districtId;
  final String soilTypeId;
  final String varietyId;

  GuideKey(this.districtId, this.soilTypeId, this.varietyId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuideKey &&
          runtimeType == other.runtimeType &&
          districtId == other.districtId &&
          soilTypeId == other.soilTypeId &&
          varietyId == other.varietyId;

  @override
  int get hashCode => districtId.hashCode ^ soilTypeId.hashCode ^ varietyId.hashCode;
}

final agronomyGuideProvider = FutureProvider.family<AgronomyGuideResponse?, GuideKey>(
  (ref, key) async {
    final service = ref.read(agronomyServiceProvider);
    try {
      return await service.fetchGuide(
        districtId: key.districtId,
        soilTypeId: key.soilTypeId,
        varietyId: key.varietyId,
      );
    } catch (e) {
      throw Exception('Failed to load guide: $e');
    }
  },
);

class AgronomyGuidePage extends ConsumerStatefulWidget {
  const AgronomyGuidePage({super.key});

  @override
  ConsumerState<AgronomyGuidePage> createState() => _AgronomyGuidePageState();
}

class _AgronomyGuidePageState extends ConsumerState<AgronomyGuidePage> {
  District? _selectedDistrict;
  SoilType? _selectedSoilType;
  bool _hasSearched = false; // Track if user has clicked search
  
  // Memoized key to prevent recreation on every build
  DistrictSoilKey? _cachedGuidesKey;

  void _handleSearch() {
    if (_selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a district to search.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _hasSearched = true;
      _cachedGuidesKey = DistrictSoilKey(
        _selectedDistrict!.id, 
        _selectedSoilType?.id
      );
    });
  }

  void _handleRefresh() {
    ref.invalidate(districtsProvider);
    if (_selectedDistrict != null) {
      ref.invalidate(soilsByDistrictProvider(_selectedDistrict!.id));
    }
    if (_hasSearched && _cachedGuidesKey != null) {
      ref.invalidate(allGuidesByDistrictAndSoilProvider(_cachedGuidesKey!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agronomy Guide'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _handleRefresh(),
        child: CustomScrollView(
          slivers: [
          // Header section with district selection
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Planting Guide',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                              ),
                              Text(
                                'Agronomy Guide',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // District Selection
                    _buildDistrictDropdown(),
                    if (_selectedDistrict != null) ...[
                      const SizedBox(height: 16),
                      _buildSoilTypeDropdown(),
                    ],
                    const SizedBox(height: 24),
                    // Search Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'SEARCH GUIDES',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Guide Content
          !_hasSearched
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    message: _selectedDistrict == null
                        ? 'Select a district to search.'
                        : 'Click search to find varieties.',
                    icon: Icons.search,
                  ),
                )
              : _buildGuidesContentSliver(),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    final districtsAsync = ref.watch(districtsProvider);

    return districtsAsync.when(
      data: (districts) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<District>(
            value: _selectedDistrict,
            isExpanded: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
              hintText: 'Select District',
              hintStyle: TextStyle(color: Colors.grey[600]),
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.primary,
            ),
            items: districts.map((district) {
              return DropdownMenuItem(
                value: district,
                child: Text(district.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDistrict = value;
                _selectedSoilType = null;
                // Don't reset _hasSearched immediately if you want to keep results 
                // until new search, but usually changing inputs should invalidate results.
                _hasSearched = false; 
                _cachedGuidesKey = null;
              });
              if (value != null) {
                ref.invalidate(soilsByDistrictProvider(value.id));
              }
            },
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading districts: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildSoilTypeDropdown() {
    if (_selectedDistrict == null) return const SizedBox.shrink();

    final soilsAsync = ref.watch(soilsByDistrictProvider(_selectedDistrict!.id));

    return soilsAsync.when(
      data: (soils) {
        if (soils.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9), // Improved visibility on colored bg
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[800]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No soil types specific to this district found.',
                    style: TextStyle(color: Colors.grey[800], fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<SoilType>(
            value: _selectedSoilType,
            isExpanded: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.landscape, color: Colors.grey),
              hintText: 'Select Soil Type (Optional)', // Updated hint
              hintStyle: TextStyle(color: Colors.grey[600]),
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.primary,
            ),
            items: [
              // Add option to deselect soil type
              const DropdownMenuItem<SoilType>(
                value: null,
                child: Text('All Soil Types', style: TextStyle(color: Colors.black)),
              ),
              ...soils.map((soil) {
                return DropdownMenuItem(
                  value: soil,
                  child: Text(soil.typeName),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedSoilType = value;
                _hasSearched = false; // Require re-search on change
                _cachedGuidesKey = null;
              });
            },
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading soil types: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildGuidesContentSliver() {
    if (!_hasSearched || _cachedGuidesKey == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final guidesAsync = ref.watch(allGuidesByDistrictAndSoilProvider(_cachedGuidesKey!));

    return guidesAsync.when(
      data: (guides) {
        if (guides.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              message: 'No planting guides found matching your criteria.',
              icon: Icons.search_off,
            ),
          );
        }
        return _buildAllGuidesSliver(guides);
      },
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingSpinner(message: 'Searching planting guides...'),
      ),
      error: (error, stack) => SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildAllGuidesSliver(List<AgronomyGuideResponse> guides) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 80),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final guide = guides[index];
            return Padding(
              padding: EdgeInsets.fromLTRB(16, index == 0 ? 16 : 8, 16, 8),
              child: _buildVarietyGuideCard(guide),
            );
          },
          childCount: guides.length,
        ),
      ),
    );
  }

  Widget _buildVarietyGuideCard(AgronomyGuideResponse guide) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.green[50]!.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Variety Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guide.varietyName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${guide.districtName} • ${guide.soilTypeName}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Variety Details
                  if (guide.varietySpecialities.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.star,
                      'Specialities',
                      guide.varietySpecialities,
                      Colors.amber,
                    ),
                  ],
                  if (guide.varietySoilTypeRecommendation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.landscape,
                      'Soil Recommendation',
                      guide.varietySoilTypeRecommendation,
                      Colors.brown,
                    ),
                  ],
                  if (guide.varietySuitabilityReason.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.help_outline,
                      'Why Suitable',
                      guide.varietySuitabilityReason,
                      Colors.blue,
                    ),
                  ],
                  // Planting Specifications
                  if (guide.varietySpacingMeters.isNotEmpty || 
                      guide.varietyVinesPerHectare != null || 
                      guide.varietyPitDimensionsCm.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.square_foot, color: Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Planting Specifications',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                              ),
                            ],
                          ),
                          if (guide.varietySpacingMeters.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildSpecRow(Icons.straighten, 'Spacing', guide.varietySpacingMeters),
                          ],
                          if (guide.varietyVinesPerHectare != null) ...[
                            const SizedBox(height: 8),
                            _buildSpecRow(Icons.grid_view, 'Vines/Ha', '${guide.varietyVinesPerHectare}'),
                          ],
                          if (guide.varietyPitDimensionsCm.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildSpecRow(Icons.crop_square, 'Pit Size', guide.varietyPitDimensionsCm),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Guide Steps
            if (guide.steps.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: _buildStepsSection(guide.steps),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVarietiesSection(List<BlackPepperVariety> varieties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.eco,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Suitable Varieties',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Varieties List
        ...varieties.map((variety) => _buildVarietyTile(variety)),
      ],
    );
  }

  Widget _buildVarietyTile(BlackPepperVariety variety) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showVarietyDetails(variety);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.green[50]!.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        variety.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        variety.specialities,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVarietyDetails(BlackPepperVariety variety) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Variety name header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.grass, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      variety.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Soil Type Recommendation
              _buildDetailCard(
                icon: Icons.landscape,
                title: 'Suitable Soil',
                content: variety.soilTypeRecommendation,
                color: Colors.brown,
              ),
              const SizedBox(height: 16),
              
              // Specialities
              _buildDetailCard(
                icon: Icons.star,
                title: 'Specialities',
                content: variety.specialities,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              
              // Suitability Reason
              _buildDetailCard(
                icon: Icons.help_outline,
                title: 'Why here?',
                content: variety.suitabilityReason,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              
              // Planting Specifications
              _buildSpecificationsCard(variety.plantingSpecifications),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.withOpacity(0.8),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content.isNotEmpty ? content : 'Not specified',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsCard(PlantingSpecifications specs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.square_foot, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Planting Specifications',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSpecRow(Icons.straighten, 'Spacing', specs.spacingMeters),
          const SizedBox(height: 12),
          _buildSpecRow(Icons.grid_view, 'Vines/Ha', '${specs.vinesPerHectare}'),
          const SizedBox(height: 12),
          _buildSpecRow(Icons.crop_square, 'Pit Size', specs.pitDimensionsCm),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.withOpacity(0.8),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'N/A',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildStepsSection(List<GuideStep> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.list_alt,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Instructional Steps',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Steps List
        ...steps.map((step) => _buildStepCard(step)),
      ],
    );
  }

  Widget _buildStepCard(GuideStep step) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${step.stepNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.details,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading guide',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (_selectedDistrict != null && _selectedSoilType != null) {
                ref.invalidate(allGuidesByDistrictAndSoilProvider(
                  DistrictSoilKey(_selectedDistrict!.id, _selectedSoilType!.id),
                ));
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
