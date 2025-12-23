import 'dart:convert';

import 'package:mmkv/mmkv.dart';
import 'package:punklorde/common/models/auth.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/store.dart';

late final MMKV authMMKV;

void initAuthStore() {
  authMMKV = MMKV("auth", cryptKey: mmkvKey);

  var primary = authMMKV.decodeString("primary_auth");
  var guest = authMMKV.decodeString("guest_auth");
  try {
    if (primary != null) {
      authCredential.value = Map<String, AuthCredential>.from(
        (jsonDecode(primary) as Map<String, dynamic>).map(
          (k1, v1) => MapEntry(k1, AuthCredential.fromJson(v1)),
        ),
      );
    }
    if (guest != null) {
      guestAuthCredential.value =
          Map<String, Map<String, GuestAuthCredential>>.from(
            (jsonDecode(guest) as Map<String, dynamic>).map(
              (k1, v1) => MapEntry(
                k1,
                (v1 as Map<String, dynamic>).map(
                  (k2, v2) => MapEntry(k2, GuestAuthCredential.fromJson(v2)),
                ),
              ),
            ),
          );
    }
  } catch (e) {}

  authCredential.subscribe((v) {
    authMMKV.encodeString(
      "primary_auth",
      jsonEncode(v.map((k1, v1) => MapEntry(k1, v1.toJson()))),
    );
  });
  guestAuthCredential.subscribe((v) {
    authMMKV.encodeString(
      "guest_auth",
      jsonEncode(
        v.map(
          (k1, v1) =>
              MapEntry(k1, v1.map((k2, v2) => MapEntry(k2, v2.toJson()))),
        ),
      ),
    );
  });
}
