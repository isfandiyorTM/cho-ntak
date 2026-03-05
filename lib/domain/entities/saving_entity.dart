import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SavingEntity extends Equatable {
  final String   id;
  final String   title;
  final double   target;
  final double   saved;
  final String   emoji;
  final Color    color;
  final DateTime createdAt;
  final DateTime? deadline;

  const SavingEntity({
    required this.id,
    required this.title,
    required this.target,
    required this.saved,
    required this.emoji,
    required this.color,
    required this.createdAt,
    this.deadline,
  });

  double get percentage  => target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
  double get remaining   => (target - saved).clamp(0, double.infinity);
  bool   get isCompleted => saved >= target;

  int? get daysLeft {
    if (deadline == null) return null;
    return deadline!.difference(DateTime.now()).inDays;
  }

  @override
  List<Object?> get props => [id, title, target, saved, emoji, color, createdAt, deadline];
}