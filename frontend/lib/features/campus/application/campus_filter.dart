// lib/features/campus/application/campus_filter.dart
//
// Estado del filtro de categorias compartido entre el listado del campus y el
// visor 3D. Conjunto vacio = sin filtro (se ve todo).

import 'package:flutter/foundation.dart';
import '../domain/entities.dart';

class CampusFilter extends ValueNotifier<Set<PlaceCategory>> {
  CampusFilter() : super(const {});

  /// Seleccion unica (menu lateral del listado). `null` limpia el filtro.
  void selectOnly(PlaceCategory? category) {
    value = category == null ? const {} : {category};
  }

  /// Agrega o quita una categoria (chips del visor 3D).
  void toggle(PlaceCategory category) {
    final next = {...value};
    if (!next.remove(category)) next.add(category);
    value = next;
  }

  void clear() => value = const {};
}
