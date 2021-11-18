import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import '/models/block_content/block_content.dart';

class ImageCarouselContent implements BlockContent {
  List images = [];

  ImageCarouselContent(this.images);

  ImageCarouselContent.fromJSON(Map<String, dynamic> data) {
    this.images = data["images"];
  }

  @override
  Widget buildView(BuildContext context, double blockSize, int rows, int cols) {
    List images = this.images;

    return Container(
      child: CarouselSlider(
          options: CarouselOptions(autoPlay: true, height: blockSize * cols),
          items: images.map((e) {
            return Builder(builder: (context) {
              return Image(
                fit: BoxFit.cover,
                image: NetworkImage(e),
              );
            });
          }).toList()),
    );
  }

  Map<String, String> toJSON() {
    return {"images": jsonEncode(images)};
  }
}
