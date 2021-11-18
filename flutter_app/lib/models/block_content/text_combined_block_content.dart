import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/models/block_content/block_content.dart';
import 'package:marquee/marquee.dart';

class TextContent implements BlockContent {
  String value = "";
  int position = 0;
  int x_pos = 0;
  int y_pos = 0;
  double fontSize = 0;
  String blockColor = "#000000";
  String blockImage = "";
  String color = "#000000";
  String font = "";
  bool underline = false;
  bool lineThrough = false;
  bool bold = false;
  bool italic = false;
  bool scrollAnimationEnabled = false;
  String scrollAnimationDirection = "";

  TextContent(
      this.value,
      this.position,
      this.x_pos,
      this.y_pos,
      this.font,
      this.fontSize,
      this.blockColor,
      this.blockImage,
      this.color,
      this.underline,
      this.lineThrough,
      this.bold,
      this.italic,
      this.scrollAnimationEnabled,
      this.scrollAnimationDirection);

  TextContent.fromJSON(Map<String, dynamic> data) {
    this.value = data["value"];
    this.position = data["position"];
    this.x_pos = data["x_pos"];
    this.y_pos = data["y_pos"];
    this.font = data["font"];
    this.fontSize = data["font_size"];
    this.blockColor = data["block_color"];
    this.blockImage = data["block_image"];
    this.color = data["color"];
    this.underline = data["underline"];
    this.lineThrough = data["line_through"];
    this.bold = data["bold"];
    this.italic = data["italic"];
    this.scrollAnimationEnabled = data["scroll_animation_enabled"];
    this.scrollAnimationDirection = data["scroll_animation_direction"];
  }

  @override
  Widget buildView(BuildContext context, double blockSize, int rows, int cols) {
    String text = this.value;
    String blockColor = this.blockColor == "transperent"
        ? "transperent"
        : this.blockColor.replaceAll("#", "0xff");
    String color = this.color.replaceAll('#', '0xff');
    int position = this.position;
    double xPos = (this.x_pos.toDouble());
    double yPos = (this.y_pos.toDouble());
    String font = this.font;
    double fontSize = this.fontSize;
    Alignment textPosition = getTextAlignemtPosition(position);
    bool underline = this.underline;
    bool lineThrough = this.lineThrough;
    bool bold = this.bold;
    bool italic = this.italic;
    bool scrollAnimationEnabled = this.scrollAnimationEnabled ?? false;
    String scrollAnimationDirection = this.scrollAnimationDirection ?? "";
    double numOfAnimatedTextToDisplay = scrollAnimationDirection == "horizontal"
        ? blockSize * rows
        : blockSize * cols;

    return Container(
      child: Stack(
        children: [
          Container(
            color: blockColor == "transperent" || blockColor == ""
                ? Colors.transparent
                : Color(int.parse(blockColor)),
          ),
          this.blockImage == null || this.blockImage == ""
              ? Container()
              : Container(
                  width: double.maxFinite,
                  child: Image(
                    fit: BoxFit.fitWidth,
                    image: NetworkImage(this.blockImage),
                  ),
                ),
          Align(
            alignment: textPosition,
            child: Container(
              margin: EdgeInsets.only(
                  bottom: yPos >= 0 ? yPos : 0,
                  top: yPos < 0 ? yPos.abs() : 0,
                  left: xPos >= 0 ? xPos : 0,
                  right: xPos < 0 ? xPos.abs() : 0),
              child: scrollAnimationEnabled
                  ? Marquee(
                      text: text,
                      blankSpace: numOfAnimatedTextToDisplay,
                      scrollAxis: scrollAnimationDirection == "horizontal"
                          ? Axis.horizontal
                          : Axis.vertical,
                      style: GoogleFonts.getFont(font == "" ? "Roboto" : font,
                          color: Color(int.parse(color)),
                          fontWeight:
                              bold ? FontWeight.bold : FontWeight.normal,
                          fontStyle:
                              italic ? FontStyle.italic : FontStyle.normal,
                          decoration: underline
                              ? TextDecoration.underline
                              : lineThrough
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                          fontSize: fontSize),
                    )
                  : Text(text,
                      style: GoogleFonts.getFont(font == "" ? "Roboto" : font,
                          color: Color(int.parse(color)),
                          fontWeight:
                              bold ? FontWeight.bold : FontWeight.normal,
                          fontStyle:
                              italic ? FontStyle.italic : FontStyle.normal,
                          decoration: underline
                              ? TextDecoration.underline
                              : lineThrough
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                          fontSize: fontSize)),
            ),
          )
        ],
      ),
    );
  }

  Alignment getTextAlignemtPosition(int position) {
    Alignment textPosition = Alignment.center;

    if (position == 1) {
      textPosition = Alignment.topLeft;
    } else if (position == 2) {
      textPosition = Alignment.topCenter;
    } else if (position == 3) {
      textPosition = Alignment.topRight;
    } else if (position == 4) {
      textPosition = Alignment.centerLeft;
    } else if (position == 5) {
      textPosition = Alignment.center;
    } else if (position == 6) {
      textPosition = Alignment.centerRight;
    } else if (position == 7) {
      textPosition = Alignment.bottomLeft;
    } else if (position == 8) {
      textPosition = Alignment.bottomCenter;
    } else if (position == 9) {
      textPosition = Alignment.bottomRight;
    }

    return textPosition;
  }

  Map<String, dynamic> toJSON() {
    return {
      "value": value,
      "position": position,
      "x_pos": x_pos,
      "y_pos": y_pos,
      "font": font,
      "font_size": fontSize,
      "block_color": blockColor,
      "block_image": blockImage,
      "color": color,
      "underline": underline,
      "line_through": lineThrough,
      "bold": bold,
      "italic": italic,
      "scroll_animation_enabled": scrollAnimationEnabled,
      "scroll_animation_direction": scrollAnimationDirection
    };
  }
}
