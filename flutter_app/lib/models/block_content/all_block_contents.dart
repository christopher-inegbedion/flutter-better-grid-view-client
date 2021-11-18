import '/models/block_content/color_combined_block_content.dart';
import '/models/block_content/image_carousel_block_content.dart';
import '/models/block_content/image_combined_block_content.dart';
import '/models/block_content/text_combined_block_content.dart';

class BlockContents {
  ///Creates the content objects from the JSON data
  static dynamic buildContentObject(String contentTag, Map<String, dynamic> contentValue) {
    Map<String, dynamic> contents = {
      "text": TextContent.fromJSON(contentValue),
      "color": ColorContent.fromJSON(contentValue),
      "image": ImageContent.fromJSON(contentValue),
      "image_carousel": ImageCarouselContent.fromJSON(contentValue)
    };

    return contents[contentTag];
  }
}
