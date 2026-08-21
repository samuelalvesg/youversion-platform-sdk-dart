/// Unofficial Dart client for the YouVersion Platform APIs (core/protocol,
/// no UI): Content (Bibles), Sign-In (OAuth PKCE), Data Exchange
/// (highlights via consent), Highlights (direct CRUD), Languages,
/// Organizations, and VOTD (Verse of the Day).
///
/// Equivalent to the `platform-core` module of the official SDKs (Kotlin,
/// Swift, React, React Native/Expo) - without their `platform-ui`/
/// `platform-reader` layers, which are native-UI-specific.
library;

export 'src/content/api/youversion_content_client.dart';
export 'src/content/models/bible.dart';
export 'src/content/models/bible_book.dart';
export 'src/content/models/bible_book_intro.dart';
export 'src/content/models/bible_chapter.dart';
export 'src/content/models/bible_passage.dart';
export 'src/content/models/bible_verse.dart';
export 'src/content/models/bible_version_index.dart';
export 'src/content/models/collection.dart';
export 'src/data_exchange/api/youversion_data_exchange_client.dart';
export 'src/data_exchange/models/data_exchange_result.dart';
export 'src/highlights/api/youversion_highlights_client.dart';
export 'src/highlights/models/highlight.dart';
export 'src/http/youversion_exception.dart';
export 'src/http/youversion_http_client.dart';
export 'src/http/youversion_sdk_headers.dart';
export 'src/languages/api/youversion_languages_client.dart';
export 'src/languages/models/language.dart';
export 'src/organizations/api/youversion_organizations_client.dart';
export 'src/organizations/models/organization.dart';
export 'src/sign_in/api/youversion_sign_in.dart';
export 'src/sign_in/models/permission.dart';
export 'src/sign_in/models/youversion_identity.dart';
export 'src/sign_in/models/youversion_token.dart';
export 'src/sign_in/pkce.dart';
export 'src/votd/api/youversion_votd_client.dart';
export 'src/votd/models/verse_of_the_day.dart';
