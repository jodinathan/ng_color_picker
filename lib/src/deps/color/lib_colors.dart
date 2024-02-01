import 'hsl.dart';
import 'rgb.dart';
import 'hsv.dart';
import 'utils/hex.dart';
import 'utils/names.dart';

export 'hsl.dart';
export 'rgb.dart';
export 'hsv.dart';
export 'utils/names.dart';

abstract class Color {
  static Color parse(String css) {
    if (css.startsWith('#')) {
      return HexColorCodec.decode(css);
    } else if (css.startsWith('rgb')) {
      return Rgb.parse(css);
    } else if (css.startsWith('hsl')) {
      return Hsl.parse(css);
    }

    {
      final ret = NamedColors.decode(css);
      if (ret != null) return ret;
    }

    throw FormatException('Unknown CSS color format!');
  }

  /// Returns CSS representation of the color
  String get css;

  /// Returns HEX representation of the color
  String hex({bool shorten = true, bool withAlpha = true});

  Color clone();

  void assignRgb(Rgb rgb);

  void assignHsl(Hsl hsl);

  bool get isDark;

  bool get isLight;

  double get brightness;

  void brighten({num percent = 10});

  void lighten({num percent = 10});

  void darken({num percent = 10});

  void mix(Color withColor, {num percent = 50});

  void tint({num percent = 10});

  void shade({num percent = 10});

  void desaturate({num percent = 10});

  void saturate({num percent = 10});

  void greyscale();

  void spin(num degree);

  void complement();

  double a =0;

  Rgb get toRgb;

  Hsl get toHsl;

  Hsv get toHsv;
}