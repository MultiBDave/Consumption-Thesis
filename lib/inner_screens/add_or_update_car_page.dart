import 'package:consumption/components/components.dart';
import 'package:consumption/helper/csv_handler.dart';
import 'package:consumption/inner_screens/fuel_management_page.dart';
import 'package:consumption/models/car_entry.dart';
import 'package:flutter/material.dart';
import 'package:consumption/main.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';

import '../helper/custom_app_bar.dart';
import '../helper/firebase.dart';
import '../helper/flutter_flow/flutter_flow_theme.dart';
import '../helper/flutter_flow/flutter_flow_widgets.dart';
import 'my_entries.dart';
import 'list_cars.dart';

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
  bool firstTime = true;
  late TextEditingController yearController;
  late TextEditingController colorController;
  late TextEditingController ownerController;
  late TextEditingController locationController;
  late TextEditingController typeController;
  late TextEditingController kmController;

  String currentModelTextFormFieldValue = '';
  String currentYearTextFormFieldValue = '';
  String currentColorTextFormFieldValue = '';
  String currentLocationTextFormFieldValue = '';
  String currentTypeTextFormFieldValue = '';
  String currentKmTextFormFieldValue = '';

  String carConsumptionValue = '';

  bool passwordFieldVisibility = false;

  String? selectedMake;
  List<String> availableModels = [];
  String? selectedModel;

  @override
  void initState() {
    loadCsvData().then((_) {
      setState(() {
        if (widget.operation == Operation.modify) {
          loadConsumptionFromCar(widget.car);
          selectedMake = widget.car.make;
          availableModels = carData[selectedMake] ?? [];
          selectedModel = widget.car.model;
        } else {
          selectedMake = carData.keys.first;
          availableModels = carData[selectedMake] ?? [];
          selectedModel = availableModels.first;
          widget.car.make = selectedMake!;
          widget.car.model = selectedModel!;
        }
      });
    });

    super.initState();
    yearController = TextEditingController();
    colorController = TextEditingController();
    locationController = TextEditingController();
    typeController = TextEditingController();
    kmController = TextEditingController();

    if (widget.operation == Operation.modify) {
      setState(() {
        yearController.text = widget.car.year.toString();
        colorController.text = widget.car.color;
        locationController.text = widget.car.location;
        typeController.text = widget.car.type;
        kmController.text = widget.car.drivenKm.toString();
        carConsumptionValue = widget.car.consumption.toStringAsFixed(2);
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
                        DropdownButtonFormField<String>(
                          value: selectedMake,
                          onChanged: (String? newMake) {
                            setState(() {
                              selectedMake = newMake;
                              widget.car.make = newMake!;
                              availableModels = carData[selectedMake] ?? [];
                              if (widget.operation == Operation.modify &&
                                  firstTime) {
                                selectedModel = widget.car.model;
                                firstTime = false;
                              } else {
                                selectedModel = null;
                              }
                            });
                          },
                          items: carData.keys
                              .map<DropdownMenuItem<String>>((String make) {
                            return DropdownMenuItem<String>(
                              value: make,
                              child: Text(make),
                            );
                          }).toList(),
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
                        ),
                        DropdownButtonFormField<String>(
                          value: availableModels.contains(selectedModel)
                              ? selectedModel
                              : null, // Ensure the value exists in the list
                          onChanged: (String? newModel) {
                            setState(() {
                              selectedModel = newModel;
                              widget.car.model = newModel!;
                            });
                          },
                          items: availableModels
                              .map<DropdownMenuItem<String>>((String model) {
                            return DropdownMenuItem<String>(
                              value: model,
                              child: Text(model),
                            );
                          }).toList(),
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
                                                widget.car.year = int.parse(
                                                    yearController.text);
                                                if (widget.operation ==
                                                    Operation.modify) {
                                                  modifyCarEntryInDb(
                                                      widget.car);
                                                }
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
                        //label which displays the current fuel and consumption
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
                          child: Text(
                            'Current fuel summary: ${widget.car.fuelSum} liters, consumption: ${carConsumptionValue} liters/100km',
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
                      child: FFButtonWidget(
                        onPressed: () {
                          setState(() {
                            if (widget.operation == Operation.add) {
                              //add new car to current users
                              //    staticCars.add(widget.car);
                              widget.car.ownerUsername =
                                  auth.currentUser!.email!;
                              addCarEntryToDb(widget.car);
                            } else if (widget.operation == Operation.modify) {
                              //    staticCars.remove(widget.car);
                              removeCarEntryFromDb(widget.car);
                            }
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => MyEntries()));
                          });
                        },
                        text: widget.operation == Operation.modify
                            ? 'DELETE'
                            : 'ADD',
                        icon: const Icon(
                          Icons.add,
                          size: 15,
                        ),
                        options: FFButtonOptions(
                          width: 600,
                          height: 48,
                          padding:
                              const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                          iconPadding:
                              const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                          color: widget.operation == Operation.modify
                              ? const Color(0xFFEFEFEF)
                              : FlutterFlowTheme.of(context).primary,
                          textStyle:
                              FlutterFlowTheme.of(context).titleSmall.override(
                                    fontFamily: 'Readex Pro',
                                    color: widget.operation == Operation.modify
                                        ? const Color(0xFFFF0800)
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
                    ),
                  ),
                  widget.operation == Operation.modify
                      ? Align(
                          alignment: const AlignmentDirectional(0.00, 0.00),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0, 34, 0, 12),
                            child: FFButtonWidget(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FuelManagementPage(car: widget.car),
                                  ),
                                );
                              },
                              text: 'Manage Fuel Entries',
                              options: FFButtonOptions(
                                width: 600,
                                height: 48,
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 0, 0, 0),
                                iconPadding:
                                    const EdgeInsetsDirectional.fromSTEB(
                                        0, 0, 0, 0),
                                color: widget.operation == Operation.modify
                                    ? const Color(0xFFEFEFEF)
                                    : FlutterFlowTheme.of(context).primary,
                                textStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      fontFamily: 'Readex Pro',
                                      color: Colors.white,
                                    ),
                                elevation: 4,
                                borderSide: const BorderSide(
                                  color: Colors.transparent,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(60),
                              ),
                            ),
                          ),
                        )
                      : Container(),
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
        if (widget.operation == Operation.modify) {
          modifyCarEntryInDb(widget.car);
        }
      });
    } else {
      setState(() {
        setControllerText();
      });
    }
  }
}
