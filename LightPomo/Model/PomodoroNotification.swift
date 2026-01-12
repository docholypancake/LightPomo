//
//  PomodoroNotification.swift
//  LightPomo
//
//  Created by Oleh on 10.01.2026.
//

import Foundation
import UserNotifications
import UIKit // Needed for UIApplication.shared.openSettingsURLString (though not directly used here, good practice if directing to settings)

class PomodoroNotification{
    
    // Function to check and request notification authorization
    static func checkAuth(completion: @escaping (Bool) -> Void){
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings(){ settings in
            // Ensure completion handler is called on the main thread for UI-related tasks
            DispatchQueue.main.async {
                switch settings.authorizationStatus{
                case .authorized: // Notifications are authorized
                    completion(true)
                case .notDetermined: // Authorization not yet requested
                    notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { allowed, error in
                        // Ensure completion handler is called on the main thread after request
                        DispatchQueue.main.async {
                            completion(allowed) // Pass the actual authorization result
                        }
                    }
                case .denied, .provisional, .ephemeral: // Notifications are denied or partially authorized
                    completion(false)
                @unknown default: // Handle any future unknown authorization statuses
                    completion(false)
                }
            }
        }
    }
    
    // Schedules a notification for when the work session should end (time for a break)
    static func scheduleBreakNotification(seconds: TimeInterval, title: String, body: String){
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Content for the notification
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        // Use a custom sound for the notification. Assumes "down.wav" is in the app bundle.
        content.sound = UNNotificationSound(named: UNNotificationSoundName(PomodoroAudioSounds.downSound.resource))
        
        // Trigger for the notification (time-based, does not repeat)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        
        // Request to schedule the notification.
        // The identifier "break_notif" ensures that a new notification with this ID will replace any existing one.
        let request = UNNotificationRequest(identifier: "break_notif", content: content, trigger: trigger)
        
        // Add the notification request to the system
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling break notification: \(error.localizedDescription)")
            } else {
                print("Break notification scheduled for \(seconds) seconds.")
            }
        }
    }

    // Schedules a notification for when the break session should end (time to get back to work)
    static func scheduleWorkNotification(seconds: TimeInterval, title: String, body: String){
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Content for the notification
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        // Use a custom sound for the notification. Assumes "up.wav" is in the app bundle.
        content.sound = UNNotificationSound(named: UNNotificationSoundName(PomodoroAudioSounds.upSound.resource))
        
        // Trigger for the notification (time-based, does not repeat)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        
        // Request to schedule the notification.
        // The identifier "work_notif" ensures that a new notification with this ID will replace any existing one.
        let request = UNNotificationRequest(identifier: "work_notif", content: content, trigger: trigger)
        
        // Add the notification request to the system
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling work notification: \(error.localizedDescription)")
            } else {
                print("Work notification scheduled for \(seconds) seconds.")
            }
        }
    }
}
