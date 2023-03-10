import 'dart:io';

// Packages imports

import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mockingjae2_mobile/src/FileManager/ScrollsManager.dart';
import 'package:mockingjae2_mobile/src/FileManager/lowestActions.dart';
import 'package:mockingjae2_mobile/src/Recorder/indexTimestamp.dart';
import 'package:mockingjae2_mobile/src/Recorder/recorder.dart';
import 'package:mockingjae2_mobile/src/StateMixins/frameworks.dart';
import 'package:mockingjae2_mobile/src/bodyWidget/ScrollsWidget/ScrollsPreviewWidgets.dart';
import 'package:mockingjae2_mobile/src/controller/imageIndexController.dart';
import 'package:mockingjae2_mobile/src/controller/scrollsControllers.dart';
import 'package:mockingjae2_mobile/src/models/Remix.dart';
import 'package:mockingjae2_mobile/src/models/Scrolls.dart';

// Utility local imports

import 'package:mockingjae2_mobile/utils/colors.dart';
import 'package:mockingjae2_mobile/utils/ui.dart';
import 'package:mockingjae2_mobile/utils/utils.dart';
import 'package:mockingjae2_mobile/src/components/icons.dart';

// Scroll Controller and Statusbar local import

import 'package:mockingjae2_mobile/src/controller/scrollPhysics.dart';
import 'package:mockingjae2_mobile/src/bodyWidget/ScrollsWidget/StatusBar.dart';
import 'package:mockingjae2_mobile/src/Recorder/testConverter.dart';
import 'package:provider/provider.dart';

// Scrolls Button related local import

import 'ScrollsWidget/InteractionWidgets.dart';
import 'ScrollsWidget/ScrollsHeader.dart';

class ScrollsBodyView extends StatelessWidget {
  const ScrollsBodyView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => ScrollsManager(context: context),
      child: const ScrollsBody(),
    );
  }
}

class ScrollsBody extends StatefulWidget {
  const ScrollsBody({super.key});

  @override
  State<ScrollsBody> createState() => _ScrollsBodyState();
}

class _ScrollsBodyState extends State<ScrollsBody>
    with DragUpdatable<ScrollsBody> {
  Highlight? highlight;
  late MainScrollsController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = MainScrollsController(
        onIndexChange: context.read<ScrollsManager>().setIndex);
    _loadAudios('').then((audios) {
      setState(() {
        this.highlight = Highlight(
            index: 440,
            forwardAudioBuffer: audios[23],
            reverseAudioBuffer: audios[24]);
      });
    });
    _scrollController.setRefresh(_refresh);
    _refresh();
    // context.read<ScrollsManager>().addAllScrollsCache(newCacheList);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    // refreshes the page and adds scrolls model to the
    // page, appending at the bottom

    // This is dummy function that fetches scrolls from the server,
    // parses into scrolls model

    Future<List<ScrollsModel>> newModels({int num = 1}) async {
      List<ScrollsModel> dummyResult = [];
      var value = await _loadImages(
          '/Users/jaekim/projects/mockingjae2_mobile/sample_scrolls/scrolls1/',
          context);

      for (int i = 0; i < num; i++) {
        dummyResult.add(value);
      }
      return dummyResult;
    }

    List<ScrollsModel> toBeAdded = await newModels(num: 10);

    addAllScrolls(toBeAdded);
  }

  void addAllScrolls(List<ScrollsModel> scrollsModels) {
    List<ScrollsIndexImageCache> scrollsCaches = [];

    for (var scrollsModel in scrollsModels) {
      ScrollsIndexImageCache newCache =
          ScrollsIndexImageCache(scrollsModel: scrollsModel);
      scrollsCaches.add(newCache);
      _scrollController.addIndex();
    }

    context.read<ScrollsManager>().addAllScrollsCache(scrollsCaches);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScrollsManager>(builder: (context, scrollsManager, child) {
      if (scrollsManager.isEmpty() || highlight == null) {
        return Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            color: scrollsBackgroundColor,
          ),
          child: Center(
            child: JaeIcon(55, 55, mainBackgroundColor),
          ),
        );
      }
      return ScrollsListViewBuilder(highlights: [
        highlight!,
        highlight!,
        highlight!,
        highlight!,
        highlight!
      ], scrollController: _scrollController);
    });
  }
}

class ScrollsListViewBuilder extends StatefulWidget {
  final List<Highlight> highlights;
  final MainScrollsController scrollController;

  const ScrollsListViewBuilder(
      {super.key, required this.highlights, required this.scrollController});

  @override
  State<ScrollsListViewBuilder> createState() => _ScrollsListViewBuilderState();
}

class _ScrollsListViewBuilderState extends State<ScrollsListViewBuilder> {
  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.vertical,
      children: [
        Expanded(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            controller: widget.scrollController,
            scrollDirection: Axis.vertical,
            itemCount: context.read<ScrollsManager>().num_scrolls(),
            itemBuilder: (context, index) {
              return Scrolls(
                  // need to implement the highlight adding...
                  scrollsCache:
                      context.read<ScrollsManager>().getScrollsCache(index),
                  highlight: widget.highlights[0],
                  parentScrollController: widget.scrollController,
                  index: index);
            },
          ),
        )
      ],
    );
  }
}

class Scrolls extends StatefulWidget {
  final MainScrollsController parentScrollController;
  final int index;
  final int duration;
  final Highlight? highlight;
  final ScrollsIndexImageCache scrollsCache;

  const Scrolls(
      {super.key,
      required this.parentScrollController,
      this.duration = 10,
      required this.index,
      required this.scrollsCache,
      this.highlight});

  @override
  _ScrollsState createState() => _ScrollsState();
}

class _ScrollsState extends State<Scrolls> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late SingleScrollsController _scrollController;
  int currentIndex = 0;
  double scrollDelta = 0;
  final double _height = 3000;
  // Each scroll has seperate audio player
  final AudioPlayer player = AudioPlayer();
  // Whether scrubbing has been recorded
  bool recording = false;
  Recorder recorder = Recorder();
  List<Image>? images;

  Future<void> playAudioFromMemory(Uint8List audioData) async {
    if (player.playing == true) {
      await player.stop();
    }

    await player.setAudioSource(BytesSource(audioData));
    await player.play();
  }

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scrollController =
        SingleScrollsController(height: _height, context: context);
    images = widget.scrollsCache.scrollsImages;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool scrollsIndexCheck(int index, length) {
    if (scrollsLowerBound(index) && scrollsUpperBound(index, length)) {
      return true;
    }
    return false;
  }

  bool scrollsLowerBound(int index) {
    if (0 <= index) {
      return true;
    }

    return false;
  }

  bool scrollsUpperBound(int index, int length) {
    if (index < length) {
      return true;
    }

    return false;
  }

  bool scrollsIndexChangeManager(
      ScrollNotification notification, List<Image> images) {
    // Buisness manager to scrolls item
    // this method manages actions related to image index changes
    // on scroll position change
    //
    // Consider this as a core functionality to the scrolls

    // defines scroll delta to use this metrix in dummy padding in
    // Stack-Position widget (Minor utility)
    scrollDelta = notification.metrics.pixels;

    // defines the _controller value by calculating current scroll position in percent
    _controller.value = 1 - _scrollController.remaining();

    // defines how image index is going to be displayed as in relationship to current scroll position
    int candidateIndex = (_controller.value * images.length).floor();
    if (!scrollsUpperBound(candidateIndex, images.length)) {
      // set index to image's last index if index exceeds upper bound
      currentIndex = images.length - 1;
    } else if (!scrollsLowerBound(candidateIndex)) {
      // set index to images's first index if index exceeds lower bound
      currentIndex = 0;
    } else {
      currentIndex = candidateIndex;
    }

    setState(() {
      candidateIndex = candidateIndex;
      scrollDelta = scrollDelta;
    });

    // Auto scroll position-time recording functionality
    // This should be imported from Recording Module

    if (!recording) {
      recorder.startRecording();
      recording = true;
    }

    recorder.updateRecording(currentIndex);

    // Highlight position audio play
    // defines the scroll direction to play forward audio and backward audio in
    // according situation
    var scrollDirection = _scrollController.position.userScrollDirection;
    if (widget.highlight != null &&
        currentIndex - 10 <= widget.highlight!.index &&
        widget.highlight!.index <= currentIndex) {
      if (scrollDirection == ScrollDirection.forward) {
        playAudioFromMemory(widget.highlight!.forwardAudioBuffer);
      } else if (scrollDirection == ScrollDirection.reverse) {
        playAudioFromMemory(widget.highlight!.reverseAudioBuffer);
      } else {
        playAudioFromMemory(widget.highlight!.forwardAudioBuffer);
      }
    }

    if (currentIndex / images.length > 0.88) {
      recording = false;
      IndexTimeLine recordedTimeline = recorder.stopRecording()!;

      if (recordedTimeline.last! - recordedTimeline.first! >
          const Duration(seconds: 2)) {
        // convert into remix
        RemixModel remix = RemixModel(
          'new',
          scrolls: widget.scrollsCache.scrollsModel,
          timeline: recordedTimeline,
        );

        Converter converter = Converter();

        converter.convertRemixToVideo(remix,
            '/Users/jaekim/projects/mockingjae2_mobile/lib/src/Recorder/newOutput.mp4');
      }

      // snap to the next scrolls
      widget.parentScrollController.switchToNextScrolls(context);
      // reset the scrolls at start
      _scrollController.fastScrubToStart();
    }

    if (notification.metrics.pixels <= -35 && widget.index != 0) {
      recording = false;
      IndexTimeLine recordedTimeline = recorder.stopRecording()!;

      if (recordedTimeline.last! - recordedTimeline.first! >
          const Duration(seconds: 2)) {
        // convert into remix
        RemixModel remix = RemixModel(
          'new',
          scrolls: widget.scrollsCache.scrollsModel,
          timeline: recordedTimeline,
        );

        Converter converter = Converter();

        converter.convertRemixToVideo(remix,
            '/Users/jaekim/projects/mockingjae2_mobile/lib/src/Recorder/newOutput.mp4');
      }

      // snap to the last scrolls if one exists
      widget.parentScrollController.switchToLastScrolls(context);
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScrollsManager>(builder: (context, scrollsManager, child) {
      if (widget.index ==
              widget.parentScrollController.getCurrentScrollsIndex() &&
          widget.parentScrollController.isIndexChanged()) {
        scrollsManager.setIndex(widget.index);
      }
      if (!widget.scrollsCache.isMemoryCached ||
          widget.scrollsCache.scrollsImages == null) {
        return Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            color: scrollsBackgroundColor,
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 103),
            child: Center(
              child: JaeIcon(55, 55, mainBackgroundColor),
            ),
          ),
        );
      }
      return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(color: scrollsBackgroundColor),
        child: NotificationListener<ScrollNotification>(
            onNotification: (notification) => scrollsIndexChangeManager(
                notification, widget.scrollsCache.scrollsImages!),
            child: SingleChildScrollView(
                controller: _scrollController,
                physics: const DampedScrollPhysics(),
                scrollDirection: Axis.vertical,
                child: SizedBox(
                  height: _height,
                  width: MediaQuery.of(context).size.width,
                  child: Stack(fit: StackFit.expand, children: [
                    Positioned(
                      top: (scrollDelta >= 0) ? scrollDelta : 0,
                      child: GestureDetector(
                        onLongPressStart: (LongPressStartDetails detail) {
                          // this auto scrolls at velocity (_height / widget.duration)
                          // works alongside with onLongPressEnd
                          _scrollController.scrubToEnd();
                        },
                        onLongPressEnd: (LongPressEndDetails detail) {
                          // this auto scrolls at velocity (_height / widget.duration)
                          // works alongside with onLongPressStart
                          _scrollController.scrubStop();
                        },
                        onDoubleTap: () {
                          // this animates back to beginning of the scrolls
                          _scrollController.fastScrubToStart();
                        },
                        onHorizontalDragStart: (details) {
                          // for test utilities only
                          // used only in test pipeline
                          widget.parentScrollController.refreshScroll();
                        },
                        child: BoxContainer(
                            context: context,
                            backgroundColor: scrollsBackgroundColor,
                            height: MediaQuery.of(context).size.height,
                            width: MediaQuery.of(context).size.width,
                            child: Stack(
                              alignment: AlignmentDirectional.topStart,
                              children: ([
                                widget
                                    .scrollsCache.scrollsImages![currentIndex],
                                // status bar
                                StatusBar(
                                    currentIndex: currentIndex,
                                    length: widget
                                        .scrollsCache.scrollsImages!.length),
                                // remix number
                                Positioned(
                                  right: 2.5,
                                  top: 20,
                                  child: ScrollsRelatedInfoButtonWrap(),
                                ),
                                Positioned(
                                  left: 10,
                                  top: 15,
                                  width: 250,
                                  child: ScrollsHeader(),
                                )
                              ]),
                            )),
                      ),
                    )
                  ]),
                ))),
      );
    });
  }
}

// buisness utilities

class BytesSource extends StreamAudioSource {
  final Uint8List _buffer;

  BytesSource(this._buffer) : super(tag: 'AudioSource');

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    // Returning the stream audio response with the parameters
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: (start ?? 0) - (end ?? _buffer.length),
      offset: start ?? 0,
      stream: Stream.fromIterable([_buffer.sublist(start ?? 0, end)]),
      contentType: 'audio/mpeg',
    );
  }
}

Future<ScrollsModel> _loadImages(String path, BuildContext context) async {
  Directory testDir =
      await _testImageLoader('newDir', 'sample_scrolls/scrolls1', 824);

  List<String> imageFiles = testDir
      .listSync()
      .whereType<File>()
      .cast<File>()
      .map((f) => f.path)
      .toList();

  imageFiles.sort((a, b) {
    final aFileName = a.split("/").last.split(".").first;
    final bFileName = b.split("/").last.split(".").first;
    return int.parse(aFileName).compareTo(int.parse(bFileName));
  });

  final images = await Future.wait(imageFiles.map(
    (imagePath) async {
      final data = await rootBundle.load(imagePath);
      return Image.memory(
        Uint8List.view(data.buffer),
        gaplessPlayback: true,
        fit: BoxFit.fitHeight,
        height: MediaQuery.of(context).size.height,
      );
    },
  ));

  ScrollsModel scrollsModel =
      ScrollsModel(imagePath: testDir, scrollsName: 'Scrolls1');

  return scrollsModel;
}

class Highlight {
  final int index;
  final Uint8List forwardAudioBuffer;
  final Uint8List reverseAudioBuffer;

  const Highlight({
    required this.index,
    required this.forwardAudioBuffer,
    required this.reverseAudioBuffer,
  });
}

Future<List<Uint8List>> _loadAudios(String path) async {
  Directory testDir =
      await _testAudioLoader('audioDirectory10', 'audios/audios7', 51);

  List<String> audioFiles = testDir
      .listSync()
      .whereType<File>()
      .cast<File>()
      .map((f) => f.path)
      .toList();

  audioFiles.sort((a, b) {
    final aFileName = a.split("/").last.split(".").first;
    final bFileName = b.split("/").last.split(".").first;
    return int.parse(aFileName).compareTo(int.parse(bFileName));
  });

  final audios = await Future.wait(audioFiles.map(
    (audioPath) async {
      final data = await rootBundle.load(audioPath);
      return Uint8List.view(data.buffer);
    },
  ));

  return audios;
}

Future<List<String>> _loadAudiosAsDir(String path) async {
  Directory testDir =
      await _testAudioLoader('audioDirectory10', 'audios/audios7', 51);

  List<String> audioFiles = testDir
      .listSync()
      .whereType<File>()
      .cast<File>()
      .map((f) => f.path)
      .toList();

  audioFiles.sort((a, b) {
    final aFileName = a.split("/").last.split(".").first;
    final bFileName = b.split("/").last.split(".").first;
    return int.parse(aFileName).compareTo(int.parse(bFileName));
  });

  final audios = await Future.wait(audioFiles.map(
    (audioPath) async {
      return audioPath;
    },
  ));

  return audios;
}

Future<Directory> _testImageLoader(
    String newDir, String assetDir, int assetLength) async {
  String newFullDir = await getOrCreateFolder('scrolls/cached/Scrolls1');

  for (int i = 1; i <= assetLength; i++) {
    String filePath = newFullDir + '/$i.jpeg';
    File imageFile = File(filePath);
    if (!await imageFile.exists()) {
      final data = await rootBundle.load('$assetDir/$i.jpeg');
      await imageFile.writeAsBytes(data.buffer.asUint8List());
    }
  }

  return Directory(newFullDir);
}

Future<Directory> _testAudioLoader(
    String newDir, String assetDir, int assetLength) async {
  String newFullDir = await getOrCreateFolder(newDir);

  for (int i = 1; i <= assetLength; i++) {
    String filePath = newFullDir + '/$i.mp3';
    File imageFile = File(filePath);
    if (!await imageFile.exists()) {
      final data = await rootBundle.load('$assetDir/$i.mp3');
      await imageFile.writeAsBytes(data.buffer.asUint8List());
    }
  }

  return Directory(newFullDir);
}
