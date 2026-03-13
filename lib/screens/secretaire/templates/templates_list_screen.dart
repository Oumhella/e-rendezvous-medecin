import 'package:flutter/material.dart';
import '../../../models/horaires_template.dart';
import '../../../services/secretaire_service.dart';
import '../../../theme/app_theme.dart';
import 'edit_template_screen.dart';

class TemplatesListScreen extends StatefulWidget {
  final String medecinId;

  const TemplatesListScreen({super.key, required this.medecinId});

  @override
  State<TemplatesListScreen> createState() => _TemplatesListScreenState();
}

class _TemplatesListScreenState extends State<TemplatesListScreen> {
  final SecretaireService _service = SecretaireService();

  void _deleteTemplate(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le modèle ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULER')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SUPPRIMER', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteTemplate(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modèles d\'horaires'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditTemplateScreen(medecinId: widget.medecinId),
          ),
        ),
        backgroundColor: AppColors.navyDark,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<HorairesTemplate>>(
        stream: _service.getTemplatesStream(widget.medecinId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Aucun modèle enregistré.\nAppuyez sur + pour en créer un.',
                  textAlign: TextAlign.center),
            );
          }

          final templates = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final t = templates[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(t.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${t.intervalles.length} intervalle(s)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.navyDark),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditTemplateScreen(medecinId: widget.medecinId, template: t),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteTemplate(t.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
