import 'package:flutter/material.dart';

import '../app/royal_dark_theme.dart';
import '../core/media/runware_video_service.dart';

class SubscriptionBoundariesCard extends StatelessWidget {
  const SubscriptionBoundariesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: RoyalColors.gold),
                SizedBox(width: 10),
                Text('حدود الخطة والخدمات', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
            SizedBox(height: 12),
            _SubscriptionBoundaryRow(
              title: SubscriptionBoundaries.localPlan,
              detail: 'متاح: قصص البداية المرخصة وأصوات Android والترجمة المحلية حيث تتوفر النماذج.',
              icon: Icons.phone_android_outlined,
              color: RoyalColors.cyan,
            ),
            _SubscriptionBoundaryRow(
              title: SubscriptionBoundaries.signedProPlan,
              detail: 'يتطلب رمز تفعيل موقعاً؛ لا يشتري أو يفتح خدمة فيديو تلقائياً.',
              icon: Icons.verified_user_outlined,
              color: RoyalColors.gold,
            ),
            _SubscriptionBoundaryRow(
              title: SubscriptionBoundaries.cloudVideoPlan,
              detail: 'غير مفعّل — ${SubscriptionBoundaries.cloudVideoLimit}',
              icon: Icons.lock_outline,
              color: RoyalColors.muted,
            ),
            _SubscriptionBoundaryRow(
              title: SubscriptionBoundaries.audioStudioPlan,
              detail: 'غير مفعّل: نسخ الصوت وتصدير MP3 يحتاجان موافقة ومزوداً ممولاً.',
              icon: Icons.graphic_eq_outlined,
              color: RoyalColors.muted,
            ),
            SizedBox(height: 8),
            Text('لا يوجد تجديد تلقائي أو دفع أو مفتاح داخل التطبيق حالياً.', style: TextStyle(color: RoyalColors.muted, height: 1.45)),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionBoundaryRow extends StatelessWidget {
  const _SubscriptionBoundaryRow({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(detail, style: const TextStyle(color: RoyalColors.muted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
