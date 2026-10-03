class ContentBlockModel {
  final String type; // text | image
  final String? text;
  final String? imageUrl;
  final String style; // heading1 | heading2 | body | emphasis | quote
  final String font; // modern | classic | comfort
  final double? size;
  final String weight; // normal | bold
  final bool italic;
  final String align; // left | center
  final String? color;

  const ContentBlockModel({
    required this.type,
    this.text,
    this.imageUrl,
    this.style = 'body',
    this.font = 'modern',
    this.size,
    this.weight = 'normal',
    this.italic = false,
    this.align = 'left',
    this.color,
  });

  factory ContentBlockModel.fromJson(Map<String, dynamic> json) {
    return ContentBlockModel(
      type: json['type'] as String? ?? 'text',
      text: json['text'] as String?,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      style: json['style'] as String? ?? 'body',
      font: json['font'] as String? ?? 'modern',
      size: (json['size'] as num?)?.toDouble(),
      weight: json['weight'] as String? ?? 'normal',
      italic: json['italic'] as bool? ?? false,
      align: json['align'] as String? ?? 'left',
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (text != null) 'text': text,
      if (imageUrl != null) 'image_url': imageUrl,
      'style': style,
      'font': font,
      if (size != null) 'size': size,
      'weight': weight,
      'italic': italic,
      'align': align,
      if (color != null) 'color': color,
    };
  }

  static ContentBlockModel textBlock(
    String text, {
    String style = 'body',
    String font = 'modern',
    double? size,
    String weight = 'normal',
    bool italic = false,
    String align = 'left',
  }) {
    return ContentBlockModel(
      type: 'text',
      text: text,
      style: style,
      font: font,
      size: size,
      weight: weight,
      italic: italic,
      align: align,
    );
  }

  static ContentBlockModel imageBlock(String url) {
    return ContentBlockModel(type: 'image', imageUrl: url);
  }
}
