// lib/core/models/content_block_model.dart

class ContentBlockModel {
  final String type; // text | image
  final String? text;
  final String? imageUrl;
  final String style;
  final String font;
  final double? size;
  final String weight;
  final bool italic;
  final String align;
  final String? color;
  
  final int schemaVersion;

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
    this.schemaVersion = 1,
  });

  bool get isText => type == 'text';
  bool get isImage => type == 'image';

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
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
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
      'schema_version': schemaVersion,
    };
  }

  ContentBlockModel copyWith({
    String? type,
    String? text,
    String? imageUrl,
    String? style,
    String? font,
    double? size,
    String? weight,
    bool? italic,
    String? align,
    String? color,
    int? schemaVersion,
  }) {
    return ContentBlockModel(
      type: type ?? this.type,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      style: style ?? this.style,
      font: font ?? this.font,
      size: size ?? this.size,
      weight: weight ?? this.weight,
      italic: italic ?? this.italic,
      align: align ?? this.align,
      color: color ?? this.color,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  static ContentBlockModel textBlock(String text, {String style = 'body', String font = 'modern', double? size, String weight = 'normal', bool italic = false, String align = 'left'}) {
    return ContentBlockModel(type: 'text', text: text, style: style, font: font, size: size, weight: weight, italic: italic, align: align);
  }

  static ContentBlockModel heading(String text, {int level = 1}) {
    return ContentBlockModel(type: 'text', text: text, style: level == 1 ? 'heading1' : 'heading2', font: 'classic', weight: 'bold', align: 'center', size: level == 1 ? 26 : 20);
  }

  static ContentBlockModel body(String text) {
    return ContentBlockModel.textBlock(text, style: 'body', font: 'modern', size: 16);
  }

  static ContentBlockModel emphasis(String text) {
    return ContentBlockModel.textBlock(text, style: 'emphasis', font: 'modern', weight: 'bold', size: 17);
  }

  static ContentBlockModel quote(String text) {
    return ContentBlockModel.textBlock(text, style: 'quote', font: 'classic', italic: true, size: 16);
  }

  static ContentBlockModel imageBlock(String url) {
    return ContentBlockModel(type: 'image', imageUrl: url);
  }
}
