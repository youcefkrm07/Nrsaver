import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/client.dart';
import '../services/local_db.dart';
import '../services/remote_api.dart';

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
  bool _hasAnyClient = false;
  bool _savingOnline = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final allClients = LocalDB.getAll();
    final trimmedQuery = _search.trim();

    final filtered = trimmedQuery.isEmpty
        ? allClients
        : allClients
            .where((client) {
              final query = trimmedQuery.toLowerCase();
              return client.name.toLowerCase().contains(query) ||
                  client.mobile4g.toLowerCase().contains(query) ||
                  client.fibre.toLowerCase().contains(query);
            })
            .toList();

    setState(() {
      _hasAnyClient = allClients.isNotEmpty;
      _clients = filtered;
    });
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _g4Ctrl.dispose();
    _fibreCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveOnline() async {
    if (_savingOnline) return;

    final messenger = ScaffoldMessenger.of(context);
    final s = Strings.of(context);
    final allClients = LocalDB.getAll();

    if (allClients.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(s.saveOnlineNoClients),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _savingOnline = true);

    final result = await RemoteApi.saveClients(allClients);

    if (!mounted) {
      return;
    }

    setState(() => _savingOnline = false);

    if (!result.success) {
      debugPrint(
          'Remote save failed (status ${result.statusCode ?? 'unknown'}): ${result.message}');
      if (result.error != null) {
        debugPrint('Remote save error detail: ${result.error}');
      }
    }

    final statusSuffix =
        result.statusCode != null ? ' (HTTP ${result.statusCode})' : '';
    final snackBarText = result.success
        ? '${s.saveOnlineSuccess}$statusSuffix'
        : '${s.saveOnlineError}$statusSuffix\n${result.message}';

    messenger.showSnackBar(
      SnackBar(
        content: Text(snackBarText),
        behavior: SnackBarBehavior.floating,
      ),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed:
                        (!_hasAnyClient || _savingOnline) ? null : _saveOnline,
                    icon: _savingOnline
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      _savingOnline ? s.savingOnline : s.saveOnline,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _clients.isEmpty
                      ? Center(
                          child: Text(s.noData),
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
    // ignore: unused_local_variable
    final _ = s; // keep reference to suppress unused warning
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
