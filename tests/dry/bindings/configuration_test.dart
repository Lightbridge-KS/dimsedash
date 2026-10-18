import 'package:dimsedash/bindings/configuration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reveal state resets in a new application scope', () {
    final first = ProviderContainer();
    expect(first.read(revealProvider), isFalse);
    first.read(revealProvider.notifier).toggle();
    expect(first.read(revealProvider), isTrue);
    first.dispose();
    final second = ProviderContainer();
    expect(second.read(revealProvider), isFalse);
    second.dispose();
  });
}
