import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../models/wallet.dart';

class WalletHeader extends StatelessWidget {
  const WalletHeader({required this.wallet, super.key});

  final Wallet? wallet;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern('tr_TR');
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final wide = constraints.maxWidth >= 700;
        final halfWidth = (constraints.maxWidth - spacing) / 2;
        final thirdWidth = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: wide ? thirdWidth : halfWidth,
              child: _BalanceTile(
                label: 'VALORANT Points',
                shortLabel: 'VP',
                value: wallet == null ? '—' : formatter.format(wallet!.vp),
                color: AppColors.gold,
                icon: Icons.diamond_outlined,
              ),
            ),
            SizedBox(
              width: wide ? thirdWidth : halfWidth,
              child: _BalanceTile(
                label: 'Radianite Points',
                shortLabel: 'RP',
                value: wallet == null
                    ? '—'
                    : formatter.format(wallet!.radianite),
                color: AppColors.blue,
                icon: Icons.hexagon_outlined,
              ),
            ),
            SizedBox(
              width: wide ? thirdWidth : constraints.maxWidth,
              child: _BalanceTile(
                label: 'Kingdom Credits',
                shortLabel: 'KC',
                value: wallet == null
                    ? '—'
                    : formatter.format(wallet!.kingdomCredits),
                color: AppColors.accent,
                icon: Icons.local_police_outlined,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({
    required this.label,
    required this.shortLabel,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String shortLabel;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.surfaceBright),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      shortLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
