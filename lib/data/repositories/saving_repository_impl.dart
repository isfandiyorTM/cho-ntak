import 'package:uuid/uuid.dart';
import '../../domain/entities/saving_entity.dart';
import '../../domain/repositories/saving_repository.dart';
import '../datasources/local_database.dart';
import '../models/saving_model.dart';

class SavingRepositoryImpl implements SavingRepository {
  final LocalDatabase _db;
  SavingRepositoryImpl(this._db);

  @override
  Future<List<SavingEntity>> getAllSavings() async {
    final maps = await _db.getAllSavings();
    return maps.map((m) => SavingModel.fromMap(m)).toList();
  }

  @override
  Future<void> addSaving(SavingEntity saving) async {
    final model = SavingModel.fromEntity(saving);
    await _db.insertSaving(model.toMap());
  }

  @override
  Future<void> updateSaving(SavingEntity saving) async {
    final model = SavingModel.fromEntity(saving);
    await _db.updateSaving(model.toMap());
  }

  @override
  Future<void> deleteSaving(String id) async {
    await _db.deleteSaving(id);
  }

  @override
  Future<void> addToSaved(String id, double amount) async {
    await _db.addToSaved(id, amount);
  }
}