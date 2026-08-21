/// Organization (publisher) behind a bible (`Bible.organizationId`).
///
/// Contract validated against platform-sdk-kotlin, `organizations/models/Organization.kt`.
class Organization {
  Organization({
    required this.id,
    this.parentOrganizationId,
    this.name,
    this.description,
    this.email,
    this.phone,
    this.primaryLanguage,
    this.websiteUrl,
    this.address,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      parentOrganizationId: json['parent_organization_id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      primaryLanguage: json['primary_language'] as String?,
      websiteUrl: json['website_url'] as String?,
      address: json['address'] as String?,
    );
  }

  final String id;
  final String? parentOrganizationId;
  final String? name;
  final String? description;
  final String? email;
  final String? phone;
  final String? primaryLanguage;
  final String? websiteUrl;
  final String? address;
}
