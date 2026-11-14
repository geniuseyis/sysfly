import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Hands content to the system share sheet.
abstract interface class ShareService {
  Future<void> shareText({required String text, String? subject, Rect? origin});

  /// Shares [bytes] as a file called [fileName].
  Future<void> shareFile({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
    String? subject,
    Rect? origin,
  });
}

class SystemShareService implements ShareService {
  const SystemShareService();

  @override
  Future<void> shareText({required String text, String? subject, Rect? origin}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject, sharePositionOrigin: origin));
  }

  @override
  Future<void> shareFile({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
    String? subject,
    Rect? origin,
  }) async {
    final file = XFile.fromData(Uint8List.fromList(bytes), mimeType: mimeType, name: fileName);
    await SharePlus.instance.share(
      ShareParams(files: [file], fileNameOverrides: [fileName], subject: subject, sharePositionOrigin: origin),
    );
  }
}

final shareServiceProvider = Provider<ShareService>((ref) => const SystemShareService());
