import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:ng_color_picker/ng_color_picker.dart';

@Component(
  selector: 'ng-color-picker-example',
  template: r'''
    <div class="css">Chosen color: {{css}}</div>
    <div class="input">
      <color-picker [(css)]="css"></color-picker>
      <div>
        <material-button
            raised
            popupSource
            #source="popupSource"
            (trigger)="showPopup = !showPopup">
          {{showPopup ? 'Close' : 'Open'}} Popup
        </material-button>
        <material-popup constrainToViewport enforceSpaceConstraints 
        [source]="source" [(visible)]="showPopup"
        (opened)="popupPicker.initiate()" [preferredPositions]="popupPos">
          <color-picker *ngIf="showPopup" 
          [(css)]="css" [bordered]="false"
          manualInitiate #popupPicker></color-picker>
        </material-popup>
      </div>
    </div>
    <hr />
    <div class="desc">
      Simple color picker for AngularDart. 
      <a href="https://github.com/jodinathan/ng_color_picker">GitHub</a>
      <a href="https://pub.dev/packages/ng_color_picker">Pub</a>
    </div>
  ''',
  directives: [
    coreDirectives,
    ColorPickerComponent,
    MaterialButtonComponent,
    MaterialPopupComponent,
    PopupSourceDirective,
  ],
  providers: [popupBindings],
  changeDetection: ChangeDetectionStrategy.OnPush,
  styleUrls: ['app_component.css'],
)
class AppComponent {
  String css = 'rgba(85, 73, 172, 1)';
  bool showPopup = false;

  final popupPos = [RelativePosition.AdjacentRight,
    RelativePosition.OffsetBottomRight];

  @ViewChild('popupPicker')
  ColorPickerComponent popupPicker;
}
