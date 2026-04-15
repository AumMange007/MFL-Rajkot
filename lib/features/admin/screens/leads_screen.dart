import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:coaching_app/models/lead_model.dart';
import 'package:coaching_app/features/admin/providers/leads_provider.dart';

const _statusConfig = {
  'new':       {'label': 'New Lead',   'color': Color(0xFF6366F1), 'icon': Icons.fiber_new_rounded},
  'contacted': {'label': 'Contacted',  'color': Color(0xFF0284C7), 'icon': Icons.phone_forwarded_rounded},
  'potential': {'label': 'Potential',  'color': Color(0xFFD97706), 'icon': Icons.star_rounded},
  'enrolled':  {'label': 'Enrolled',   'color': Color(0xFF059669), 'icon': Icons.check_circle_rounded},
  'dropped':   {'label': 'Dropped',    'color': Color(0xFFDC2626), 'icon': Icons.cancel_rounded},
};

class LeadsScreen extends ConsumerStatefulWidget {
  final bool readOnly;
  const LeadsScreen({super.key, this.readOnly = false});
  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _tabs = ['All', 'New', 'Contacted', 'Potential', 'Enrolled', 'Dropped'];
  final _tabFilters = ['all', 'new', 'contacted', 'potential', 'enrolled', 'dropped'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leadsState = ref.watch(leadsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Pipeline v3', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.auto_awesome, color: Colors.blueAccent), onPressed: _seed),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(leadsProvider.notifier).fetchLeads()),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(hintText: 'Search...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            )),
            TabBar(controller: _tabController, isScrollable: true, tabAlignment: TabAlignment.start, tabs: _tabs.map((t) => Tab(text: t)).toList()),
          ]),
        ),
      ),
      body: leadsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allLeads) {
          return TabBarView(controller: _tabController, children: _tabFilters.map((f) {
            final filtered = allLeads.where((l) {
              final mF = f == 'all' || l.status == f;
              final mS = _searchQuery.isEmpty || l.name.toLowerCase().contains(_searchQuery) || l.phone.contains(_searchQuery);
              return mF && mS;
            }).toList();
            if (filtered.isEmpty) return const Center(child: Text('No leads'));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: f == 'all' ? filtered.length + 1 : filtered.length,
              itemBuilder: (c, i) {
                if (f == 'all' && i == 0) return _summary(allLeads);
                final l = filtered[f == 'all' ? i - 1 : i];
                return _LeadCard(
                  lead: l, 
                  readOnly: widget.readOnly, 
                  onEdit: () => _open(l), 
                  onCall: () => _call(l.phone), 
                  onWA: () => _wa(l.phone),
                );
              },
            );
          }).toList());
        },
      ),
      floatingActionButton: widget.readOnly ? null : FloatingActionButton(onPressed: () => _open(null), child: const Icon(Icons.add)),
    );
  }

  Widget _summary(List<LeadModel> all) {
    final counts = <String, int>{};
    for (var l in all) counts[l.status] = (counts[l.status] ?? 0) + 1;
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [
      _chip('New', counts['new'] ?? 0, const Color(0xFF6366F1)), const SizedBox(width: 8),
      _chip('Pot.', counts['potential'] ?? 0, const Color(0xFFD97706)), const SizedBox(width: 8),
      _chip('Enr.', counts['enrolled'] ?? 0, const Color(0xFF059669)),
    ]));
  }

  Widget _chip(String l, int c, Color col) => Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Column(children: [Text('$c', style: TextStyle(color: col, fontWeight: FontWeight.bold)), Text(l, style: TextStyle(color: col, fontSize: 10))])));

  void _seed() async {
    await ref.read(leadsProvider.notifier).seedDummyLeads();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeded!')));
  }

  void _call(String p) async { final u = Uri.parse('tel:$p'); if (await canLaunchUrl(u)) launchUrl(u); }
  void _wa(String p) async {
    final c = p.replaceAll(RegExp(r'[^0-9]'), '');
    final f = c.length == 10 ? '91$c' : c;
    final u = Uri.parse("https://wa.me/$f");
    if (await canLaunchUrl(u)) launchUrl(u, mode: LaunchMode.externalApplication);
  }

  void _open(LeadModel? l) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          child: _LeadForm(existing: l, onSave: (lead) {
            if (l == null) ref.read(leadsProvider.notifier).addLead(lead);
            else ref.read(leadsProvider.notifier).updateLead(l.id, lead.toMap());
            Navigator.pop(ctx);
          }),
        ),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final LeadModel lead;
  final bool readOnly;
  final VoidCallback onEdit;
  final VoidCallback onCall;
  final VoidCallback onWA;
  const _LeadCard({required this.lead, required this.readOnly, required this.onEdit, required this.onCall, required this.onWA});

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig[lead.status]!;
    final col = cfg['color'] as Color;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        ListTile(
          leading: CircleAvatar(backgroundColor: col.withOpacity(0.1), child: Text(lead.name[0], style: TextStyle(color: col))),
          title: Text(lead.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(lead.phone),
          trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(cfg['label'] as String, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold))),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          IconButton(icon: const Icon(Icons.call, color: Colors.green, size: 22), onPressed: onCall),
          IconButton(icon: const Icon(Icons.chat_rounded, color: Colors.teal, size: 22), onPressed: onWA),
          if (!readOnly) IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 22), onPressed: onEdit),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _LeadForm extends StatefulWidget {
  final LeadModel? existing;
  final void Function(LeadModel) onSave;
  const _LeadForm({this.existing, required this.onSave});
  @override
  State<_LeadForm> createState() => _LeadFormState();
}

class _LeadFormState extends State<_LeadForm> {
  final _fKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  late String _st = widget.existing?.status ?? 'new';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(key: _fKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(widget.existing == null ? 'New Lead' : 'Edit Lead', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Required' : null),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _st,
          decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
          items: _statusConfig.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value['label'] as String))).toList(),
          onChanged: (v) => setState(() => _st = v!),
        ),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {
          if (_fKey.currentState!.validate()) {
            widget.onSave(LeadModel(id: widget.existing?.id ?? '', name: _name.text, phone: _phone.text, status: _st, createdAt: widget.existing?.createdAt ?? DateTime.now()));
          }
        }, child: const Text('Save'))),
      ])),
    );
  }
}
