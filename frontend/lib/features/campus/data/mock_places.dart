// lib/features/campus/data/mock_places.dart
//
// Datos de ejemplo locales — sin backend. Reemplazar por datos reales
// cuando exista una API de mapas/POIs.
//
// Solo hay lugares de categorias con ubicacion en el modelo 3D (`mapa_capas`):
// los demas no se pueden mostrar ni elegir como destino.

import '../domain/entities.dart';

const List<CampusPlace> mockCampusPlaces = [
  CampusPlace(name: 'Salón 101', category: PlaceCategory.salones, location: 'Bloque A · Piso 1'),
  CampusPlace(name: 'Salón 205', category: PlaceCategory.salones, location: 'Bloque B · Piso 2'),
  CampusPlace(name: 'Salón 310', category: PlaceCategory.salones, location: 'Bloque C · Piso 3'),
  CampusPlace(name: 'Laboratorio de Sistemas', category: PlaceCategory.laboratorios, location: 'Bloque C · Piso 2'),
  CampusPlace(name: 'Laboratorio de Química', category: PlaceCategory.laboratorios, location: 'Bloque D · Piso 1'),
  CampusPlace(name: 'Cancha de Fútbol', category: PlaceCategory.canchas, location: 'Zona Deportiva'),
  CampusPlace(name: 'Cancha de Baloncesto', category: PlaceCategory.canchas, location: 'Zona Deportiva'),
  CampusPlace(name: 'Auditorio Principal', category: PlaceCategory.auditorios, location: 'Bloque Central · Piso 1'),
  CampusPlace(name: 'Auditorio Menor', category: PlaceCategory.auditorios, location: 'Bloque B · Piso 1'),
  CampusPlace(name: 'Biblioteca Central', category: PlaceCategory.biblioteca, location: 'Bloque Central · Piso 2'),
  CampusPlace(name: 'Cafetería Principal', category: PlaceCategory.cafeteria, location: 'Zona Común'),
  CampusPlace(name: 'Estacionamiento Norte', category: PlaceCategory.estacionamientos, location: 'Entrada Norte'),
  CampusPlace(name: 'Estacionamiento Sur', category: PlaceCategory.estacionamientos, location: 'Entrada Sur'),
  CampusPlace(name: 'Rectoría', category: PlaceCategory.oficinasAdministrativas, location: 'Edificio Administrativo · Piso 2'),
  CampusPlace(name: 'Bienestar Universitario', category: PlaceCategory.bienestarUniversitario, location: 'Edificio Administrativo · Piso 1'),
  CampusPlace(name: 'Plaza Central', category: PlaceCategory.areasVerdes, location: 'Zona Común'),
];
