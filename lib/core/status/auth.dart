import 'package:punklorde/common/models/auth.dart';
import 'package:punklorde/core/account/manager.dart';
import 'package:signals/signals.dart';

final Signal<Map<String, dynamic>> authStatus = signal({});

final Signal<Map<String, AuthCredential>> authCredential = signal({});

final AuthManager authManager = AuthManager();
