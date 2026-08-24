import 'dart:async';

import 'package:flutter/services.dart';
import 'package:punklorde/core/account/code_handler.dart';
import 'package:punklorde/module/model/auth.dart';
import 'package:punklorde/utils/etc/byte.dart';

class PkldFileHandler {
  static const _channelName = 'hacker.silverwolf.punklorde/pkld_handler';

  final List<PkldTypeHandler> _handlers = [];

  PkldFileHandler() {
    _handlers.add(_GuestAccountPkldHandler());
  }

  void registerHandler(PkldTypeHandler handler) {
    _handlers.add(handler);
  }

  void init() {
    final channel = MethodChannel(_channelName);
    channel.setMethodCallHandler((call) async {
      if (call.method == 'onPkldFileReceived') {
        final bytes = call.arguments as Uint8List;
        await _handleFile(bytes);
      }
    });

    channel.invokeMethod('getPendingPkldFile').then((result) {
      if (result is Uint8List && result.isNotEmpty) {
        _handleFile(result);
      }
    });
  }

  Future<void> _handleFile(Uint8List bytes) async {
    for (final handler in _handlers) {
      if (handler.match(bytes)) {
        await handler.handle(bytes);
        return;
      }
    }
  }
}

abstract class PkldTypeHandler {
  bool match(Uint8List bytes);
  Future<void> handle(Uint8List bytes);
}

class _GuestAccountPkldHandler extends PkldTypeHandler {
  @override
  bool match(Uint8List bytes) {
    return startsWith(bytes, shareDataMagicNum);
  }

  @override
  Future<void> handle(Uint8List bytes) async {
    await handlerGuestAccount.handleFromFile(bytes);
  }
}

final pkldFileHandler = PkldFileHandler();
