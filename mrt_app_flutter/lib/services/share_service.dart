import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/project.dart';

class ShareService {
  /// Comparte archivos seleccionados (PDF, XLSX, JSON) a través del Share Sheet nativo de Android
  static Future<void> shareFiles({
    required Project project,
    Uint8List? pdfBytes,
    List<int>? excelBytes,
    String? jsonContent,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final List<XFile> filesToShare = [];

    final safeName = project.name.replaceAll(RegExp(r'[^\w\s\.-]'), '_');

    // 1. Archivo PDF
    if (pdfBytes != null) {
      final pdfPath = '${tempDir.path}/${safeName}_Control_Obra.pdf';
      final file = File(pdfPath);
      await file.writeAsBytes(pdfBytes);
      filesToShare.add(XFile(pdfPath, mimeType: 'application/pdf', name: '${safeName}_Control_Obra.pdf'));
    }

    // 2. Archivo Excel
    if (excelBytes != null) {
      final xlsxPath = '${tempDir.path}/${safeName}_Planilla.xlsx';
      final file = File(xlsxPath);
      await file.writeAsBytes(excelBytes);
      filesToShare.add(XFile(
        xlsxPath,
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        name: '${safeName}_Planilla.xlsx',
      ));
    }

    // 3. Archivo Respaldo JSON / .mrt
    if (jsonContent != null) {
      final jsonPath = '${tempDir.path}/${safeName}_Proyecto.mrt';
      final file = File(jsonPath);
      await file.writeAsString(jsonContent);
      filesToShare.add(XFile(jsonPath, mimeType: 'application/json', name: '${safeName}_Proyecto.mrt'));
    }

    if (filesToShare.isNotEmpty) {
      await Share.shareXFiles(
        filesToShare,
        subject: 'Control de Obra MRT - ${project.name}',
        text: 'Adjunto reporte de control de obra de Micro-embalse de Retención Temporaria (MRT): ${project.name} - Establecimiento: ${project.establishment}.',
      );
    }
  }
}
