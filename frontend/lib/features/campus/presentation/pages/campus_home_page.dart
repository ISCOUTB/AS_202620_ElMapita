// lib/features/campus/presentation/pages/campus_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/locale/locale_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/mock_places.dart';
import '../../domain/entities.dart';
import '../category_labels.dart';

class CampusHomePage extends StatefulWidget {
  const CampusHomePage({super.key});

  @override
  State<CampusHomePage> createState() => _CampusHomePageState();
}

class _CampusHomePageState extends State<CampusHomePage> {
  PlaceCategory? _selectedCategory;

  List<CampusPlace> get _filteredPlaces {
    if (_selectedCategory == null) return mockCampusPlaces;
    return mockCampusPlaces
        .where((p) => p.category == _selectedCategory)
        .toList();
  }

  void _selectCategory(PlaceCategory? category) {
    setState(() => _selectedCategory = category);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.watch<LocaleCubit>().state;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedCategory == null
              ? l10n.appTitle
              : categoryLabel(context, _selectedCategory!),
        ),
        actions: [
          IconButton(
            tooltip: l10n.languageToggleTooltip,
            onPressed: () => context.read<LocaleCubit>().toggle(),
            icon: Text(
              locale.languageCode.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
      drawer: _CategoryDrawer(
        selectedCategory: _selectedCategory,
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
                  title: Text(place.name),
                  subtitle: Text(place.location),
                );
              },
            ),
    );
  }
}

class _CategoryDrawer extends StatelessWidget {
  final PlaceCategory? selectedCategory;
  final ValueChanged<PlaceCategory?> onSelect;

  const _CategoryDrawer({
    required this.selectedCategory,
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
                    selected: selectedCategory == null,
                    onTap: () => onSelect(null),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ...PlaceCategory.values.map(
                    (category) => _DrawerItem(
                      icon: category.icon,
                      label: categoryLabel(context, category),
                      selected: selectedCategory == category,
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
