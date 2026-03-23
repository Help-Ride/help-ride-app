class DialCodeOption {
  const DialCodeOption({
    required this.isoCode,
    required this.countryName,
    required this.dialCode,
  });

  final String isoCode;
  final String countryName;
  final String dialCode;

  String get label => '$countryName ($dialCode)';
}

const authDialCodeOptions = <DialCodeOption>[
  DialCodeOption(isoCode: 'CA', countryName: 'Canada', dialCode: '+1'),
  DialCodeOption(isoCode: 'US', countryName: 'United States', dialCode: '+1'),
  DialCodeOption(isoCode: 'GB', countryName: 'United Kingdom', dialCode: '+44'),
  DialCodeOption(isoCode: 'AU', countryName: 'Australia', dialCode: '+61'),
  DialCodeOption(isoCode: 'IN', countryName: 'India', dialCode: '+91'),
  DialCodeOption(isoCode: 'MX', countryName: 'Mexico', dialCode: '+52'),
];
