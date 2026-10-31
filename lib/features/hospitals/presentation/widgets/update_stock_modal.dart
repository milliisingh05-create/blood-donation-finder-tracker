import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/blood_compatibility.dart';
import '../../domain/models/hospital.dart';
import '../controllers/hospitals_controller.dart';

/// Modal bottom sheet allowing hospital staff to update blood unit inventory.
class UpdateStockModal extends ConsumerStatefulWidget {
  final Hospital hospital;

  const UpdateStockModal({
    super.key,
    required this.hospital,
  });

  @override
  ConsumerState<UpdateStockModal> createState() => _UpdateStockModalState();
}

class _UpdateStockModalState extends ConsumerState<UpdateStockModal> {
  late Map<String, int> _editableStock;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editableStock = Map<String, int>.from(widget.hospital.bloodStock);
    for (final group in BloodCompatibility.allBloodGroups) {
      _editableStock.putIfAbsent(group, () => 0);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    final repo = ref.read(hospitalsRepositoryProvider);
    for (final entry in _editableStock.entries) {
      if (widget.hospital.stockFor(entry.key) != entry.value) {
        await repo.updateBloodStock(
          hospitalId: widget.hospital.id,
          bloodGroup: entry.key,
          newUnits: entry.value,
        );
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Inventory updated for ${widget.hospital.name}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update Inventory', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 2),
                  Text(widget.hospital.name, style: AppTextStyles.bodySmall),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lightRedTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Staff Mode',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryRed),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // 8 Blood Groups Inventory Steppers
          SizedBox(
            height: 280,
            child: ListView(
              children: BloodCompatibility.allBloodGroups.map((group) {
                final units = _editableStock[group] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              group,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$units Unit${units != 1 ? "s" : ""}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: units < 3 ? AppColors.primaryRed : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton.filled(
                            onPressed: units > 0
                                ? () => setState(() => _editableStock[group] = units - 1)
                                : null,
                            icon: const Icon(Icons.remove, size: 16),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.lightRedTint,
                              foregroundColor: AppColors.primaryRed,
                              minimumSize: const Size(32, 32),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: () => setState(() => _editableStock[group] = units + 1),
                            icon: const Icon(Icons.add, size: 16),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(32, 32),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Stock Levels', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
