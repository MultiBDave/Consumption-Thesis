import 'package:consumption/models/car_entry.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

import '../../helper/custom_app_bar.dart';
import '../../helper/firebase.dart';
import '../../helper/flutter_flow/flutter_flow_theme.dart';
import '../../helper/flutter_flow/flutter_flow_widgets.dart';
import '../my_entries.dart';
import '../../components/components.dart';
class AddCarForm extends StatefulWidget {
  final CarEntry car;
  final Operation operation;

  const AddCarForm({super.key, required this.car, required this.operation});

  @override
  // ignore: library_private_types_in_public_api
  _AddCarFormState createState() => _AddCarFormState();
}

class _AddCarFormState extends State<AddCarForm> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  late TextEditingController makeController;
  late TextEditingController modelController;
  late TextEditingController yearController;
  late TextEditingController colorController;
  late TextEditingController ownerController;
  late TextEditingController locationController;
  late TextEditingController typeController;
  late TextEditingController kmController;
  late TextEditingController initialKmController;
  late TextEditingController tankSizeController;

  String currentMakeTextFormFieldValue = '';
  String currentModelTextFormFieldValue = '';
  String currentYearTextFormFieldValue = '';
  String currentColorTextFormFieldValue = '';
  String currentLocationTextFormFieldValue = '';
  String currentTypeTextFormFieldValue = '';
  String currentKmTextFormFieldValue = '';
  String currentInitialKmTextFormFieldValue = '';
  String currentTankSizeTextFormFieldValue = '';

  bool passwordFieldVisibility = false;

  List<String> colorList = ['Red', 'Blue', 'Green', 'Yellow', 'Black', 'White'];
  List<String> carList = [
    'Wagon',
    'Sedan',
    'Hatchback',
    'SUV',
    'Coupe',
    'Convertible',
    'Van',
    'Pickup',
    'Minivan',
    'Bus',
    'Truck',
    'Motorcycle',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    makeController = TextEditingController();
    modelController = TextEditingController();
    yearController = TextEditingController();
    colorController = TextEditingController();
    locationController = TextEditingController();
    typeController = TextEditingController();
    kmController = TextEditingController();
    initialKmController = TextEditingController();
    tankSizeController = TextEditingController();

    if (widget.operation == Operation.modify) {
      setState(() {
        makeController.text = widget.car.make;
        modelController.text = widget.car.model;
        yearController.text = widget.car.year.toString();
        colorController.text = widget.car.color;
        locationController.text = widget.car.location;
        typeController.text = widget.car.type;
        kmController.text = widget.car.drivenKm.toString();
        initialKmController.text = widget.car.initialKm.toString();
        tankSizeController.text = widget.car.tankSize.toString();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: CustomAppBar(
          //todo make patient name dynamic
          title: 'Back to My entries',
          onBackPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 15, 0, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Align(
                          alignment: const AlignmentDirectional(-1.00, 0.00),
                          child: Text(
                            'Add new car',
                            style: FlutterFlowTheme.of(context)
                                .headlineMedium
                                .override(
                                  fontFamily: 'Outfit',
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        TextFormField(
                          controller: makeController,
                          autofocus: true,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: 'Make',
                            labelStyle:
                                FlutterFlowTheme.of(context).labelMedium,
                            hintStyle: FlutterFlowTheme.of(context).labelMedium,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          onChanged: (String newValue) {
                            setState(() {
                              currentMakeTextFormFieldValue = newValue;
                            });
                          },
                          onTapOutside: (newValue) {
                            saveTextValue(
                                currentMakeTextFormFieldValue, makeController,
                                (value) {
                              widget.car.make = value;
                            }, () {
                              makeController.text = widget.car.make;
                            });
                            FocusScope.of(context).unfocus();
                          },
                          onFieldSubmitted: (String newValue) {
                            saveTextValue(
                                currentMakeTextFormFieldValue, makeController,
                                (value) {
                              widget.car.make = value;
                            }, () {
                              makeController.text = widget.car.make;
                            });
                          },
                        ),
                        TextFormField(
                          controller: modelController,
                          autofocus: true,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: 'Model',
                            labelStyle:
                                FlutterFlowTheme.of(context).labelMedium,
                            hintStyle: FlutterFlowTheme.of(context).labelMedium,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          onChanged: (String newValue) {
                            setState(() {
                              currentModelTextFormFieldValue = newValue;
                            });
                          },
                          onTapOutside: (newValue) {
                            saveTextValue(
                                currentModelTextFormFieldValue, modelController,
                                (value) {
                              widget.car.model = value;
                            }, () {
                              modelController.text = widget.car.model;
                            });
                            FocusScope.of(context).unfocus();
                          },
                          onFieldSubmitted: (String newValue) {
                            saveTextValue(
                                currentModelTextFormFieldValue, modelController,
                                (value) {
                              widget.car.model = value;
                            }, () {
                              modelController.text = widget.car.model;
                            });
                          },
                        ),
                        TextFormField(
                          controller: yearController,
                          autofocus: true,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: 'Year',
                            labelStyle:
                                FlutterFlowTheme.of(context).labelMedium,
                            hintStyle: FlutterFlowTheme.of(context).labelMedium,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          onTap: () => {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Select year'),
                                    content: Container(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: 100,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          return ListTile(
                                            title: Text(
                                                (DateTime.now().year - index)
                                                    .toString()),
                                            onTap: () {
                                              setState(() {
                                                yearController.text =
                                                    (DateTime.now().year -
                                                            index)
                                                        .toString();
                                              });
                                              Navigator.of(context).pop();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                })
                          },
                          onChanged: (String newValue) {
                            setState(() {
                              currentYearTextFormFieldValue = newValue;
                            });
                          },
                          onTapOutside: (newValue) {
                            saveTextValue(
                                currentYearTextFormFieldValue, yearController,
                                (value) {
                              widget.car.year = int.parse(value);
                            }, () {
                              yearController.text = widget.car.year.toString();
                            });
                            FocusScope.of(context).unfocus();
                          },
                          onFieldSubmitted: (String newValue) {
                            saveTextValue(
                                currentYearTextFormFieldValue, yearController,
                                (value) {
                              widget.car.year = int.parse(value);
                            }, () {
                              yearController.text = widget.car.year.toString();
                            });
                          },
                        ),
                        TextFormField(
                          controller: locationController,
                          autofocus: true,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: 'Location',
                            labelStyle:
                                FlutterFlowTheme.of(context).labelMedium,
                            hintStyle: FlutterFlowTheme.of(context).labelMedium,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          onTap: () async {
                            showCountryPicker(
                              context: context,
                              onSelect: (Country country) {
                                setState(() {
                                  locationController.text = country.displayName;
                                  widget.car.location = country.displayName;
                                });
                              },
                            );
                          },
                        ),
                        DropdownButtonFormField<String>(
                          items: colorList
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          value: widget.car.color == ''
                              ? colorList.first
                              : colorList
                                  .where(
                                      (element) => element == widget.car.color)
                                  .first,
                          decoration: InputDecoration(
                            labelText: 'Color',
                            labelStyle:
                                FlutterFlowTheme.of(context).labelMedium,
                            hintStyle: FlutterFlowTheme.of(context).labelMedium,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                colorController.text = newValue;
                                widget.car.color = newValue;
                              });
                            }
                          },
                        ),
                        DropdownButtonFormField<String>(
                          items: carList
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          value: widget.car.type == ''
                              ? carList.first
                              : carList
                                  .where(
                                      (element) => element == widget.car.type)
                                  .first,
                          decoration: InputDecoration(
                            labelText: 'Type',
                            labelStyle:
                                FlutterFlowTheme.of(context).labelMedium,
                            hintStyle: FlutterFlowTheme.of(context).labelMedium,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                typeController.text = newValue;
                                widget.car.type = newValue;
                              });
                            }
                          },
                        ),
                        TextFormField(
                          controller: kmController,
                          autofocus: true,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: 'Km',
                            labelStyle:
                                FlutterFlowTheme.of(context).labelMedium,
                            hintStyle: FlutterFlowTheme.of(context).labelMedium,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          onChanged: (String newValue) {
                            setState(() {
                              currentKmTextFormFieldValue = newValue;
                            });
                          },
                          onTapOutside: (newValue) {
                            saveTextValue(
                                currentKmTextFormFieldValue, kmController,
                                (value) {
                              widget.car.drivenKm = int.parse(value);
                            }, () {
                              kmController.text =
                                  widget.car.drivenKm.toString();
                            });
                            FocusScope.of(context).unfocus();
                          },
                          onFieldSubmitted: (String newValue) {
                            saveTextValue(
                                currentKmTextFormFieldValue, kmController,
                                (value) {
                              widget.car.drivenKm = int.parse(value);
                            }, () {
                              kmController.text =
                                  widget.car.drivenKm.toString();
                            });
                          },
                        ),
                        // Initial mileage field (for used cars)
                        TextFormField(
                          controller: initialKmController,
                          autofocus: true,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: 'Initial Kilometers (for used cars)',
                            hintText: 'Enter initial mileage for used cars',
                            labelStyle:
                                FlutterFlowTheme.of(context).labelMedium,
                            hintStyle: FlutterFlowTheme.of(context).labelMedium,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          keyboardType: TextInputType.number,
                          onChanged: (String newValue) {
                            setState(() {
                              currentInitialKmTextFormFieldValue = newValue;
                            });
                          },
                          onTapOutside: (newValue) {
                            saveTextValue(
                                currentInitialKmTextFormFieldValue, initialKmController,
                                (value) {
                              widget.car.initialKm = int.tryParse(value) ?? 0;
                            }, () {
                              initialKmController.text =
                                  widget.car.initialKm.toString();
                            });
                            FocusScope.of(context).unfocus();
                          },
                          onFieldSubmitted: (String newValue) {
                            saveTextValue(
                                currentInitialKmTextFormFieldValue, initialKmController,
                                (value) {
                              widget.car.initialKm = int.tryParse(value) ?? 0;
                            }, () {
                              initialKmController.text =
                                  widget.car.initialKm.toString();
                            });
                          },
                        ),
                        // Tank size field
                        TextFormField(
                          controller: tankSizeController,
                          autofocus: true,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: 'Fuel Tank Size (liters)',
                            hintText: 'Enter fuel tank size',
                            labelStyle:
                                FlutterFlowTheme.of(context).labelMedium,
                            hintStyle: FlutterFlowTheme.of(context).labelMedium,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          keyboardType: TextInputType.number,
                          onChanged: (String newValue) {
                            setState(() {
                              currentTankSizeTextFormFieldValue = newValue;
                            });
                          },
                          onTapOutside: (newValue) {
                            saveTextValue(
                                currentTankSizeTextFormFieldValue, tankSizeController,
                                (value) {
                              widget.car.tankSize = int.tryParse(value) ?? 0;
                            }, () {
                              tankSizeController.text =
                                  widget.car.tankSize.toString();
                            });
                            FocusScope.of(context).unfocus();
                          },
                          onFieldSubmitted: (String newValue) {
                            saveTextValue(
                                currentTankSizeTextFormFieldValue, tankSizeController,
                                (value) {
                              widget.car.tankSize = int.tryParse(value) ?? 0;
                            }, () {
                              tankSizeController.text =
                                  widget.car.tankSize.toString();
                            });
                          },
                        ),
                        //label which displays the current fuel and consumption
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                          child: Text(
                            'Current fuel summary: ${widget.car.fuelSum} liters, consumption: ${widget.car.getConsumption()} liters/100km\nEstimated range with full tank: ${widget.car.estimatedRange}',
                            style: FlutterFlowTheme.of(context)
                                .bodyText1
                                .override(
                                  fontFamily: 'Readex Pro',
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: const AlignmentDirectional(0.00, 0.00),
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(0, 34, 0, 12),
                      child: Column(
                        children: [
                          FFButtonWidget(
                            onPressed: () {
                              setState(() {
                                // Always update car fields from controllers before saving
                                widget.car.make = makeController.text;
                                widget.car.model = modelController.text;
                                widget.car.year = int.tryParse(yearController.text) ?? 0;
                                widget.car.color = colorController.text;
                                widget.car.location = locationController.text;
                                widget.car.type = typeController.text;
                                widget.car.drivenKm = int.tryParse(kmController.text) ?? 0;
                                widget.car.initialKm = int.tryParse(initialKmController.text) ?? 0;
                                widget.car.tankSize = int.tryParse(tankSizeController.text) ?? 0;
                                if (widget.operation == Operation.add) {
                                  // Assign a unique id for new entries
                                  widget.car.id = DateTime.now().millisecondsSinceEpoch;
                                  widget.car.ownerUsername = auth.currentUser!.email!;
                                  addCarEntryToDb(widget.car);
                                } else if (widget.operation == Operation.modify) {
                                  modifyCarEntryInDb(widget.car);
                                }
                                Navigator.of(context).pop();
                              });
                            },
                            text: widget.operation == Operation.modify ? 'SAVE CHANGES' : 'ADD',
                            icon: widget.operation == Operation.modify
                                ? const Icon(
                                    Icons.save,
                                    size: 15,
                                    color: Colors.green,
                                  )
                                : const Icon(
                                    Icons.add,
                                    size: 15,
                                  ),
                            options: FFButtonOptions(
                              width: 600,
                              height: 48,
                              padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                              iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                              color: widget.operation == Operation.modify
                                  ? const Color(0xFFEFEFEF)
                                  : FlutterFlowTheme.of(context).primary,
                              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                    fontFamily: 'Readex Pro',
                                    color: widget.operation == Operation.modify
                                        ? const Color(0xFF00C853)
                                        : Colors.white,
                                  ),
                              elevation: 4,
                              borderSide: const BorderSide(
                                color: Colors.transparent,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(60),
                            ),
                          ),
                          if (widget.operation == Operation.modify)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: FFButtonWidget(
                                onPressed: () {
                                  // Add your delete logic here if needed
                                  // removeCarEntryFromDb(widget.car.id); // Uncomment if you have this function
                                  Navigator.of(context).pop();
                                },
                                text: 'DELETE',
                                icon: const Icon(
                                  Icons.delete,
                                  size: 15,
                                  color: Colors.red,
                                ),
                                options: FFButtonOptions(
                                  width: 600,
                                  height: 48,
                                  color: Colors.red.shade100,
                                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                        fontFamily: 'Readex Pro',
                                        color: Colors.red,
                                      ),
                                  elevation: 2,
                                  borderSide: const BorderSide(
                                    color: Colors.transparent,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(60),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void saveTextValue(String currentFieldValue, TextEditingController controller,
      Function setAttribute, Function setControllerText) {
    if (currentFieldValue.isNotEmpty) {
      setState(() {
        setAttribute(currentFieldValue);
        //if (widget.modifying) modifyRelativeInDb(widget.relative);
      });
    } else {
      setState(() {
        setControllerText();
      });
    }
  }
}
