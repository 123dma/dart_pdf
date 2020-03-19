/*
 * Copyright (C) 2017, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ignore_for_file: omit_local_variable_types

part of pdf;

class PdfStream {
  static const int precision = 5;

  static const int _grow = 65536;

  Uint8List _stream = Uint8List(_grow);

  int _offset = 0;

  void _ensureCapacity(int size) {
    if (_stream.length - _offset >= size) {
      return;
    }

    final int newSize = math.max(_offset + size + _grow, _offset * 2);
    final Uint8List newBuffer = Uint8List(newSize);
    newBuffer.setAll(0, _stream);
    _stream = newBuffer;
  }

  void putByte(int s) {
    _ensureCapacity(1);
    _stream[_offset++] = s;
  }

  void putBytes(List<int> s) {
    _ensureCapacity(s.length);
    _stream.setAll(_offset, s);
    _offset += s.length;
  }

  void setBytes(int offset, Iterable<int> iterable) {
    _stream.setAll(offset, iterable);
  }

  void putStream(PdfStream s) {
    putBytes(s._stream);
  }

  int get offset => _offset;

  Uint8List output() => _stream.sublist(0, _offset);

  void putString(String s) {
    for (int codeUnit in s.codeUnits) {
      if (codeUnit <= 0x7f) {
        putByte(codeUnit);
      } else {
        putByte(0x20);
      }
    }
  }

  void putNum(double d) {
    assert(d != double.infinity);
    putString(d.toStringAsFixed(precision));
  }

  void putNumList(List<double> d) {
    putString(d.map((double v) {
      assert(v != double.infinity);
      return v.toStringAsFixed(precision);
    }).join(' '));
  }

  /// Escape special characters
  /// \ddd Character code ddd (octal)
  void putTextBytes(List<int> s) {
    for (int c in s) {
      switch (c) {
        case 0x0a: // \n Line feed (LF)
          putByte(0x5c);
          putByte(0x6e);
          break;
        case 0x0d: // \r Carriage return (CR)
          putByte(0x5c);
          putByte(0x72);
          break;
        case 0x09: // \t Horizontal tab (HT)
          putByte(0x5c);
          putByte(0x74);
          break;
        case 0x08: // \b Backspace (BS)
          putByte(0x5c);
          putByte(0x62);
          break;
        case 0x0c: // \f Form feed (FF)
          putByte(0x5c);
          putByte(0x66);
          break;
        case 0x28: // \( Left parenthesis
          putByte(0x5c);
          putByte(0x28);
          break;
        case 0x29: // \) Right parenthesis
          putByte(0x5c);
          putByte(0x29);
          break;
        case 0x5c: // \\ Backslash
          putByte(0x5c);
          putByte(0x5c);
          break;
        default:
          putByte(c);
      }
    }
  }
}
