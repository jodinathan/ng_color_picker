import 'package:ngdart/angular.dart';
import 'package:ng_color_picker/ng_color_picker.dart';

@Component(
  selector: 'my-app',
  templateUrl: 'app_component.html',
  directives: [
    coreDirectives,
    ColorPickerComponent,
  ],
  styleUrls: ['app_component.css'],
)
class AppComponent {
  String css = 'rgba(85, 73, 172, 1)';
}
