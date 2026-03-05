import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isDefault;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [id, name, color, isDefault];
}