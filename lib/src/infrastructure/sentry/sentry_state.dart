import 'package:meta/meta.dart';

@immutable
final class SentryState {
  final bool isEnabled;

  SentryState({required this.isEnabled});
}
