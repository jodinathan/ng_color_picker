import 'dart:async';
import 'dart:html';
import 'dart:math' as math;

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:dispose/dispose.dart';
import 'package:lib_colors/lib_colors.dart';

const RGB_MAX = 255.0;
const HUE_MAX = 360.0;
const SV_MAX = 100.0;
const pointerHalfSize = 10;
const alphaGutter = 8, alphaHalfGutter = 4;

extension PickerHsv on Hsv {
  String toCss() => toRgb!.toCss();
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
    styleUrls: ['color_picker.scss.css'],
    changeDetection: ChangeDetectionStrategy.OnPush,
    directives: [
      coreDirectives,
      materialInputDirectives,
      MaterialIconComponent,
      MaterialRippleComponent,
      MaterialInputComponent
    ])
class ColorPickerComponent with Disposable implements OnInit {
  final StreamController<Rgb> _rgbChange = StreamController<Rgb>();
  final StreamController<String> _cssChange = StreamController<String>();
  final Rgb defaultColor = Rgb(r: 255, g: 255, b: 255, a: 1);
  final ChangeDetectorRef _cd;
  final NgZone _zone;
  final DeferredContentAware? _parent;
  Hsv? _currentHsv;

  bool _initiated = false;
  @HostBinding('class.initiated')
  bool get initiated => _initiated;

  bool _rectOk = false;
  @HostBinding('class.rectOk')
  bool get rectOk => !_observeResize || _rectOk;

  ColorPickerComponent(this._cd, this._zone, @Optional() this._parent) {
    final par = _parent;

    if (par != null) {
      _observeResize = true;

      each(par.contentVisible, (bool visible) {
        _zone.runAfterChangesObserved(() {
          _rectOk = visible;

          if (visible) {
            _refresh();
          }

          _cd.markForCheck();
        });
      });
    }
  }

  bool _observeResize = false;

  Rgb? _rgb;
  @Input()
  set rgb(Rgb? value) {
    _rgb = value;
    _inputError = null;
    _invalidCss = false;
  }

  Rgb? get rgb => _rgb;

  late StreamedIntervalTimer _saturationBeat;

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
        _currentHsv = RGBtoHSV(_rgb!.clone(a: 1));

        if (_initiated) {
          _refresh();
        }
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

  String? _huePos;
  String? get huePos => _huePos;

  String? _alphaPos, _alphaOriginPos;
  String? get alphaPos => _alphaPos;

  String? _saturationLeft;
  String? get saturationLeft => _saturationLeft;

  String? _saturationTop;
  String? get saturationTop => _saturationTop;

  Hsv? _hsv;

  DivElement? _hue;
  @ViewChild('hue')
  set hue(DivElement? element) => _hue = element;
  DivElement get hue => _hue!;

  DivElement? _saturation;
  @ViewChild('saturation')
  set saturation(DivElement? element) => _saturation = element;
  DivElement get saturation => _saturation!;

  DivElement? _alpha;
  @ViewChild('alpha')
  set alpha(DivElement? element) => _alpha = element;
  DivElement get alpha => _alpha!;

  MaterialRippleComponent? _saturationRipple;
  @ViewChild('saturationRipple')
  set saturationRipple(MaterialRippleComponent? element) =>
      _saturationRipple = element;
  MaterialRippleComponent get saturationRipple => _saturationRipple!;

  MaterialRippleComponent? _selectedRipple;
  @ViewChild('selectedRipple')
  set selectedRipple(MaterialRippleComponent? element) =>
      _selectedRipple = element;
  MaterialRippleComponent get selectedRipple => _selectedRipple!;

  Rectangle? _hueRect, _saturationRect, _alphaRect;

  Hsv RGBtoHSV(Rgb rgb) {
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

  void saturationMove(MouseEvent? event) {
    if (event == null) {
      return;
    }

    _saturationRect ??= saturation.getBoundingClientRect();

    final posX = event.page.x - _saturationRect!.left;
    final sraw = posX / _saturationRect!.width;
    final posY = event.page.y - _saturationRect!.top;
    final vraw = posY / _saturationRect!.height;

    _saturationLeft = '${posX - pointerHalfSize}px';
    _saturationTop = '${posY - pointerHalfSize}px';

    final h = (_hsv ?? RGBtoHSV(_rgb!)).h;
    final num s = math.max(sraw, 0) * SV_MAX;
    final num v = (1 - math.max(vraw, 0)) * SV_MAX;

    _hsv = Hsv(
      h: h,
      s: s,
      v: v,
    );

    _inputCss = _css = _hsv!.clone(a: rgb!.a).toCss();
    _cd.markForCheck();
  }

  void hueClick(MouseEvent event) {
    click(event);
    _currentHsv = _hsv!.clone(a: 1);
  }

  void _add(Rgb newRgb) {
    rgb = newRgb;
    _rgbChange.add(newRgb);
    _cssChange.add(newRgb.toCss());
  }

  void click(MouseEvent event, {bool ripple = true}) {
    _add((_hsv!.clone(a: rgb!.a)).toRgb!);

    if (ripple) {
      saturationRipple.createRipple(event.client.x as int, event.client.y as int);
    }

    selectedRipple.createRipple(event.client.x as int, event.client.y as int);
  }

  @HostListener('mouseout', [r'$event'])
  void sliderOut(MouseEvent event) {
    _refresh();
  }

  @HostListener('mousemove', [r'$event'])
  void checkOut(MouseEvent event) {
    if (_hueRect != null && ![saturation, hue, alpha].contains(event.target)) {
      _refresh();
    }
  }

  void hueMove(MouseEvent event) {
    _hueRect ??= hue.getBoundingClientRect();
    final pos = event.page.x - _hueRect!.left;
    final v = pos / _hueRect!.width;

    _huePos = '${pos - pointerHalfSize}px';
    _hsv = Hsv(h: math.max(v, -0), s: 100, v: 100);
    _calcSaturationPos();

    _hueCss = _hsv!.toCss();
    _inputCss = _css = _hsv!.clone(a: rgb!.a).toCss();
  }

  void alphaClick(MouseEvent event) {
    _alphaOriginPos = alphaPos;
    _add(alphaMove(event));
  }

  Rgb alphaMove(MouseEvent event) {
    _alphaRect ??= alpha.getBoundingClientRect();
    final pos = event.page.x - (_alphaRect!.left + alphaHalfGutter);
    var a = pos / (_alphaRect!.width - alphaGutter);
    final mod = math.pow(10.0, 2);

    a = (a * mod).round().toDouble() / mod;
    _alphaPos = '${pos - pointerHalfSize}px';

    final h2 = _rgb!.clone(a: 1 - math.min(math.max(a, 0), 1));

    _inputCss = _css = h2.toCss();

    return h2;
  }

  void _calcSaturationPos() {
    _saturationRect ??= saturation.getBoundingClientRect();

    _saturationLeft =
        '${((_hsv!.s / SV_MAX) * _saturationRect!.width) - pointerHalfSize}px';
    _saturationTop =
        '${((1 - (_hsv!.v / SV_MAX)) * _saturationRect!.height) - pointerHalfSize}px';
  }

  void refresh() {
    _refresh();
    _cd.markForCheck();
  }

  void _refresh() {
    final rgb = _rgb!.clone(a: 1);
    final width = hue.getBoundingClientRect().width;
    final alphaWidth =
        alpha.getBoundingClientRect().width - alphaGutter;

    _clearBeats();

    _hsv = RGBtoHSV(rgb);

    _calcSaturationPos();
    _huePos = '${(_hsv!.h * width) - pointerHalfSize}px';
    _alphaPos = _alphaOriginPos ??
        '${(((1 - _rgb!.a) * alphaWidth) - pointerHalfSize)}px';
    _css = _rgb!.toCss();

    if (!_invalidCss) {
      _inputCss = _css;
    }

    _hueCss = ((_currentHsv ?? _hsv)!.clone()
          ..s = 100
          ..v = 100)
        .toCss();

    _saturationRect = _alphaRect = _hueRect = null;
  }

  @override
  void ngOnInit() {
    rgb ??= defaultColor;
    _currentHsv = RGBtoHSV(_rgb!.clone(a: 1));
    _refresh();

    _saturationBeat = streamedInterval(saturation.onMouseMove,
        const Duration(milliseconds: 1), saturationMove);

    _initiated = !manualInitiate;
  }

  void _clearBeats() {
    if (_initiated) {
      _saturationBeat.clear();
    }
  }

  void initiate() {
    if (!_initiated) {
      _initiated = true;
      _currentHsv = RGBtoHSV(_rgb!.clone(a: 1));
      refresh();
    }
  }
}
