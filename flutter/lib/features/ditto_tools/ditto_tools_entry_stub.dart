import 'package:flutter/material.dart';

import '../../ditto/ditto_manager.dart';

class DittoToolsButton extends StatelessWidget {
  const DittoToolsButton({super.key, required this.manager});

  final DittoManager manager;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.construction),
      label: const Text('Ditto Tools native only'),
    );
  }
}

class DittoToolsIconButton extends StatelessWidget {
  const DittoToolsIconButton({super.key, required this.manager});

  final DittoManager? manager;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Ditto Tools are available on native builds',
      onPressed: null,
      icon: const Icon(Icons.hub),
    );
  }
}
