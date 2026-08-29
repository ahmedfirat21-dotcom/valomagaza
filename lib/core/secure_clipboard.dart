import 'package:flutter/services.dart';

class SecureClipboard {
  SecureClipboard._();

  /// Panodaki metni bir kez okur ve token bağlantısının panoda kalmaması için
  /// hemen temizler.
  static Future<String> readAndClearText() async {
    final value = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    await Clipboard.setData(const ClipboardData(text: ''));
    return value;
  }
}
