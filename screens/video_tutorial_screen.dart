import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoTutorialScreen extends StatefulWidget {
  final bool isArabic;

  const VideoTutorialScreen({super.key, required this.isArabic});

  @override
  State<VideoTutorialScreen> createState() => _VideoTutorialScreenState();
}

class VideoInstruction {
  final Duration start;
  final Duration end;
  final String textAr;
  final String textEn;

  VideoInstruction({
    required this.start,
    required this.end,
    required this.textAr,
    required this.textEn,
  });
}

class _VideoTutorialScreenState extends State<VideoTutorialScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  final List<VideoInstruction> _instructions = [
    VideoInstruction(
      start: const Duration(seconds: 0),
      end: const Duration(seconds: 60), // 1:00
      textAr: 'فتح التطبيق وظهور شاشة الترحيب. الضغط على زر البداية، ثم الانتقال لصفحة التسجيل.',
      textEn: 'Opening the app, showing the Welcome screen, clicking Start, then moving to Registration.',
    ),
    VideoInstruction(
      start: const Duration(seconds: 60), // 1:00
      end: const Duration(seconds: 120), // 2:00
      textAr: 'تعبئة معلومات الحساب (الاسم، البريد، كلمة المرور) والضغط على زر المتابعة.',
      textEn: 'Filling in account details (name, email, password) and clicking Continue.',
    ),
    VideoInstruction(
      start: const Duration(seconds: 120), // 2:00
      end: const Duration(seconds: 180), // 3:00
      textAr: 'ظهور صفحة الخريطة. تحديد الموقع الحالي أو السماح بالوصول للموقع للانتقال للرئيسية.',
      textEn: 'Map screen appears. Selecting current location or granting location access to move to Dashboard.',
    ),
    VideoInstruction(
      start: const Duration(seconds: 180), // 3:00
      end: const Duration(seconds: 240), // 4:00
      textAr: 'الدخول للواجهة الرئيسية، وظهور بطاقة المستخدم والإحصائيات، واستعراض الأقسام.',
      textEn: 'Entering the main dashboard, showing user card and statistics, and exploring sections.',
    ),
    VideoInstruction(
      start: const Duration(seconds: 240), // 4:00
      end: const Duration(seconds: 300), // 5:00
      textAr: 'التنقل بين الخيارات، الضغط على الأيقونات واستعراض البيانات، وفتح/إغلاق القوائم.',
      textEn: 'Navigating through options, clicking icons to view data, and opening/closing menus.',
    ),
    VideoInstruction(
      start: const Duration(seconds: 300), // 5:00
      end: const Duration(seconds: 360), // 6:00
      textAr: 'استمرار استعراض الصفحة الرئيسية، مراجعة النشاط، وتجربة أزرار التطبيق.',
      textEn: 'Continuing to explore the main dashboard, reviewing activity, and trying out buttons.',
    ),
    VideoInstruction(
      start: const Duration(seconds: 360), // 6:00
      end: const Duration(seconds: 420), // 7:00
      textAr: 'التنقل بين الأقسام السفلية، عرض وتحديث التفاصيل الإضافية داخل الحساب.',
      textEn: 'Navigating bottom tabs, viewing and updating additional account details.',
    ),
    VideoInstruction(
      start: const Duration(seconds: 420), // 7:00
      end: const Duration(seconds: 480), // 8:00
      textAr: 'الرجوع للواجهة الرئيسية ومراجعة الإحصائيات والمعلومات الظاهرة.',
      textEn: 'Returning to the main dashboard, reviewing displayed statistics and info.',
    ),
    VideoInstruction(
      start: const Duration(seconds: 480), // 8:00
      end: const Duration(seconds: 540), // 9:00
      textAr: 'فتح صفحات فرعية ثم الرجوع للرئيسية والتنقل بين التبويبات.',
      textEn: 'Opening sub-pages then returning to the main screen, and switching between tabs.',
    ),
    VideoInstruction(
      start: const Duration(seconds: 540), // 9:00
      end: const Duration(seconds: 600), // 10:00
      textAr: 'مراجعة بيانات المستخدم واستعراض نفس الصفحة مع تجربة خيارات إضافية.',
      textEn: 'Reviewing user data and exploring the same page with additional options.',
    ),
    VideoInstruction(
      start: const Duration(seconds: 600), // 10:00
      end: const Duration(seconds: 660), // 11:00
      textAr: 'استمرار التنقل داخل التطبيق وتجربة الإعدادات والرجوع للرئيسية.',
      textEn: 'Continuing to navigate, testing settings, and returning to the main dashboard.',
    ),
    VideoInstruction(
      start: const Duration(seconds: 660), // 11:00
      end: const Duration(seconds: 720), // 12:00
      textAr: 'مراجعة معلومات الحساب مرة ثانية ومتابعة استعراض الواجهة الرئيسية.',
      textEn: 'Checking account info again and continuing to explore the main dashboard.',
    ),
    VideoInstruction(
      start: const Duration(seconds: 720), // 12:00
      end: const Duration(seconds: 810), // 13:30
      textAr: 'فتح القوائم بشكل سريع، التنقل بين الصفحات وانتهاء التسجيل.',
      textEn: 'Opening menus quickly, switching between pages, and finishing the tutorial.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/tutorial.mp4')
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getCurrentInstruction() {
    final position = _controller.value.position;
    for (var instruction in _instructions) {
      if (position >= instruction.start && position <= instruction.end) {
        return widget.isArabic ? instruction.textAr : instruction.textEn;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isArabic ? 'فيديو تعليمي' : 'Video Tutorial'),
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    VideoPlayer(_controller),
                    _ControlsOverlay(controller: _controller),
                    // Adding subtitle overlay that updates with video position
                    ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, VideoPlayerValue value, child) {
                        final text = _getCurrentInstruction();
                        if (text.isEmpty) return const SizedBox.shrink();

                        return Positioned(
                          bottom: 30, // Just above the progress bar
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              text,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    VideoProgressIndicator(_controller, allowScrubbing: true),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
      ],
    );
  }
}
