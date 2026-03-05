import '../entities/saving_entity.dart';

abstract class SavingRepository {
  Future<List<SavingEntity>> getAllSavings();
  Future<void> addSaving(SavingEntity saving);
  Future<void> updateSaving(SavingEntity saving);
  Future<void> deleteSaving(String id);
  Future<void> addToSaved(String id, double amount);
}