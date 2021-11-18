class CombinedBlockContent {
   String content_type;
   dynamic content;

  CombinedBlockContent(String content_type, dynamic content) {
    this.content_type = content_type;
    this.content = content;
  }

  Map<String, dynamic> toJSON(CombinedBlockContent content) {
    return {"content_type": content_type, "content": content};
  }
}
