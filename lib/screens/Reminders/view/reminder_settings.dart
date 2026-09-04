import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:readora/screens/Reminders/controller/reminder_controller.dart';
import 'package:readora/screens/Reminders/service/reminder_service.dart';
import 'package:readora/utils/colors.dart';
import 'package:readora/utils/custom_snackbar.dart';

class ReminderSettings extends StatelessWidget {
  const ReminderSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(ReminderController());

    return Scaffold(
      backgroundColor: AppColor.bgcolor,
      appBar: AppBar(
        backgroundColor: AppColor.bgcolor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColor.iconstext),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Reminders & Notifications',
          style: TextStyle(
            color: AppColor.iconstext,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Reading Time Reminder ──────────────────────────────
          _SectionHeader(
            icon: Icons.menu_book_rounded,
            iconColor: AppColor.clickedbutton,
            title: 'Reading Time Reminder',
            subtitle: 'Get notified when it\'s time to read',
          ),
          _ReminderCard(
            child: Obx(() => Column(
                  children: [
                    // Toggle row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Enable reading reminder',
                          style: TextStyle(
                            color: AppColor.iconstext,
                            fontSize: 14,
                          ),
                        ),
                        Switch(
                          value: ctrl.readingReminderEnabled.value,
                          activeThumbColor: AppColor.clickedbutton,
                          onChanged: ctrl.toggleReadingReminder,
                        ),
                      ],
                    ),
                    // Time picker row (only visible when enabled)
                    if (ctrl.readingReminderEnabled.value) ...[
                      const Divider(color: AppColor.unselected, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reminder time',
                                style: TextStyle(
                                  color: AppColor.iconstext,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ctrl.formatTime(ctrl.readingReminderTime.value),
                                style: const TextStyle(
                                  color: AppColor.clickedbutton,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: ctrl.readingReminderTime.value,
                                builder: (ctx, child) =>
                                    _themedTimePicker(ctx, child),
                              );
                              if (picked != null) {
                                ctrl.setReadingReminderTime(picked);
                              }
                            },
                            icon: const Icon(Icons.access_time,
                                size: 16, color: AppColor.white),
                            label: const Text(
                              'Change',
                              style: TextStyle(color: AppColor.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.clickedbutton,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _InfoChip(label: '🔔 Repeats every day at this time'),
                    ],
                  ],
                )),
          ),




          // ── Friend Post Notifications ──────────────────────────
          _SectionHeader(
            icon: Icons.people_alt_rounded,
            iconColor: const Color(0xFFFFA726),
            title: 'Friend Post Notifications',
            subtitle: 'Get notified when friends share new posts',
          ),
          _ReminderCard(
            child: Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Friend posts alerts',
                          style: TextStyle(
                            color: AppColor.iconstext,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Notified instantly when a friend posts',
                          style: TextStyle(
                            color: AppColor.unselected,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: ctrl.friendPostReminderEnabled.value,
                      activeThumbColor: const Color(0xFFFFA726),
                      onChanged: ctrl.toggleFriendPostReminder,
                    ),
                  ],
                )),
          ),

          // ── Save Settings Button ────────────────────────────────
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  ctrl.saveAndRescheduleAll();
                  customSnackbar(
                    title: 'Success',
                    message: 'Notification settings saved & scheduled!',
                  );
                },
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: const Text(
                  'Save Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.clickedbutton,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Preview / Test button ──────────────────────────────
          Center(
            child: OutlinedButton.icon(
              onPressed: () async {
                await _sendTestNotification(ctrl);
                Get.snackbar(
                  '✅ Test Sent',
                  'Check your notification panel!',
                  backgroundColor: AppColor.clickedbutton,
                  colorText: AppColor.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              icon: const Icon(Icons.notifications_active,
                  color: AppColor.clickedbutton),
              label: const Text(
                'Send Test Notification',
                style: TextStyle(color: AppColor.clickedbutton),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColor.clickedbutton),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  Future<void> _sendTestNotification(ReminderController ctrl) async {
    await ReminderService.instance.showTestNotification();
  }

  Widget _themedTimePicker(BuildContext ctx, Widget? child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppColor.clickedbutton,
          surface: AppColor.bgcolor,
          onSurface: AppColor.iconstext,
        ),
        dialogTheme: DialogThemeData(backgroundColor: AppColor.bgcolor),
      ),
      child: child!,
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: AppColor.iconstext,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                      color: AppColor.unselected,
                      fontSize: 12,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Widget child;
  const _ReminderCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.unselected.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.unselected.withOpacity(0.4)),
      ),
      child: child,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColor.clickedbutton.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColor.clickedbutton,
          fontSize: 11,
        ),
      ),
    );
  }
}
