import 'package:material_ui/material_ui.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Heavy startup (Firebase, DI, SharedPreferences) is deferred to the splash
  // screen so the first frame/logo appears quickly.
  runApp(const SafeRoomApp());
}
