import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:notifications/services/notification_service.dart';

class NotificationButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () async {
            await NotificationService.createNotification(
              id: 1,
              title: 'Default Notification',
              body: 'This is the body',
              summary: 'Small summary',
            );
          },
          child: const Text('Default Notification'),
        ),
        
        OutlinedButton(
          onPressed: () async {
            await NotificationService.createNotification(
              id: 5,
              title: 'Big Image Notification',
              body: 'Notification with image',
              notificationLayout: NotificationLayout.BigPicture,
              bigPicture: 'https://picsum.photos/300/200',
            );
          },
          child: const Text('Big Image Notification'),
        ),

        OutlinedButton(
          onPressed: () async {
            await NotificationService.createNotification(
              id: 6,
              title: 'Scheduled Notification',
              body: 'Appears after 5 seconds',
              scheduled: true,
              interval: const Duration(seconds: 5),
            );
          },
          child: const Text('Scheduled Notification'),
        ),
      ],
    );
  }
}