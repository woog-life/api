enum Region {
  germany('DE', decimalSeparator: ','),
  usa('US', decimalSeparator: '.'),
  ;

  final String identifier;
  final String decimalSeparator;

  const Region(this.identifier, {required this.decimalSeparator});

  static Region? parseIdentifier(String identifier) {
    for (final region in Region.values) {
      if (region.identifier == identifier) {
        return region;
      }
    }
    return null;
  }
}
