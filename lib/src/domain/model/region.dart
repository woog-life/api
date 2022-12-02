import 'package:country_code/country_code.dart';

final _commaCountries = {
  CountryCode.AL,
  CountryCode.DZ,
  CountryCode.AD,
  CountryCode.AO,
  CountryCode.AR,
  CountryCode.AM,
  CountryCode.AT,
  CountryCode.AZ,
  CountryCode.BY,
  CountryCode.BE,
  CountryCode.BO,
  CountryCode.BA,
  CountryCode.BR,
  CountryCode.BG,
  CountryCode.CM,
  CountryCode.CL,
  CountryCode.CO,
  CountryCode.CR,
  CountryCode.HR,
  CountryCode.CU,
  CountryCode.CY,
  CountryCode.CZ,
  CountryCode.DK,
  CountryCode.EC,
  CountryCode.EE,
  CountryCode.FO,
  CountryCode.FI,
  CountryCode.FR,
  CountryCode.DE,
  CountryCode.GE,
  CountryCode.GR,
  CountryCode.GL,
  CountryCode.HU,
  CountryCode.IS,
  CountryCode.ID,
  CountryCode.IT,
  CountryCode.KZ,
  CountryCode.KG,
  CountryCode.LV,
  CountryCode.LB,
  CountryCode.LT,
  CountryCode.MR,
  CountryCode.MD,
  CountryCode.MN,
  CountryCode.ME,
  CountryCode.MA,
  CountryCode.MZ,
  CountryCode.NL,
  CountryCode.MK,
  CountryCode.NO,
  CountryCode.PY,
  CountryCode.PE,
  CountryCode.PL,
  CountryCode.PT,
  CountryCode.RO,
  CountryCode.RU,
  CountryCode.RS,
  CountryCode.SK,
  CountryCode.SI,
  CountryCode.SO,
  CountryCode.ZA,
  CountryCode.ES,
  CountryCode.SR,
  CountryCode.SE,
  CountryCode.CH,
  CountryCode.TN,
  CountryCode.TR,
  CountryCode.TM,
  CountryCode.UA,
  CountryCode.UY,
  CountryCode.UZ,
  CountryCode.VE,
  CountryCode.VN,
  CountryCode.ZW,
};

final _dotCountries = {
  CountryCode.AU,
  CountryCode.BS,
  CountryCode.BD,
  CountryCode.BW,
  CountryCode.KH,
  CountryCode.CA,
  CountryCode.CN,
  CountryCode.DO,
  CountryCode.EG,
  CountryCode.SV,
  CountryCode.ET,
  CountryCode.GH,
  CountryCode.GT,
  CountryCode.GY,
  CountryCode.HN,
  CountryCode.HK,
  CountryCode.IN,
  CountryCode.IE,
  CountryCode.IL,
  CountryCode.JM,
  CountryCode.JP,
  CountryCode.JO,
  CountryCode.KE,
  CountryCode.KP,
  CountryCode.KR,
  CountryCode.LY,
  CountryCode.LI,
  CountryCode.LU,
  CountryCode.MY,
  CountryCode.MV,
  CountryCode.MT,
  CountryCode.MX,
  CountryCode.MM,
  CountryCode.NA,
  CountryCode.NP,
  CountryCode.NZ,
  CountryCode.NI,
  CountryCode.NG,
  CountryCode.PK,
  CountryCode.PA,
  CountryCode.PH,
  CountryCode.QA,
  CountryCode.SA,
  CountryCode.SG,
  CountryCode.SO,
  CountryCode.LK,
  CountryCode.CH,
  CountryCode.SY,
  CountryCode.TW,
  CountryCode.TZ,
  CountryCode.TH,
  CountryCode.UG,
  CountryCode.AE,
  CountryCode.GB,
  CountryCode.US,
};

class Region {
  final String identifier;
  final String decimalSeparator;

  const Region._(this.identifier, {required this.decimalSeparator});

  static const Region germany = Region._(
    'DE',
    decimalSeparator: ',',
  );

  static const Region usa = Region._(
    'US',
    decimalSeparator: '.',
  );

  static Region? parseIdentifier(String identifier) {
    final CountryCode code;
    try {
      code = CountryCode.parse(identifier);
    } on FormatException {
      return null;
    }

    if (_commaCountries.contains(code)) {
      return Region._(code.alpha2, decimalSeparator: ',');
    } else if (_dotCountries.contains(code)) {
      return Region._(code.alpha2, decimalSeparator: '.');
    } else {
      // Just default to comma, just by going by the number of countries that
      // support this as part their SI style (yes, there's multiple ones).
      return Region._(code.alpha2, decimalSeparator: ',');
    }
  }
}
