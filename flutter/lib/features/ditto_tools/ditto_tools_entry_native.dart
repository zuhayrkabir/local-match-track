import 'package:ditto_flutter_tools/ditto_flutter_tools.dart';
import 'package:flutter/material.dart';

import '../../ditto/ditto_manager.dart';

class DittoToolsButton extends StatelessWidget {
  const DittoToolsButton({super.key, required this.manager});

  final DittoManager manager;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: manager.dataAccessReady
          ? () => _openDittoTools(context, manager)
          : null,
      icon: const Icon(Icons.hub),
      label: const Text('Open Ditto Tools'),
    );
  }
}

class DittoToolsIconButton extends StatelessWidget {
  const DittoToolsIconButton({super.key, required this.manager});

  final DittoManager? manager;

  @override
  Widget build(BuildContext context) {
    final value = manager;
    final enabledManager = value?.dataAccessReady == true ? value : null;
    return IconButton(
      tooltip: enabledManager != null
          ? 'Open Ditto Tools'
          : 'Ditto Tools available after Ditto activates',
      onPressed: enabledManager != null
          ? () => _openDittoTools(context, enabledManager)
          : null,
      icon: const Icon(Icons.hub),
    );
  }
}

void _openDittoTools(BuildContext context, DittoManager manager) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => _DittoToolsScreen(manager: manager)),
  );
}

class _DittoToolsScreen extends StatelessWidget {
  const _DittoToolsScreen({required this.manager});

  final DittoManager manager;

  @override
  Widget build(BuildContext context) {
    final ditto = manager.ditto;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ditto Tools'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Peers'),
              Tab(icon: Icon(Icons.sync), text: 'Sync'),
              Tab(icon: Icon(Icons.terminal), text: 'DQL'),
              Tab(icon: Icon(Icons.health_and_safety), text: 'Permissions'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
              Tab(icon: Icon(Icons.storage), text: 'Storage'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PeerListView(ditto: ditto),
            PeerSyncStatusView(ditto: ditto),
            QueryEditorView(ditto: ditto),
            const PermissionsHealthView(),
            SystemSettingsView(ditto: ditto),
            DiskUsageView(ditto: ditto),
          ],
        ),
      ),
    );
  }
}
