part of 'saving_bloc.dart';

abstract class SavingState extends Equatable {
  const SavingState();
  @override List<Object?> get props => [];
}

class SavingInitial extends SavingState {}
class SavingLoading extends SavingState {}
class SavingError   extends SavingState {
  final String message;
  const SavingError(this.message);
  @override List<Object?> get props => [message];
}

class SavingLoaded extends SavingState {
  final List<SavingEntity> savings;
  const SavingLoaded(this.savings);
  @override List<Object?> get props => [savings];
}