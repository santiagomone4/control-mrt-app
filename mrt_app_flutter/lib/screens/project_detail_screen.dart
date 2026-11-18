import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/database_service.dart';
import 'tabs/tab_data_entry.dart';
import 'tabs/tab_design.dart';
import 'tabs/tab_profile_sheet.dart';
import 'tabs/tab_export.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project initialProject;

  const ProjectDetailScreen({
    Key? key,
    required this.initialProject,
  }) : super(key: key);

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Project _project;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _project = widget.initialProject;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateProject(Project updated) async {
    setState(() {
      _project = updated;
      _isSaving = true;
    });

    await DatabaseService.saveProject(updated);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _project.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            if (_project.establishment.isNotEmpty)
              Text(
                _project.establishment,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note, size: 20), text: "1. DATOS"),
            Tab(icon: Icon(Icons.architecture, size: 20), text: "2. DISEÑO"),
            Tab(icon: Icon(Icons.query_stats, size: 20), text: "3. PERFIL"),
            Tab(icon: Icon(Icons.share, size: 20), text: "4. EXPORTAR"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña 1: Datos
          TabDataEntry(
            project: _project,
            onProjectUpdated: _updateProject,
          ),
          // Pestaña 2: Diseño MRT
          TabDesign(
            project: _project,
            onProjectUpdated: _updateProject,
          ),
          // Pestaña 3: Perfil y Planilla
          TabProfileSheet(
            project: _project,
          ),
          // Pestaña 4: Exportación
          TabExport(
            project: _project,
          ),
        ],
      ),
    );
  }
}
