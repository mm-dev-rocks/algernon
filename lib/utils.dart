// SPDX-License-Identifier: GPL-3.0-only

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:intl/intl.dart' as intl;

import 'app_state.dart';
import 'constants.dart';

/// General helper/utility methods used in various places.
/// Sometimes this file gets copy/pasted between projects so some functions will be irrelevant/unused

String getMd5Hash(Object? input) {
  String string = input.toString();
  return md5.convert(utf8.encode(string)).toString().substring(0, ALGERNON.hashIdLength);
}

String printShortDuration(Duration duration) {
  String prefix = duration.isNegative ? '-' : '';
  String hours = duration.inHours > 0 ? "${duration.inHours.toString()}h${ALGERNON.thinSpace}" : '';
  String minutes = duration.inMinutes > 0
      ? "${duration.inMinutes.remainder(60).abs().toString()}m${ALGERNON.thinjkkSpace}"
      : '';
  String seconds =
      duration.inSeconds > 0 ? "${duration.inSeconds.remainder(60).abs().toString()}s" : '';

  return (hours.isEmpty && minutes.isEmpty && seconds.isEmpty)
      ? '?'
      : prefix + hours + minutes + seconds;
}

String printFullDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");

  String prefix = duration.isNegative ? '-' : '';
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());

  return "$prefix${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}

bool isAnAddedInfoFileExtension(String fileExtension) {
  return ALGERNON.addedInfoFileExtensions.contains(fileExtension);
}

bool isACueSheetFileExtension(String fileExtension) {
  return ALGERNON.cueSheetFileExtensions.contains(fileExtension);
}

//bool isABookMimeType(String mimeType) {
//  return ALGERNON.bookMimeTypes.contains(mimeType);
//}

bool isABookOrChapterMimeType(String mimeType) {
  return ALGERNON.bookOrChapterMimeTypes.contains(mimeType);
}

bool isACoverImageMimeType(String mimeType) {
  return ALGERNON.coverImageMimeTypes.contains(mimeType);
}

String trimLeadingAndTrailingSlashes(String text) {
  while (text.endsWith('/')) {
    text = text.substring(0, text.length - 1);
  }
  while (text.startsWith('/')) {
    //AppState.debug("leading slash");
    text = text.substring(1);
  }
  return text;
}

String decodeBytesToText(bytes) {
  String text = '';
  if (bytes.isNotEmpty) {
    AppState.log("Text file exists");
    try {
      text = ascii.decode(bytes);
    } catch (e) {
      AppState.log("ascii: $e");
    }
    if (text.isEmpty) {
      try {
        text = utf8.decode(bytes);
      } catch (e) {
        AppState.log("utf8: $e");
      }
    }
    if (text.isEmpty) {
      try {
        text = latin1.decode(bytes);
      } catch (e) {
        AppState.log("latin1: $e");
      }
    }
  } else {
    text = "[[INVALID]]";
  }
  return text;
}

double roundToDecimalPlaces(double number, int places) {
  return double.parse((number).toStringAsFixed(places));
}

Size measuredTextSize(context, text, textStyle) {
  return (TextPainter(
    text: TextSpan(
      text: text,
      style: textStyle,
    ),
    maxLines: 1,
    // ignore: deprecated_member_use
    textScaleFactor: MediaQuery.of(context).textScaleFactor,
    textDirection: TextDirection.ltr,
  )..layout())
      .size;
}

/// [substrings] may be individual words or groups of words.
String longestWord(List<String> substrings) {
  final String longestWord = substrings.join(' ').split(" ").reduce((a, b) {
    return a.length > b.length ? a : b;
  });

  return longestWord;
}

double paintedTextWidth(String text, TextStyle style) {
  TextPainter textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: style,
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );
  textPainter.layout();
  return textPainter.width;
}

String parseHtmlString(String htmlString) {
  final document = parse(htmlString);
  String parsedString = htmlString;
  if (document.body != null) {
    parsedString = parse(document.body!.text).documentElement!.text;
  }

  return parsedString;
}

double safeNorm(double normalised) =>
    (normalised == double.infinity || normalised.isNaN) ? 0 : normalised;

List<Widget> spacedWidgets(
        {required Iterable<Widget> children, double horizontalGap = 0, double verticalGap = 0}) =>
    children
        .expand((item) sync* {
          yield SizedBox(width: horizontalGap, height: verticalGap);
          yield item;
        })
        .skip(1)
        .toList();

/// Given a list of [TextSpan] widgets, return a list of the same widgets with extra [TextSpan]s
/// inserted inbetween all of the original children, to act as spacers.
List<TextSpan> spacedTextSpan({required Iterable<TextSpan> children, String spacer = ' '}) =>
    children
        .expand((item) sync* {
          yield TextSpan(text: spacer);
          yield item;
        })
        .skip(1)
        .toList();

List<String> prettyDateAndTimeFromUtcString(String utc) {
  //String response = '[NO PREVIOUS SCAN DATE AVAILABLE]';
  String date = '';
  String time = '';

  if (utc.contains(':') && utc.contains('-')) {
    [date, time] = utc.split(' ');
    var [yyyy, mm, dd] = date.split('-');

    date = intl.DateFormat.yMMMMd().format(DateTime(int.parse(yyyy), int.parse(mm), int.parse(dd)));
  }
  return [date, time];
}

/// Flutter can describe alignment in a rectangle with numbers from `-1` to `1`, with `-1` representing
/// the left (or top), and `1` representing the right (or bottom) of the rectangle.
/// Sometimes we want to take a normalised (0 - 1) number and convert it to work with this alignment
/// method. That's what this function is for.
double normalisedToAlignmentRectanglePos(double normalised) {
  return 2 * (normalised - 0.5);
}

/// Book file or directory names are used as titles. These often have characters which are
/// unnecessary, make the title longer or otherwise difficult to display in limited space. This
/// method gets rid of characters we don't want and and breaks the title up into parts (a bit like
/// main/sub/sub-sub, inferred via blunt heuristics but good enough for 'pretty display').
/// Regarding information loss, the unaltered filename is exposed in the UI in other places for
/// users who need to see it.
List<String> getCleanedTitleParts(String title) {
  String cleanedTitle = title.replaceAll("_", " ");

  /// Split on:
  ///   ` - `
  ///   ` - `
  ///   `(`
  ///   `)`
  ///   `[`
  ///   `]`

  const String tempDelimiter = "ALGERNON";
  final splitter = RegExp(
      // ignore: prefer_interpolation_to_compose_strings
      r'(, |- | -| - | ~ |\(|\)|\[|\]|mp3\b|\.opus|\.m4b\b|\.mp3\b|128k|64k|' + tempDelimiter + ')',
      caseSensitive: false);
  final splitterNumAtStart = RegExp(r'^[0-9]+ ');
  final splitterPartNumAtEnd2 = RegExp(
      r'\b([0-9]+)|(disc [0-9]+)|(series [0-9]+)|(volume [0-9]+)|(part [0-9]+)$',
      caseSensitive: false);

  cleanedTitle = cleanedTitle.splitMapJoin(splitterNumAtStart,
      onMatch: (m) => '${m[0]!.substring(0, m[0]!.length - 1)}$tempDelimiter',
      onNonMatch: (n) => n);

  cleanedTitle = cleanedTitle.splitMapJoin(splitterPartNumAtEnd2,
      onMatch: (m) => '$tempDelimiter${m[0]!}', onNonMatch: (n) => n);

  List<String> titleParts = cleanedTitle.split(splitter);
  titleParts.removeWhere((part) => part.trim().isEmpty);

  return titleParts.map((String part) => part.trim()).toList();
}
