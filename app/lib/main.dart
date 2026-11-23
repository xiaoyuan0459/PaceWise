import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pacebridge/app/app.dart';
import 'package:pacebridge/data/core.dart';
import 'package:pacebridge/src/rust/api/app.dart';
import 'package:pacebridge/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  try {
    final support = await getApplicationSupportDirectory();
    final info = open(dataDir: '${support.path}/data');
    runApp(
      ProviderScope(
        overrides: [appInfoProvider.overrideWithValue(info)],
        child: const PaceBridgeApp(),
      ),
    );
  } catch (error) {
    runApp(_StartupError(error));
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError(this.error);

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Rust 内核启动失败：$error'),
          ),
        ),
      ),
    );
  }
}
