
# Live example  
Visit the [live example](https://jodinathan.github.io/ng_color_picker/) hosted by github-pages

# Usage

```dart
import 'package:angular/angular.dart';
import 'package:ng_color_picker/ng_color_picker.dart';

@Component(
  selector: 'ng-color-picker-example',
  template: r'''
    <div>Chosen color: {{css}}</div>
      <color-picker [(css)]="css"></color-picker>
    </div>
  ''',
  directives: [
    coreDirectives,
    ColorPickerComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class AppComponent {
  String css = 'rgba(85, 73, 172, 1)';
}
 
```

# Todo
 - CMYK
 - Presets

