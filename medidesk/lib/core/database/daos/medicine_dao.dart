import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/lookup_tables.dart';

part 'medicine_dao.g.dart';

@DriftAccessor(tables: [BrandMedicines, GenericMedicines])
class MedicineDao extends DatabaseAccessor<AppDatabase>
    with _$MedicineDaoMixin {
  MedicineDao(super.db);

  Stream<List<BrandMedicineRow>> searchBrand(String query, {String? form}) {
    final like = '%${query.toLowerCase()}%';
    final q = select(brandMedicines)
      ..where((t) {
        final nameMatch = t.brandName.lower().like(like) |
            t.strength.lower().like(like) |
            t.manufacturer.lower().like(like);
        if (form != null && form.isNotEmpty) {
          return nameMatch & t.form.equals(form) & t.isActive.equals(1);
        }
        return nameMatch & t.isActive.equals(1);
      })
      ..limit(50);
    return q.watch();
  }

  Stream<List<GenericMedicineRow>> searchGeneric(String query) {
    final like = '%${query.toLowerCase()}%';
    return (select(genericMedicines)
          ..where(
            (t) =>
                t.genericName.lower().like(like) |
                t.drugClass.lower().like(like),
          )
          ..limit(50))
        .watch();
  }

  Future<BrandMedicineRow?> getBrandById(String id) =>
      (select(brandMedicines)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertAllBrand(List<BrandMedicinesCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(brandMedicines, rows);
    });
  }

  Future<void> upsertAllGeneric(List<GenericMedicinesCompanion> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(genericMedicines, rows);
    });
  }
}
