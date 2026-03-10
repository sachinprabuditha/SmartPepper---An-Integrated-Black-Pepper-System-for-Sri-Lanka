import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/district_model.dart';
import 'models/soil_type_model.dart';
import 'models/guide_step_model.dart';
import 'models/agronomy_guide_response_model.dart';
import 'services/agronomy_service.dart';
import '../../../../../widgets/loading_spinner.dart';
import '../../../../../widgets/empty_state.dart';
import '../../../../../providers/language_provider.dart';
import '../../../../../localization/app_localizations.dart';
import '../../../../../config/theme.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _DistrictSoilKey {
  final String districtId;
  final String? soilTypeId;

  _DistrictSoilKey(this.districtId, this.soilTypeId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _DistrictSoilKey &&
          runtimeType == other.runtimeType &&
          districtId == other.districtId &&
          soilTypeId == other.soilTypeId;

  @override
  int get hashCode => districtId.hashCode ^ soilTypeId.hashCode;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class AgronomyGuideScreen extends StatefulWidget {
  const AgronomyGuideScreen({super.key});

  @override
  State<AgronomyGuideScreen> createState() => _AgronomyGuideScreenState();
}

class _AgronomyGuideScreenState extends State<AgronomyGuideScreen> {
  final AgronomyService _agronomyService = AgronomyService();

  District? _selectedDistrict;
  SoilType? _selectedSoilType;
  bool _hasSearched = false;
  _DistrictSoilKey? _cachedGuidesKey;

  // Future variables
  late Future<List<District>> _districtsFuture;
  Future<List<SoilType>>? _soilsFuture;
  Future<List<AgronomyGuideResponse>>? _guidesFuture;

  @override
  void initState() {
    super.initState();
    _districtsFuture = _agronomyService.fetchAllDistricts();
  }

  String get _lang {
    if (!mounted) return 'en';
    return Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;
  }

  void _handleSearch() {
    if (_selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a district to search.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() {
      _hasSearched = true;
      _cachedGuidesKey =
          _DistrictSoilKey(_selectedDistrict!.id, _selectedSoilType?.id);
      _guidesFuture = _agronomyService.searchGuides(
          _cachedGuidesKey!.districtId, _cachedGuidesKey!.soilTypeId);
    });
  }

  void _handleRefresh() {
    setState(() {
      _districtsFuture = _agronomyService.fetchAllDistricts();
      if (_selectedDistrict != null) {
        _soilsFuture =
            _agronomyService.fetchSoilsByDistrict(_selectedDistrict!.id);
      }
      if (_hasSearched && _cachedGuidesKey != null) {
        _guidesFuture = _agronomyService.searchGuides(
            _cachedGuidesKey!.districtId, _cachedGuidesKey!.soilTypeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // The UI listens to languageProvider changes inherently if it's placed here,
    // but the global picker handles the state change itself.
    Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('plantation_agronomy_guide')),
        elevation: 0,
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _handleRefresh(),
        child: CustomScrollView(
          slivers: [
            // Header
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
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.eco,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('agronomy_planting_guide'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12),
                              ),
                              Text(
                                context.tr('plantation_agronomy_guide'),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      _buildDistrictDropdown(),
                      if (_selectedDistrict != null) ...[
                        const SizedBox(height: 16),
                        _buildSoilTypeDropdown(),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            context.tr('agronomy_search_guides'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Results
            !_hasSearched
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      message: _selectedDistrict == null
                          ? context.tr('agronomy_select_district_to_search')
                          : context.tr('agronomy_click_search_varieties'),
                      icon: Icons.search,
                    ),
                  )
                : _buildGuidesContentSliver(),
          ],
        ),
      ),
    );
  }

  // ─── Dropdowns ──────────────────────────────────────────────────────────────

  Widget _buildDistrictDropdown() {
    return FutureBuilder<List<District>>(
      future: _districtsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                  context.tr('plantation_error_loading_districts') +
                      ': ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)));
        } else if (snapshot.hasData) {
          final districts = snapshot.data!;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonFormField<District>(
              value: _selectedDistrict,
              isExpanded: true,
              hint: Text(
                context.tr('agronomy_select_district'),
                style: const TextStyle(color: Colors.white70),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(Icons.location_on, color: AppTheme.pepperGold),
                hintText: context.tr('agronomy_select_district'),
                hintStyle: const TextStyle(color: Colors.white70),
              ),
              dropdownColor: AppTheme.deepEmerald,
              style: const TextStyle(color: Colors.white),
              icon: Icon(Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.primary),
              items: districts
                  .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d.name.get(_lang),
                          style: const TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDistrict = value;
                  _selectedSoilType = null;
                  _hasSearched = false;
                  _cachedGuidesKey = null;
                });
                if (value != null) {
                  setState(() {
                    _soilsFuture =
                        _agronomyService.fetchSoilsByDistrict(value.id);
                  });
                }
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSoilTypeDropdown() {
    if (_selectedDistrict == null || _soilsFuture == null)
      return const SizedBox.shrink();
    return FutureBuilder<List<SoilType>>(
      future: _soilsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading soil types: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)));
        } else if (snapshot.hasData) {
          final soils = snapshot.data!;
          if (soils.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.orange[800]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('agronomy_no_soil_for_district'),
                    style: TextStyle(color: Colors.grey[800], fontSize: 13),
                  ),
                ),
              ]),
            );
          }
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonFormField<SoilType>(
              value: _selectedSoilType,
              isExpanded: true,
              hint: Text(
                context.tr('agronomy_select_soil_optional'),
                style: const TextStyle(color: Colors.white70),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(Icons.landscape, color: AppTheme.pepperGold),
                hintText: context.tr('agronomy_select_soil_optional'),
                hintStyle: const TextStyle(color: Colors.white70),
              ),
              dropdownColor: AppTheme.deepEmerald,
              style: const TextStyle(color: Colors.white),
              icon: Icon(Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.primary),
              items: [
                DropdownMenuItem<SoilType>(
                  value: null,
                  child: Text(context.tr('agronomy_all_soil_types'),
                      style: const TextStyle(color: Colors.white)),
                ),
                ...soils.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.typeName.get(_lang),
                        style: const TextStyle(color: Colors.white)))),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSoilType = value;
                  _hasSearched = false;
                  _cachedGuidesKey = null;
                });
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  // ─── Guide Content ───────────────────────────────────────────────────────────

  Widget _buildGuidesContentSliver() {
    if (!_hasSearched || _guidesFuture == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return FutureBuilder<List<AgronomyGuideResponse>>(
      future: _guidesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: LoadingSpinner(
                message: context.tr('agronomy_searching_guides')),
          );
        } else if (snapshot.hasError) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _buildErrorState(snapshot.error.toString()),
          );
        } else if (snapshot.hasData) {
          final guides = snapshot.data!;
          if (guides.isEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                message: context.tr('agronomy_no_guides_found'),
                icon: Icons.search_off,
              ),
            );
          }
          // Deduplicate by varietyId
          final seenVarieties = <String>{};
          final uniqueGuides = <AgronomyGuideResponse>[];
          for (final guide in guides) {
            if (!seenVarieties.contains(guide.varietyId)) {
              seenVarieties.add(guide.varietyId);
              uniqueGuides.add(guide);
            }
          }
          return SliverPadding(
            padding: const EdgeInsets.only(bottom: 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: EdgeInsets.fromLTRB(16, index == 0 ? 16 : 8, 16, 8),
                  child: _buildGuideCard(uniqueGuides[index]),
                ),
                childCount: uniqueGuides.length,
              ),
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildGuideCard(AgronomyGuideResponse guide) {
    final soilTypeText = _selectedSoilType == null
        ? context.tr('agronomy_all_suitable_soils')
        : guide.soilTypeName.get(_lang);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green[50]!.withOpacity(0.3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          const Icon(Icons.eco, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guide.varietyName.get(_lang),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${guide.districtName.get(_lang)} • $soilTypeText',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  if (guide.varietySpecialities.get(_lang).isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                        Icons.star,
                        context.tr('plantation_specialities'),
                        guide.varietySpecialities.get(_lang),
                        Colors.amber),
                  ],
                  if (guide.varietySoilTypeRecommendation
                      .get(_lang)
                      .isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        Icons.landscape,
                        context.tr('agronomy_soil_recommendation'),
                        guide.varietySoilTypeRecommendation.get(_lang),
                        Colors.brown),
                  ],
                  if (guide.varietySuitabilityReason.get(_lang).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        Icons.help_outline,
                        context.tr('agronomy_why_suitable'),
                        guide.varietySuitabilityReason.get(_lang),
                        Colors.blue),
                  ],
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
                          Row(children: [
                            Icon(Icons.square_foot,
                                color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Planting Specifications',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700]),
                            ),
                          ]),
                          if (guide.varietySpacingMeters.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildSpecRow(Icons.straighten, 'Spacing',
                                guide.varietySpacingMeters),
                          ],
                          if (guide.varietyVinesPerHectare != null) ...[
                            const SizedBox(height: 8),
                            _buildSpecRow(Icons.grid_view, 'Vines/Ha',
                                '${guide.varietyVinesPerHectare}'),
                          ],
                          if (guide.varietyPitDimensionsCm.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildSpecRow(Icons.crop_square, 'Pit Size',
                                guide.varietyPitDimensionsCm),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
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

  Widget _buildDetailRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.withOpacity(0.8))),
              const SizedBox(height: 4),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[700])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 18, color: Colors.grey[600]),
      const SizedBox(width: 8),
      Text('$label:',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(value.isNotEmpty ? value : 'N/A',
            style: Theme.of(context).textTheme.bodyMedium),
      ),
    ]);
  }

  Widget _buildStepsSection(List<GuideStep> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
              color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.list_alt,
                color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr('agronomy_instructional_steps'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        ...steps.map((step) => _buildStepCard(step)),
      ],
    );
  }

  Widget _buildStepCard(GuideStep step) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      color: const Color(0xFF0A3D24), // Darker green for contrast
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFB8860B), // Dark Golden Rod
                    Color(0xFFDAA520), // Golden Rod
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
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
                      fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title.get(_lang),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(step.details.get(_lang),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9), height: 1.5)),
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
            context.tr('agronomy_error_loading_guide'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(error,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _hasSearched = false;
                _cachedGuidesKey = null;
              });
            },
            icon: const Icon(Icons.refresh),
            label: Text(context.tr('common_retry')),
          ),
        ],
      ),
    );
  }
}
