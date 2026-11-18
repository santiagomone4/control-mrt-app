import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/project.dart';
import '../../services/design_calc_service.dart';
import '../../services/export_pdf_service.dart';
import '../../services/export_excel_service.dart';
import '../../services/share_service.dart';

class TabExport extends StatefulWidget {
  final Project project;

  const TabExport({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  State<TabExport> createState() => _TabExportState();
}

class _TabExportState extends State<TabExport> {
  bool _exportPdf = true;
  bool _exportExcel = true;
  bool _exportJson = true;

  bool _isExporting = false;
  String? _statusMessage;

  Future<void> _shareSelectedFiles() async {
    if (!_exportPdf && !_exportExcel && !_exportJson) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Seleccione al menos un tipo de archivo para compartir."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isExporting = true;
        _statusMessage = "Generando archivos seleccionados...";
      });

      final summary = DesignCalcService.calculateMrtProfile(
        points: widget.project.points,
        params: widget.project.designParams,
      );

      Uint8List? pdfBytes;
      if (_exportPdf) {
        setState(() => _statusMessage = "Generando informe PDF con perfil vectorial...");
        pdfBytes = await ExportPdfService.generatePdfReport(
          project: widget.project,
          summary: summary,
        );
      }

      List<int>? excelBytes;
      if (_exportExcel) {
        setState(() => _statusMessage = "Generando planilla Excel (.xlsx) con 3 pestañas...");
        excelBytes = ExportExcelService.generateExcelReport(
          project: widget.project,
          summary: summary,
        );
      }

      String? jsonContent;
      if (_exportJson) {
        jsonContent = widget.project.toJson();
      }

      setState(() => _statusMessage = "Abriendo selector nativo de compartir (WhatsApp / Drive)...");

      await ShareService.shareFiles(
        project: widget.project,
        pdfBytes: pdfBytes,
        excelBytes: excelBytes,
        jsonContent: jsonContent,
      );

      setState(() {
        _isExporting = false;
        _statusMessage = "¡Archivos listos para enviar!";
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
        _statusMessage = "Error al exportar: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _previewPdf() async {
    try {
      setState(() {
        _isExporting = true;
        _statusMessage = "Preparando vista previa del PDF...";
      });

      final summary = DesignCalcService.calculateMrtProfile(
        points: widget.project.points,
        params: widget.project.designParams,
      );

      final pdfBytes = await ExportPdfService.generatePdfReport(
        project: widget.project,
        summary: summary,
      );

      setState(() {
        _isExporting = false;
        _statusMessage = null;
      });

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: '${widget.project.name}_Control_Obra.pdf',
      );
    } catch (e) {
      setState(() {
        _isExporting = false;
        _statusMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al visualizar PDF: $e")),
      );
    }
  }

  Future<void> _saveToDevice() async {
    try {
      setState(() {
        _isExporting = true;
        _statusMessage = "Guardando archivos en el almacenamiento local...";
      });

      final summary = DesignCalcService.calculateMrtProfile(
        points: widget.project.points,
        params: widget.project.designParams,
      );

      final dir = await getApplicationDocumentsDirectory();
      final safeName = widget.project.name.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
      final List<String> savedPaths = [];

      if (_exportPdf) {
        final pdfBytes = await ExportPdfService.generatePdfReport(
          project: widget.project,
          summary: summary,
        );
        final file = File('${dir.path}/${safeName}_Informe.pdf');
        await file.writeAsBytes(pdfBytes);
        savedPaths.add(file.path);
      }

      if (_exportExcel) {
        final excelBytes = ExportExcelService.generateExcelReport(
          project: widget.project,
          summary: summary,
        );
        if (excelBytes != null) {
          final file = File('${dir.path}/${safeName}_Planilla.xlsx');
          await file.writeAsBytes(excelBytes);
          savedPaths.add(file.path);
        }
      }

      if (_exportJson) {
        final file = File('${dir.path}/${safeName}_Proyecto.mrt');
        await file.writeAsString(widget.project.toJson());
        savedPaths.add(file.path);
      }

      setState(() {
        _isExporting = false;
        _statusMessage = "Guardado con éxito en Documentos:\n${savedPaths.join('\n')}";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Archivos guardados en el almacenamiento del dispositivo."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isExporting = false;
        _statusMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Tarjeta resumen del proyecto
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            children: [
              Row(
                children: [
                  const Icon(Icons.share, color: Color(0xFF0F172A), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    widget.project.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Establecimiento: ${widget.project.establishment.isEmpty ? 'N/D' : widget.project.establishment} | ${widget.project.points.length} puntos relevados",
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Selección de archivos con checkboxes
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            children: [
              const Text(
                "Seleccione los archivos a generar y compartir:",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),

              CheckboxListTile(
                value: _exportPdf,
                activeColor: const Color(0xFF0F172A),
                title: const Text("Reporte Técnico en PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text("Metadatos, gráfico vectorial con áreas de corte/relleno y planilla completa.", style: TextStyle(fontSize: 11)),
                secondary: const Icon(Icons.picture_as_pdf, color: Colors.red),
                onChanged: (val) => setState(() => _exportPdf = val ?? false),
              ),
              const Divider(height: 1),

              CheckboxListTile(
                value: _exportExcel,
                activeColor: const Color(0xFF0F172A),
                title: const Text("Planilla en Excel (.xlsx)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text("3 pestañas: Resumen de Diseño, Control de Obra (Corte/Relleno) y Datos Crudos.", style: TextStyle(fontSize: 11)),
                secondary: const Icon(Icons.table_chart, color: Colors.green),
                onChanged: (val) => setState(() => _exportExcel = val ?? false),
              ),
              const Divider(height: 1),

              CheckboxListTile(
                value: _exportJson,
                activeColor: const Color(0xFF0F172A),
                title: const Text("Archivo de Respaldo (.mrt / .json)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text("Para abrir, editar o continuar el relevamiento en otro teléfono o en la oficina.", style: TextStyle(fontSize: 11)),
                secondary: const Icon(Icons.data_object, color: Colors.blue),
                onChanged: (val) => setState(() => _exportJson = val ?? false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Botón principal de compartir
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _shareSelectedFiles,
          icon: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.share, color: Colors.white),
          label: Text(
            _isExporting ? "PROCESANDO ARCHIVOS..." : "COMPARTIR (WHATSAPP, DRIVE, CORREO)",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 10),

        // Botones secundarios
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isExporting ? null : _previewPdf,
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text("VISTA PREVIA PDF"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isExporting ? null : _saveToDevice,
                icon: const Icon(Icons.save_alt, size: 18),
                label: const Text("GUARDAR LOCAL"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),

        if (_statusMessage != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Text(
              _statusMessage!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ],
    );
  }
}
