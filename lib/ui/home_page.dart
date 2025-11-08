import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../services/local_db.dart';
import '../models/client.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _g4Ctrl = TextEditingController();
  final _fibreCtrl = TextEditingController();
  String _search = '';

  List<ClientModel> _clients = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _clients = _search.isEmpty
          ? LocalDB.getAll()
          : LocalDB.search(_search);
    });
  }

  Future<void> _exportDb() async {
    final s = Strings.of(context);
    try {
      final directory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: s.selectExportDirectory,
      );
      if (directory == null) return;
      final fileName =
          'clients_backup_${DateTime.now().millisecondsSinceEpoch}.hive';
      final savedPath =
          await LocalDB.exportToDirectory(directory, fileName: fileName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.exportSuccess}\n$savedPath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.exportFailure}\n$e')),
      );
    }
  }

  Future<void> _importDb() async {
    final s = Strings.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['hive'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.bytes != null) {
        await LocalDB.importFromBytes(file.bytes!);
      } else if (file.path != null) {
        await LocalDB.importFromFile(file.path!);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.importUnsupported)),
        );
        return;
      }
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.importSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.importFailure}\n$e')),
      );
    }
  }

  Future<void> _addOrUpdate({ClientModel? edit}) async {
    final s = Strings.of(context);
    if (edit != null) {
      _nameCtrl.text = edit.name;
      _g4Ctrl.text = edit.mobile4g;
      _fibreCtrl.text = edit.fibre;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
            child: Directionality(
              textDirection: s.isAr ? TextDirection.rtl : TextDirection.ltr,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(
                      label: s.name,
                      controller: _nameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? s.enterName
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      label: s.n4g,
                      controller: _g4Ctrl,
                      validator: (v) {
                        final has4g = v != null && v.trim().isNotEmpty;
                        final hasFibre = _fibreCtrl.text.trim().isNotEmpty;
                        return has4g || hasFibre ? null : s.enter4gOrFibre;
                      },
                      keyboard: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      label: s.fibre,
                      controller: _fibreCtrl,
                      validator: (v) {
                        final hasFibre = v != null && v.trim().isNotEmpty;
                        final has4g = _g4Ctrl.text.trim().isNotEmpty;
                        return has4g || hasFibre ? null : s.enter4gOrFibre;
                      },
                      keyboard: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() != true) return;
                        // Capture Navigator before awaiting to avoid using context across async gaps
                        final nav = Navigator.of(ctx);
                        if (edit == null) {
                          await LocalDB.addClient(
                              _nameCtrl.text.trim(),
                              _g4Ctrl.text.trim(),
                              _fibreCtrl.text.trim());
                        } else {
                          await LocalDB.updateClient(edit.copyWith(
                            name: _nameCtrl.text.trim(),
                            mobile4g: _g4Ctrl.text.trim(),
                            fibre: _fibreCtrl.text.trim(),
                          ));
                        }
                        _nameCtrl.clear();
                        _g4Ctrl.clear();
                        _fibreCtrl.clear();
                        if (nav.canPop()) {
                          nav.pop();
                        }
                        _refresh();
                      },
                      child: Text(edit == null ? s.addClient : s.edit),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final isRtl = s.isAr;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.appTitle),
          actions: [
            IconButton(
              tooltip: s.exportDb,
              icon: const Icon(Icons.file_upload),
              onPressed: _exportDb,
            ),
            IconButton(
              tooltip: s.importDb,
              icon: const Icon(Icons.file_download),
              onPressed: _importDb,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: PopupMenuButton<Locale>(
                icon: const Icon(Icons.language),
                onSelected: (loc) => MyLocale.change(context, loc),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: Locale('en'), child: Text('English')),
                  PopupMenuItem(value: Locale('ar'), child: Text('العربية')),
                ],
              ),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _addOrUpdate(),
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(s.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (v) {
                    _search = v;
                    _refresh();
                  },
                  decoration: InputDecoration(
                    hintText: s.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _clients.isEmpty
                      ? Center(
                          child: Text(isRtl ? 'لا يوجد بيانات' : 'No data'),
                        )
                      : ListView.builder(
                          itemCount: _clients.length,
                          itemBuilder: (context, i) {
                            final c = _clients[i];
                            return _ClientTile(
                              client: c,
                              onEdit: () => _addOrUpdate(edit: c),
                              onDelete: () async {
                                await LocalDB.deleteClient(c.id);
                                _refresh();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  final ClientModel client;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ClientTile({required this.client, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final mobile4g = client.mobile4g.trim();
    final fibre = client.fibre.trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    client.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
                IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.call, size: 18, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    '4G: ${client.mobile4g}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  tooltip: s.copy,
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: mobile4g.isEmpty
                      ? null
                      : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await Clipboard.setData(
                          ClipboardData(text: mobile4g),
                        );
                        messenger.showSnackBar(
                          SnackBar(content: Text(s.copied)),
                        );
                      },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.wifi, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: SelectableText(
                    'FIBRE: ${client.fibre}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  tooltip: s.copy,
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: fibre.isEmpty
                      ? null
                      : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await Clipboard.setData(
                          ClipboardData(text: fibre),
                        );
                        messenger.showSnackBar(
                          SnackBar(content: Text(s.copied)),
                        );
                      },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MyLocale extends InheritedWidget {
  final Locale locale;
  final void Function(Locale) setLocale;
  const MyLocale({required this.locale, required this.setLocale, required super.child, super.key});

  static void change(BuildContext context, Locale locale) {
    context.findAncestorStateOfType<_LocaleState>()?.change(locale);
  }

  @override
  bool updateShouldNotify(covariant MyLocale oldWidget) => oldWidget.locale != locale;
}

class LocaleSwitcher extends StatefulWidget {
  final Widget child;
  const LocaleSwitcher({super.key, required this.child});

  @override
  State<LocaleSwitcher> createState() => _LocaleState();
}

class _LocaleState extends State<LocaleSwitcher> {
  Locale _locale = const Locale('en');

  void change(Locale l) => setState(() => _locale = l);

  @override
  Widget build(BuildContext context) {
    return MyLocale(
      locale: _locale,
      setLocale: change,
      child: widget.child,
    );
  }
}
