import 'lib_colors.dart';

import 'utils/num.dart';

class Hsl implements Color {
  double _h = 0;

  double _s = 0;

  double _l = 0;

  double _a = 0;

  Hsl({num h = 0, num s = sMax, num l = 50, num a = 1.0}) {
    this.h = h;
    this.s = s;
    this.l = l;
    this.a = a;
  }

  factory Hsl.parse(String css) {
    var match = hslRegExp.matchAsPrefix(css);
    if (match != null) {
      return Hsl(
        h: double.parse(match.group(1)!),
        s: double.parse(match.group(2) ?? match.group(3)!),
        l: double.parse(match.group(4) ?? match.group(5)!),
      );
    }

    match = hslaRegExp.matchAsPrefix(css);
    if (match != null) {
      return Hsl(
        h: double.parse(match.group(1)!),
        s: double.parse(match.group(2) ?? match.group(3)!),
        l: double.parse(match.group(4) ?? match.group(5)!),
        a: double.parse(match.group(6) ?? match.group(7)!),
      );
    }

    throw FormatException();
  }

  num get h => _h;

  num get s => _s;

  num get l => _l;

  @override
  double get a => _a;

  double get opacity => a / 255;

  set h(num v) {
    if (v < hMin || v > hMax) throw ArgumentError.value(v);
    _h = v.toDouble();
  }

  set s(num v) {
    if (v < sMin || v > sMax) throw ArgumentError.value(v);
    _s = v.toDouble();
  }

  set l(num v) {
    if (lMin < 0 || v > lMax) throw ArgumentError.value(v);
    _l = v.toDouble();
  }

  @override
  set a(num v) {
    if (v < 0 || v > 1.0) throw ArgumentError.value(v);
    _a = v.toDouble();
  }

  @override
  void assignRgb(Rgb rgb) {
    assignHsl(rgb.toHsl);
  }

  @override
  void assignHsl(Hsl hsl) {
    a = hsl.a;
    h = hsl.h;
    s = hsl.s;
    l = hsl.l;
  }

  @override
  bool get isDark => brightness < 128.0;

  @override
  bool get isLight => !isDark;

  @override
  double get brightness => toRgb.brightness;

  @override
  void brighten({num percent = 10}) {
    assignRgb(toRgb..brighten(percent: percent));
  }

  @override
  void lighten({num percent = 10}) {
    l = (l + percent).clamp(sMin, sMax);
  }

  @override
  void darken({num percent = 10}) {
    l = (l - percent).clamp(sMin, sMax);
  }

  @override
  void desaturate({num percent = 10}) {
    s = (s - percent).clamp(sMin, sMax);
  }

  @override
  void saturate({num percent = 10}) {
    s = (s + percent).clamp(sMin, sMax);
  }

  @override
  void greyscale() {
    s = 0;
  }

  @override
  void spin(num degrees) {
    final hue = (h + degrees) % 360;
    h = hue < 0 ? 360 + hue : hue;
  }

  @override
  void complement() {
    h = (h + 180) % 360;
  }

  @override
  void mix(Color withColor, {num percent = 50}) {
    assignRgb(toRgb..mix(withColor, percent: percent));
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
  Hsl clone({num? h, num? s, num? l, num? a}) =>
      Hsl(h: h ?? this.h, s: s ?? this.s, l: l ?? this.l, a: a ?? this.a);

  @override
  Rgb get toRgb {
    List<num> rgb = [0, 0, 0];

    num hue = h / 360 % 1;
    num saturation = s / 100;
    num luminance = l / 100;

    if (hue < 1 / 6) {
      rgb[0] = 1;
      rgb[1] = hue * 6;
    } else if (hue < 2 / 6) {
      rgb[0] = 2 - hue * 6;
      rgb[1] = 1;
    } else if (hue < 3 / 6) {
      rgb[1] = 1;
      rgb[2] = hue * 6 - 2;
    } else if (hue < 4 / 6) {
      rgb[1] = 4 - hue * 6;
      rgb[2] = 1;
    } else if (hue < 5 / 6) {
      rgb[0] = hue * 6 - 4;
      rgb[2] = 1;
    } else {
      rgb[0] = 1;
      rgb[2] = 6 - hue * 6;
    }

    rgb = rgb.map((val) => val + (1 - saturation) * (0.5 - val)).toList();

    if (luminance < 0.5) {
      rgb = rgb.map((val) => luminance * 2 * val).toList();
    } else {
      rgb = rgb.map((val) => luminance * 2 * (1 - val) + 2 * val - 1).toList();
    }

    rgb = rgb.map((val) => (val * 255).round()).toList();

    return Rgb(r: rgb[0] as int, g: rgb[1] as int, b: rgb[2] as int, a: a);
  }

  @override
  Hsl get toHsl => clone();

  @override
  Hsv get toHsv => toRgb.toHsv;

  @override
  String get css {
    return 'hsl(${shortenDouble(h as double)}, ${shortenDouble(s as double)}%, ${shortenDouble(l as double)}%, ${shortenDouble(a)})';
  }

  @override
  String hex({bool shorten = true, bool withAlpha = true}) =>
      toRgb.hex(shorten: shorten, withAlpha: withAlpha);

  @override
  String toString() => css;

  static const double hMin = 0;
  static const double sMin = 0;
  static const double lMin = 0;
  static const double hMax = 360;
  static const double sMax = 100;
  static const double lMax = 100;

  static final hslRegExp = RegExp(
      r'^hsl\(\s*(\d+(\.\d*)?|\.\d+)\s*,\s*(\d+(\.\d*)?|\.\d+)%\s*,\s*(\d+(\.\d*)?|\.\d+)%\s*\)$');
  static final hslaRegExp = RegExp(
      r'^hsl\(\s*(\d+(\.\d*)?|\.\d+)\s*,\s*(\d+(\.\d*)?|\.\d+)%\s*,\s*(\d+(\.\d*)?|\.\d+)%\s*,\s*(\d+(\.\d*)?|\.\d+)\s*\)$');
}
