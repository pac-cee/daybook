// Console exercises intentionally print their results.
// ignore_for_file: avoid_print
Future<String> orderBrochette() async {
  await Future<void>.delayed(const Duration(seconds: 3));
  return 'Your brochette is ready';
}

Future<String> orderDrink() async {
  await Future<void>.delayed(const Duration(seconds: 1));
  return 'Your Fanta is ready';
}

Future<void> main() async {
  final watch = Stopwatch()..start();
  print('1. You order a brochette and a drink');
  final food = orderBrochette();
  final drink = orderDrink();
  print('2. While they are prepared, you chat with your friends');
  for (final item in await Future.wait([food, drink])) {
    print(item);
  }
  print(
    '3. You eat. Both orders took about ${watch.elapsed.inSeconds} seconds.',
  );
}
