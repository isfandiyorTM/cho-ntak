import 'package:flutter/material.dart';
import '../../domain/entities/saving_entity.dart';

class SavingModel extends SavingEntity {
  const SavingModel({
    required super.id,
    required super.title,
    required super.target,
    required super.saved,
    required super.emoji,
    required super.color,
    required super.createdAt,
    super.deadline,
  });

  factory SavingModel.fromMap(Map<String, dynamic> m) => SavingModel(
    id:        m['id'],
    title:     m['title'],
    target:    m['target'],
    saved:     m['saved'],
    emoji:     m['emoji'] ?? '🎯',
    color:     Color(m['color'] ?? 0xFFFFD700),
    createdAt: DateTime.parse(m['created_at']),
    deadline:  m['deadline'] != null ? DateTime.parse(m['deadline']) : null,
  );

  Map<String, dynamic> toMap() => {
    'id':         id,
    'title':      title,
    'target':     target,
    'saved':      saved,
    'emoji':      emoji,
    'color':      color.toARGB32(),
    'created_at': createdAt.toIso8601String(),
    'deadline':   deadline?.toIso8601String(),
  };

  factory SavingModel.fromEntity(SavingEntity e) => SavingModel(
    id: e.id, title: e.title, target: e.target, saved: e.saved,
    emoji: e.emoji, color: e.color, createdAt: e.createdAt, deadline: e.deadline,
  );
}