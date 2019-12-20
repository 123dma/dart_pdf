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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';
import 'package:test/test.dart';

Document pdf;

void main() {
  setUpAll(() {
    Document.debug = true;
    pdf = Document();
  });

  test('Pdf Jpeg Download', () async {
    final PdfImage image = PdfImage.jpeg(
      pdf.document,
      image: await download('https://www.nfet.net/nfet.jpg'),
    );

    pdf.addPage(Page(
      build: (Context context) => Center(child: Image(image)),
    ));
  });

  test('Pdf Jpeg Orientations', () {
    pdf.addPage(
      Page(
        build: (Context context) => GridView(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          children: List<Widget>.generate(
            images.length,
            (int index) => Image(
              PdfImage.jpeg(
                pdf.document,
                image: base64.decode(images[index]),
              ),
            ),
          ),
        ),
      ),
    );
  });

  tearDownAll(() {
    final File file = File('jpeg.pdf');
    file.writeAsBytesSync(pdf.save());
  });
}

Future<Uint8List> download(String url) async {
  final HttpClient client = HttpClient();
  final HttpClientRequest request = await client.getUrl(Uri.parse(url));
  final HttpClientResponse response = await request.close();
  final BytesBuilder builder = await response.fold(
      BytesBuilder(), (BytesBuilder b, List<int> d) => b..add(d));
  final List<int> data = builder.takeBytes();
  return Uint8List.fromList(data);
}

const List<String> images = <String>[
  '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',
];
