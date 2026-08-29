import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:valo_magaza/models/wallet.dart';

void main() {
  test('VP, RP, Kingdom Credits ve diğer bakiyeler kayıpsız çözümlenir', () {
    final source = File('test/fixtures/wallet.json').readAsStringSync();
    final wallet = Wallet.fromJson(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );

    expect(wallet.vp, 2450);
    expect(wallet.radianite, 80);
    expect(wallet.kingdomCredits, 7250);
    expect(wallet.balances['mock-unknown-currency'], 12);
  });
}
