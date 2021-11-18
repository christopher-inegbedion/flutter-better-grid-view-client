import 'package:flutter/material.dart';

abstract class BlockContent {
  BlockContent();
  
  BlockContent.fromJSON(Map data);

  Widget buildView(BuildContext context, double blockSize, int rows, int cols) {
    return Container(
      child: Text("View not built"),
    );
  }

  Map toJSON();
}
