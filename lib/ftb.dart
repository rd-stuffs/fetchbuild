// SPDX-License-Identifier: Apache-2.0

library ftb;

import 'package:http/http.dart' as http;

// 256KB
const int _fetchChunkBytesDefault = 256 * 1024;

List<String> _matchPrefixes = [
  'post-build',
  'pre-build',
  'pre-device',
  'post-build-incremental',
  'post-sdk-level',
  'post-security-patch-level',
  'post-timestamp',
];

List<int> _matchSuffix = [0x0a]; // newline

Future<Map<String, String>?> getPostBuildFromUrl(String url,
    {List<String>? extraKeys}) async {
  // Check if the server supports range requests
  // If it doesn't we can't use this method
  if (!await isRangeSupported(url)) {
    return null;
  }

  // Fetch the first 256KB of the file or the whole file if it's smaller
  // This will prevent errors if the file is smaller than 256KB (which is unlikely)
  int? fileSize = await getFileSize(url);

  if (fileSize == null) {
    print('Failed to get file size');
    return null;
  }

  int fetchChunkBytes =
      fileSize < _fetchChunkBytesDefault ? fileSize : _fetchChunkBytesDefault;

  Map<String, String> headers = {
    'Accept-Encoding': 'identity',
    'Range': 'bytes=0-$fetchChunkBytes' // we only need the first 1MB
  };

  http.Response response = await http.get(Uri.parse(url), headers: headers);

  if (response.statusCode == 200 || response.statusCode == 206) {
    // Add extra keys
    List<String> allPrefixes = List.from(_matchPrefixes);
    if (extraKeys != null) {
      allPrefixes.addAll(extraKeys);
    }

    Map<String, String> result = {};

    for (final prefix in allPrefixes) {
      var prefixCodeUnits = '$prefix='.codeUnits;
      int matchIndex = 0;
      int fileIndex = -1;

      for (var i = 0; i < response.bodyBytes.length; i++) {
        if (matchIndex == prefixCodeUnits.length) break;
        if (response.bodyBytes[i] == prefixCodeUnits[matchIndex]) {
          matchIndex++;

          if (matchIndex == prefixCodeUnits.length) {
            fileIndex = i + 1;
            break;
          }
        } else {
          matchIndex = 0;
        }
      }

      if (fileIndex != -1) {
        // We have a match, now we need to find the end of the string
        for (var i = fileIndex; i < response.bodyBytes.length; i++) {
          if (response.bodyBytes[i] == _matchSuffix[0]) {
            result[prefix.replaceAll('=', '')] = String.fromCharCodes(response
                .bodyBytes
                .sublist(fileIndex, i - _matchSuffix.length + 1));
            break;
          }
        }
      }
    }

    return result;
  } else {
    // Download failed, no fun
    return null;
  }
}

Future<int?> getFileSize(String url) async {
  http.Response response = await http.head(Uri.parse(url), headers: {
    'Accept-Encoding': 'identity',
  });
  if (response.statusCode == 200) {
    return int.parse(response.headers['content-length']!);
  } else {
    return null;
  }
}

Future<bool> isRangeSupported(String url) async {
  // Check if server reports accept-ranges: bytes
  http.Response response = await http.head(Uri.parse(url), headers: {
    'Accept-Encoding': 'identity',
  });
  if (response.statusCode == 200) {
    return response.headers['accept-ranges'] == 'bytes';
  } else {
    return false;
  }
}
