/*
 * Copyright (C) 2017, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

part of pdf;

@immutable
class PdfRect {
  final double x, y, w, h;

  static const zero = PdfRect(0.0, 0.0, 0.0, 0.0);

  const PdfRect(this.x, this.y, this.w, this.h);

  factory PdfRect.fromLTRB(
      double left, double top, double right, double bottom) {
    return PdfRect(left, top, right - left, bottom - top);
  }

  factory PdfRect.fromPoints(PdfPoint offset, PdfPoint size) {
    return PdfRect(offset.x, offset.y, size.x, size.y);
  }

  double get l => x;
  double get b => y;
  double get r => x + w;
  double get t => y + h;

  @override
  String toString() => "PdfRect($x, $y, $w, $h)";

  PdfRect operator *(double factor) {
    return PdfRect(x * factor, y * factor, w * factor, h * factor);
  }

  PdfPoint get offset => PdfPoint(x, y);
  PdfPoint get size => PdfPoint(w, h);

  PdfPoint get topLeft => PdfPoint(x, y);
  PdfPoint get topRight => PdfPoint(r, y);
  PdfPoint get bottomLeft => PdfPoint(x, t);
  PdfPoint get bottomRight => PdfPoint(r, t);
}
