import 'dart:convert';
import 'dart:math';

import 'package:constraint_view/custom_views/task_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/models/block.dart';
import '/models/block_command.dart';
import '/models/comb_block_drag_info.dart';
import '/models/combined_block_content.dart';
import '/models/combined_block_in_group.dart';
import '/models/combined_group.dart';
import '/models/grid.dart';
import '/models/grid_custom_background.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import '/network_config.dart';
import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:string_validator/string_validator.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:giphy_get/giphy_get.dart';

class GridUIView extends StatefulWidget {
  int rows;
  int columns;
  List<CombinedGroup> data;
  String gridJson;
  CustomGridBackground gridBackgroundData;
  _GridUIViewState state;

  GridUIView(this.gridJson, this.columns, this.rows, this.gridBackgroundData,
      this.data,
      {Key key})
      : super(key: key);

  GridUIView.empty({Key key}) : super(key: key) {
    gridJson = null;
    columns = 0;
    rows = 0;
    gridBackgroundData = null;
    data = null;
  }

  @override
  _GridUIViewState createState() {
    state = _GridUIViewState(columns, rows, data,
        gridJson: gridJson, gridCustomBackgroudData: gridBackgroundData);

    return state;
  }

  void changeCols(int cols) {
    state.changeCols(cols);
  }

  void changeRows(int rows) {
    state.changeRows(rows);
  }

  void changeGrid(List<CombinedGroup> data) {
    state.data = data;
  }

  void changeEditMode(bool val) {
    state.changeEditState(val);
  }

  void changeGridJSON(String value) {
    state.gridJson = value;
  }

  void changeCustomBackground(CustomGridBackground customGridBackground) {
    state.changeGridBackround(customGridBackground);
  }
}

class _GridUIViewState extends State<GridUIView> {
  int columns;
  int rows;
  List<CombinedGroup> data;
  CustomGridBackground gridCustomBackgroudData;
  String gridJson;
  double blockSize;
  bool editMode = false;
  GlobalKey<FormState> _createCombinedBlockKey = GlobalKey<FormState>();
  GlobalKey<FormState> _enterTextGlobalKey = GlobalKey<FormState>();
  final enterBlockTextController = TextEditingController();
  final enterBlockFontSizeController = TextEditingController();
  final enterBlockTextColorController = TextEditingController();

  final _enterURLGlobalKey = GlobalKey<FormState>();
  final enterBlockURLController = TextEditingController();

  final _enterColorGlobalKey = GlobalKey<FormState>();
  final enterBlockColorController = TextEditingController();

  final _enterTaskIDGlobalKey = GlobalKey<FormState>();
  final _enterTaskIDController = TextEditingController();
  final _enterTaskImageController = TextEditingController();

  final _imageCarouselKey = GlobalKey<FormState>();

  int selectedBlockContentType = -1;
  int selectedBlockCommandType = -1;

  final blockHeightController = TextEditingController();
  final blockWidthController = TextEditingController();
  final blockStartColumnController = TextEditingController();
  final blockStartRowController = TextEditingController();
  _GridUIViewState(this.columns, this.rows, this.data,
      {this.gridJson, this.gridCustomBackgroudData}) {
    _createCombinedBlockKey = GlobalKey<FormState>();
    _enterTextGlobalKey = GlobalKey<FormState>();
  }

  ///Combined block creation dialog
  String selectedFont;

  Future<void> createCombinedBlockialog(
      BuildContext context, bool fromDragging) async {
    String contentType = "";

    //Text content preview settings
    Alignment textPreviewAlignment = Alignment.center;
    String textPreview = "None";
    double textSizePreview = 13;
    String textColorPreview = "#000000";
    String blockColorPreview = "#ffffff";

    List<String> allFonts = GoogleFonts.asMap().keys.toList();

    int _yPositionData = 0;
    int _xPositionData = 0;

    enterBlockFontSizeController.text = "20";

    List<TextEditingController> imageCarouselInputFields = [];

    if (selectedFont == null) {
      selectedFont = allFonts[Random().nextInt(allFonts.length)];
    }

    String selectedOnTapCommand = "Load task";
    String selectedOnTapValue;
    String selectedOnHoldCommand;
    String selectedOnHoldValue;

    bool isTextScrollingEnabled = false;
    String _textAnimationSelecttion = "horizontal";

    Map<String, dynamic> textContent = {
      "font_family": "",
      "position": 5,
      "font": selectedFont,
      "font_size": enterBlockFontSizeController.text,
      "x_pos": _xPositionData,
      "y_pos": _yPositionData,
      "underline": false,
      "line_through": false,
      "bold": false,
      "italic": false,
      "scroll_animation_enabled": false,
      "scroll_animation_direction": null
    };

    Map<String, dynamic> taskContent = {"task_image": 5};

    Map<String, dynamic> imageCarouselContent = {"images": []};

    Map<String, dynamic> imageContent = {"link": ""};

    Map colorContent = {"color_val": "#ffffff"};

    //Block command
    GlobalKey<FormState> onTapValueKey = GlobalKey();
    TextEditingController onTapValueController = TextEditingController();
    BlockCommand blockCommand = BlockCommand("", "", "", "");

    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Create a combined block'),
              content: SingleChildScrollView(
                  child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 40),
                    child: Opacity(
                      opacity: fromDragging ? 0.5 : 1,
                      child: IgnorePointer(
                        ignoring: fromDragging,
                        child: Form(
                            key: _createCombinedBlockKey,
                            child: Column(children: <Widget>[
                              TextFormField(
                                controller: blockHeightController,
                                decoration: InputDecoration(
                                    labelText: 'Combined block height'),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Height required';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: blockWidthController,
                                decoration: const InputDecoration(
                                    labelText: 'Combined block width'),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Width required';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: blockStartColumnController,
                                decoration: InputDecoration(
                                    labelText: 'Grid start column'),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Column required';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: blockStartRowController,
                                decoration: InputDecoration(
                                    labelText: 'Grid start row'),
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Row required';
                                  }
                                  return null;
                                },
                              ),
                            ])),
                      ),
                    ),
                  ),

                  // Select content type
                  Container(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Select content type",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      //Content type options
                      Container(
                        alignment: Alignment.center,
                        child: Wrap(
                          alignment: WrapAlignment.spaceAround,
                          children: [
                            TextButton(
                              child: Text(
                                "Text",
                                style: TextStyle(
                                    color: selectedBlockContentType == 1
                                        ? Colors.green
                                        : Colors.blue),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedBlockContentType = 1;
                                });
                              },
                            ),
                            TextButton(
                              child: Text(
                                "Image/GIF",
                                style: TextStyle(
                                    color: selectedBlockContentType == 2
                                        ? Colors.green
                                        : Colors.blue),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedBlockContentType = 2;
                                });
                              },
                            ),
                            TextButton(
                              child: Text(
                                "Color",
                                style: TextStyle(
                                    color: selectedBlockContentType == 3
                                        ? Colors.green
                                        : Colors.blue),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedBlockContentType = 3;
                                });
                              },
                            ),
                            TextButton(
                              child: Text(
                                "Task",
                                style: TextStyle(
                                    color: selectedBlockContentType == 4
                                        ? Colors.green
                                        : Colors.blue),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedBlockContentType = 4;
                                });
                              },
                            ),
                            TextButton(
                              child: Text(
                                "Image carousel",
                                style: TextStyle(
                                    color: selectedBlockContentType == 5
                                        ? Colors.green
                                        : Colors.blue),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedBlockContentType = 5;
                                });
                              },
                            )
                          ],
                        ),
                      ),

                      //Text
                      Visibility(
                        visible: selectedBlockContentType == 1,
                        child: Column(
                          children: [
                            //Text preview
                            Container(
                                decoration: BoxDecoration(
                                    color: HexColor(blockColorPreview),
                                    border: Border.all(
                                        width: 1, color: Colors.grey[200])),
                                height: 100,
                                child: Align(
                                    alignment: textPreviewAlignment,
                                    child: Container(
                                      margin: EdgeInsets.only(
                                          bottom: _yPositionData >= 0
                                              ? _yPositionData.toDouble().abs()
                                              : 0,
                                          top: _yPositionData < 0
                                              ? (_yPositionData.toDouble())
                                                  .abs()
                                              : 0,
                                          left: _xPositionData >= 0
                                              ? _xPositionData.toDouble().abs()
                                              : 0,
                                          right: _xPositionData < 0
                                              ? (_xPositionData.toDouble())
                                                  .abs()
                                              : 0),
                                      child: Text(textPreview,
                                          style: GoogleFonts.getFont(
                                              selectedFont,
                                              fontWeight: textContent["bold"]
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              fontStyle: textContent["italic"]
                                                  ? FontStyle.italic
                                                  : FontStyle.normal,
                                              decoration: textContent[
                                                      "underline"]
                                                  ? TextDecoration.underline
                                                  : textContent["line_through"]
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : TextDecoration.none,
                                              color: HexColor(textColorPreview),
                                              fontSize: textSizePreview)),
                                    ))),
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Text(
                                "Text preview",
                                style: TextStyle(fontSize: 12),
                              ),
                            ),

                            //Text options
                            Container(
                              alignment: Alignment.centerLeft,
                              child: Form(
                                  key: _enterTextGlobalKey,
                                  child: Column(
                                    children: [
                                      //Block text
                                      TextFormField(
                                        onChanged: (text) {
                                          setState(() {
                                            if (text == "") {
                                              textPreview = "None";
                                            } else {
                                              textPreview = text;
                                            }
                                          });
                                        },
                                        controller: enterBlockTextController,
                                        decoration:
                                            InputDecoration(labelText: 'Text'),
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return 'Text required';
                                          }
                                          contentType = "text";
                                          textContent["value"] = value;
                                          return null;
                                        },
                                      ),

                                      //Text font
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              margin: EdgeInsets.only(
                                                  top: 30, bottom: 10),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    child: Text(
                                                      "Text font",
                                                      style: TextStyle(
                                                          fontSize: 13),
                                                    ),
                                                  ),
                                                  SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    child: DropdownButton(
                                                      value: selectedFont,
                                                      onChanged:
                                                          (String newFont) {
                                                        contentType = "text";
                                                        textContent["font"] =
                                                            newFont;
                                                        setState(() {
                                                          selectedFont =
                                                              newFont;
                                                        });
                                                      },
                                                      items: allFonts.map<
                                                              DropdownMenuItem<
                                                                  String>>(
                                                          (String value) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: value,
                                                          child: Text(
                                                            value,
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Container(
                                            child: Row(
                                              children: [
                                                IconButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        textContent["bold"] =
                                                            !textContent[
                                                                "bold"];
                                                      });
                                                    },
                                                    icon: Icon(
                                                      Icons.format_bold,
                                                      color: textContent["bold"]
                                                          ? Colors.green
                                                          : Colors.black,
                                                    )),
                                                IconButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        textContent["italic"] =
                                                            !textContent[
                                                                "italic"];
                                                      });
                                                    },
                                                    icon: Icon(
                                                      Icons.format_italic,
                                                      color:
                                                          textContent["italic"]
                                                              ? Colors.green
                                                              : Colors.black,
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      //Text decoration
                                      Row(
                                        children: [
                                          Expanded(
                                              child: Text("Text decoration",
                                                  style:
                                                      TextStyle(fontSize: 15))),
                                          Container(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        textContent[
                                                                "underline"] =
                                                            !textContent[
                                                                "underline"];
                                                        if (textContent[
                                                            "line_through"]) {
                                                          textContent[
                                                                  "line_through"] =
                                                              false;
                                                        }
                                                      });
                                                    },
                                                    icon: Icon(
                                                      Icons.format_underline,
                                                      color: textContent[
                                                              "underline"]
                                                          ? Colors.green
                                                          : Colors.black,
                                                    )),
                                                IconButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        textContent[
                                                                "line_through"] =
                                                            !textContent[
                                                                "line_through"];
                                                        if (textContent[
                                                            "underline"]) {
                                                          textContent[
                                                                  "underline"] =
                                                              false;
                                                        }
                                                      });
                                                    },
                                                    icon: Icon(
                                                      Icons.strikethrough_s,
                                                      color: textContent[
                                                              "line_through"]
                                                          ? Colors.green
                                                          : Colors.black,
                                                    )),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      //Text font size
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              onChanged: (size) {
                                                setState(() {
                                                  if (size == "") {
                                                    textSizePreview = 13;
                                                  } else {
                                                    textSizePreview =
                                                        double.tryParse(size);
                                                  }
                                                });
                                              },
                                              controller:
                                                  enterBlockFontSizeController,
                                              decoration: InputDecoration(
                                                  labelText: 'Text font size'),
                                              validator: (value) {
                                                if (value.isEmpty) {
                                                  return 'Font size required';
                                                }
                                                contentType = "text";
                                                textContent["font_size"] =
                                                    double.parse(value);
                                                return null;
                                              },
                                            ),
                                          ),
                                          IconButton(
                                              iconSize: 13,
                                              onPressed: (() {
                                                if (isNumeric(
                                                    enterBlockFontSizeController
                                                        .text)) {
                                                  setState(() {
                                                    textSizePreview = double.parse(
                                                            enterBlockFontSizeController
                                                                .text) +
                                                        1;
                                                    enterBlockFontSizeController
                                                        .text = (textSizePreview
                                                            .toInt())
                                                        .toString();
                                                  });
                                                }
                                              }),
                                              icon: Icon(Icons.add)),
                                          IconButton(
                                              iconSize: 13,
                                              onPressed: (() {
                                                if (isNumeric(
                                                    enterBlockFontSizeController
                                                        .text)) {
                                                  setState(() {
                                                    textSizePreview = double.parse(
                                                            enterBlockFontSizeController
                                                                .text) -
                                                        1;
                                                    enterBlockFontSizeController
                                                        .text = (textSizePreview
                                                            .toInt())
                                                        .toString();
                                                  });
                                                }
                                              }),
                                              icon: Icon(Icons.remove)),
                                        ],
                                      ),

                                      //Text Y position
                                      Container(
                                        margin: EdgeInsets.only(top: 20),
                                        child: Row(
                                          children: [
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _yPositionData += 1;
                                                  });
                                                  contentType = "text";
                                                  textContent["y_pos"] =
                                                      _yPositionData;
                                                },
                                                iconSize: 18,
                                                icon: Icon(Icons.expand_less)),
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _yPositionData -= 1;
                                                  });
                                                  contentType = "text";
                                                  textContent["y_pos"] =
                                                      _yPositionData;
                                                },
                                                iconSize: 18,
                                                icon: Icon(Icons.expand_more)),
                                            Container(
                                                margin:
                                                    EdgeInsets.only(left: 20),
                                                child: Text(
                                                    _yPositionData.toString())),
                                            Expanded(
                                              child: Container(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  "Y position",
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      //Text X position
                                      Container(
                                        margin: EdgeInsets.only(top: 20),
                                        child: Row(
                                          children: [
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _xPositionData -= 1;
                                                  });
                                                  contentType = "text";
                                                  textContent["x_pos"] =
                                                      _xPositionData;
                                                },
                                                iconSize: 18,
                                                icon: Icon(
                                                    Icons.keyboard_arrow_left)),
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _xPositionData += 1;
                                                  });
                                                  contentType = "text";
                                                  textContent["x_pos"] =
                                                      _xPositionData;
                                                },
                                                iconSize: 18,
                                                icon: Icon(Icons
                                                    .keyboard_arrow_right)),
                                            Container(
                                                margin:
                                                    EdgeInsets.only(left: 20),
                                                child: Text(
                                                    _xPositionData.toString())),
                                            Expanded(
                                              child: Container(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  "X position",
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      //Text color
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              onChanged: (color) {
                                                setState(() {
                                                  if (color == "") {
                                                    textColorPreview =
                                                        "#000000";
                                                  } else {
                                                    if (isHexColor(color)) {
                                                      textColorPreview = color;
                                                    } else {
                                                      textColorPreview =
                                                          "#000000";
                                                    }
                                                  }
                                                });
                                              },
                                              controller:
                                                  enterBlockTextColorController,
                                              decoration: InputDecoration(
                                                  labelText: 'Text color'),
                                              validator: (value) {
                                                if (value.isEmpty) {
                                                  return 'Text color required';
                                                }
                                                contentType = "text";
                                                textContent["color"] = value;
                                                return null;
                                              },
                                            ),
                                          ),
                                          TextButton(
                                              onPressed: () {
                                                showColorPickerDialog()
                                                    .then((value) {
                                                  setState(() {
                                                    enterBlockTextColorController
                                                        .text = "#${value.hex}";
                                                  });
                                                  contentType = "text";
                                                  textContent["color"] =
                                                      "#${value.hex}";
                                                });
                                              },
                                              child: Text("Pick color"))
                                        ],
                                      ),

                                      //Combined block color
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              onChanged: (color) {
                                                if (isHexColor(color)) {
                                                  setState(() {
                                                    blockColorPreview = color;
                                                  });
                                                }
                                              },
                                              controller:
                                                  enterBlockColorController,
                                              decoration: InputDecoration(
                                                  labelText: 'Block color'),
                                              validator: (value) {
                                                contentType = "text";
                                                textContent["block_color"] =
                                                    value.isEmpty ? "" : value;
                                                return null;
                                              },
                                            ),
                                          ),
                                          TextButton(
                                              onPressed: () {
                                                showColorPickerDialog()
                                                    .then((value) {
                                                  setState(() {
                                                    enterBlockColorController
                                                        .text = "#${value.hex}";
                                                  });
                                                  contentType = "text";
                                                  textContent["block_color"] =
                                                      "#${value.hex}";
                                                });
                                              },
                                              child: Text("Pick color"))
                                        ],
                                      ),

                                      //Block image link
                                      TextFormField(
                                        controller: enterBlockURLController,
                                        decoration: InputDecoration(
                                            labelText:
                                                'Combined block image link'),
                                        validator: (value) {
                                          contentType = "text";
                                          textContent["block_image"] =
                                              value.isEmpty ? "" : value;
                                          return null;
                                        },
                                      ),

                                      //Text position
                                      Container(
                                          margin: EdgeInsets.only(top: 40),
                                          alignment: Alignment.centerLeft,
                                          child: Text("Text position",
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.north_west),
                                                onPressed: () {
                                                  textContent["position"] = 1;
                                                  setState(() {
                                                    textPreviewAlignment =
                                                        Alignment.topLeft;
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.north),
                                                onPressed: () {
                                                  textContent["position"] = 2;
                                                  setState(() {
                                                    textPreviewAlignment =
                                                        Alignment.topCenter;
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.north_east),
                                                onPressed: () {
                                                  textContent["position"] = 3;
                                                  setState(() {
                                                    textPreviewAlignment =
                                                        Alignment.topRight;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.west),
                                                onPressed: () {
                                                  textContent["position"] = 4;
                                                  setState(() {
                                                    textPreviewAlignment =
                                                        Alignment.centerLeft;
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                    Icons.filter_center_focus),
                                                onPressed: () {
                                                  textContent["position"] = 5;
                                                  setState(() {
                                                    textPreviewAlignment =
                                                        Alignment.center;
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.east),
                                                onPressed: () {
                                                  textContent["position"] = 6;
                                                  setState(() {
                                                    textPreviewAlignment =
                                                        Alignment.centerRight;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.south_west),
                                                  onPressed: () {
                                                    textContent["position"] = 7;
                                                    setState(() {
                                                      textPreviewAlignment =
                                                          Alignment.bottomLeft;
                                                    });
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.south),
                                                  onPressed: () {
                                                    textContent["position"] = 8;
                                                    setState(() {
                                                      textPreviewAlignment =
                                                          Alignment
                                                              .bottomCenter;
                                                    });
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.south_east),
                                                  onPressed: () {
                                                    textContent["position"] = 9;
                                                    setState(() {
                                                      textPreviewAlignment =
                                                          Alignment.bottomRight;
                                                    });
                                                  },
                                                ),
                                              ])
                                        ],
                                      ),

                                      //Animate text
                                      Container(
                                          margin: EdgeInsets.only(top: 40),
                                          alignment: Alignment.centerLeft,
                                          child: Text("Animate text",
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          CheckboxListTile(
                                              title: const Text(
                                                  "Enable text scrolling"),
                                              value: isTextScrollingEnabled,
                                              onChanged: (bool val) {
                                                setState(() {
                                                  isTextScrollingEnabled = val;
                                                  textContent[
                                                          "scroll_animation_enabled"] =
                                                      val;
                                                  textContent[
                                                          "scroll_animation_direction"] =
                                                      _textAnimationSelecttion;
                                                });
                                              }),
                                          Container(
                                            color: isTextScrollingEnabled
                                                ? Colors.transparent
                                                : Colors.grey[300],
                                            // margin: EdgeInsets.only(left: 10),
                                            child: IgnorePointer(
                                              ignoring: !isTextScrollingEnabled,
                                              child: Column(
                                                children: [
                                                  RadioListTile<String>(
                                                      title: Text("Horizontal"),
                                                      value: "horizontal",
                                                      groupValue:
                                                          _textAnimationSelecttion,
                                                      onChanged:
                                                          (String value) {
                                                        setState(() {
                                                          _textAnimationSelecttion =
                                                              value;
                                                          textContent[
                                                                  "scroll_animation_direction"] =
                                                              value;
                                                        });
                                                      }),
                                                  RadioListTile<String>(
                                                      title: Text("Vertical"),
                                                      value: "vertical",
                                                      groupValue:
                                                          _textAnimationSelecttion,
                                                      onChanged:
                                                          (String value) {
                                                        setState(() {
                                                          _textAnimationSelecttion =
                                                              value;
                                                          textContent[
                                                                  "scroll_animation_direction"] =
                                                              value;
                                                        });
                                                      })
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      )
                                    ],
                                  )),
                            ),
                          ],
                        ),
                      ),

                      //Image/GIF
                      Visibility(
                        visible: selectedBlockContentType == 2,
                        child: Column(
                          children: [
                            Container(
                              margin: EdgeInsets.only(right: 20),
                              alignment: Alignment.centerLeft,
                              child: Form(
                                key: _enterURLGlobalKey,
                                child: TextFormField(
                                  controller: enterBlockURLController,
                                  decoration: InputDecoration(
                                      labelText: 'Image/GIF url'),
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return 'URL required';
                                    }
                                    contentType = "image";
                                    imageContent["link"] = value;
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            Wrap(
                              children: [
                                TextButton(
                                    onPressed: () async {
                                      GiphyGif gif = await GiphyGet.getGif(
                                        context: context, //Required
                                        apiKey:
                                            "ShudUpzvLP3cWyNuNyfpZjF771JmVfhL", //Required.
                                        lang: GiphyLanguage
                                            .english, //Optional - Language for query.
                                        tabColor: Colors
                                            .teal, // Optional- default accent color.
                                      );
                                      setState(() {
                                        enterBlockURLController.text =
                                            gif.images.fixedHeight.url;
                                      });
                                    },
                                    child: Text("Select a GIF")),
                                TextButton(
                                    onPressed: () {
                                      selectImageFromServerDialog(
                                          enterBlockURLController);
                                    },
                                    child: Text("Select from upload")),
                              ],
                            )
                          ],
                        ),
                      ),

                      //Color
                      Visibility(
                        visible: selectedBlockContentType == 3,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                alignment: Alignment.centerLeft,
                                child: Form(
                                  key: _enterColorGlobalKey,
                                  child: TextFormField(
                                    controller: enterBlockColorController,
                                    decoration:
                                        InputDecoration(labelText: 'Color'),
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return 'Hex color required';
                                      }
                                      contentType = "color";
                                      colorContent["color_val"] = value;
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),
                            TextButton(
                                onPressed: () {
                                  showColorPickerDialog().then((value) {
                                    setState(() {
                                      enterBlockColorController.text =
                                          "#${value.hex}";
                                    });
                                    contentType = "color";
                                    colorContent["color_val"] = "#${value.hex}";
                                  });
                                },
                                child: Text("Pick color"))
                          ],
                        ),
                      ),

                      //Task
                      Visibility(
                          visible: selectedBlockContentType == 4,
                          child: Container(
                            alignment: Alignment.centerLeft,
                            child: Form(
                              key: _enterTaskIDGlobalKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _enterTaskIDController,
                                    decoration:
                                        InputDecoration(labelText: "Task ID"),
                                    validator: (value) {
                                      if (value.isEmpty) {
                                        return "Task ID required";
                                      }
                                      contentType = "task";
                                      taskContent["task_id"] = value;
                                      return null;
                                    },
                                  ),
                                  Column(
                                    children: [
                                      TextFormField(
                                        controller: _enterTaskImageController,
                                        decoration: InputDecoration(
                                            labelText: "Image link"),
                                        validator: (value) {
                                          contentType = "task";
                                          taskContent["task_image"] = value;
                                          return null;
                                        },
                                      ),
                                      TextButton(
                                          onPressed: () {
                                            selectImageFromServerDialog(
                                                _enterTaskImageController);
                                          },
                                          child: Text("Select from upload")),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )),

                      //Image carousel
                      Visibility(
                        visible: selectedBlockContentType == 5,
                        child: Container(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 20),
                                child: TextButton(
                                    onPressed: () {
                                      imageCarouselContent["images"].add("");
                                      contentType = "image_carousel";
                                      setState(() {
                                        imageCarouselInputFields
                                            .add(TextEditingController());
                                      });
                                    },
                                    child: Text("Add image")),
                              ),
                              Form(
                                  key: _imageCarouselKey,
                                  child: Container(
                                    width: double.maxFinite,
                                    height: 300,
                                    child: Expanded(
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount:
                                            imageCarouselInputFields.length,
                                        itemBuilder: (context, i) {
                                          return Container(
                                            height: 160,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Expanded(
                                                  child: TextFormField(
                                                      onChanged: (val) {
                                                        imageCarouselContent[
                                                            "images"][i] = val;
                                                      },
                                                      validator: (String val) {
                                                        if (val == "") {
                                                          return "Please enter the image link";
                                                        }

                                                        return null;
                                                      },
                                                      controller:
                                                          imageCarouselInputFields[
                                                              i],
                                                      decoration:
                                                          InputDecoration(
                                                        hintText: "Image link",
                                                      )),
                                                ),
                                                Container(
                                                  margin:
                                                      EdgeInsets.only(top: 10),
                                                  child: Row(
                                                    children: [
                                                      Column(
                                                        children: [
                                                          TextButton(
                                                              onPressed: () {
                                                                selectImageFromServerDialog(
                                                                        imageCarouselInputFields[
                                                                            i])
                                                                    .then(
                                                                        (url) {
                                                                  imageCarouselContent[
                                                                          "images"]
                                                                      [i] = url;
                                                                });
                                                              },
                                                              child: Text(
                                                                  "Select from upload")),
                                                          TextButton(
                                                              onPressed:
                                                                  () async {
                                                                GiphyGif gif =
                                                                    await GiphyGet
                                                                        .getGif(
                                                                  context:
                                                                      context, //Required
                                                                  apiKey:
                                                                      "ShudUpzvLP3cWyNuNyfpZjF771JmVfhL", //Required.
                                                                  lang: GiphyLanguage
                                                                      .english, //Optional - Language for query.
                                                                  tabColor: Colors
                                                                      .teal, // Optional- default accent color.
                                                                );
                                                                setState(() {
                                                                  String gifUrl = gif
                                                                      .images
                                                                      .fixedHeight
                                                                      .url;
                                                                  imageCarouselInputFields[
                                                                              i]
                                                                          .text =
                                                                      gifUrl;
                                                                  imageCarouselContent[
                                                                          "images"]
                                                                      [
                                                                      i] = gifUrl;
                                                                });
                                                              },
                                                              child: Text(
                                                                  "Select a GIF")),
                                                        ],
                                                      ),
                                                      TextButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              imageCarouselInputFields
                                                                  .removeAt(i);
                                                            });
                                                          },
                                                          child: Text("Remove",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .red))),
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ))
                            ],
                          ),
                        ),
                      )
                    ],
                  )),

                  Container(
                    margin: EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Select block command",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          child: Wrap(
                            alignment: WrapAlignment.spaceAround,
                            children: [
                              TextButton(
                                child: Text(
                                  "On tap",
                                  style: TextStyle(
                                      color: selectedBlockCommandType == 1
                                          ? Colors.green
                                          : Colors.blue),
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedBlockCommandType = 1;
                                  });
                                },
                              ),
                              TextButton(
                                child: Text(
                                  "On hold",
                                  style: TextStyle(
                                      color: selectedBlockCommandType == 2
                                          ? Colors.green
                                          : Colors.blue),
                                ),
                                onPressed: () {
                                  setState(() {
                                    selectedBlockCommandType = 2;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                            visible: selectedBlockCommandType == 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButton(
                                  value: selectedOnTapCommand,
                                  items: BlockCommand.blockActions
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      selectedOnTapCommand = val;
                                      blockCommand.onTapCommand = val;
                                    });
                                  },
                                ),
                                Form(
                                    key: onTapValueKey,
                                    child: TextFormField(
                                      controller: onTapValueController,
                                      onChanged: (val) {
                                        setState(() {
                                          blockCommand.onTapValue = val;
                                        });
                                      },
                                      decoration:
                                          InputDecoration(hintText: "Value"),
                                    ))
                              ],
                            )),
                        Visibility(
                            visible: selectedBlockCommandType == 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DropdownButton(
                                  value: selectedOnHoldCommand,
                                  items: BlockCommand.blockActions
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      selectedOnHoldCommand = val;
                                      blockCommand.onHoldCommand = val;
                                    });
                                  },
                                ),
                                Form(
                                    key: onTapValueKey,
                                    child: TextFormField(
                                      controller: onTapValueController,
                                      onChanged: (val) {
                                        setState(() {
                                          blockCommand.onHoldValue = val;
                                        });
                                      },
                                      decoration:
                                          InputDecoration(hintText: "Value"),
                                    ))
                              ],
                            ))
                      ],
                    ),
                  )
                ],
              )),
              actions: <Widget>[
                TextButton(
                  child: Text('Approve'),
                  onPressed: () {
                    bool complete = false;
                    // Validate returns true if the form is valid, otherwise false.
                    if (_createCombinedBlockKey.currentState.validate()) {
                      if (selectedBlockContentType == 1 &&
                          _enterTextGlobalKey.currentState.validate()) {
                        complete = true;
                      } else if (selectedBlockContentType == 2 &&
                          _enterURLGlobalKey.currentState.validate()) {
                        complete = true;
                      } else if (selectedBlockContentType == 3 &&
                          _enterColorGlobalKey.currentState.validate()) {
                        complete = true;
                      } else if (selectedBlockContentType == 4 &&
                          _enterTaskIDGlobalKey.currentState.validate()) {
                        complete = true;
                      } else if (selectedBlockContentType == 5 &&
                          _imageCarouselKey.currentState.validate()) {
                        complete = true;
                      } else {
                        complete = false;
                      }
                    }

                    if (complete) {
                      if (contentType == "text") {
                        addCombinedBlock(
                            gridJson,
                            blockHeightController.text,
                            blockWidthController.text,
                            blockStartColumnController.text,
                            blockStartRowController.text,
                            contentType,
                            textContent,
                            blockCommand);
                      } else if (contentType == "task") {
                        addCombinedBlock(
                            gridJson,
                            blockHeightController.text,
                            blockWidthController.text,
                            blockStartColumnController.text,
                            blockStartRowController.text,
                            contentType,
                            taskContent,
                            blockCommand);
                      } else if (contentType == "image_carousel") {
                        addCombinedBlock(
                            gridJson,
                            blockHeightController.text,
                            blockWidthController.text,
                            blockStartColumnController.text,
                            blockStartRowController.text,
                            contentType,
                            imageCarouselContent,
                            blockCommand);
                      } else if (contentType == "color") {
                        addCombinedBlock(
                            gridJson,
                            blockHeightController.text,
                            blockWidthController.text,
                            blockStartColumnController.text,
                            blockStartRowController.text,
                            contentType,
                            colorContent,
                            blockCommand);
                      } else if (contentType == "image") {
                        addCombinedBlock(
                            gridJson,
                            blockHeightController.text,
                            blockWidthController.text,
                            blockStartColumnController.text,
                            blockStartRowController.text,
                            contentType,
                            imageContent,
                            blockCommand);
                      }

                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String> selectImageFromServerDialog(TextEditingController controller) {
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  "Select an image",
                  style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
                ),
                content: FutureBuilder(
                  future: getAllImagesFromServer(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      List<Reference> links = snapshot.data;
                      return Container(
                        height: 400,
                        width: double.maxFinite,
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: links.length,
                            itemBuilder: (context, i) {
                              return Container(
                                margin: EdgeInsets.only(bottom: 20),
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                    onPressed: () {
                                      links[i].getDownloadURL().then((url) {
                                        setState(() {
                                          controller.text = url;
                                        });
                                        Navigator.of(context).pop(url);
                                      });
                                    },
                                    child: Wrap(
                                      alignment: WrapAlignment.start,
                                      direction: Axis.vertical,
                                      children: [
                                        FutureBuilder(
                                          future: links[i].getDownloadURL(),
                                          builder: (context, imageSnapshot) {
                                            if (imageSnapshot.hasData) {
                                              return Image.network(
                                                imageSnapshot.data,
                                                width: 50,
                                              );
                                            } else {
                                              return CircularProgressIndicator();
                                            }
                                          },
                                        ),
                                        Container(
                                            margin: EdgeInsets.only(top: 10),
                                            child: Text(links[i].name)),
                                      ],
                                    )),
                              );
                            }),
                      );
                    } else {
                      return CircularProgressIndicator();
                    }
                  },
                ),
              );
            },
          );
        });
  }

  Future<List> getAllImagesFromServer() async {
    List<Reference> images = [];
    firebase_storage.ListResult result =
        await firebase_storage.FirebaseStorage.instance.ref().listAll();

    result.items.forEach((element) async {
      // String url = await element.getDownloadURL();
      images.add(element);
    });

    return images;
  }

  ///Combined block removal dialog
  Future<void> deleteCombinedBlockialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete a combined block'),
          content: SingleChildScrollView(
              child: Form(
                  key: _createCombinedBlockKey,
                  child: Column(children: <Widget>[
                    TextFormField(
                      controller: blockHeightController,
                      decoration:
                          InputDecoration(labelText: 'Combined block height'),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Height required';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: blockWidthController,
                      decoration:
                          InputDecoration(labelText: 'Combined block width'),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Width required';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: blockStartColumnController,
                      decoration:
                          InputDecoration(labelText: 'Grid start column'),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Column required';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: blockStartRowController,
                      decoration: InputDecoration(labelText: 'Grid start row'),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Row required';
                        }
                        return null;
                      },
                    ),
                  ]))),
          actions: <Widget>[
            TextButton(
              child: Text('Approve'),
              onPressed: () {
                // Validate returns true if the form is valid, otherwise false.
                if (_createCombinedBlockKey.currentState.validate()) {
                  deleteCombinedBlock(
                      gridJson,
                      blockHeightController.text,
                      blockWidthController.text,
                      blockStartColumnController.text,
                      blockStartRowController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<Color> showColorPickerDialog() {
    Color selectedColor = Colors.blue; // Material blue.

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            // title: const Text('Pick a color!'),
            content: SingleChildScrollView(
              child: ColorPicker(
                copyPasteBehavior: ColorPickerCopyPasteBehavior(
                    copyFormat: ColorPickerCopyFormat.hexRRGGBB),
                showRecentColors: true,
                showColorCode: true,
                pickersEnabled: {
                  ColorPickerType.wheel: true,
                  ColorPickerType.accent: false,
                  ColorPickerType.primary: false
                },
                // Use the screenPickerColor as start color.
                color: selectedColor,
                // Update the screenPickerColor using the callback.
                onColorChanged: (Color color) =>
                    setState(() => selectedColor = color),
                width: 44,
                height: 44,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Got it'),
                onPressed: () {
                  // setState(() => currentColor = pickerColor);
                  Navigator.of(context).pop(selectedColor);
                },
              ),
            ],
          );
        });
  }

  bool getEditState() {
    return editMode;
  }

  void changeEditState(bool state) {
    setState(() {
      editMode = state;
    });
  }

  void changeGridBackround(CustomGridBackground background) {
    setState(() {
      gridCustomBackgroudData = background;
    });
  }

  void changeState() {
    setState(() {});
  }

  ///Returns the actual size of a block
  double getBlockSize(int rows) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth / rows;
  }

  ///Post changes made to the UI grid to the server
  Future<String> postGridToServer(
      String addr, String path, Map<String, String> data) async {
    String grid;
    try {
      http.Response response =
          await http.post(Uri.http(addr, path), body: data);

      if (response.statusCode == 200) {
        grid = response.body;
      } else {
        grid = '';
      }
    } catch (e, stacktrace) {
      Scaffold.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text("An error occured. Try again."),
      ));
    }

    return grid;
  }

  ///Move a combined block to a specific position
  ///
  ///The combined block's details are passed in the [startColumn], [startRow], [height], [row] and the target locations are [targetColumn] and [targetRow]
  ///
  ///[blockQuadrant], [blockQuadrantCol] and [blockQuadrantRow] specify what part of the combined block is being dragged. Example: A 2x2 combined block,
  ///being dragged from the bottom left corner will have a [blockQuadrant] value of 2, [blockQuadrantCol] value of 1 and [blockQuadrantRow] value of 0.
  ///
  ///**blockQuadrant**
  ///
  /// Identifying the [blockQuadrant] for a 2x2 combined block. Each part is denoted with its [blockQuadrant] value. The values move from
  /// the top left to the bottom right.
  /// ```
  /// | 0 | 1 |
  /// | 2 | 3 |
  /// ```
  ///
  /// **blockQuadrantCol**
  ///
  /// Identifying the [blockQuadrantCol] for a 4x2 combined block. Each part is denoted with its [blockQuadrantCol] value. The values move from
  /// the left to right.
  /// ```
  /// | 0 | 1 | 2 | 3 |
  /// | 0 | 1 | 2 | 3 |
  /// ```
  ///
  /// **blockQuadrantRow**
  ///
  /// Identifying the [blockQuadrantRow] for a 2x4 combined block. Each part is denoted with its [blockQuadrantRow] value. The values move from
  /// the top to bottom.
  /// ```
  /// | 0 | 0 |
  /// | 1 | 1 |
  /// | 2 | 2 |
  /// | 3 | 3 |
  /// ```
  void moveCombinedBlock(
      String gridJSON,
      int startColumn,
      int startRow,
      int height,
      int width,
      int targetColumn,
      int targetRow,
      int blockQuadrant,
      int blockQuadrantCol,
      int blockQuadrantRow) {
    Map<String, String> data = {
      'grid_json': gridJSON,
      'start_column': startColumn.toString(),
      'start_row': startRow.toString(),
      'height': height.toString(),
      'width': width.toString(),
      'target_column': (targetColumn - blockQuadrantCol).toString(),
      'target_row': (targetRow - blockQuadrantRow).toString()
    };

    Grid.getInstance().postGridChangesToServer("/move", data);
  }

  ///Create a combined block
  void addCombinedBlock(
      String gridJSON,
      String height,
      String width,
      String startColumn,
      String startRow,
      String contentType,
      dynamic content,
      BlockCommand command) {
    Map<String, String> data;
    if (contentType == "text") {
      data = {
        'grid_json': gridJSON,
        'height': height,
        'width': width,
        'start_row': width,
        'target_column': startColumn,
        'target_row': startRow.toString(),
        'content_type': contentType,
        'command': jsonEncode(command.toJSON()),
        'content': jsonEncode(content)
      };
    } else {
      data = {
        'grid_json': gridJSON,
        'height': height,
        'width': width,
        'start_row': width,
        'target_column': startColumn,
        'target_row': startRow.toString(),
        'content_type': contentType,
        'command': jsonEncode(command.toJSON()),
        'content': jsonEncode(content)
      };
    }

    Grid.getInstance().postGridChangesToServer("/create", data);
  }

  ///Delete a combined block
  void deleteCombinedBlock(String gridJSON, String height, String width,
      String startColumn, String startRow) {
    Map<String, String> data = {
      'grid_json': gridJSON,
      'height': height,
      'width': width,
      'start_row': width,
      'target_column': startColumn,
      'target_row': startRow.toString()
    };

    Grid.getInstance().postGridChangesToServer("/delete", data);
  }

  ///Change the amount of columns
  void changeCols(int colsChange) {
    setState(() {
      columns = colsChange;
    });
  }

  ///Change the amount of rows
  void changeRows(int rowsChange) {
    setState(() {
      rows = rowsChange;
    });
  }

  ///Change the grid's data
  void changeData(List data) {
    setState(() {
      this.data = data;
    });
  }

  ///Create a single block.
  ///
  ///Create a singular empty block in a grid. These blocks do not have any content but instead serve as visual guides for where content can be
  ///added and also as a drop target when moving combined blocks to another location.
  ///
  ///The [combinedGroupSection] is either 1 or 3, because empty blocks are only created for the sections above/below the main combined group section.
  Widget _createSingleEmptyBlock(int targetColumn, int targetRow) {
    Color color;
    if (dragSelectGridController.value.isSelecting &&
        targetColumn >= startGridColumn &&
        targetColumn <= endColumnCurrentlyOn &&
        targetRow >= startGridRow &&
        targetRow <= endRowCurrentlyOn) {
      color = Colors.blueGrey;
    } else {
      color = Colors.black;
    }
    return DragTarget(
      builder: (context, List<CombBlockDragInformation> candidateData,
          rejectedData) {
        return DottedBorder(
          // This is what produces the dot effect when in edit mode
          dashPattern: [1, blockSize - 1],
          strokeCap: StrokeCap.square,
          color: Colors.grey[700],
          child: Container(
              width: blockSize,
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(color: color)),
        );
      },
      onWillAccept: (CombBlockDragInformation data) {
        return true;
      },
      onAccept: (data) {
        CombBlockDragInformation dragInformation = data;
        moveCombinedBlock(
            gridJson,
            dragInformation.combinedBlockStartColumn,
            dragInformation.combinedBlockStartRow,
            dragInformation.combinedBlockHeight,
            dragInformation.combinedBlockWidth,
            targetColumn,
            targetRow,
            dragInformation.blockQuadrantDraggingFrom,
            dragInformation.blockQuadrantColumn,
            dragInformation.blockQuadrantRow);
      },
    );
  }

  void processButtonActionCommand(String command, String value) {
    if (command == "Load task") {
      String id = command;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TaskView(id, "test")),
      );
    }
  }

  ///Create a combined block
  ///
  ///Creates a combined block in a combined group on a grid. The [combinedGroupIndexInCombinedGroupList] is the index of the combined group in the CombinedGroup list, and the
  ///[combinedBlockIndexInCombinedGroup] is the section of the combined group the combined block resides is. The first combined block in a combined group will have
  ///a [combinedBlockIndexInCombinedGroup] value of 1, the second will have a value of 2 and so on.
  Widget createCombinedBlock(Block block, int startCol, int startRow,
      {double height = 0.0, double width}) {
    double numberOfColumns = height / blockSize;
    double numberOfRows = width / blockSize;
    int blockQuadrant =
        0; //stores the block quadrant value when the user begins dragging the combined block
    CombBlockDragInformation dragInformation = CombBlockDragInformation();
    BlockCommand blockCommand = block.blockCommand;

    Widget combinedBlock = Stack(
      children: [
        GestureDetector(
          onTap: () {
            print(blockCommand.onTapCommand);
            processButtonActionCommand(
                blockCommand.onTapCommand, blockCommand.onTapValue);
          },
          onLongPress: () {
            if (blockCommand.onHoldCommand != "") {
              processButtonActionCommand(
                  blockCommand.onHoldCommand, blockCommand.onHoldValue);
            }
          },
          child: createCombinedBlockContent(
              block.content, numberOfColumns.toInt(), numberOfRows.toInt()),
        ),

        ///Block quadrants
        IgnorePointer(
          ignoring: !editMode,
          child: ListView.builder(
              itemCount: numberOfColumns.toInt(),
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, colIndex) {
                return Container(
                    height: blockSize,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: numberOfRows.toInt(),
                        itemBuilder: (context, rowIndex) {
                          return GestureDetector(
                            behavior: HitTestBehavior.deferToChild,
                            onTapDown: (details) {
                              int combinedBlockWidth = numberOfRows.toInt();
                              int combinedBlockHeight = numberOfColumns.toInt();

                              if (numberOfRows > 1) {
                                blockQuadrant = colIndex + rowIndex + 1;
                              } else {
                                blockQuadrant = colIndex + 1;
                              }

                              dragInformation.block = block;
                              dragInformation.blockQuadrantDraggingFrom =
                                  blockQuadrant;
                              dragInformation.blockQuadrantColumn = colIndex;
                              dragInformation.blockQuadrantRow = rowIndex;
                              dragInformation.combinedBlockHeight =
                                  combinedBlockHeight;
                              dragInformation.combinedBlockWidth =
                                  combinedBlockWidth;
                              dragInformation.combinedBlockStartColumn =
                                  startCol;
                              dragInformation.combinedBlockStartRow = startRow;
                            },
                            child: Container(
                              width: blockSize,
                              height: blockSize,
                              decoration: BoxDecoration(color: null),
                            ),
                          );
                        }));
              }),
        ),
      ],
    );

    return LongPressDraggable(
      data: dragInformation,
      child: GestureDetector(
        onDoubleTap: () {
          int height = numberOfColumns.toInt();
          int width = numberOfRows.toInt();

          if (editMode) {
            print(gridJson);
            deleteCombinedBlock(gridJson, height.toString(), width.toString(),
                startCol.toString(), startRow.toString());
          }
        },
        child: Container(
            width: width,
            decoration: BoxDecoration(
                border: editMode
                    ? Border.all(color: Colors.white, width: 2)
                    : null),
            child: combinedBlock),
      ),
      feedback: Material(
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
              color: Colors.orange,
              border: Border.all(color: Colors.white, width: 2)),
          child: Center(
              child: Text(
            "Editing",
            style: TextStyle(fontSize: 20, color: Colors.white),
          )),
        ),
      ),
      childWhenDragging: Container(
        width: width,
        decoration: BoxDecoration(
            color: Colors.grey,
            border: Border.all(color: Colors.white, width: 2)),
        child: Center(
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  ///Create the content in the combined block.
  Widget createCombinedBlockContent(
      CombinedBlockContent blockContent, int cols, int rows) {
    return blockContent.content.buildView(context, blockSize, rows, cols);
  }

  Future getCombinedBlockTaskDetails(String taskID) async {
    try {
      http.Response response = await http.Client()
          .get(Uri.http(NetworkConfig.serverAddr + "8000", "/task/$taskID"));

      if (response.statusCode == 200) {
        Map taskData = jsonDecode(response.body);
        if (taskData["msg"] == "not_found") {
          return null;
        } else {
          return taskData;
        }
      } else {
        return null;
      }
    } catch (e, stacktrace) {}
  }

  ///Return the alignment for the block content text type position property

  int endColumnCurrentlyOn = 0;
  int endRowCurrentlyOn = 0;
  int startGridRow = 0;
  int startGridColumn = 0;
  bool startDrag = false;
  final dragSelectGridController = DragSelectGridViewController();

  ///Creates empty blocks in the grid
  Widget createEmptyBlocks() {
    return Listener(
      onPointerUp: (d) {
        if (dragSelectGridController.value.isSelecting && editMode) {
          int newCombinedBlockHeight =
              (endColumnCurrentlyOn - startGridColumn) + 1;
          int newCombinedBlockWidth = (endRowCurrentlyOn - startGridRow) + 1;

          blockHeightController.text = newCombinedBlockHeight.toString();
          blockWidthController.text = newCombinedBlockWidth.toString();
          blockStartColumnController.text = startGridColumn.toString();
          blockStartRowController.text = startGridRow.toString();
          createCombinedBlockialog(context, true);

          dragSelectGridController.clear();
        }
      },
      onPointerDown: (d) {
        dragSelectGridController.addListener(() {
          if (editMode) {
            Set<int> selectedIndices =
                dragSelectGridController.value.selectedIndexes;
            if (!startDrag) {
              startDrag = true;
              startGridColumn = (selectedIndices.elementAt(0) / rows).floor();
              startGridRow = selectedIndices.elementAt(0) % rows;
            }
          }
        });
      },
      child: Visibility(
        visible: editMode,
        child: Container(
          color: Colors.black,
          child: rows == 0
              ? Container(
                  height: MediaQuery.of(context).size.height,
                  color: Colors.amber,
                )
              : DragSelectGridView(
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: false,
                  gridController: dragSelectGridController,
                  itemCount: rows * columns,
                  itemBuilder: (context, index, selected) {
                    int colIndex = (index / rows).floor();
                    int rowIndex = index % rows;

                    return _createSingleEmptyBlock(colIndex, rowIndex);
                  },
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: (rows * blockSize) / rows,
                  ),
                ),
        ),
      ),
    );
  }

  List<Widget> initGrids(List data, double blockSize) {
    List<Widget> widgets = [];

    if (data != null) {
      if (data.length > 0) {
        int numberOfCombinedGroups = data.length;

        for (int combGroupIndex = 0;
            combGroupIndex < numberOfCombinedGroups;
            combGroupIndex++) {
          CombinedGroup combinedGroup = data[combGroupIndex];
          int totalColumnsAbove = combinedGroup.columnsAbove;

          for (int i = 0; i < combinedGroup.combinedBlocks.length; i++) {
            CombinedBlockInGroup combinedBlockInGroup =
                combinedGroup.combinedBlocks[i];
            Block block = combinedBlockInGroup.block;
            int emptyColsAbove = combinedBlockInGroup.numberOfColumnsAbove;
            int emptyRowsBefore = combinedBlockInGroup.numberOfRowsLeft;
            double blockHeight = block.numberOfColumns * blockSize;
            double blockWidth = block.numberOfRows * blockSize;

            widgets.add(Positioned(
                top: (emptyColsAbove + totalColumnsAbove) * blockSize,
                left: emptyRowsBefore * blockSize,
                child: Container(
                  height: blockHeight,
                  width: blockWidth,
                  child: createCombinedBlock(block,
                      (emptyColsAbove + totalColumnsAbove), emptyRowsBefore,
                      height: blockHeight, width: blockWidth),
                )));
          }
        }
      }
    } else {
      widgets.add(Container(
        height: MediaQuery.of(context).size.height,
        color: Colors.black,
        child: Align(
          alignment: Alignment.center,
          child: Text(
            "No grid data",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ));
    }

    return widgets;
  }

  Widget _buildGridBackground(CustomGridBackground gridBackgroundData) {
    if (gridBackgroundData != null) {
      if (gridBackgroundData.is_color) {
        String color = gridBackgroundData.link_or_color.replaceAll("#", "0xff");
        return Container(
          height: columns * getBlockSize(rows),
          color: Color(int.parse(color)),
        );
      } else if (gridBackgroundData.is_link) {
        String link = gridBackgroundData.link_or_color;
        return Container(
          height: columns * getBlockSize(rows),
          child: Image.network(link, fit: BoxFit.cover),
        );
      }
    } else {
      return Container(
        height: MediaQuery.of(context).size.height,
        color: Colors.black,
        child: Align(
          alignment: Alignment.center,
          child: Text(
            "No grid backgroud data",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    dragSelectGridController.addListener(() {
      if (editMode && dragSelectGridController.value.isSelecting) {
        Set<int> selectedIndices =
            dragSelectGridController.value.selectedIndexes;
        startDrag = false;

        endColumnCurrentlyOn = (selectedIndices
                    .elementAt(dragSelectGridController.value.amount - 1) /
                rows)
            .floor();
        endRowCurrentlyOn = selectedIndices
                .elementAt(dragSelectGridController.value.amount - 1) %
            rows;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    dragSelectGridController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    blockSize = getBlockSize(rows);

    return Container(
      color: Colors.black,
      height: columns == 0
          ? MediaQuery.of(context).size.height
          : columns * blockSize,
      child: Stack(
        children: [
          _buildGridBackground(gridCustomBackgroudData),
          createEmptyBlocks(),
          Stack(children: initGrids(data, blockSize)),
        ],
      ),
    );
  }
}
