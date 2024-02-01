import 'dart:math';

import 'utils/hex.dart';
import 'utils/num.dart';

import 'lib_colors.dart';

class Rgb implements Color {
  int _r = 0;

  int _g = 0;

  int _b = 0;

  double _a = 0;

  Rgb({int r = 0, int g = 0, int b = 0, num a = 1.0}) {
    this.r = r;
    this.g = g;
    this.b = b;
    this.a = a;
  }

  factory Rgb.parse(String css) {
    if (css.startsWith('rgba')) {
      var match = rgbaRegExp.matchAsPrefix(css);
      if (match == null) throw FormatException("Invalid value!");

      var r = int.tryParse(match[1]!);
      if (r == null) throw FormatException("Invalid red compenent!");
      var g = int.tryParse(match[2]!);
      if (g == null) throw FormatException("Invalid green compenent!");
      var b = int.tryParse(match[3]!);
      if (b == null) throw FormatException("Invalid blue compenent!");
      var a = double.tryParse(match[4] ?? match[5]!);
      if (a == null) throw FormatException("Invalid alpha compenent!");
      return Rgb(r: r, g: g, b: b, a: a);
    }

    if (css.startsWith('rgb')) {
      var match = rgbRegExp.matchAsPrefix(css);
      if (match == null) throw FormatException("Invalid value!");

      var r = int.tryParse(match[1]!);
      if (r == null) throw FormatException("Invalid red compenent!");
      var g = int.tryParse(match[2]!);
      if (g == null) throw FormatException("Invalid green compenent!");
      var b = int.tryParse(match[3]!);
      if (b == null) throw FormatException("Invalid blue compenent!");
      return Rgb(r: r, g: g, b: b);
    }

    {
      final ret = NamedColors.decode(css);
      if (ret != null) return ret;
    }
    // TODO Eu Isaque implementei isso e não testei muito ainda
    if (css.startsWith('#')) {
      var hexColor = css.replaceAll('#', '');
      // if (hexColor.length == 3) {
      //   hexColor = '$hexColor$hexColor';
      //   var r = int.tryParse(hexColor.substring(0, 2), radix: 16);
      //   if (r == null) throw FormatException("Invalid red compenent!");
      //   var g = int.tryParse(hexColor.substring(2, 4), radix: 16);
      //   if (g == null) throw FormatException("Invalid green compenent!");
      //   var b = int.tryParse(hexColor.substring(4, 6), radix: 16);
      //   if (b == null) throw FormatException("Invalid blue compenent!");
      //   return Rgb(r: r, g: g, b: b);
      // }
      if (hexColor.length == 6) {
        var r = int.tryParse(hexColor.substring(0, 2), radix: 16);
        if (r == null) throw FormatException("Invalid red compenent!");
        var g = int.tryParse(hexColor.substring(2, 4), radix: 16);
        if (g == null) throw FormatException("Invalid green compenent!");
        var b = int.tryParse(hexColor.substring(4, 6), radix: 16);
        if (b == null) throw FormatException("Invalid blue compenent!");
        return Rgb(r: r, g: g, b: b);
      } else if (hexColor.length == 8) {
       
        var r = int.tryParse(hexColor.substring(0, 2), radix: 16);
        if (r == null) throw FormatException("Invalid red compenent!");
        var g = int.tryParse(hexColor.substring(2, 4), radix: 16);
        if (g == null) throw FormatException("Invalid green compenent!");
        var b = int.tryParse(hexColor.substring(4, 6), radix: 16);
        if (b == null) throw FormatException("Invalid blue compenent!");
        num? a = int.tryParse(hexColor.substring(6, 8), radix: 16);
    
        if (a == null) throw FormatException("Invalid blue compenent!");

        if (a >= 0 && a <= 255) {
          a = a / 255.0;
        } else {
          throw ArgumentError("Input value must be in the range 0-255");
        }

        return Rgb(r: r, g: g, b: b, a: a);
      }
    }

    throw FormatException("Invalid value!");
  }

  factory Rgb.fromHex(String hex) => HexColorCodec.decode(hex);

  factory Rgb.fromCssName(String name) {
    final ret = NamedColors.decode(name);
    if (ret == null) throw FormatException('Unknown color name $name');
    return ret;
  }

  factory Rgb.fromInt(int color) {
    double a = (color & 0xFF) / 0xFF;
    int b = (color >> 8) & 0xFF;
    int g = (color >> 16) & 0xFF;
    int r = (color >> 24) & 0xFF;
    return Rgb(r: r, g: g, b: b, a: a);
  }

  int get r => _r;

  int get g => _g;

  int get b => _b;

  @override
  double get a => _a;

  set r(int v) {
    if (v < 0 || v > 255) throw ArgumentError.value(v);
    _r = v;
  }

  set g(int v) {
    if (v < 0 || v > 255) throw ArgumentError.value(v);
    _g = v;
  }

  set b(int v) {
    if (v < 0 || v > 255) throw ArgumentError.value(v);
    _b = v;
  }

  @override
  set a(num v) {
    if (v < 0 || v > 1.0) throw ArgumentError.value(v);
    _a = v.toDouble();
  }

  @override
  Rgb clone({int? r, int? g, int? b, num? a}) =>
      Rgb(r: r ?? this.r, g: g ?? this.g, b: b ?? this.b, a: a ?? this.a);

  @override
  void assignRgb(Rgb rgb) {
    r = rgb.r;
    g = rgb.g;
    b = rgb.b;
    a = rgb.a;
  }

  @override
  void assignHsl(Hsl hsl) {
    assignRgb(hsl.toRgb);
  }

  @override
  double get brightness => (r * 299 + g * 587 + b * 114) / 1000;

  @override
  bool get isDark => brightness < 128.0;

  @override
  bool get isLight => !isDark;

  @override
  void brighten({num percent = 10}) {
    final term = (-(255 * percent / 100)).round();

    r = max(0, min(255, r - term));
    g = max(0, min(255, g - term));
    b = max(0, min(255, b - term));
  }

  @override
  void lighten({num percent = 10}) {
    assignHsl(toHsl..lighten(percent: percent));
  }

  @override
  void darken({num percent = 10}) {
    assignHsl(toHsl..darken(percent: percent));
  }

  @override
  void mix(Color withColor, {num percent = 50}) {
    final int p = (percent / 100).round();

    final withRgb = withColor.toRgb;
    a = (withRgb.a - a) * p + a;
    r = (withRgb.r - r) * p + r;
    g = (withRgb.g - g) * p + g;
    b = (withRgb.b - b) * p + b;
  }

  @override
  void tint({num percent = 10}) {
    mix(white, percent: percent);
  }

  @override
  void shade({num percent = 10}) {
    mix(black, percent: percent);
  }

  @override
  void desaturate({num percent = 10}) {
    assignHsl(toHsl..desaturate(percent: percent));
  }

  @override
  void saturate({num percent = 10}) {
    assignHsl(toHsl..saturate(percent: percent));
  }

  @override
  void greyscale() {
    assignHsl(toHsl..s = 0);
  }

  @override
  void spin(num degree) {
    assignHsl(toHsl..spin(degree));
  }

  @override
  void complement() {
    assignHsl(toHsl..complement());
  }

  @override
  Rgb get toRgb => clone();

  @override
  Hsl get toHsl {
    num rf = r / 255;
    num gf = g / 255;
    num bf = b / 255;
    num cMax = [rf, gf, bf].reduce(max);
    num cMin = [rf, gf, bf].reduce(min);
    num delta = cMax - cMin;
    num hue;
    num saturation;
    num luminance;

    if (cMax == rf) {
      hue = 60 * ((gf - bf) / delta % 6);
    } else if (cMax == gf) {
      hue = 60 * ((bf - rf) / delta + 2);
    } else {
      hue = 60 * ((rf - gf) / delta + 4);
    }

    if (hue.isNaN || hue.isInfinite) {
      hue = 0;
    }

    luminance = (cMax + cMin) / 2;

    if (delta == 0) {
      saturation = 0;
    } else {
      saturation = delta / (1 - (luminance * 2 - 1).abs());
    }

    return Hsl(h: hue, s: saturation * 100, l: luminance * 100, a: a);
  }

  @override
  Hsv get toHsv {
    final int max_ = max(max(r, g), b);
    final int min_ = min(min(r, g), b);
    final int d = max_ - min_;
    final int v = max_;
    final double s = max_ == 0 ? 0 : d / max_;
    double h = 0.0;

    if (max_ != min_) {
      if (max_ == r) {
        h = (g - b) / d + (g < b ? 6.0 : 0.0);
      } else if (max_ == g) {
        h = (b - r) / d + 2.0;
      } else {
        h = (r - g) / d + 4.0;
      }

      h /= 6.0;
    }

    return Hsv(h: h, s: s, v: v, a: a);
  }

  @override
  String get css => 'rgba($r, $g, $b, ${shortenDouble(a)})';

  @override
  String hex({bool shorten = true, bool withAlpha = true}) {
    return HexColorCodec.encode(this, shorten: shorten, withAlpha: withAlpha);
  }

  @override
  String toString() => css;

  static final rgbRegExp =
      RegExp(r'rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)$');
  static final rgbaRegExp = RegExp(
      r'rgba\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d+(\.\d*)?|\.\d+)\s*\)$');
}
