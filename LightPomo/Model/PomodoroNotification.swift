//
//  PomodoroNotification.swift
//  LightPomo
//
//  Created by Oleh on 10.01.2026.
//

import Foundation
import UserNotifications

class PomodoroNotification{
    
    static func checkAuth(completion: @escaping (Bool) -> Void){
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings(){ settings in
            switch settings.authorizationStatus{
            case .authorized:
                completion(true)
            case .notDetermined:
                notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { allowed, error in
                    completion(true)
                }
            default:
                completion(false)
            }
        }
    }
    
    static func scheduleNotification(seconds: TimeInterval, title: String, body: String){
        let notificationCenter = UNUserNotificationCenter.current()
        
        //previous notification handling
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
        
        //content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.sound = UNNotificationSound(named: UNNotificationSoundName(PomodoroAudioSounds.upSound.resource))
        
        //trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        
        //request
        let request = UNNotificationRequest(identifier: "notif", content: content, trigger: trigger)
        
        //adding request
        notificationCenter.add(request)
        
    }
    
    // Schedule a notification without clearing existing ones
    static func addNotification(seconds: TimeInterval, title: String, body: String, identifier: String){
        let notificationCenter = UNUserNotificationCenter.current()
        
        //content
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound(named: UNNotificationSoundName(PomodoroAudioSounds.upSound.resource))
        
        //trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        
        //request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        //adding request
        notificationCenter.add(request)
    }
}
