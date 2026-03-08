import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/district_model.dart';
import 'models/soil_type_model.dart';
import 'models/guide_step_model.dart';
import 'models/agronomy_guide_response_model.dart';
import 'services/agronomy_service.dart';
import '../../../../../widgets/loading_spinner.dart';
import '../../../../../widgets/empty_state.dart';
import '../../../../../widgets/language_picker_button.dart';
import '../../../../../providers/language_provider.dart';
import 'package:provider/provider.dart' as vanilla_provider;

// ─── Providers ────────────────────────────────────────────────────────────────

final _agronomyServiceProvider = Provider<AgronomyService>(
  (ref) => AgronomyService(),
);

final _districtsProvider = FutureProvider<List<District>>((ref) async {
  return ref.read(_agronomyServiceProvider).fetchAllDistricts();
});

final _soilsByDistrictProvider =
    FutureProvider.family<List<SoilType>, String>((ref, districtId) async {
  return ref.read(_agronomyServiceProvider).fetchSoilsByDistrict(districtId);
});

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

final _allGuidesByDistrictAndSoilProvider =
    FutureProvider.family<List<AgronomyGuideResponse>, _DistrictSoilKey>(
        (ref, key) async {
  return ref
      .read(_agronomyServiceProvider)
      .searchGuides(key.districtId, key.soilTypeId);
});

// ─── Page ─────────────────────────────────────────────────────────────────────

class AgronomyGuideScreen extends ConsumerStatefulWidget {
  const AgronomyGuideScreen({super.key});

  @override
  ConsumerState<AgronomyGuideScreen> createState() =>
      _AgronomyGuideScreenState();
}

class _AgronomyGuideScreenState extends ConsumerState<AgronomyGuideScreen> {
  District? _selectedDistrict;
  SoilType? _selectedSoilType;
  bool _hasSearched = false;
  _DistrictSoilKey? _cachedGuidesKey;

  String get _lang {
    if (!mounted) return 'en';
    return vanilla_provider.Provider.of<LanguageProvider>(context, listen: false).locale.languageCode;
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
    });
  }

  void _handleRefresh() {
    ref.invalidate(_districtsProvider);
    if (_selectedDistrict != null) {
      ref.invalidate(_soilsByDistrictProvider(_selectedDistrict!.id));
    }
    if (_hasSearched && _cachedGuidesKey != null) {
      ref.invalidate(_allGuidesByDistrictAndSoilProvider(_cachedGuidesKey!));
    }
  }

  @override
  Widget build(BuildContext context) {
    // The UI listens to languageProvider changes inherently if it's placed here,
    // but the global picker handles the state change itself.
    vanilla_provider.Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _lang == 'en' ? 'Agronomy Guide' : 'කෘෂිවිද්‍යා මාර්ගෝපදේශය'),
        elevation: 0,
        actions: const [
          LanguagePickerButton(),
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
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.8),
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
                                _lang == 'en'
                                    ? 'Planting Guide'
                                    : 'වගා මාර්ගෝපදේශය',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                        color:
                                            Colors.white.withOpacity(0.9),
                                        fontSize: 12),
                              ),
                              Text(
                                _lang == 'en'
                                    ? 'Agronomy Guide'
                                    : 'කෘෂිවිද්‍යා මාර්ගෝපදේශය',
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            _lang == 'en'
                                ? 'SEARCH GUIDES'
                                : 'මාර්ගෝපදේශ සොයන්න',
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

  // ─── Dropdowns ──────────────────────────────────────────────────────────────

  Widget _buildDistrictDropdown() {
    final districtsAsync = ref.watch(_districtsProvider);
    return districtsAsync.when(
      data: (districts) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonFormField<District>(
          value: _selectedDistrict,
          isExpanded: true,
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon:
                const Icon(Icons.location_on, color: Colors.grey),
            hintText: _lang == 'en'
                ? 'Select District'
                : 'දිස්ත්‍රික්කය තෝරන්න',
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
          icon: Icon(Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.primary),
          items: districts
              .map((d) => DropdownMenuItem(
                  value: d, child: Text(d.name.get(_lang))))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedDistrict = value;
              _selectedSoilType = null;
              _hasSearched = false;
              _cachedGuidesKey = null;
            });
            if (value != null) {
              ref.invalidate(_soilsByDistrictProvider(value.id));
            }
          },
        ),
      ),
      loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading districts: $e',
              style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildSoilTypeDropdown() {
    if (_selectedDistrict == null) return const SizedBox.shrink();
    final soilsAsync =
        ref.watch(_soilsByDistrictProvider(_selectedDistrict!.id));
    return soilsAsync.when(
      data: (soils) {
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
                  _lang == 'en'
                      ? 'No soil types specific to this district found.'
                      : 'මෙම දිස්ත්‍රික්කයට විශේෂිත පස වර්ග හමු නොවිණි.',
                  style: TextStyle(color: Colors.grey[800], fontSize: 13),
                ),
              ),
            ]),
          );
        }
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonFormField<SoilType>(
            value: _selectedSoilType,
            isExpanded: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon:
                  const Icon(Icons.landscape, color: Colors.grey),
              hintText: _lang == 'en'
                  ? 'Select Soil Type (Optional)'
                  : 'පස වර්ගය තෝරන්න (විකල්ප)',
              hintStyle: TextStyle(color: Colors.grey[600]),
            ),
            icon: Icon(Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.primary),
            items: [
              DropdownMenuItem<SoilType>(
                value: null,
                child: Text(
                    _lang == 'en'
                        ? 'All Soil Types'
                        : 'සියලුම පස වර්ග',
                    style: const TextStyle(color: Colors.black)),
              ),
              ...soils.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.typeName.get(_lang)))),
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
      },
      loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading soil types: $e',
              style: const TextStyle(color: Colors.red))),
    );
  }

  // ─── Guide Content ───────────────────────────────────────────────────────────

  Widget _buildGuidesContentSliver() {
    if (!_hasSearched || _cachedGuidesKey == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final guidesAsync =
        ref.watch(_allGuidesByDistrictAndSoilProvider(_cachedGuidesKey!));
    return guidesAsync.when(
      data: (guides) {
        if (guides.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              message: _lang == 'en'
                  ? 'No planting guides found matching your criteria.'
                  : 'ඔබගේ සෙවුමට ගැළපෙන මාර්ගෝපදේශ හමු නොවිණි.',
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
                padding: EdgeInsets.fromLTRB(
                    16, index == 0 ? 16 : 8, 16, 8),
                child: _buildGuideCard(uniqueGuides[index]),
              ),
              childCount: uniqueGuides.length,
            ),
          ),
        );
      },
      loading: () => SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingSpinner(
            message: _lang == 'en'
                ? 'Searching planting guides...'
                : 'සොයමින් පවතී...'),
      ),
      error: (e, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorState(e.toString()),
      ),
    );
  }

  Widget _buildGuideCard(AgronomyGuideResponse guide) {
    final soilTypeText = _selectedSoilType == null
        ? (_lang == 'en' ? 'All Suitable Soils' : 'සියලුම සුදුසු පස')
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
                      child: const Icon(Icons.eco,
                          color: Colors.white, size: 24),
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
                    _buildDetailRow(Icons.star, _lang == 'en' ? 'Specialities' : 'විශේෂතා',
                        guide.varietySpecialities.get(_lang), Colors.amber),
                  ],
                  if (guide.varietySoilTypeRecommendation.get(_lang).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.landscape, _lang == 'en' ? 'Soil Recommendation' : 'නිර්දේශිත පස',
                        guide.varietySoilTypeRecommendation.get(_lang), Colors.brown),
                  ],
                  if (guide.varietySuitabilityReason.get(_lang).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.help_outline, _lang == 'en' ? 'Why Suitable' : 'සුදුසු වීමට හේතුව',
                        guide.varietySuitabilityReason.get(_lang), Colors.blue),
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
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.list_alt,
                color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              _lang == 'en' ? 'Instructional Steps' : 'උපදෙස් පියවර',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.grey[800]),
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
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!, width: 1)),
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
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.3),
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
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800])),
                  const SizedBox(height: 8),
                  Text(step.details.get(_lang),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700], height: 1.5)),
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
            _lang == 'en'
                ? 'Error loading guide'
                : 'මාර්ගෝපදේශය පැටවීමේ දෝෂයකි',
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
            label: Text(
                _lang == 'en' ? 'Retry' : 'නැවත උත්සාහ කරන්න'),
          ),
        ],
      ),
    );
  }
}
