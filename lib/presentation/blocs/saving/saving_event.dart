part of 'saving_bloc.dart';

abstract class SavingEvent extends Equatable {
  const SavingEvent();
  @override List<Object?> get props => [];
}

class LoadSavings extends SavingEvent {}

class AddSavingEvent extends SavingEvent {
  final String title, emoji;
  final double target;
  final Color  color;
  final DateTime? deadline;
  const AddSavingEvent({required this.title, required this.target,
    required this.emoji, required this.color, this.deadline});
  @override List<Object?> get props => [title, target, emoji, deadline];
}

class UpdateSavingEvent extends SavingEvent {
  final SavingEntity saving;
  const UpdateSavingEvent(this.saving);
  @override List<Object?> get props => [saving];
}

class DeleteSavingEvent extends SavingEvent {
  final String id;
  const DeleteSavingEvent(this.id);
  @override List<Object?> get props => [id];
}

class AddToSavedEvent extends SavingEvent {
  final String id;
  final double amount;
  const AddToSavedEvent({required this.id, required this.amount});
  @override List<Object?> get props => [id, amount];
}