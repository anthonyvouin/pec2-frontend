class Creator {
  final String bic;
  final String city;
  final String companyName;
  final String documentProofUrl;
  final String iban;
  final String id;
  final String postalCode;
  final String siretNumber;
  final String streetAddress;
  final String vatNumber;

  Creator({
    required this.bic,
    required this.city,
    required this.companyName,
    required this.documentProofUrl,
    required this.iban,
    required this.id,
    required this.postalCode,
    required this.siretNumber,
    required this.streetAddress,
    required this.vatNumber
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      bic: json['bic'],
      city: json['city'],
      companyName: json['companyName'],
      documentProofUrl: json['documentProofUrl'],
      iban: json['iban'],
      id: json['id'],
      postalCode: json['postalCode'],
      siretNumber: json['siretNumber'],
      streetAddress: json['streetAddress'],
      vatNumber: json['vatNumber'],
    );
  }
}
