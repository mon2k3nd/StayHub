import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/branch_model.dart';
import '../application/branch_notifier.dart';

class EditBranchScreen extends ConsumerStatefulWidget {
  final BranchModel branch;
  const EditBranchScreen({super.key, required this.branch});

  @override
  ConsumerState<EditBranchScreen> createState() => _EditBranchScreenState();
}

class _EditBranchScreenState extends ConsumerState<EditBranchScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _elecCtrl;
  late TextEditingController _waterCtrl;
  late TextEditingController _internetCtrl;
  late TextEditingController _parkingCtrl;
  late TextEditingController _trashCtrl;

  bool _petPolicy = false;
  bool _roommatePolicy = false;
  bool _hasPccc = false;
  String _closingTime = 'Tự do';
  String _cookingPolicy = 'TRONG_PHONG';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _nameCtrl = TextEditingController(text: b.branchName);
    _addressCtrl = TextEditingController(text: b.address);
    _elecCtrl = TextEditingController(
      text: b.electricityPrice?.toStringAsFixed(0) ?? '0',
    );
    _waterCtrl = TextEditingController(
      text: b.waterPrice?.toStringAsFixed(0) ?? '0',
    );
    _internetCtrl = TextEditingController(
      text: b.internetPrice?.toStringAsFixed(0) ?? '0',
    );
    _parkingCtrl = TextEditingController(
      text: b.parkingPrice?.toStringAsFixed(0) ?? '0',
    );
    _trashCtrl = TextEditingController(
      text: b.trashPrice?.toStringAsFixed(0) ?? '0',
    );

    _petPolicy = b.petPolicy ?? true;
    _roommatePolicy = b.roommatePolicy ?? true;
    _hasPccc = b.hasPccc ?? false;
    _closingTime = b.closingTime ?? 'Tự do';
    _cookingPolicy = b.cookingPolicy ?? 'TRONG_PHONG';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _elecCtrl.dispose();
    _waterCtrl.dispose();
    _internetCtrl.dispose();
    _parkingCtrl.dispose();
    _trashCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updatedData = {
        'branchName': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'electricityPrice': double.tryParse(_elecCtrl.text) ?? 0,
        'waterPrice': double.tryParse(_waterCtrl.text) ?? 0,
        'internetFee': double.tryParse(_internetCtrl.text) ?? 0,
        'parkingFee': double.tryParse(_parkingCtrl.text) ?? 0,
        'garbageFee': double.tryParse(_trashCtrl.text) ?? 0,
        'petPolicy': _petPolicy,
        'roommatePolicy': _roommatePolicy,
        'hasPccc': _hasPccc,
        'closingTime': _closingTime,
        'cookingPolicy': _cookingPolicy,
      };

      await ref
          .read(branchProvider.notifier)
          .updateBranch(widget.branch.id, updatedData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật chi nhánh!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa chi nhánh',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionTitle('Thông tin cơ bản'),
            const SizedBox(height: 12),
            _buildTextField(
              'Tên chi nhánh',
              _nameCtrl,
              icon: CupertinoIcons.building_2_fill,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Địa chỉ',
              _addressCtrl,
              icon: CupertinoIcons.location_solid,
            ),

            const SizedBox(height: 32),
            _buildSectionTitle('Cấu hình Phí'),
            const SizedBox(height: 12),
            _buildTextField(
              'Giá điện (VNĐ/kwh)',
              _elecCtrl,
              isNumber: true,
              icon: CupertinoIcons.bolt_fill,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Giá nước (VNĐ)',
              _waterCtrl,
              isNumber: true,
              icon: CupertinoIcons.drop_fill,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Phí Internet (VNĐ/phòng)',
              _internetCtrl,
              isNumber: true,
              icon: CupertinoIcons.wifi,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Phí gửi xe (VNĐ/xe)',
              _parkingCtrl,
              isNumber: true,
              icon: CupertinoIcons.car_detailed,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Phí rác (VNĐ/người)',
              _trashCtrl,
              isNumber: true,
              icon: CupertinoIcons.trash,
            ),

            const SizedBox(height: 32),
            _buildSectionTitle('Chính sách & Nội quy'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Cho phép nuôi thú cưng',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    value: _petPolicy,
                    activeTrackColor: const Color(0xFF0EA5E9),
                    onChanged: (val) => setState(() => _petPolicy = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Cho phép ở ghép',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    value: _roommatePolicy,
                    activeTrackColor: const Color(0xFF0EA5E9),
                    onChanged: (val) => setState(() => _roommatePolicy = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Có hệ thống PCCC',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    value: _hasPccc,
                    activeTrackColor: const Color(0xFF10B981),
                    onChanged: (val) => setState(() => _hasPccc = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              'Giờ giấc đóng cửa',
              _closingTime,
              ['Tự do', '22:00', '23:00', '00:00'],
              (val) => setState(() => _closingTime = val!),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              'Chính sách nấu ăn',
              _cookingPolicy,
              ['TRONG_PHONG', 'KHU_VUC_CHUNG', 'KHONG_CHO'],
              (val) => setState(() => _cookingPolicy = val!),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CupertinoButton(
            color: const Color(0xFF0EA5E9),
            borderRadius: BorderRadius.circular(12),
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const CupertinoActivityIndicator(color: Colors.white)
                : const Text(
                    'Lưu thay đổi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (val) =>
          val == null || val.trim().isEmpty ? 'Bắt buộc nhập' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280)),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0EA5E9)),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    final List<String> safeOptions = List.from(options);
    if (!safeOptions.contains(value)) {
      safeOptions.add(value);
    }

    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      items: safeOptions.map((e) {
        String display = e;
        if (e == 'TRONG_PHONG') display = 'Trong phòng';
        if (e == 'KHU_VUC_CHUNG') display = 'Khu vực chung';
        if (e == 'KHONG_CHO') display = 'Không cho phép nấu ăn';
        return DropdownMenuItem(
          value: e,
          child: Text(display, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
