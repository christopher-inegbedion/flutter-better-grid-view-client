import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../network_config.dart';
import '/grid_view.dart';
import '/enum/block_type.dart';
import '/enum/combined_group_type.dart';
import '/models/block.dart';
import '/models/block_command.dart';
import '/models/block_content/all_block_contents.dart';
import '/models/combined_block_content.dart';
import '/models/combined_block_in_group.dart';
import '/models/combined_group.dart';
import 'grid_custom_background.dart';
import 'package:http/http.dart' as http;

class Grid {
  static Grid instance;

  int gridColumns;
  int gridRows;
  bool editMode = false;

  List<CombinedGroup> combinedGroups;
  String gridJson;
  CustomGridBackground gridCustomBackground;
  GridUIView _gridUIView;
  Function onViewInitComplete;

  Grid._() {
    _gridUIView = GridUIView.empty();
  }

  static Grid getInstance() {
    if (instance == null) {
      instance = Grid._();
      instance._gridUIView = GridUIView.empty();
    }

    return instance;
  }

  ///Retrieve a Grid layout from the url specified
  Future<String> _getGridFromServer(String addr, String path) async {
    String grid;
    try {
      http.Response response = await http.Client().get(Uri.http(addr, path));

      if (response.statusCode == 200) {
        grid = response.body;
      } else {
        grid = '';
      }
    } catch (e, stacktrace) {
      print(e);
      print(stacktrace);
      return null;
    }

    return grid;
  }

  ///Post changes made to the UI grid to the server
  Future<String> postGridChangesToServer(
      String path, Map<String, String> data) async {
    print(data);
    String grid;

    try {
      http.Response response = await http.Client().post(
          Uri.http(NetworkConfig.serverAddr + NetworkConfig.serverPort, path),
          body: data);
      if (response.statusCode == 200) {
        grid = response.body;
      } else {
        grid = '';
      }

      loadGrid("", gridAlreadyLoaded: true, gridJSONString: grid);
    } catch (e, stacktrace) {
      print(e);
      print(stacktrace);
      return null;
    }

    return grid;
  }

  ///Load the grid's data from JSON source. When this method is called, the old Grid's data is
  ///replaced with the new one and the view is rebuilt.
  Future<Grid> loadGrid(String path,
      {bool gridAlreadyLoaded = false, String gridJSONString}) async {
    Map<String, dynamic> decodedGridJSON;
    instance.combinedGroups = [];

    //gridLoaded should be true if the grid JSON is already gotten from the postGridToServer(..) method
    if (gridAlreadyLoaded) {
      decodedGridJSON = jsonDecode(gridJSONString);
    } else {
      String loadedGrid = await _getGridFromServer(
          NetworkConfig.serverAddr + NetworkConfig.serverPort,
          "/load_grid/" + path);
      if (loadedGrid == null) {
        return null;
      }
      decodedGridJSON = jsonDecode(loadedGrid);
    }

    ///Grid in json format
    instance.gridJson = json.encode(decodedGridJSON);

    ///Number of columns in the grid
    instance.gridColumns = decodedGridJSON["grid_columns"];

    ///Number or rows in the grid
    instance.gridRows = decodedGridJSON["grid_rows"];

    ///Grid's custom background
    instance.gridCustomBackground = CustomGridBackground(
      decodedGridJSON["custom_background"]["is_link"],
      decodedGridJSON["custom_background"]["is_color"],
      decodedGridJSON["custom_background"]["link_or_color"],
    );

    ///Create each combined group object and asign each to [combinedGroups]
    if (decodedGridJSON["combined_groups"] != null) {
      for (Map<String, dynamic> combinedGroupFromJSON
          in decodedGridJSON["combined_groups"]) {
        List<CombinedBlockInGroup> allCombinedBlocks = [];

        ///Create each combined group's combined block
        for (Map<String, dynamic> combinedBlocks
            in combinedGroupFromJSON["combined_blocks"]) {
          String blockContentType =
              combinedBlocks["block"]["content"]["content_type"];

          Map contentValue = combinedBlocks["block"]["content"]["value"];
          Map blockCommandValue = combinedBlocks["block"]["block_command"];
          dynamic content =
              BlockContents.buildContentObject(blockContentType, contentValue);
          int blockRows = combinedBlocks["block"]["number_of_rows"];
          int blockCols = combinedBlocks["block"]["number_of_columns"];

          BlockCommand blockCommand;
          if (combinedBlocks["block"]["block_command"] != null) {
            String tapCommand = blockCommandValue["tap_command"];
            String tapCommandValue = blockCommandValue["tap_command_value"];
            String holdCommand = blockCommandValue["hold_command"];
            String holdCommandValue = blockCommandValue["hold_command_value"];

            blockCommand = BlockCommand(
                tapCommand, tapCommandValue, holdCommand, holdCommandValue);
          } else {
            blockCommand = BlockCommand("", "", "", "");
          }

          CombinedBlockContent blockContent =
              CombinedBlockContent(blockContentType, content);
          Block block = Block(BlockType.combined, blockContent, blockRows,
              blockCols, blockCommand);

          CombinedBlockInGroup combinedBlockInGroup = CombinedBlockInGroup(
              combinedBlocks["number_of_rows_left"],
              combinedBlocks["number_of_rows_right"],
              combinedBlocks["number_of_columns_above"],
              combinedBlocks["number_of_columns_below"],
              combinedBlocks["position_in_combined_group"],
              block);

          allCombinedBlocks.add(combinedBlockInGroup);
        }

        CombinedGroup combinedGroup = CombinedGroup(
            convertFromStringToCombinedGroupType(
                combinedGroupFromJSON["combined_group_type"]),
            combinedGroupFromJSON["columns_above"],
            combinedGroupFromJSON["columns_below"],
            combinedGroupFromJSON["number_of_columns"],
            combinedGroupFromJSON["number_of_rows"],
            allCombinedBlocks);

        combinedGroups.add(combinedGroup);
      }
    }

    instance.combinedGroups = combinedGroups;

    buildGridView();

    return getInstance();
  }

  void createAndSaveNewGrid(
      String numberOfColumns, String numberOfRows, String gridName) {
    Map<String, String> data = {
      "number_of_columns": numberOfColumns,
      "number_of_rows": numberOfRows
    };

    postGridChangesToServer("/create_grid", data).then((val) {
      saveGrid(gridName);
    });
  }

  void saveGrid(String gridName) {
    Map<String, String> data = {"grid_name": gridName, "grid": gridJson};

    postGridChangesToServer("/save_grid", data).then((val) {
      if (val == "") {
        throw Exception("An error occured");
      }
    });
  }

  get gridUIView {
    return _gridUIView;
  }

  CombinedGroupType convertFromStringToCombinedGroupType(String type) {
    if (type == "SINGLE_COMBINED_GROUP")
      return CombinedGroupType.SINGLE_COMBINED_GROUP;
    if (type == "MULTIPLE_COMBINED_GROUP_SAME_HEIGHT")
      return CombinedGroupType.MULITPLE_COMBINED_GROUP_SAME_HEIGHT;
    if (type == "MULTIPLE_COMBINED_GROUP_DIFF_HEIGHT")
      return CombinedGroupType.MULTIPLE_COMBINED_GROUP_DIFF_HEIGHT;

    return null;
  }

  Future<Map<String, dynamic>> parseJsonFromAssets(String assetsPath) async {
    return rootBundle
        .loadString(assetsPath)
        .then((jsonStr) => jsonDecode(jsonStr));
  }

  Map<String, dynamic> toJSON(Grid grid) {
    return {
      "grid_json": gridJson,
      "gridColumns": gridColumns,
      "gridRows": gridRows,
      "combinedGroups": combinedGroups
    };
  }

  void buildGridView() {
    _gridUIView.changeCols(gridColumns);
    _gridUIView.changeRows(gridRows);
    _gridUIView.changeGrid(combinedGroups);
    _gridUIView.changeGridJSON(gridJson);
    _gridUIView.changeCustomBackground(gridCustomBackground);

    onViewInitComplete();
  }

  void toggleEditMode() {
    instance.editMode = !instance.editMode;
    _gridUIView.changeEditMode(instance.editMode);
  }
}
