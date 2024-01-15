// SPDX-License-Identifier: Apache-2.0

import 'package:fetchbuild/ftb.dart' as ftb;

void main(List<String> arguments) {
  // Argument 1: URL

  if (arguments.isEmpty) {
    print('Usage: fetchbuild <URL> [extra keys]');
    return;
  }

  String url = arguments[0];

  List<String>? extraKeys;

  if (arguments.length > 1) {
    extraKeys = arguments.sublist(1);
  }

  ftb.getPostBuildFromUrl(url, extraKeys: extraKeys).then((postBuild) {
    if (postBuild == null) {
      print('No post-build found');
      return;
    }

    for (final key in postBuild.keys) {
      print('$key: ${postBuild[key]}');
    }
  });
}
