import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../core/platform/android_overlay_service.dart';
import '../../core/platform/shared_text_inbox.dart';
import '../feature_hub_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  static const _features = <_FeatureSpec>[
    _FeatureSpec(FeatureKind.translation, 'ترجمة نصية', 'ترجمة محلية + مايك', Icons.translate, Colors.blueAccent),
    _FeatureSpec(FeatureKind.dialogue, 'حوار مترجم', 'محرران + مايك الجهاز', Icons.forum, Colors.cyanAccent),
    _FeatureSpec(FeatureKind.documents, 'مستندات وعدسة', 'OCR صور + PDF وTXT محلي', Icons.document_scanner, Colors.tealAccent),
    _FeatureSpec(FeatureKind.stories, 'قصص وإلهام', 'قصص وإلهام محلي', Icons.auto_stories, Colors.orangeAccent),
    _FeatureSpec(FeatureKind.games, 'الشطرنج', 'لعب محلي أو ضد الكمبيوتر', Icons.castle, Colors.purpleAccent),
    _FeatureSpec(FeatureKind.settings, 'الإعدادات', 'خصوصية وحزم وPRO', Icons.settings, Colors.blueGrey),
  ];

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  SharedTextInbox? _sharedTextInbox;
  bool _openingSharedText = false;
  bool _changingOverlay = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inbox = context.read<SharedTextInbox>();
    if (_sharedTextInbox == inbox) return;
    _sharedTextInbox?.removeListener(_openPendingSharedText);
    _sharedTextInbox = inbox..addListener(_openPendingSharedText);
    _openPendingSharedText();
  }

  @override
  void dispose() {
    _sharedTextInbox?.removeListener(_openPendingSharedText);
    _pulseController.dispose();
    super.dispose();
  }

  void _openPendingSharedText() {
    if (!mounted || _openingSharedText) return;
    final inbox = _sharedTextInbox;
    if (inbox?.pendingText == null) return;
    _openingSharedText = true;
    final text = inbox!.takePendingText();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || text == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => FeatureHubScreen(
            kind: FeatureKind.translation,
            initialTranslationText: text,
          ),
        ),
      );
      if (mounted) {
        _openingSharedText = false;
        _openPendingSharedText();
      }
    });
  }

  void _showInspirationPreview() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1B2838),
        title: const Text('إلهام ميرور سكربيون', style: TextStyle(color: Colors.amber, fontSize: 18)),
        content: const Text('تُربط رسالة الإلهام بخدمة ذكاء حقيقية بعد تثبيت مسارها الخادمي؛ لا يولّد التطبيق رسالة افتراضية هنا.'),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('حسناً'))],
      ),
    );
  }

  void _openFeature(FeatureKind kind) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => FeatureHubScreen(kind: kind)));
  }

  Future<void> _toggleOverlay(bool enabled) async {
    setState(() => _changingOverlay = true);
    final overlay = context.read<AndroidOverlayService>();
    final result = enabled
        ? await overlay.showBubble()
        : await overlay.closeBubble();
    if (!mounted) return;
    setState(() => _changingOverlay = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
  }

  @override
  Widget build(BuildContext context) {
    final overlay = context.watch<AndroidOverlayService>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D1B2A), Color(0xFF1B2838)],
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(overlay)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _FeatureCard(
                        feature: _features[index],
                        onTap: () => _openFeature(_features[index].kind),
                      ),
                      childCount: _features.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: _Footer()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AndroidOverlayService overlay) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: 0.25,
                child: Transform.translate(
                  offset: const Offset(0, 110),
                  child: Transform.scale(
                    scaleX: 1.2,
                    scaleY: -1.0,
                    child: Transform(
                      transform: Matrix4.rotationX(1.4),
                      alignment: Alignment.center,
                      child: _buildScorpionLogo(isReflection: true),
                    ),
                  ),
                ),
              ),
              GestureDetector(onTap: _showInspirationPreview, child: _buildScorpionLogo()),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'ميرور سكربيون',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Color(0xFF00B0FF),
              shadows: [Shadow(color: Colors.blueAccent, blurRadius: 10), Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 4)],
            ),
          ),
          const SizedBox(height: 8),
          const Text('حيث تُصنع البدايات', style: TextStyle(fontSize: 16, color: Colors.white54, fontStyle: FontStyle.italic)),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bubble_chart_outlined,
                  color: overlay.isVisible ? Colors.cyanAccent : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    overlay.isSupported
                        ? (overlay.isVisible
                            ? 'الفقاعة فوق التطبيقات: مفعّلة'
                            : 'الفقاعة فوق التطبيقات: متوقفة')
                        : 'الفقاعة فوق التطبيقات: Android فقط',
                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                ),
                Switch.adaptive(
                  value: overlay.isVisible,
                  onChanged: _changingOverlay || !overlay.isSupported
                      ? null
                      : _toggleOverlay,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorpionLogo({bool isReflection = false}) {
    final logo = Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blueAccent.withValues(alpha: isReflection ? 0.2 : 0.5), width: 2),
        boxShadow: isReflection ? null : [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.35), blurRadius: 20, spreadRadius: 2)],
        image: const DecorationImage(image: AssetImage('assets/images/scorpion_bg.jpeg'), fit: BoxFit.cover),
      ),
    );
    if (isReflection) return logo;
    return AnimatedBuilder(animation: _pulseAnimation, child: logo, builder: (_, child) => Transform.scale(scale: _pulseAnimation.value, child: child));
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature, required this.onTap});

  final _FeatureSpec feature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.055),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: feature.color.withValues(alpha: 0.35))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(feature.icon, color: feature.color, size: 42),
              const SizedBox(height: 14),
              Text(feature.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(feature.subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white54, height: 1.35)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(30),
      child: Opacity(opacity: 0.3, child: Center(child: Text('Mirror Scorpion\nv4 Flutter/Android', textAlign: TextAlign.center, style: TextStyle(fontSize: 10)))),
    );
  }
}

class _FeatureSpec {
  const _FeatureSpec(this.kind, this.title, this.subtitle, this.icon, this.color);

  final FeatureKind kind;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}
