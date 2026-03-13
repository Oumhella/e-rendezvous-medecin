import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/horaires_template.dart';
import '../../../services/secretaire_service.dart';
import '../../../theme/app_theme.dart';
import 'edit_template_screen.dart';

class TemplatesListScreen extends StatefulWidget {
  final String medecinId;
  final bool embedded;

  const TemplatesListScreen({super.key, required this.medecinId, this.embedded = false});

  @override
  State<TemplatesListScreen> createState() => _TemplatesListScreenState();
}

class _TemplatesListScreenState extends State<TemplatesListScreen> {
  final SecretaireService _service = SecretaireService();

  void _deleteTemplate(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Supprimer le modèle ?', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULER')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('SUPPRIMER'),
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
    if (widget.embedded) return _buildContent();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Modèles d\'horaires', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.tealDark,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditTemplateScreen(medecinId: widget.medecinId),
          ),
        ),
        backgroundColor: AppColors.orangeAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return StreamBuilder<List<HorairesTemplate>>(
      stream: _service.getTemplatesStream(widget.medecinId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.tealDark));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Icon(Icons.style_rounded, size: 80, color: AppColors.tealDark.withOpacity(0.1)),
                 const SizedBox(height: 16),
                 Text(
                  'Aucun modèle enregistré.',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textGray),
                ),
                 Text(
                  'Créez-en un pour gagner du temps.',
                  style: GoogleFonts.inter(color: AppColors.textGray, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final templates = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final t = templates[index];
            return _TemplateCard(
              template: t,
              onEdit: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditTemplateScreen(medecinId: widget.medecinId, template: t),
                ),
              ),
              onDelete: () => _deleteTemplate(t.id),
            );
          },
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final HorairesTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateCard({required this.template, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: AppColors.tealDark),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.nom.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900, 
                          color: AppColors.tealDark, 
                          fontSize: 13, 
                          letterSpacing: 1
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${template.intervalles.length} plage(s) horaire(s)',
                        style: GoogleFonts.inter(color: AppColors.textGray, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: template.intervalles.take(3).map((i) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${i.heureDebut}-${i.heureFin}',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.tealDark),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, color: AppColors.tealDark, size: 20),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
