import 'package:freezed_annotation/freezed_annotation.dart';

part 'medicine_models.freezed.dart';
part 'medicine_models.g.dart';

/// Domain model for a generic (INN) medicine — mirrors [GenericMedicineRow].
@freezed
class GenericMedicine with _$GenericMedicine {
  const factory GenericMedicine({
    required String id,
    required String genericName,
    required String drugClass,
    @Default('') String therapeuticClass,
    @Default('') String indications,
    @Default('[]') String contraindications,
    @Default('') String sideEffects,
  }) = _GenericMedicine;

  factory GenericMedicine.fromJson(Map<String, dynamic> json) =>
      _$GenericMedicineFromJson(json);
}

/// Domain model for a branded medicine — mirrors [BrandMedicineRow].
@freezed
class BrandMedicine with _$BrandMedicine {
  const factory BrandMedicine({
    required String id,
    required String genericId,
    required String brandName,
    required String manufacturer,
    required String strength,
    required String form,
    double? mrp,
    @Default(true) bool isActive,
  }) = _BrandMedicine;

  factory BrandMedicine.fromJson(Map<String, dynamic> json) =>
      _$BrandMedicineFromJson(json);
}

/// Unified search result — used by [MedicineRepository.search] and the
/// prescription form autocomplete.  A result may represent either a brand
/// (preferred) or a generic when no brand match exists.
@freezed
class MedicineSearchResult with _$MedicineSearchResult {
  const factory MedicineSearchResult({
    /// The ID stored in [PrescriptionItem.medicineId].
    required String id,

    /// Display name shown in the autocomplete dropdown.
    required String displayName,

    /// Whether this result came from [BrandMedicines] (`true`) or
    /// [GenericMedicines] (`false`).
    @Default(true) bool isBrand,

    String? genericId,
    String? genericName,
    String? manufacturer,
    String? strength,
    String? form,
    double? mrp,
  }) = _MedicineSearchResult;

  factory MedicineSearchResult.fromJson(Map<String, dynamic> json) =>
      _$MedicineSearchResultFromJson(json);
}
