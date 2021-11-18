# Flutter better-grid-view

An implementation of a grid layout system with Flutter.

![grid layout](assets/grid_layout.gif)

## What is better-grid-view?
better-grid-view is a design system that allows for the creation of customizable grid layouts. The grid is composed of blocks that can be created/deleted/moved around as requried to form a desired layout.

better-grid-view works by converting data in a matrix stored along with a dictionary of each blocks corresponding content, on the layout server into a JSON string object which is then used to create the Grid layout on the server side. The matrix determines how many rows and columns the grid has and the size of each block. Empty spaces with no block are labelled with a '0' and a block will instead have a numerical ID, 1, 2, 3, etc, and it is this ID that is used to store the block's content data.


**Example 1**: The diagram below is a 3x3 matrix with no combined block.
```
    1   2   3
  -------------
1 | 0 | 0 | 0 |
  -------------
2 | 0 | 0 | 0 |
  -------------
3 | 0 | 0 | 0 |
  -------------
```
</br>

**Example 2**: The diagram below is a 5x5 matrix with a 2x2 combined block at position (2,2. The first 2 is the column, the second 2 is the row). The parts of the matrix with the combined block is marked with a '1'.
```
    1   2   3   4   5
  ---------------------
1 | 0 | 0 | 0 | 0 | 0 |
  ---------------------
2 | 0 | 1 | 1 | 0 | 0 |
  ---------------------
3 | 0 | 1 | 1 | 0 | 0 |
  ---------------------
4 | 0 | 0 | 0 | 0 | 0 |
  ---------------------
5 | 0 | 0 | 0 | 0 | 0 |
  ---------------------
```
</br>

**Example**: The diagram below is a 5x5 matrix with a 2x2 combined block at position (1,1) and a 1x3 combined block at position (4,3). The parts of the matrix with a combined block is marked with a '1'.
```
    1   2   3   4   5
  ---------------------
1 | 1 | 1 | 0 | 0 | 0 |
  ---------------------
2 | 1 | 1 | 0 | 0 | 0 |
  ---------------------
3 | 0 | 0 | 0 | 0 | 0 |
  ---------------------
4 | 0 | 0 | 1 | 1 | 1 |
  ---------------------
5 | 0 | 0 | 0 | 0 | 0 |
  ---------------------
```
</br>

## How the better-grid-view client receives the layout data?
The layout for a better-grid-view client is determined by the JSON string object received from the better-grid-view layout server. The data in the matrix is converted into a JSON string object which describes its size, position in the Grid, its content, etc. This JSON data is then sent to a better-grid-view client that is able to understand the JSON and convert it into a layout
```
#################        JSON         #################
|    SERVER     | ------------------> |     CLIENT    |
#################                     #################
```

## How is the layout updated?
When an update to the Grid is made, the potential change to be made is sent to the layout server with the change details and then the new changes are re-calculated server-side and sent back to the better-grid-view client as a full JSON string object which is then re-updated with a new layout.

</br>

**Example**
```
(1) Change is made
#####################################                        
|            CLIENT                 |     (API request)      ####################
|   (Combined block is deleted)     | ---------------------->|      SERVER      |
#####################################                        ####################

(2) Changes are re-calculated
#################################
|             SERVER            |              JSON
|   (Change has been received)  |
|   (Change is re-calculated)   | -------------------------------> JSON string
#################################

(3) JSON string is sent back to client
#####################      JSON     ####################
|       SERVER      | ------------> |      CLIENT      |
#####################               ####################
```

## What is the layout of the JSON received from the server?
The structure of the better-grid-view JSON and each property definition is as follows:
```python
{
    # This is the total amount of columns in the grid 
    "grid_columns": 

    # This is the amount of rows in the grid
    "grid_rows": 

    # This is an array that contains the data for each combined block. 
    "combined_groups": 
    [

        # ~~~This array contains multiple combined groups~~~
        # What is a combined group?: Each combined block is grouped with other combined blocks
        # that are adjacent to it horizontally. A combined group is therefore a collection of
        # horizontally adjacent combined blocks.

        {
      # This describes the type of combined group
      "combined_group_type": 

      # This is the number of empty blocks above the combined group.
       # If a combined group A is below another combined group B, then the number of
       # columns above for A will be the number of columns above before reaching B,
      "columns_above": 

      # This is the number of empty blocks below the combined group.
      # This value is always 0 if the combined group is not the last in the array, 
      # else it will be the number of blocks before the end of the grid.
      "columns_below": 

      # This is the maximum amount of column space occupied by the blocks in
      # the combined group,
      "number_of_columns": 

      # This value is the same as the number of rows in the grid,
      "number_of_rows": 
      
      # This property describes each individual combined block in the combined group
      "combined_blocks": [

          # ~~~This array contains each combined block in the combined group~~~

        {
          
          # This is the number of empty rows to the left of a combined block before another combined block,
          "number_of_rows_left": 

          # This is the number of empty rows to the right of a combined block before another combined block
          "number_of_rows_right": 

          # This is the number of empty columns above a combined block in the combined group
          "number_of_columns_above": 

          # This is the number of empty columns below a combined block in the combined group
          "number_of_columns_below": 

          # This is the positional index of a combined block in its combined group.
           # The first combined block from the left is 1, second 2, etc.
          "position_in_combined_group": 
          
          # This describes the properties of a combined block in detail
          "block":  {
            
            # This identifies the block in the grid. Used to assign the blocks content
            "index": 
            
            # This is the type of combined block
            "type": 

            # This describes what type of content the combined block is to display (More on this below)
            "content": 
            
            # This describes the number of rows the combined block occupies (Its width)
            "number_of_rows": 

            # This describes the number of columns the combined block occupies (Its height)
            "number_of_columns": 

            "combined_group_position": --

            "block_position": --
          }
        }
        ...n
      ]
}
```

## Block content
Blocks can have different types of content in them. These describe what will be displayed in the block. These could include:
- Text
- Color
- Image
- Video
- etc...

Each of the content types have their own unique data structure.

#### Server side
This will be covered in the better-grid-ui server documentation

#### Client side
Each Block content is just a class that implements the BlockContent abstract class. The class defines the properties of the content and how it should be rendered.
</br>

#### Structure of a typical Block content class
```dart
class NewContentName implements BlockContent {
    String property1;
    String property2;

    NewContentName(this.property1, this.property2);

    NewContentName.fromJSON(Map data) {
        this.property1 = data["property1"];
        this.property2 = data["property2"];
    }


    //Build the view of your content in this method
    @override
    Widget buildView(BuildContext context, double blockSize, int rows, int cols) {
        return Container(
            child: Text("$property1 $property2");
           );
       }
   }
```

### Creating custom content
To create a custom content is quite straightforward
#### Server side
This will be covered in the better-grid-ui server documentation

#### Client side
1. Create a new class to describe the properties of the content and decide upon the tag for the content

   ```dart
   class NewContentName implements BlockContent {
       String property1;
       String property2;

       NewContentName(this.property1, this.property2);

       NewContentName.fromJSON(Map data) {
           this.property1 = data["property1"];
           this.property2 = data["property2"];
       }


       //Build the view of your content in this method
       @override
       Widget buildView(BuildContext context, double blockSize, int rows, int cols) {
           return Container(
               child: Text("$property1 $property2");
           );
       }
   }
   ```
   
2. Add a the new content Object to the BlockContent ```buildContentObject(String contentTag, Map contentValue)``` method

    ```dart
    ...
    "task1": Content1.fromJSON(contentValue),
    "task2": Content2.fromJSON(contentValue),
    "new_content": NewContentName.fromJSON(contentValue) //Append the new content to the dictionary in the method
    ...

3. That's it! If the content is attached to a block it will automatically get built, with the ```buildView(...)``` method in the content's class

### How do the blocks in the matrix know which content is theirs?
Each block is given a ID to identify it and that ID is stored in the block content object

## Data transfer diagram
How is the data transfered from the server to the client, vice-versa.
```
  /###########################################################################/         /####################################################################################/
  #                             Server side                                   #         #                                  Client side                                       #
  #  +----------+     +---------------+     +------------------------------+  #  JSON   #  +--------------+     +---------------+     +-------------------+     +----------+ #
  #  |  Matrix  | <-> |  Grid object  | <-> |  JSON string representation  |  # <-----> #  | JSON string  | <-> |  Grid object  | <-> |  GridView object  | <-> |  Layout  | #
  #  +----------+     +---------------+     +------------------------------+  #         #  +--------------+     +---------------+     +-------------------+     +----------+ #
  /###########################################################################/         /####################################################################################/

The position and size of the combined blocks are stored in a matrix on the server, the block components are stored in a dictionary,
 both of these are then used to build the Grid object with describes the entire Grid, after that this object is 
converted to a JSON string representation to be sent to the client. Once the data reaches the client the JSON is converted
into a Grid object which will have all the specifications for the Grid and then a custom stateful widget class GridView is 
created that can transform the data in the Grid object into layout.
```

### How to use?
#### Loading a grid
To load and display the grid widget on the screen
1. Create a Grid object.
```dart
...
class MyApp extends StatelessWidget {
  Grid grid;
...
```
2. Initialize the Grid object using the ```getInstance()``` static method in the page widget's ```build()``` method (if stateless) or ```initState()``` method (if stateful)
```dart
grid = Grid.getInstance();
```

3. To load a grid layour from the grid server, call the ```loadGrid(gridName)``` method on the Grid object
```dart
grid.loadGrid(gridName)
```

#### Creating a new grid
To create a new grid, call the Grid's ```createAndSaveNewGrid(numberOfColumns, numberOfRows, gridName)``` method to create and display a new Grid.

#### Toggling edit mode
To toggle in/out of the Grid's edit mode, call the Grid's ```toggleEditMode()``` method. Once in edit mode, there are already available default gestures avaiable, those of which include:
1. **Hold to drag**: Holding on a block will enable it to be moved and placed in a different location
![holding a block to move it to another position](assets/moving_block.gif)


2. **Double tap to delete**: Double tapping on a block will cause it to be deleted
![double tapping a block to delete it](assets/deleting_block.gif)


### Changing server address data
To change the server address and port, head over to the network_config.dart file.

Change ```serverPort``` to change the port of the Grid server and Change the ```serverAddr``` to change the server's address

###### Reminder: The column is horizontal, row is vertical.
