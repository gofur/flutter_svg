import 'dart:ui';

import 'package:xml/xml.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:vector_math/vector_math_64.dart';

import 'avd/xml_parsers.dart';
import 'utilities/xml.dart';
import 'vector_drawable.dart';

class DrawableAvdRoot extends DrawableRoot {
  const DrawableAvdRoot(DrawableViewport viewBox, List<Drawable> children,
      DrawableDefinitionServer definitions, DrawableStyle style)
      : super(viewBox, children, definitions, style);
}

/// An SVG Shape element that will be drawn to the canvas.
class DrawableAvdPath extends DrawableShape {
  const DrawableAvdPath(Path path, DrawableStyle style) : super(path, style);

  /// Creates a [DrawableAvdPath] from an XML <path> element
  factory DrawableAvdPath.fromXml(XmlElement el) {
    final String d =
        getAttribute(el, 'pathData', def: '', namespace: androidNS);
    final Path path = parseSvgPathData(d);
    assert(path != null);

    path.fillType = parsePathFillType(el);
    final DrawablePaint stroke = parseStroke(el, path.getBounds());
    final DrawablePaint fill = parseFill(el, path.getBounds());

    return DrawableAvdPath(
      path,
      DrawableStyle(stroke: stroke, fill: fill),
    );
  }
}

/// Creates a [Drawable] from an SVG <g> or shape element.  Also handles parsing <defs> and gradients.
///
/// If an unsupported element is encountered, it will be created as a [DrawableNoop].
Drawable parseAvdElement(XmlElement el, Rect bounds) {
  if (el.name.local == 'path') {
    return DrawableAvdPath.fromXml(el);
  } else if (el.name.local == 'group') {
    return parseAvdGroup(el, bounds);
  }
  // TODO: clipPath
  print('Unhandled element ${el.name.local}');
  return DrawableNoop(el.name.local);
}

/// Parses an AVD <group> element.
Drawable parseAvdGroup(XmlElement el, Rect bounds) {
  final List<Drawable> children = <Drawable>[];
  for (XmlNode child in el.children) {
    if (child is XmlElement) {
      final Drawable el = parseAvdElement(child, bounds);
      if (el != null) {
        children.add(el);
      }
    }
  }

  final Matrix4 transform = parseTransform(el);

  final DrawablePaint fill = parseFill(el, bounds);
  final DrawablePaint stroke = parseStroke(el, bounds);

  return DrawableGroup(
    children,
    DrawableStyle(
      transform: transform?.storage,
      stroke: stroke,
      fill: fill,
      groupOpacity: 1.0,
    ),
  );
}
