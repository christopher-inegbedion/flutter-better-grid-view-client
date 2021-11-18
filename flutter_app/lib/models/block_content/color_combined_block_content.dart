import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:string_validator/string_validator.dart';

import 'block_content.dart';

class ColorContent implements BlockContent {
  String colorVal = "#000000";

  ColorContent(this.colorVal);

  ColorContent.fromJSON(Map<String, dynamic> data) {
    colorVal = data["color_val"];
  }

  @override
  Widget buildView(BuildContext context, double blockSize, int rows, int cols) {
    String color = colorVal.replaceAll("#", "").replaceAll('"', "");
    if (isHexColor(color)) {
      return Container(
        color: color == "transperent" ? Colors.transparent : HexColor(color),
      );
    } else {
      return Container(
        color: Colors.transparent,
        child: const Center(
          child: Text("Color error", style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  @override
  Map<String, String> toJSON() {
    return {"color_val": colorVal};
  }
}
