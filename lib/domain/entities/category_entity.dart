import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CategoryEntity extends Equatable {
  final String   id;
  final String   name;
  final IconData icon;
  final Color    color;
  final bool     isDefault;
  final String?  emoji; // null for default categories (use icon), set for custom

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
    this.emoji,
  });

  CategoryEntity copyWith({
    String?   name,
    String?   emoji,
    Color?    color,
  }) => CategoryEntity(
    id:        id,
    name:      name  ?? this.name,
    icon:      icon,
    color:     color ?? this.color,
    isDefault: isDefault,
    emoji:     emoji ?? this.emoji,
  );

  @override
  List<Object?> get props => [id, name, color, isDefault, emoji];
}