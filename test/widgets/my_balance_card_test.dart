import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wg_app/core/money.dart';
import 'package:wg_app/domain/pair_debts.dart';
import 'package:wg_app/features/balances/ui/my_balance_card.dart';

import 'test_app.dart';

PairDebt _debt(String otherId, int cents) =>
    PairDebt(otherId: otherId, cents: cents, entries: const []);

void main() {
  const names = {'a': 'Ana', 'b': 'Ben', 'h': 'Hakan'};

  testWidgets('owed: total without a sign and one line per person', (tester) async {
    // I paid 6,00 € for three people: Ana and Ben owe me 2,00 € each.
    await pumpTestApp(
      tester,
      Scaffold(
        body: MyBalanceCard(
          cents: 400,
          debts: [_debt('a', -200), _debt('b', -200)],
          names: names,
          lang: 'tr',
        ),
      ),
    );
    final l10n = await l10nFor(const Locale('tr'));
    final two = formatCents(200, locale: 'tr');

    expect(find.text(l10n.owedToYouTitle), findsOneWidget);
    expect(find.text(formatCents(400, locale: 'tr')), findsOneWidget);
    expect(find.text(l10n.owesYouLine('Ana', two)), findsOneWidget);
    expect(find.text(l10n.owesYouLine('Ben', two)), findsOneWidget);
    expect(find.textContaining('+'), findsNothing);
  });

  testWidgets('owing: "you owe" with the person to pay', (tester) async {
    await pumpTestApp(
      tester,
      Scaffold(
        body: MyBalanceCard(cents: -200, debts: [_debt('h', 200)], names: names, lang: 'tr'),
      ),
    );
    final l10n = await l10nFor(const Locale('tr'));

    expect(find.text(l10n.youOweTitle), findsOneWidget);
    expect(find.text(l10n.youOweLine('Hakan', formatCents(200, locale: 'tr'))), findsOneWidget);
  });

  testWidgets('settled: no amount, just "all settled up"', (tester) async {
    await pumpTestApp(
      tester,
      Scaffold(
        body: MyBalanceCard(cents: 0, debts: const [], names: names, lang: 'tr'),
      ),
    );
    final l10n = await l10nFor(const Locale('tr'));

    expect(find.text(l10n.allSettledUp), findsOneWidget);
    expect(find.text(formatCents(0, locale: 'tr')), findsNothing);
  });

  testWidgets('tappable only when a handler is given', (tester) async {
    var taps = 0;
    await pumpTestApp(
      tester,
      Scaffold(
        body: MyBalanceCard(
          cents: 0,
          debts: const [],
          names: names,
          lang: 'tr',
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.byType(MyBalanceCard));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });
}
