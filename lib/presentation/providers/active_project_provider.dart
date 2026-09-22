import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project_detection.dart';
import '../../services/project_detector_service.dart';

final activeProjectPathProvider = StateProvider<String>((ref) {
  return Directory.current.path;
});

final activeProjectProvider = FutureProvider<ProjectDetection?>((ref) async {
  final path = ref.watch(activeProjectPathProvider);
  final detector = ProjectDetectorService();
  return detector.detect(path);
});
