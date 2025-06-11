class SiretResponse {
  final String? siret;
  final String? company_name;
  final String? company_type;
  final String? address;
  final String? postal_code;
  final String? city;

  SiretResponse({
    this.siret,
    this.company_name,
    this.company_type,
    this.address,
    this.postal_code,
    this.city,
  });

  factory SiretResponse.fromJson(Map<String, dynamic> json) {
    return SiretResponse(
      siret: json['siret']?.toString(),
      company_name: json['company_name']?.toString(),
      company_type: json['company_type']?.toString(),
      address: json['address']?.toString(),
      postal_code: json['postal_code']?.toString(),
      city: json['city']?.toString(),
    );
  }
}
