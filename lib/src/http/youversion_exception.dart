/// Exceção lançada por qualquer chamada às APIs da YouVersion Platform.
class YouVersionException implements Exception {
  YouVersionException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() => 'YouVersionException($statusCode): $message';
}
