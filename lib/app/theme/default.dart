import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:forui/forui.dart';
import 'package:pinput/pinput.dart';

const _colorsLight = FColors(
  brightness: .light,
  systemOverlayStyle: .dark,
  barrier: Color(0x33000000),
  background: Color(0xFFFEFEFF),
  foreground: Color(0xFF09090B),
  primary: Color(0xFF4B5CC4),
  primaryForeground: Color(0xFFEFF6FF),
  secondary: Color(0xFFF4F4F5),
  secondaryForeground: Color(0xFF18181B),
  muted: Color(0xFFF4F4F5),
  mutedForeground: Color(0xFF71717B),
  destructive: Color(0xFFE7000B),
  destructiveForeground: Color(0xFFFAFAFA),
  error: Color(0xFFE7000B),
  errorForeground: Color(0xFFFAFAFA),
  card: Color(0xFFFEFEFF),
  border: Color(0xFFE4E4E7),
);

const _colorsDark = FColors(
  brightness: .dark,
  systemOverlayStyle: .light,
  barrier: Color(0x7A000000),
  background: Color(0xFF1D1D1F),
  foreground: Color(0xFFFAFAFA),
  primary: Color(0xFF2775B6),
  primaryForeground: Color(0xFFEFF6FF),
  secondary: Color(0xFF2A2A2D),
  secondaryForeground: Color(0xFFFAFAFA),
  muted: Color(0xFF27272A),
  mutedForeground: Color(0xFF9F9FA9),
  destructive: Color(0xFFFF6467),
  destructiveForeground: Color(0xFFFAFAFA),
  error: Color(0xFFFF6467),
  errorForeground: Color(0xFFFAFAFA),
  card: Color(0xFF212123),
  border: Color(0x1AFFFFFF),
);

FThemeData _defaultLight(bool mobile) => FThemeData(
  touch: mobile,
  debugLabel: 'Blue Light Touch',
  colors: _colorsLight,
);

FThemeData _defaultDark(bool mobile) => FThemeData(
  touch: mobile,
  debugLabel: 'Blue Dark Touch',
  colors: _colorsDark,
);

final lightTheme = _defaultLight(
  const <TargetPlatform>{
    .android,
    .iOS,
    .fuchsia,
  }.contains(defaultTargetPlatform),
);

final darkTheme = _defaultDark(
  const <TargetPlatform>{
    .android,
    .iOS,
    .fuchsia,
  }.contains(defaultTargetPlatform),
);

final pinLightTheme = PinTheme(
  width: 56,
  height: 56,
  textStyle: .new(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    fontFamily: 'AlteDIN1451',
    color: lightTheme.colors.foreground,
  ),
  decoration: .new(
    color: lightTheme.colors.card,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: lightTheme.colors.border, width: 1),
  ),
);

final pinDarkTheme = PinTheme(
  width: 56,
  height: 56,
  textStyle: .new(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    fontFamily: 'AlteDIN1451',
    color: darkTheme.colors.foreground,
  ),
  decoration: .new(
    color: darkTheme.colors.card,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: darkTheme.colors.border, width: 1),
  ),
);
