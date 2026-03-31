import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import '../../../domain/entities/saving_entity.dart';
import '../../../domain/repositories/saving_repository.dart';

part 'saving_event.dart';
part 'saving_state.dart';

class SavingBloc extends Bloc<SavingEvent, SavingState> {
  final SavingRepository _repo;

  SavingBloc({required SavingRepository repository})
      : _repo = repository,
        super(SavingInitial()) {
    on<LoadSavings>(_onLoad);
    on<AddSavingEvent>(_onAdd);
    on<UpdateSavingEvent>(_onUpdate);
    on<DeleteSavingEvent>(_onDelete);
    on<AddToSavedEvent>(_onAddToSaved);
  }

  Future<void> _onLoad(LoadSavings e, Emitter<SavingState> emit) async {
    emit(SavingLoading());
    try {
      final savings = await _repo.getAllSavings();
      emit(SavingLoaded(savings));
    } catch (e) {
      emit(SavingError(e.toString()));
    }
  }

  Future<void> _onAdd(AddSavingEvent e, Emitter<SavingState> emit) async {
    try {
      final saving = SavingEntity(
        id:        const Uuid().v4(),
        title:     e.title,
        target:    e.target,
        saved:     0,
        emoji:     e.emoji,
        color:     e.color,
        createdAt: DateTime.now(),
        deadline:  e.deadline,
      );
      await _repo.addSaving(saving);
      add(LoadSavings());
    } catch (err) {
      emit(SavingError(err.toString()));
    }
  }

  Future<void> _onUpdate(UpdateSavingEvent e, Emitter<SavingState> emit) async {
    try {
      await _repo.updateSaving(e.saving);
      add(LoadSavings());
    } catch (err) {
      emit(SavingError(err.toString()));
    }
  }

  Future<void> _onDelete(DeleteSavingEvent e, Emitter<SavingState> emit) async {
    try {
      await _repo.deleteSaving(e.id);
      add(LoadSavings());
    } catch (err) {
      emit(SavingError(err.toString()));
    }
  }

  Future<void> _onAddToSaved(AddToSavedEvent e, Emitter<SavingState> emit) async {
    try {
      await _repo.addToSaved(e.id, e.amount);
      add(LoadSavings());
    } catch (err) {
      emit(SavingError(err.toString()));
    }
  }
}