// lib/features/campus/data/mock_places.dart
//
// Datos de ejemplo locales — sin backend. Reemplazar por datos reales
// cuando exista una API de mapas/POIs.
//
// Solo hay lugares de categorias con ubicacion en el modelo 3D (`mapa_capas`):
// los demas no se pueden mostrar ni elegir como destino. Cada lugar trae su
// texto en español e ingles.

import '../domain/entities.dart';

const List<CampusPlace> mockCampusPlaces = [
  CampusPlace(name: 'Salón 101', nameEn: 'Classroom 101', category: PlaceCategory.salones, location: 'Bloque A · Piso 1', locationEn: 'Block A · Floor 1'),
  CampusPlace(name: 'Salón 205', nameEn: 'Classroom 205', category: PlaceCategory.salones, location: 'Bloque B · Piso 2', locationEn: 'Block B · Floor 2'),
  CampusPlace(name: 'Salón 310', nameEn: 'Classroom 310', category: PlaceCategory.salones, location: 'Bloque C · Piso 3', locationEn: 'Block C · Floor 3'),
  CampusPlace(name: 'Laboratorio de Sistemas', nameEn: 'Systems Lab', category: PlaceCategory.laboratorios, location: 'Bloque C · Piso 2', locationEn: 'Block C · Floor 2'),
  CampusPlace(name: 'Laboratorio de Química', nameEn: 'Chemistry Lab', category: PlaceCategory.laboratorios, location: 'Bloque D · Piso 1', locationEn: 'Block D · Floor 1'),
  CampusPlace(name: 'Cancha de Fútbol', nameEn: 'Soccer Field', category: PlaceCategory.canchas, location: 'Zona Deportiva', locationEn: 'Sports Area'),
  CampusPlace(name: 'Cancha de Baloncesto', nameEn: 'Basketball Court', category: PlaceCategory.canchas, location: 'Zona Deportiva', locationEn: 'Sports Area'),
  CampusPlace(name: 'Auditorio Principal', nameEn: 'Main Auditorium', category: PlaceCategory.auditorios, location: 'Bloque Central · Piso 1', locationEn: 'Central Block · Floor 1'),
  CampusPlace(name: 'Auditorio Menor', nameEn: 'Small Auditorium', category: PlaceCategory.auditorios, location: 'Bloque B · Piso 1', locationEn: 'Block B · Floor 1'),
  CampusPlace(name: 'Biblioteca Central', nameEn: 'Central Library', category: PlaceCategory.biblioteca, location: 'Bloque Central · Piso 2', locationEn: 'Central Block · Floor 2'),
  CampusPlace(name: 'Cafetería Principal', nameEn: 'Main Cafeteria', category: PlaceCategory.cafeteria, location: 'Zona Común', locationEn: 'Common Area'),
  CampusPlace(name: 'Estacionamiento Norte', nameEn: 'North Parking', category: PlaceCategory.estacionamientos, location: 'Entrada Norte', locationEn: 'North Entrance'),
  CampusPlace(name: 'Estacionamiento Sur', nameEn: 'South Parking', category: PlaceCategory.estacionamientos, location: 'Entrada Sur', locationEn: 'South Entrance'),
  CampusPlace(name: 'Rectoría', nameEn: "Rector's Office", category: PlaceCategory.oficinasAdministrativas, location: 'Edificio Administrativo · Piso 2', locationEn: 'Administrative Building · Floor 2'),
  CampusPlace(name: 'Bienestar Universitario', nameEn: 'University Wellbeing', category: PlaceCategory.bienestarUniversitario, location: 'Edificio Administrativo · Piso 1', locationEn: 'Administrative Building · Floor 1'),
  CampusPlace(name: 'Plaza Central', nameEn: 'Central Plaza', category: PlaceCategory.areasVerdes, location: 'Zona Común', locationEn: 'Common Area'),
];
