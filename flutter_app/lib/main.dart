import 'package:better_grid_view/models/grid.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:hexcolor/hexcolor.dart';

import 'network_config.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Grid grid;

  Color backgroundColor;
  Color devToolsBtnColor;

  void setBackgroundColor() async {
    if (grid.gridCustomBackground.is_link) {
      final PaletteGenerator generator =
          await PaletteGenerator.fromImageProvider(
              Image.network(grid.gridCustomBackground.link_or_color).image);
      setState(() {
        backgroundColor = generator.dominantColor.color;
        devToolsBtnColor = generator.dominantColor.bodyTextColor;
      });
    } else {
      final PaletteGenerator generator = PaletteGenerator.fromColors(
          [PaletteColor(HexColor(grid.gridCustomBackground.link_or_color), 1)]);
      setState(() {
        backgroundColor = HexColor(grid.gridCustomBackground.link_or_color);
        devToolsBtnColor = generator.dominantColor.bodyTextColor;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    grid = Grid.getInstance();
    grid.loadGrid("a");
    grid.onViewInitComplete = setBackgroundColor;
  }

  Widget buildDevTooldBtn(String text, Function action) {
    return TextButton(
      child: Text(
        text,
        style: TextStyle(color: Colors.black),
      ),
      onPressed: () {
        action();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: ListView(
          children: [
            grid.gridUIView,
            buildDevTooldBtn("Toggle edit mode", () {
              setState(() {
                grid.toggleEditMode();
              });
            }),
          ],
        ),
      ),
    );
  }
}
