import 'package:flutter/material.dart';

// ─── id generator ──────────────────────────────────────────────────────────
int _seq = 0;
String newElementId() =>
    'e${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${(_seq++).toRadixString(36)}';

// ─── element kinds ─────────────────────────────────────────────────────────
enum ElementKind {
  // Text
  text,
  heading1,
  heading2,
  heading3,
  quote,
  callout,
  code,
  bulletList,
  numberedList,
  wordArt,
  // Visuals
  image,
  divider,
  shapeRect,
  shapeOval,
  signature,
  // Data
  table,
  barChart,
  lineChart,
  pieChart,
  kpi,
  // Misc
  attachment,
  columns,
  qrCode,
}

extension ElementKindMeta on ElementKind {
  String get label {
    switch (this) {
      case ElementKind.text:
        return 'Text';
      case ElementKind.heading1:
        return 'Heading 1';
      case ElementKind.heading2:
        return 'Heading 2';
      case ElementKind.heading3:
        return 'Heading 3';
      case ElementKind.quote:
        return 'Quote';
      case ElementKind.callout:
        return 'Callout';
      case ElementKind.code:
        return 'Code';
      case ElementKind.bulletList:
        return 'Bulleted list';
      case ElementKind.numberedList:
        return 'Numbered list';
      case ElementKind.wordArt:
        return 'Word art';
      case ElementKind.image:
        return 'Image';
      case ElementKind.divider:
        return 'Divider';
      case ElementKind.shapeRect:
        return 'Rectangle';
      case ElementKind.shapeOval:
        return 'Ellipse';
      case ElementKind.signature:
        return 'Signature';
      case ElementKind.table:
        return 'Table';
      case ElementKind.barChart:
        return 'Bar chart';
      case ElementKind.lineChart:
        return 'Line chart';
      case ElementKind.pieChart:
        return 'Pie chart';
      case ElementKind.kpi:
        return 'KPI card';
      case ElementKind.attachment:
        return 'Attachment';
      case ElementKind.columns:
        return 'Columns';
      case ElementKind.qrCode:
        return 'QR code';
    }
  }

  IconData get icon {
    switch (this) {
      case ElementKind.text:
        return Icons.notes_rounded;
      case ElementKind.heading1:
        return Icons.title_rounded;
      case ElementKind.heading2:
        return Icons.text_fields_rounded;
      case ElementKind.heading3:
        return Icons.short_text_rounded;
      case ElementKind.quote:
        return Icons.format_quote_rounded;
      case ElementKind.callout:
        return Icons.lightbulb_outline_rounded;
      case ElementKind.code:
        return Icons.code_rounded;
      case ElementKind.bulletList:
        return Icons.format_list_bulleted_rounded;
      case ElementKind.numberedList:
        return Icons.format_list_numbered_rounded;
      case ElementKind.wordArt:
        return Icons.auto_awesome_rounded;
      case ElementKind.image:
        return Icons.image_outlined;
      case ElementKind.divider:
        return Icons.horizontal_rule_rounded;
      case ElementKind.shapeRect:
        return Icons.crop_square_rounded;
      case ElementKind.shapeOval:
        return Icons.circle_outlined;
      case ElementKind.signature:
        return Icons.draw_outlined;
      case ElementKind.table:
        return Icons.table_chart_outlined;
      case ElementKind.barChart:
        return Icons.bar_chart_rounded;
      case ElementKind.lineChart:
        return Icons.show_chart_rounded;
      case ElementKind.pieChart:
        return Icons.pie_chart_outline_rounded;
      case ElementKind.kpi:
        return Icons.insights_rounded;
      case ElementKind.attachment:
        return Icons.attach_file_rounded;
      case ElementKind.columns:
        return Icons.view_column_outlined;
      case ElementKind.qrCode:
        return Icons.qr_code_2_rounded;
    }
  }

  String get category {
    switch (this) {
      case ElementKind.text:
      case ElementKind.heading1:
      case ElementKind.heading2:
      case ElementKind.heading3:
      case ElementKind.quote:
      case ElementKind.callout:
      case ElementKind.code:
      case ElementKind.bulletList:
      case ElementKind.numberedList:
      case ElementKind.wordArt:
        return 'Text';
      case ElementKind.image:
      case ElementKind.divider:
      case ElementKind.shapeRect:
      case ElementKind.shapeOval:
      case ElementKind.signature:
        return 'Visuals';
      case ElementKind.table:
      case ElementKind.barChart:
      case ElementKind.lineChart:
      case ElementKind.pieChart:
      case ElementKind.kpi:
        return 'Data';
      case ElementKind.attachment:
      case ElementKind.columns:
      case ElementKind.qrCode:
        return 'Misc';
    }
  }

  bool get isTextual {
    return category == 'Text';
  }

  Size get defaultSize {
    switch (this) {
      case ElementKind.heading1:
        return const Size(560, 64);
      case ElementKind.heading2:
        return const Size(520, 52);
      case ElementKind.heading3:
        return const Size(480, 44);
      case ElementKind.text:
        return const Size(440, 90);
      case ElementKind.quote:
        return const Size(480, 100);
      case ElementKind.callout:
        return const Size(480, 110);
      case ElementKind.code:
        return const Size(520, 140);
      case ElementKind.bulletList:
      case ElementKind.numberedList:
        return const Size(440, 130);
      case ElementKind.wordArt:
        return const Size(420, 92);
      case ElementKind.image:
        return const Size(360, 220);
      case ElementKind.divider:
        return const Size(560, 24);
      case ElementKind.shapeRect:
      case ElementKind.shapeOval:
        return const Size(220, 160);
      case ElementKind.signature:
        return const Size(280, 110);
      case ElementKind.table:
        return const Size(560, 200);
      case ElementKind.barChart:
      case ElementKind.lineChart:
        return const Size(520, 280);
      case ElementKind.pieChart:
        return const Size(360, 320);
      case ElementKind.kpi:
        return const Size(220, 130);
      case ElementKind.attachment:
        return const Size(320, 64);
      case ElementKind.columns:
        return const Size(640, 240);
      case ElementKind.qrCode:
        return const Size(160, 160);
    }
  }
}

// ─── element model ─────────────────────────────────────────────────────────
class DesignElement {
  String id;
  ElementKind kind;
  double x, y, width, height;
  int z;

  // text content
  String text;

  // text style
  double fontSize;
  String fontFamily;
  bool bold;
  bool italic;
  bool underline;
  String? colorHex; // 0xAARRGGBB string
  String? bgHex;
  String? borderHex;
  double borderWidth;
  double borderRadius;
  String align; // 'left' | 'center' | 'right' | 'justify'
  double lineHeight;
  double opacity;
  double rotation; // degrees

  // type-specific data
  Map<String, dynamic> data;

  DesignElement({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.z = 0,
    this.text = '',
    this.fontSize = 14,
    this.fontFamily = 'Inter',
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.colorHex,
    this.bgHex,
    this.borderHex,
    this.borderWidth = 0,
    this.borderRadius = 8,
    this.align = 'left',
    this.lineHeight = 1.45,
    this.opacity = 1.0,
    this.rotation = 0,
    Map<String, dynamic>? data,
  }) : data = data ?? <String, dynamic>{};

  Rect get rect => Rect.fromLTWH(x, y, width, height);

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'x': x,
        'y': y,
        'w': width,
        'h': height,
        'z': z,
        if (text.isNotEmpty) 'text': text,
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        if (bold) 'bold': true,
        if (italic) 'italic': true,
        if (underline) 'underline': true,
        if (colorHex != null) 'color': colorHex,
        if (bgHex != null) 'bg': bgHex,
        if (borderHex != null) 'border': borderHex,
        if (borderWidth != 0) 'borderW': borderWidth,
        if (borderRadius != 8) 'radius': borderRadius,
        if (align != 'left') 'align': align,
        if (lineHeight != 1.45) 'lh': lineHeight,
        if (opacity != 1.0) 'opacity': opacity,
        if (rotation != 0) 'rot': rotation,
        if (data.isNotEmpty) 'data': data,
      };

  factory DesignElement.fromJson(Map<String, dynamic> j) {
    return DesignElement(
      id: (j['id'] as String?) ?? newElementId(),
      kind: ElementKind.values.firstWhere(
        (k) => k.name == (j['kind'] as String?),
        orElse: () => ElementKind.text,
      ),
      x: (j['x'] as num?)?.toDouble() ?? 32,
      y: (j['y'] as num?)?.toDouble() ?? 32,
      width: (j['w'] as num?)?.toDouble() ?? 360,
      height: (j['h'] as num?)?.toDouble() ?? 80,
      z: (j['z'] as num?)?.toInt() ?? 0,
      text: (j['text'] as String?) ?? '',
      fontSize: (j['fontSize'] as num?)?.toDouble() ?? 14,
      fontFamily: (j['fontFamily'] as String?) ?? 'Inter',
      bold: (j['bold'] as bool?) ?? false,
      italic: (j['italic'] as bool?) ?? false,
      underline: (j['underline'] as bool?) ?? false,
      colorHex: j['color'] as String?,
      bgHex: j['bg'] as String?,
      borderHex: j['border'] as String?,
      borderWidth: (j['borderW'] as num?)?.toDouble() ?? 0,
      borderRadius: (j['radius'] as num?)?.toDouble() ?? 8,
      align: (j['align'] as String?) ?? 'left',
      lineHeight: (j['lh'] as num?)?.toDouble() ?? 1.45,
      opacity: (j['opacity'] as num?)?.toDouble() ?? 1.0,
      rotation: (j['rot'] as num?)?.toDouble() ?? 0,
      data: (j['data'] is Map)
          ? Map<String, dynamic>.from(j['data'] as Map)
          : <String, dynamic>{},
    );
  }

  DesignElement copy({String? newId}) => DesignElement(
        id: newId ?? newElementId(),
        kind: kind,
        x: x,
        y: y,
        width: width,
        height: height,
        z: z,
        text: text,
        fontSize: fontSize,
        fontFamily: fontFamily,
        bold: bold,
        italic: italic,
        underline: underline,
        colorHex: colorHex,
        bgHex: bgHex,
        borderHex: borderHex,
        borderWidth: borderWidth,
        borderRadius: borderRadius,
        align: align,
        lineHeight: lineHeight,
        opacity: opacity,
        rotation: rotation,
        data: Map<String, dynamic>.from(data),
      );
}

// ─── page metadata ─────────────────────────────────────────────────────────
enum PageSize {
  a4Portrait,
  a4Landscape,
  letterPortrait,
  letterLandscape,
}

extension PageSizeMeta on PageSize {
  Size get pixels {
    switch (this) {
      case PageSize.a4Portrait:
        return const Size(794, 1123); // 96 DPI A4
      case PageSize.a4Landscape:
        return const Size(1123, 794);
      case PageSize.letterPortrait:
        return const Size(816, 1056);
      case PageSize.letterLandscape:
        return const Size(1056, 816);
    }
  }

  String get label {
    switch (this) {
      case PageSize.a4Portrait:
        return 'A4 · Portrait';
      case PageSize.a4Landscape:
        return 'A4 · Landscape';
      case PageSize.letterPortrait:
        return 'Letter · Portrait';
      case PageSize.letterLandscape:
        return 'Letter · Landscape';
    }
  }

  String get shortLabel {
    switch (this) {
      case PageSize.a4Portrait:
        return 'A4';
      case PageSize.a4Landscape:
        return 'A4 L';
      case PageSize.letterPortrait:
        return 'US';
      case PageSize.letterLandscape:
        return 'US L';
    }
  }

  bool get isLandscape =>
      this == PageSize.a4Landscape || this == PageSize.letterLandscape;
}

// ─── helpers ───────────────────────────────────────────────────────────────
String designColorToHex(Color c) {
  final argb = ((c.a * 255).round() << 24) |
      ((c.r * 255).round() << 16) |
      ((c.g * 255).round() << 8) |
      (c.b * 255).round();
  return '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

Color hexToColor(String? hex, Color fallback) {
  if (hex == null) return fallback;
  var s = hex.trim();
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 6) s = 'FF$s';
  final v = int.tryParse(s, radix: 16);
  return v == null ? fallback : Color(v);
}

const List<String> kFontFamilies = [
  'Inter',
  'Roboto',
  'Lato',
  'Open Sans',
  'Merriweather',
  'Playfair Display',
  'Source Sans 3',
  'Source Code Pro',
  'Poppins',
  'Nunito',
  'Montserrat',
  'Vazirmatn',
];
