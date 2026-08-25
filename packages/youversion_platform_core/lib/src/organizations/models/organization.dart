/// A localized place name with short and long forms (e.g. `short_name:
/// "OK"`, `long_name: "Oklahoma"`).
class PlaceName {
  PlaceName({this.shortName, this.longName});

  factory PlaceName.fromJson(Map<String, dynamic> json) {
    return PlaceName(
      shortName: json['short_name'] as String?,
      longName: json['long_name'] as String?,
    );
  }

  final String? shortName;
  final String? longName;
}

/// [Organization.address] - confirmed live (`GET /v1/organizations`) and
/// against `platform-sdk-react`'s `OrganizationAddressSchema`, a
/// structured object, not a plain string. `platform-sdk-kotlin`'s own
/// `Organization.address: String?` has the same gap this class fixes -
/// see `docs/DECISIONS.md`.
class OrganizationAddress {
  OrganizationAddress({
    this.formattedAddress,
    this.formattedLocality,
    this.placeId,
    this.latitude,
    this.longitude,
    this.administrativeAreaLevel1,
    this.locality,
    this.country,
  });

  factory OrganizationAddress.fromJson(Map<String, dynamic> json) {
    PlaceName? place(String key) {
      final value = json[key];
      return value is Map<String, dynamic> ? PlaceName.fromJson(value) : null;
    }

    return OrganizationAddress(
      formattedAddress: json['formatted_address'] as String?,
      formattedLocality: json['formatted_locality'] as String?,
      placeId: json['place_id'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      administrativeAreaLevel1: place('administrative_area_level_1'),
      locality: place('locality'),
      country: place('country'),
    );
  }

  /// Human-readable address, e.g. `"7255 W. Camp Wisdom Rd., Dallas, TX 75236"`.
  final String? formattedAddress;
  final String? formattedLocality;
  final String? placeId;
  final double? latitude;
  final double? longitude;
  final PlaceName? administrativeAreaLevel1;
  final PlaceName? locality;
  final PlaceName? country;
}

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
      address: switch (json['address']) {
        final Map<String, dynamic> value => OrganizationAddress.fromJson(value),
        _ => null,
      },
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

  /// Confirmed live: a real structured object (`formatted_address` etc.),
  /// not a plain string - see [OrganizationAddress]'s doc comment.
  final OrganizationAddress? address;
}
