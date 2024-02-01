// ignore_for_file: constant_identifier_names
import 'dart:async';
import 'dart:html';
import 'dart:math' as math;
import 'package:ngdart/angular.dart';
import 'package:ngforms/ngforms.dart';
import 'deps/color/lib_colors.dart';
import 'deps/dispose/generic.dart';
//import 'deps/dispose/interval.dart';
import 'deps/deferred_content_aware.dart';

const RGB_MAX = 255.0;
const HUE_MAX = 360.0;
const SV_MAX = 100.0;
const pointerHalfSize = 10;
const alphaGutter = 8, alphaHalfGutter = 4;

extension PickerHsv on Hsv {
  String toCss() => toRgb.toCss();
}

extension PickerRgb on Rgb {
  String toCss() =>
      'rgba($r, $g, $b, ${a == 0 || a == 1 ? '$a' : a.toStringAsFixed(2)})';
}

/// Simple color picker for AngularDart.
///
/// Usage: <color-picker [(css)]="css"></color-picker>
@Component(
    selector: 'color-picker',
    templateUrl: 'color_picker.html',
    styleUrls: ['color_picker.css'],
    changeDetection: ChangeDetectionStrategy.onPush,
    directives: [
      coreDirectives,
      formDirectives,
    ])
class ColorPickerComponent with Disposable implements OnInit, OnDestroy {
  final StreamController<Rgb> _rgbChange = StreamController<Rgb>();
  final StreamController<String> _cssChange = StreamController<String>();
  final Rgb defaultColor = Rgb(r: 255, g: 255, b: 255, a: 1);
  final ChangeDetectorRef _cd;

  // ignore: unused_field
  final NgZone _zone;
  // ignore: unused_field
  final DeferredContentAware? _parent;

  Hsv? _currentHsv;

  StreamSubscription<MouseEvent>? ssMousemove;
  StreamSubscription<MouseEvent>? ssMousedown;
  StreamSubscription<MouseEvent>? ssMouseup;

  ColorPickerComponent(this._cd, this._zone, @Optional() this._parent) {
    ssMousemove = document.body?.onMouseMove.listen(onMouseMove);
    ssMousedown = document.body?.onMouseDown.listen(onMousedown);
    ssMouseup = document.body?.onMouseUp.listen(onMouseup);
  }

  Rgb? _rgb;
  @Input()
  set rgb(Rgb? value) {
    _rgb = value;
    _inputError = null;
    _invalidCss = false;
  }

  Rgb? get rgb => _rgb;

  /// Makes the cursors invisible until manually call [initiate].
  @Input()
  bool manualInitiate = false;

  /// RGB object outputs.
  @Output()
  Stream<Rgb> get rgbChange => _rgbChange.stream;

  /// If the box should have a AngularComponents box-shadow style.
  @HostBinding('class.bordered')
  @Input()
  bool bordered = true;

  bool _invalidCss = false;

  String? _css;
  String? get css => _css;

  String? _inputError;
  String? get inputError => _inputError;

  String? _inputCss;
  String? get inputCss => _inputCss;

  /// CSS input: rgba() or #hex.
  @Input('css')
  set inputCss(String? value) {
    _inputCss = value;

    if (value != null && value != _css) {
      try {
        final n = Rgb.parse(value);

        rgb = n;
        _currentHsv = rgbTohsv(_rgb!.clone(a: 1));

        _refresh();
      } catch (e) {
        _invalidCss = true;
        _inputError = ' ';
      }
    }
  }

  /// The output in the form of css rgba().
  @Output()
  Stream<String> get cssChange => _cssChange.stream;

  String? _hueCss;
  String? get hueCss => _hueCss;

  late String huePos;

  String? alphaOriginPos;
  String? alphaPos;

  String? saturationLeft;

  String? saturationTop;

  late Hsv _hsv;

  @ViewChild('hue')
  DivElement? hue;

  @ViewChild('saturation')
  DivElement? saturation;

  @ViewChild('alpha')
  DivElement? alpha;
  num alphaValue = 1;
  num hueValue = 1;

  Rectangle? get saturationRect => saturation!.getBoundingClientRect();
  Rectangle? get hueRect => hue?.getBoundingClientRect();
  Rectangle? get alphaRect => alpha?.getBoundingClientRect();

  Hsv rgbTohsv(Rgb rgb) {
    // It converts [0,255] format, to [0,1]
    final r = (rgb.r == RGB_MAX) ? 1 : (rgb.r % RGB_MAX / (RGB_MAX));
    final g = (rgb.g == RGB_MAX) ? 1 : (rgb.g % RGB_MAX / (RGB_MAX));
    final b = (rgb.b == RGB_MAX) ? 1 : (rgb.b % RGB_MAX / (RGB_MAX));
    final max = math.max(math.max(r, g), b);
    final min = math.min(math.min(r, g), b);
    final d = max - min;
    final v = max;
    final s = max == 0 ? 0 : d / max;
    late num h;

    if (max == min) {
      h = 0; // achromatic
    } else {
      if (max == r) {
        h = (g - b) / d + (g < b ? 6 : 0);
      } else if (max == g) {
        h = (b - r) / d + 2;
      } else if (max == b) {
        h = (r - g) / d + 4;
      }

      h /= 6;
    }

    return Hsv(h: h, s: (s * SV_MAX).round(), v: (v * SV_MAX).round());
  }

  void updateSaturation(num posX, num posY) {
    if (posX < 1) {
      posX = 0;
    }
    if (posX > saturationRect!.width) {
      posX = saturationRect!.width;
    }
    if (posY < 1) {
      posY = 0;
    }
    if (posY > saturationRect!.height) {
      posY = saturationRect!.height;
    }

    final sraw = posX / saturationRect!.width;
    final vraw = posY / saturationRect!.height;

    saturationLeft = '${posX - pointerHalfSize}px';
    saturationTop = '${posY - pointerHalfSize}px';

    //final h = _hsv.h;
    final num s = math.max(sraw, 0) * SV_MAX;
    final num v = (1 - math.max(vraw, 0)) * SV_MAX;

    //_hsv = Hsv(h: h, s: s, v: v, a: alphaValue);
    _hsv.s = s;
    _hsv.v = v;

    updateInputVal();
  }

  void _calcSaturationPos() {
    lastSaturationPosX = ((_hsv.s / SV_MAX) * saturationRect!.width);
    lastSaturationPosY = ((1 - (_hsv.v / SV_MAX)) * saturationRect!.height);

    saturationLeft = '${lastSaturationPosX - pointerHalfSize}px';
    saturationTop = '${lastSaturationPosY - pointerHalfSize}px';
  }

  void saturationClick(MouseEvent event) {
    final posX = event.page.x - saturationRect!.left;
    final posY = event.page.y - saturationRect!.top;
    updateSaturation(posX, posY);
    //_add((_hsv!.clone(a: rgb!.a)).toRgb);
  }

  void _add(Rgb newRgb) {
    rgb = newRgb;
    _rgbChange.add(newRgb);
    _cssChange.add(newRgb.toCss());
  }

  @HostListener('mouseout', [r'$event'])
  void sliderOut(MouseEvent event) {
    //_refresh();
  }

  @HostListener('mousemove', [r'$event'])
  void checkOut(MouseEvent event) {
    // if (hueRect != null && ![saturation, hue, alpha].contains(event.target)) {
    //   _refresh();
    // }
  }

  bool isHueMove = false;
  bool isAlphaMove = false;
  bool isSaturationMove = false;
  num lastSaturationPosX = 0;
  num lastSaturationPosY = 0;

  /// global mouse move event handler
  void onMouseMove(MouseEvent event) {
    if (isHueMove) {
      final posX = event.page.x - hueRect!.left;
      updateHue(posX);
      //updateSaturation(lastSaturationPosX, lastSaturationPosY);
    }
    if (isAlphaMove) {
      final posX = event.page.x - (alphaRect!.left + alphaHalfGutter);
      updateAlpha(posX);
    }
    if (isSaturationMove) {
      lastSaturationPosX = event.page.x - saturationRect!.left;
      lastSaturationPosY = event.page.y - saturationRect!.top;
      updateSaturation(lastSaturationPosX, lastSaturationPosY);
    }
  }

  void onMousedown(MouseEvent event) {
    isHueMove = event.target == hue;
    isAlphaMove = event.target == alpha;
    isSaturationMove = event.target == saturation;
  }

  void onMouseup(MouseEvent event) {
    isHueMove = false;
    isAlphaMove = false;
    isSaturationMove = false;
  }

  void hueClick(MouseEvent event) {
    final pos = event.page.x - hueRect!.left;
    updateHue(pos);
  }

  void updateHue(num posX) {
    if (posX < 1) {
      posX = 0;
    }
    if (posX > hueRect!.width) {
      posX = hueRect!.width;
    }
    final v = posX / hueRect!.width;
    huePos = '${posX - pointerHalfSize}px';

    hueValue = math.max(v, -0);
    _hsv.h = hueValue;

    _hueCss = Hsv(h: hueValue, s: 100, v: 100).toCss();
    updateInputVal();
  }

  void alphaClick(MouseEvent event) {
    alphaOriginPos = alphaPos;
    final pos = event.page.x - (alphaRect!.left + alphaHalfGutter);
    updateAlpha(pos);
  }

  void updateAlpha(num posX) {
    if (posX < 1) {
      posX = 0;
    }
    if (posX > alphaRect!.width) {
      posX = alphaRect!.width;
    }

    var a = posX / (alphaRect!.width - alphaGutter);
    final mod = math.pow(10.0, 2);

    a = (a * mod).round().toDouble() / mod;
    alphaPos = '${posX - pointerHalfSize}px';

    alphaValue = 1 - math.min(math.max(a, 0), 1);
    _hsv.a = alphaValue;
    updateInputVal();
  }

  void updateInputVal() {
    _inputCss = _css = _hsv.toCss();
     _cd.markForCheck();
     _add(_hsv.toRgb);
  }

  void refresh() {
    _refresh();
    _cd.markForCheck();
  }

  void _refresh() {
    final rgb = _rgb!.clone(a: 1);
    final width = hueRect!.width;
    final alphaWidth = alphaRect!.width - alphaGutter;

    _hsv = rgbTohsv(rgb);

    _calcSaturationPos();
    huePos = '${(_hsv.h * width) - pointerHalfSize}px';
    alphaPos = alphaOriginPos ??
        '${(((1 - _rgb!.a) * alphaWidth) - pointerHalfSize)}px';
    _css = _rgb!.toCss();

    if (!_invalidCss) {
      _inputCss = _css;
    }

    _hueCss = ((_currentHsv ?? _hsv).clone()
          ..s = 100
          ..v = 100)
        .toCss();
  }

  @override
  void ngOnInit() {
    rgb ??= defaultColor;
    _currentHsv = rgbTohsv(_rgb!.clone(a: 1));
    _refresh();
  }

  @override
  void ngOnDestroy() {
    ssMousemove?.cancel();
    ssMousedown?.cancel();
    ssMouseup?.cancel();
  }
}
