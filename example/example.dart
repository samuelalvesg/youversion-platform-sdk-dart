import 'package:youversion_platform/youversion_platform.dart';

Future<void> main() async {
  final content = YouVersionContentClient(appKey: 'SUA_APP_KEY_AQUI');

  final biblias = await content.listBibles(languageRanges: ['pt']);
  for (final biblia in biblias) {
    print('${biblia.id}: ${biblia.title}');
  }

  if (biblias.isNotEmpty) {
    final trecho = await content.getPassage(
      bibleId: biblias.first.id,
      passageId: 'JHN.3.16',
      format: 'text',
    );
    print(trecho.content);
  }

  content.close();
}
