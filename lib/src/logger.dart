import 'package:logger/logger.dart';

export 'package:logger/logger.dart';

final logger = Logger(
  printer: SimplePrinter(),
  filter: ProductionFilter(),
);
