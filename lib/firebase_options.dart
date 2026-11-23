import 'package:firebase_core/firebase_core.dart';

/// Replace this file with the output of `flutterfire configure`.
///
/// Keeping the missing configuration explicit prevents development credentials
/// from being fabricated or accidentally committed for the wrong project.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform => throw StateError(
    'Firebase configuration is missing. Run flutterfire configure with '
    'the Whatbytes Firebase project before launching the app.',
  );
}
