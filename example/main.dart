import 'package:angular/angular.dart';
import 'lib/app_component.template.dart' as ng_root;
import 'main.template.dart' as ng_main;

// Visit the github to see the app_component.dart and app_component.html
void main() {
  runApp(ng_root.AppComponentNgFactory, createInjector: rootInjector);
}

@GenerateInjector([])
final InjectorFactory rootInjector = ng_main.rootInjector$Injector;
