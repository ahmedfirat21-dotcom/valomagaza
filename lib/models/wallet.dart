import '../core/constants.dart';

class Wallet {
  const Wallet({
    required this.vp,
    required this.radianite,
    required this.kingdomCredits,
    required this.balances,
  });

  final int vp;
  final int radianite;
  final int kingdomCredits;

  /// Sunucunun döndürdüğü tüm para birimlerini kayıpsız tutar. Arayüzde
  /// bilinen VP, Radianite ve Kingdom Credits bakiyeleri adlarıyla gösterilir.
  final Map<String, int> balances;

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final rawBalances =
        (json['Balances'] ?? json['balances']) as Map? ?? const {};
    final balances = <String, int>{};
    for (final entry in rawBalances.entries) {
      balances[entry.key.toString().toLowerCase()] = _number(entry.value);
    }
    return Wallet(
      vp: balances[AppConstants.vpCurrencyId] ?? 0,
      radianite: balances[AppConstants.radianiteCurrencyId] ?? 0,
      kingdomCredits: balances[AppConstants.kingdomCreditsCurrencyId] ?? 0,
      balances: Map.unmodifiable(balances),
    );
  }

  static int _number(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
