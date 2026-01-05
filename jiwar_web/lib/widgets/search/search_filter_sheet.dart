import 'package:flutter/material.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';

class SearchFilterSheet extends StatefulWidget {
  final String? initialType;
  final Function(Map<String, dynamic>) onApply;

  const SearchFilterSheet({
    super.key,
    this.initialType,
    required this.onApply,
  });

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  String _selectedType = 'all';
  String _sortBy = 'rating';
  RangeValues _priceRange = const RangeValues(0, 1000);
  
  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'all';
  }

  @override
  Widget build(BuildContext context) {
    // final l10n = AppLocalizations.of(context)!;
    // Hardcoding for now to speed up, then localize
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Type Filter
          const Text('Provider Type', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeChip('All', 'all'),
                const SizedBox(width: 8),
                _buildTypeChip('Doctors', 'doctor'),
                const SizedBox(width: 8),
                _buildTypeChip('Pharmacies', 'pharmacy'),
                const SizedBox(width: 8),
                _buildTypeChip('Teachers', 'teacher'),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sort By
          const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSortChip('Rating', 'rating'),
              const SizedBox(width: 8),
              _buildSortChip('Distance', 'distance'), // Needs backend support
            ],
          ),
          
          if (_selectedType == 'doctor') ...[
             const SizedBox(height: 24),
             const Text('Price Range (EGP)', style: TextStyle(fontWeight: FontWeight.bold)),
             RangeSlider(
               values: _priceRange,
               min: 0,
               max: 2000,
               divisions: 20,
               labels: RangeLabels(
                 _priceRange.start.round().toString(),
                 _priceRange.end.round().toString(),
               ),
               activeColor: AppColors.primary,
               onChanged: (values) => setState(() => _priceRange = values),
             ),
          ],
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply({
                  'type': _selectedType,
                  'sort': _sortBy,
                  'min_price': _priceRange.start,
                  'max_price': _priceRange.end,
                });
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String value) {
    final isSelected = _selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _selectedType = value),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _sortBy = value),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }
}
