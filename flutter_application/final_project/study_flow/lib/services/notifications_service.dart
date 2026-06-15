import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static Future<void> init() async {
    await AwesomeNotifications().initialize(
      null, // Icône par défaut (null utilise l'icône de l'app)
      [
        NotificationChannel(
          channelKey: 'study_flow_channel',
          channelName: 'Study Flow Notifications',
          channelDescription: 'Notifications for study session updates',
          defaultColor: const Color(0xFF9D50BB),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        )
      ],
      debug: true,
    );

    // Demander la permission à l'utilisateur
    try {
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }
    } catch (e) {
      print("Erreur lors de la demande de permission de notification : $e");
    }
  }
  



  // 1. Immediate notification when a study_session is added to the cloud
  static Future<void> showStudySessionAddedNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'study_flow_channel',
        title: 'New Study Session Added !',
        body: 'Your study session has been successfully registered in the Cloud.',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  // 2. Immediate notification when a study_session is modified to the cloud
  static Future<void> showStudySessionModifiedNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: 'study_flow_channel',
        title: 'Study Session Modified !',
        body: 'Your study session has been successfully updated in the Cloud.',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  // 3. Immediate notification when a study_session is deleted from the cloud
  static Future<void> showStudySessionDeletedNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 3,
        channelKey: 'study_flow_channel',
        title: 'Study Session Deleted !',
        body: 'Your study session has been successfully deleted from the Cloud.',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  // 2. Daily reminder
  static Future<void> scheduleDailyReminder() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 4,
        channelKey: 'study_flow_channel',
        title: 'Daily Study Reminder',
        body: 'Don\'t forget to update your study progress today!',
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        hour: 20,
        minute: 0,
        second: 0,
        millisecond: 0,
        repeats: true,
      ),
    );
  }

  
}