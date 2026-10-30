// lib/features/campus/presentation/pages/campus_home_page.dart

import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/locale/language_toggle_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/di/injector.dart';
import '../../../mapas/infrastructure/api/campus_layers_repository.dart';
import '../../application/campus_filter.dart';
import '../../data/mock_places.dart';
import '../../domain/entities.dart';
import '../category_labels.dart';

class CampusHomePage extends StatefulWidget {
  const CampusHomePage({super.key});

  @override
  State<CampusHomePage> createState() => _CampusHomePageState();
}

class _CampusHomePageState extends State<CampusHomePage> {
  final CampusFilter _filter = getIt<CampusFilter>();

  Set<PlaceCategory> get _selected => _filter.value;

  /// Categorias con ubicacion en el modelo 3D (vacio mientras carga o sin datos).
  Set<String> _available = const {};

  @override
  void initState() {
    super.initState();
    _filter.addListener(_onFilterChanged);
    getIt<CampusLayersRepository>().load().then((layers) {
      if (mounted) setState(() => _available = layers.categories);
    });
  }

  @override
  void dispose() {
    _filter.removeListener(_onFilterChanged);
    super.dispose();
  }

  void _onFilterChanged() => setState(() {});

  List<CampusPlace> get _filteredPlaces {
    if (_selected.isEmpty) return mockCampusPlaces;
    return mockCampusPlaces
        .where((p) => _selected.contains(p.category))
        .toList();
  }

  void _selectCategory(PlaceCategory? category) {
    _filter.selectOnly(category);
    Navigator.of(context).pop();
  }

  String _title(AppLocalizations l10n) {
    if (_selected.isEmpty) return l10n.appTitle;
    if (_selected.length == 1) return categoryLabel(context, _selected.first);
    return l10n.categoriesCount(_selected.length);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title(l10n)),
        actions: [
          const LanguageToggleButton(),
        ],
      ),
      drawer: _CategoryDrawer(
        selected: _selected,
        available: _available,
        onSelect: _selectCategory,
      ),
      body: _filteredPlaces.isEmpty
          ? Center(child: Text(l10n.emptyCategoryMessage))
          : ListView.separated(
              itemCount: _filteredPlaces.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final place = _filteredPlaces[index];
                return ListTile(
                  leading: Icon(place.category.icon, color: AppTheme.primary),
                  title: Text(place.nameFor(languageCode)),
                  subtitle: Text(place.locationFor(languageCode)),
                );
              },
            ),
    );
  }
}

class _CategoryDrawer extends StatelessWidget {
  final Set<PlaceCategory> selected;
  final Set<String> available;
  final ValueChanged<PlaceCategory?> onSelect;

  const _CategoryDrawer({
    required this.selected,
    required this.available,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      backgroundColor: AppTheme.primary,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      'assets/iconutb.jpg',
                      width: 44,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.appTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n.filterByPlace,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white24),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
                    icon: Icons.apps_outlined,
                    label: l10n.allPlaces,
                    selected: selected.isEmpty,
                    onTap: () => onSelect(null),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ...PlaceCategory.values
                      .where((c) => available.isEmpty || available.contains(c.name))
                      .map(
                    (category) => _DrawerItem(
                      icon: category.icon,
                      label: categoryLabel(context, category),
                      selected: selected.contains(category),
                      onTap: () => onSelect(category),
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
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: selected ? AppTheme.skyBlue : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: selected ? Colors.white : Colors.white70),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
