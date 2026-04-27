import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoe_vault_project/models/shoe.dart';
import 'package:shoe_vault_project/services/database_service.dart';

class NotificationService {
  static Future<void> init() async {
    await AwesomeNotifications().initialize(
      null, // Icône par défaut (null utilise l'icône de l'app)
      [
        NotificationChannel(
          channelKey: 'shoe_vault_channel',
          channelName: 'Shoe Vault Notifications',
          channelDescription: 'Notifications for shoe distance updates (update your kms with the shoes used today)',
          defaultColor: const Color(0xFF9D50BB),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        )
      ],
      debug: true,
    );

    // Demander la permission à l'utilisateur
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }



  // 1. Immediate notification when a shoe is added to the cloud
  static Future<void> showShoeAddedNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'shoe_vault_channel',
        title: 'New Shoe Added ! 👟',
        body: 'Your pair has been successfully registered in the Cloud.',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  // 2. Daily reminder
  static Future<void> scheduleDailyReminder() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: 'shoe_vault_channel',
        title: 'Distance Update 🏃‍♂️',
        body: 'Don\'t forget to update your shoes\' distance today!',
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

  static String printShoesOverThreshold(List<Shoe> shoes, double threshold) {
    List<Shoe> finalShoes = [];
    for (final shoe in shoes) {
      if (shoe.kilometers >= threshold) {
        finalShoes.add(shoe);
      }
    }
    if (finalShoes.isEmpty) return '';
    
    String text = '';
    for (final shoe in finalShoes) {
      text += '${shoe.modelName} has reached ${shoe.kilometers} km\n';
    }
    return text + 'Please consider replacing them soon!';
  }

  static Future<void> scheduleDailyReminder2(dynamic dbService) async {
    final prefs = await SharedPreferences.getInstance();
    double threshold = prefs.getDouble('km_threshold') ?? 500.0;
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 3,
        channelKey: 'shoe_vault_channel',
        title: 'Change Shoes',
        body: printShoesOverThreshold(await dbService.isar.shoes.where().findAll(), threshold),
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        hour: 21,
        minute: 0,
        second: 0,
        millisecond: 0,
        repeats: true,
      ),
    );
  }
}