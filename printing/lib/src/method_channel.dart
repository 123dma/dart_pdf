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

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/rendering.dart' show Rect;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';

import 'callback.dart';
import 'interface.dart';
import 'print_job.dart';
import 'printer.dart';
import 'printing_info.dart';
import 'raster.dart';

const MethodChannel _channel = MethodChannel('net.nfet.printing');

/// An implementation of [PrintingPlatform] that uses method channels.
class MethodChannelPrinting extends PrintingPlatform {
  MethodChannelPrinting() : super() {
    _channel.setMethodCallHandler(_handleMethod);
  }

  static final Map<int, PrintJob> _printJobs = <int, PrintJob>{};
  static int _jobIndex = 0;

  /// Callbacks from platform plugins
  static Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onLayout':
        final PrintJob job = _printJobs[call.arguments['job']];
        try {
          final PdfPageFormat format = PdfPageFormat(
            call.arguments['width'],
            call.arguments['height'],
            marginLeft: call.arguments['marginLeft'],
            marginTop: call.arguments['marginTop'],
            marginRight: call.arguments['marginRight'],
            marginBottom: call.arguments['marginBottom'],
          );

          final List<int> bytes = await job.onLayout(format);

          if (bytes == null) {
            throw 'onLayout returned null';
          }

          return Uint8List.fromList(bytes);
        } catch (e) {
          return e.toString();
        }
        break;
      case 'onCompleted':
        final bool completed = call.arguments['completed'];
        final String error = call.arguments['error'];
        final PrintJob job = _printJobs[call.arguments['job']];
        if (completed == false && error != null) {
          job.onCompleted.completeError(error);
        } else {
          job.onCompleted.complete(completed);
        }
        break;
      case 'onHtmlRendered':
        final PrintJob job = _printJobs[call.arguments['job']];
        job.onHtmlRendered.complete(call.arguments['doc']);
        break;
      case 'onHtmlError':
        final PrintJob job = _printJobs[call.arguments['job']];
        job.onHtmlRendered.completeError(call.arguments['error']);
        break;
      case 'onPageRasterized':
        final PrintJob job = _printJobs[call.arguments['job']];
        final PdfRaster raster = PdfRaster(
          call.arguments['width'],
          call.arguments['height'],
          call.arguments['image'],
        );
        job.onPageRasterized.add(raster);
        break;
      case 'onPageRasterEnd':
        final PrintJob job = _printJobs[call.arguments['job']];
        job.onPageRasterized.close();
        _printJobs.remove(job.index);
        break;
    }
  }

  static PrintJob _newPrintJob(PrintJob job) {
    job.index = _jobIndex++;
    _printJobs[job.index] = job;
    return job;
  }

  @override
  Future<PrintingInfo> info() async {
    _channel.setMethodCallHandler(_handleMethod);
    Map<dynamic, dynamic> result;

    try {
      result = await _channel.invokeMethod(
        'printingInfo',
        <String, dynamic>{},
      );
    } catch (e) {
      print('Error getting printing info: $e');
      return PrintingInfo.unavailable;
    }

    return PrintingInfo.fromMap(result);
  }

  @override
  Future<bool> layoutPdf(
    LayoutCallback onLayout,
    String name,
    PdfPageFormat format,
  ) async {
    final PrintJob job = _newPrintJob(PrintJob(
      onCompleted: Completer<bool>(),
      onLayout: onLayout,
    ));

    final Map<String, dynamic> params = <String, dynamic>{
      'name': name,
      'job': job.index,
      'width': format.width,
      'height': format.height,
      'marginLeft': format.marginLeft,
      'marginTop': format.marginTop,
      'marginRight': format.marginRight,
      'marginBottom': format.marginBottom,
    };

    await _channel.invokeMethod<int>('printPdf', params);
    try {
      return await job.onCompleted.future;
    } finally {
      _printJobs.remove(job.index);
    }
  }

  @override
  Future<Printer> pickPrinter(Rect bounds) async {
    final Map<String, dynamic> params = <String, dynamic>{
      'x': bounds.left,
      'y': bounds.top,
      'w': bounds.width,
      'h': bounds.height,
    };
    final Map<dynamic, dynamic> printer = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('pickPrinter', params);
    if (printer == null) {
      return null;
    }
    return Printer(
      url: printer['url'],
      name: printer['name'],
      model: printer['model'],
      location: printer['location'],
    );
  }

  @override
  Future<bool> directPrintPdf(
    Printer printer,
    LayoutCallback onLayout,
    String name,
    PdfPageFormat format,
  ) async {
    final PrintJob job = _newPrintJob(PrintJob(
      onCompleted: Completer<bool>(),
    ));

    final List<int> bytes = await onLayout(format);
    if (bytes == null) {
      return false;
    }

    final Map<String, dynamic> params = <String, dynamic>{
      'name': name,
      'printer': printer.url,
      'doc': Uint8List.fromList(bytes),
      'job': job.index,
    };
    await _channel.invokeMethod<int>('directPrintPdf', params);
    final bool result = await job.onCompleted.future;
    _printJobs.remove(job.index);
    return result;
  }

  @override
  Future<bool> sharePdf(
    List<int> bytes,
    String filename,
    Rect bounds,
  ) async {
    final Map<String, dynamic> params = <String, dynamic>{
      'doc': Uint8List.fromList(bytes),
      'name': filename,
      'x': bounds.left,
      'y': bounds.top,
      'w': bounds.width,
      'h': bounds.height,
    };
    return await _channel.invokeMethod<int>('sharePdf', params) != 0;
  }

  @override
  Future<List<int>> convertHtml(
      String html, String baseUrl, PdfPageFormat format) async {
    final PrintJob job = _newPrintJob(PrintJob(
      onHtmlRendered: Completer<List<int>>(),
    ));

    final Map<String, dynamic> params = <String, dynamic>{
      'html': html,
      'baseUrl': baseUrl,
      'width': format.width,
      'height': format.height,
      'marginLeft': format.marginLeft,
      'marginTop': format.marginTop,
      'marginRight': format.marginRight,
      'marginBottom': format.marginBottom,
      'job': job.index,
    };

    await _channel.invokeMethod<void>('convertHtml', params);
    final List<int> result = await job.onHtmlRendered.future;
    _printJobs.remove(job.index);
    return result;
  }

  @override
  Stream<PdfRaster> raster(
    List<int> document,
    List<int> pages,
    double dpi,
  ) {
    final PrintJob job = _newPrintJob(PrintJob(
      onPageRasterized: StreamController<PdfRaster>(),
    ));

    final Map<String, dynamic> params = <String, dynamic>{
      'doc': Uint8List.fromList(document),
      'pages': pages,
      'scale': dpi / PdfPageFormat.inch,
      'job': job.index,
    };

    _channel.invokeMethod<void>('rasterPdf', params);
    return job.onPageRasterized.stream;
  }
}
