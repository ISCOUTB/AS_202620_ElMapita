// lib/features/mapas/presentation/pages/model_test_page.dart
//
// Visor 3D de prueba (S9): renderiza un .glb publico de Supabase Storage con
// rotacion, zoom y desplazamiento tactil. Independiente del backend.

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

const String kTestModelUrl =
    'https://smgbmfbgxfjkspvtyvfb.supabase.co/storage/v1/object/public/modelos_prueba/pruebaSupabase.glb';

class ModelTestPage extends StatelessWidget {
  final String modelUrl;

  const ModelTestPage({super.key, this.modelUrl = kTestModelUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modelo 3D de prueba')),
      body: ModelViewer(
        src: modelUrl,
        alt: 'Modelo 3D de prueba alojado en Supabase',
        cameraControls: true,
        autoRotate: true,
        disableZoom: false,
        backgroundColor: const Color(0xFF1B2A41),
      ),
    );
  }
}
