// Packages imports

import 'package:flutter/cupertino.dart';

// Utility local imports

import 'package:mockingjae2_mobile/utils/colors.dart';
import 'package:mockingjae2_mobile/utils/ui.dart';
import 'package:mockingjae2_mobile/utils/utils.dart';
import 'package:mockingjae2_mobile/src/components/icons.dart';

// Scroll Controller and Statusbar local import

import 'package:mockingjae2_mobile/src/controller/scrollControlers.dart';
import 'package:mockingjae2_mobile/src/bodyWidget/ScrollsWidget/StatusBar.dart';


// Scrolls Button related local import

import 'package:mockingjae2_mobile/src/components/buttons.dart';

class ScrollsRelatedInfoButtonWrap extends StatelessWidget {
  const ScrollsRelatedInfoButtonWrap({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: const [
        ScrollsInfoButton(
          iconData: CupertinoIcons.arrow_2_circlepath, 
          statistic: 61),
        ScrollsInfoButton(
          iconData: CupertinoIcons.heart,
          statistic: 3)
      ],
    );
  }
}