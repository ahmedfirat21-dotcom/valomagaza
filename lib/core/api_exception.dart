enum ApiErrorType {
  network,
  unauthorized,
  rateLimited,
  serviceUnavailable,
  invalidLoginUrl,
  storeData,
  matchData,
  collectionData,
  competitiveData,
  unknown,
}

class ApiException implements Exception {
  const ApiException(this.type, {this.statusCode, this.cause});

  final ApiErrorType type;
  final int? statusCode;
  final Object? cause;

  bool get isSessionExpired => type == ApiErrorType.unauthorized;

  String get userMessage {
    switch (type) {
      case ApiErrorType.network:
        return 'İnternet bağlantısı yok. Bağlantınızı kontrol edip tekrar deneyin.';
      case ApiErrorType.unauthorized:
        return 'Riot oturumu sona erdi. Lütfen yeniden giriş yapın.';
      case ApiErrorType.rateLimited:
        return 'Çok fazla istek gönderildi. Lütfen biraz sonra tekrar deneyin.';
      case ApiErrorType.serviceUnavailable:
        return 'Riot hizmetine şu anda ulaşılamıyor. Lütfen daha sonra deneyin.';
      case ApiErrorType.invalidLoginUrl:
        return 'Kopyalanan giriş bağlantısı geçersiz.';
      case ApiErrorType.storeData:
        return 'Mağaza verisi alınamadı.';
      case ApiErrorType.matchData:
        return 'Maç verisi alınamadı.';
      case ApiErrorType.collectionData:
        return 'Koleksiyon verisi alınamadı.';
      case ApiErrorType.competitiveData:
        return 'Rekabet bilgisi alınamadı.';
      case ApiErrorType.unknown:
        return 'Beklenmeyen bir sorun oluştu. Lütfen tekrar deneyin.';
    }
  }

  static ApiException fromStatus(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return ApiException(ApiErrorType.unauthorized, statusCode: statusCode);
    }
    if (statusCode == 429) {
      return ApiException(ApiErrorType.rateLimited, statusCode: statusCode);
    }
    if (statusCode >= 500) {
      return ApiException(
        ApiErrorType.serviceUnavailable,
        statusCode: statusCode,
      );
    }
    return ApiException(ApiErrorType.unknown, statusCode: statusCode);
  }

  @override
  String toString() => userMessage;
}
