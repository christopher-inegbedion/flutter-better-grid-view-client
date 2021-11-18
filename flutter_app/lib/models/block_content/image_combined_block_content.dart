import 'package:flutter/material.dart';
import '/models/block_content/block_content.dart';

class ImageContent implements BlockContent {
  String link = "";

  ImageContent(this.link);

  ImageContent.fromJSON(Map<String, dynamic> data) {
    this.link = data["link"];
  }

  @override
  Widget buildView(BuildContext context, double blockSize, int rows, int cols) {
    String link = this.link.replaceAll('"', "");

      return Image(
        image: NetworkImage(link),
      );
  }

  Map<String, String> toJSON() {
    return {"link": link};
  }
}
