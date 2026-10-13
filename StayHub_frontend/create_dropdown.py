import os

code = '''import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../../core/data/address_data.dart';
import '../../../../core/services/api_client.dart';

class AddressDropdownOverlay extends StatefulWidget {
  final Offset position;
  final Size size;
  final String? initialProvince;
  final String? initialDistrict;
  final String? initialWard;
  final Function(String? province, String? district, String? ward) onApply;
  final VoidCallback onDismiss;

  const AddressDropdownOverlay({
    Key? key,
    required this.position,
    required this.size,
    this.initialProvince,
    this.initialDistrict,
    this.initialWard,
    required this.onApply,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<AddressDropdownOverlay> createState() => _AddressDropdownOverlayState();
}

class _AddressDropdownOverlayState extends State<AddressDropdownOverlay> {
  int _currentStep = 0; // 0: Province, 1: District, 2: Ward
  
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _wards = [];
  
  Map<String, dynamic>? _selectedProvince;
  Map<String, dynamic>? _selectedDistrict;
  Map<String, dynamic>? _selectedWard;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _provinces = AddressData.getProvinces63Sorted();
    
    if (widget.initialProvince != null) {
      // Find province
      final p = _provinces.where((e) => e['name'] == widget.initialProvince || e['full_name'] == widget.initialProvince).firstOrNull;
      if (p != null) {
        _selectedProvince = p;
        _currentStep = 1;
        _fetchDistricts(p['id'].toString()).then((_) {
          if (widget.initialDistrict != null) {
            final d = _districts.where((e) => e['name'] == widget.initialDistrict || e['full_name'] == widget.initialDistrict).firstOrNull;
            if (d != null) {
              setState(() {
                _selectedDistrict = d;
                _currentStep = 2;
              });
              _fetchWards(d['id'].toString()).then((_) {
                if (widget.initialWard != null) {
                  final w = _wards.where((e) => e['name'] == widget.initialWard || e['full_name'] == widget.initialWard).firstOrNull;
                  if (w != null) {
                    setState(() {
                      _selectedWard = w;
                    });
                  }
                }
              });
            }
          }
        });
      }
    }
  }

  Future<void> _fetchDistricts(String provinceId) async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().get('/api/v1/addresses/districts/\');
      if (mounted) {
        setState(() {
          _districts = (res['data'] as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error fetch districts: \');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchWards(String districtId) async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().get('/api/v1/addresses/wards/\');
      if (mounted) {
        setState(() {
          _wards = (res['data'] as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      debugPrint('Error fetch wards: \');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSelectProvince(Map<String, dynamic> p) {
    setState(() {
      _selectedProvince = p;
      _selectedDistrict = null;
      _selectedWard = null;
      _currentStep = 1;
    });
    _fetchDistricts(p['id'].toString());
  }

  void _onSelectDistrict(Map<String, dynamic> d) {
    setState(() {
      _selectedDistrict = d;
      _selectedWard = null;
      _currentStep = 2;
    });
    _fetchWards(d['id'].toString());
  }

  void _onSelectWard(Map<String, dynamic> w) {
    setState(() {
      _selectedWard = w;
    });
  }
  
  void _apply() {
    widget.onApply(
      _selectedProvince?['name'],
      _selectedDistrict?['name'],
      _selectedWard?['name'],
    );
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    
    double top = widget.position.dy + widget.size.height + 8;
    double left = widget.position.dx;
    
    // clamp width
    double width = 320;
    if (left + width > screenW - 16) {
      left = screenW - width - 16;
    }
    if (left < 16) left = 16;
    
    double height = 400;
    if (top + height > screenH - 16) {
      height = screenH - top - 16;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          top: top,
          left: left,
          width: width,
          height: height,
          child: Material(
            color: Colors.transparent,
            child: GlassContainer(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  _buildHeader(),
                  const Divider(height: 1, color: Colors.white24),
                  Expanded(
                    child: _isLoading 
                      ? const Center(child: CircularProgressIndicator())
                      : _buildList(),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentStep = 0),
              child: Text(
                _selectedProvince?['name'] ?? 'Ch?n T?nh/Thnh',
                style: TextStyle(
                  color: _currentStep == 0 ? Colors.blue : Colors.black87,
                  fontWeight: _currentStep == 0 ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 16),
          Expanded(
            child: GestureDetector(
              onTap: _selectedProvince == null ? null : () => setState(() => _currentStep = 1),
              child: Text(
                _selectedDistrict?['name'] ?? 'Qu?n/Huy?n',
                style: TextStyle(
                  color: _currentStep == 1 ? Colors.blue : Colors.black54,
                  fontWeight: _currentStep == 1 ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 16),
          Expanded(
            child: GestureDetector(
              onTap: _selectedDistrict == null ? null : () => setState(() => _currentStep = 2),
              child: Text(
                _selectedWard?['name'] ?? 'Phu?ng/X',
                style: TextStyle(
                  color: _currentStep == 2 ? Colors.blue : Colors.black54,
                  fontWeight: _currentStep == 2 ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    List<Map<String, dynamic>> items = [];
    if (_currentStep == 0) items = _provinces;
    if (_currentStep == 1) items = _districts;
    if (_currentStep == 2) items = _wards;

    if (items.isEmpty) {
      return const Center(child: Text('Khng c d? li?u'));
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        bool isSelected = false;
        if (_currentStep == 0) isSelected = _selectedProvince?['id'] == item['id'];
        if (_currentStep == 1) isSelected = _selectedDistrict?['id'] == item['id'];
        if (_currentStep == 2) isSelected = _selectedWard?['id'] == item['id'];

        return ListTile(
          dense: true,
          title: Text(
            item['name'] ?? '',
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.black87,
            ),
          ),
          trailing: isSelected ? const Icon(Icons.check, color: Colors.blue, size: 16) : null,
          onTap: () {
            if (_currentStep == 0) _onSelectProvince(item);
            else if (_currentStep == 1) _onSelectDistrict(item);
            else if (_currentStep == 2) _onSelectWard(item);
          },
        );
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedProvince = null;
                _selectedDistrict = null;
                _selectedWard = null;
                _currentStep = 0;
              });
            },
            child: const Text('Xa', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('p d?ng'),
          ),
        ],
      ),
    );
  }
}
'''

with open('lib/features/guest/presentation/widgets/guest_address_dropdown_overlay.dart', 'w', encoding='utf-8') as f:
    f.write(code)
