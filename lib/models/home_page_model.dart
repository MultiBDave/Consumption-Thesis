import '../helper/flutter_flow/flutter_flow_model.dart';
import '../helper/flutter_flow/flutter_flow_util.dart';
import '../helper/flutter_flow/form_field_controller.dart';
import '../inner_screens/list_cars.dart' show ListCarsScreen;
import 'package:flutter/material.dart';

class ListCarsScreenModel extends FlutterFlowModel<ListCarsScreen> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  // State field(s) for DropDown widget.
  String? dropDownValue1;
  FormFieldController<String>? dropDownValueController1;
  // State field(s) for DropDown widget.
  String? dropDownValue2;
  FormFieldController<String>? dropDownValueController2;

  /// Initialization and disposal methods.

  void initState(BuildContext context) {}

  void dispose() {
    unfocusNode.dispose();
  }

  /// Action blocks are added here.

  /// Additional helper methods are added here.
}
