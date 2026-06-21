import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class RawDataPage extends StatefulWidget {
  final Map<String, dynamic> rawData;

  const RawDataPage({super.key, required this.rawData});

  @override
  State<RawDataPage> createState() => _RawDataPageState();
}

class _RawDataPageState extends State<RawDataPage> {
  late final TextEditingController _searchCtrl;
  late final Map<String, TextEditingController> _fieldCtrls;
  late final List<String> _allKeys;
  String _searchQuery = '';
  bool _showEmpty = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();

    _allKeys = widget.rawData.keys.toList()..sort();
    _fieldCtrls = {};

    for (final key in _allKeys) {
      final value = widget.rawData[key];
      if (value != null || !_showEmpty) {
        _fieldCtrls[key] = TextEditingController(
          text: value?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final c in _fieldCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _visibleKeys {
    var keys = _allKeys;
    if (!_showEmpty) {
      keys = keys.where((k) => widget.rawData[k] != null).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      keys = keys.where((k) => k.toLowerCase().contains(q)).toList();
    }
    return keys;
  }

  Map<String, dynamic> _buildPatch() {
    final original = widget.rawData;
    final patch = <String, dynamic>{};
    for (final entry in _fieldCtrls.entries) {
      final originalVal = original[entry.key]?.toString() ?? '';
      final newVal = entry.value.text.trim();
      if (newVal != originalVal) {
        patch[entry.key] = newVal;
      }
    }
    return patch;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleKeys;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: const Text('Raw Data'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _buildPatch()),
            child: Text(
              'Save',
              style: TextStyle(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.w600,
                fontSize: context.getResponsiveSize(3.8),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              context.getResponsiveSize(4),
              context.heightPercent(1),
              context.getResponsiveSize(4),
              context.heightPercent(1),
            ),
            child: Column(
              children: [
                Container(
                  height: context.heightPercent(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade50,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.5),
                      color: AppColors.textDark,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: context.heightPercent(1.2),
                      ),
                      hintText: 'Search fields...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(
                        Icons.search,
                        size: context.getResponsiveSize(4.5),
                        color: Colors.grey.shade500,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Icon(
                                Icons.close,
                                size: context.getResponsiveSize(4),
                                color: Colors.grey.shade500,
                              ),
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                SizedBox(height: context.heightPercent(0.8)),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        _showEmpty = !_showEmpty;
                        _rebuildCtrls();
                      }),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.getResponsiveSize(3),
                          vertical: context.heightPercent(0.6),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: _showEmpty
                              ? AppColors.primaryGold.withValues(alpha: 0.12)
                              : Colors.grey.shade100,
                          border: Border.all(
                            color: _showEmpty
                                ? AppColors.primaryGold.withValues(alpha: 0.4)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          _showEmpty ? 'Showing all' : 'Hide empty',
                          style: TextStyle(
                            fontSize: context.getResponsiveSize(2.8),
                            fontWeight: FontWeight.w500,
                            color: _showEmpty
                                ? AppColors.primaryGold
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${visible.length} of ${_allKeys.length} fields',
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(2.8),
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                context.getResponsiveSize(4),
                context.heightPercent(1),
                context.getResponsiveSize(4),
                context.heightPercent(3),
              ),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final key = visible[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: context.heightPercent(1),
                  ),
                  child: TextFormField(
                    controller: _fieldCtrls[key],
                    style: TextStyle(
                      fontSize: context.getResponsiveSize(3.5),
                      color: AppColors.textDark,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: key,
                      labelStyle: TextStyle(
                        fontSize: context.getResponsiveSize(3),
                        color: Colors.grey.shade500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: context.getResponsiveSize(3.5),
                        vertical: context.heightPercent(1.2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryGold,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _rebuildCtrls() {
    for (final c in _fieldCtrls.values) {
      c.dispose();
    }
    _fieldCtrls.clear();
    for (final key in _allKeys) {
      final value = widget.rawData[key];
      if (value != null || !_showEmpty) {
        _fieldCtrls[key] = TextEditingController(
          text: value?.toString() ?? '',
        );
      }
    }
  }
}
