import 'package:youversion_platform_core/youversion_platform_core.dart';

Future<void> main() async {
  final content = YouVersionContentClient(appKey: 'SUA_APP_KEY_AQUI');

  final biblias = await content.listBibles(languageRanges: ['pt']);
  for (final biblia in biblias.data) {
    print('${biblia.id}: ${biblia.title}');
  }

  if (biblias.data.isNotEmpty) {
    final trecho = await content.getPassage(
      bibleId: biblias.data.first.id,
      passageId: 'JHN.3.16',
      format: 'text',
    );
    print(trecho.content);
  }

  content.close();
}
