//
//  ContentView.swift
//  LightPomo
//
//  Created by Oleh on 10.01.2026.
//

import SwiftUI
import UserNotifications

struct WorkView: View {
    @State private var timerMinutes: Int = 25
    @State private var timerSeconds: Int = 0
    @State private var isRunning = false
    @State private var timer: Timer? = nil
    @State private var endDate: Date? = nil // Store the target end time
    
    // State variable to store the initial minutes set by the user
    @State private var initialSetMinutes: Int = 25

    // New state variable to control the presentation of BreakView
    @State private var showBreakView = false

    let audio = PomodoroAudio()

    var body: some View {
        ZStack { // Use a ZStack to ensure the background fills completely
            Color.red // This will be the full-screen background
                .ignoresSafeArea()

            VStack {
                Text("Work")
                    .font(.system(size: 60, weight: .heavy)) // Really large and bold
                    .padding(.bottom, 20) // Add some space below the title
                    .foregroundColor(.white)

                Text(String(format: "%02d:%02d", timerMinutes, timerSeconds))
                    .font(.system(size: 80, weight: .black)) // Really large and really bold
                    .padding(.top)
                    .foregroundColor(.white)


                VStack {
                    // Custom Minute Picker
                    HStack(spacing: 8) {
                        Button {
                            if initialSetMinutes > 1 {
                                initialSetMinutes -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .disabled(isRunning || initialSetMinutes == 1) // Disable based on initialSetMinutes

                        Text("\(initialSetMinutes) min") // Display initialSetMinutes here
                            .font(.headline)
                            .fontWeight(.regular)
                            .frame(minWidth: 60)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)


                        Button {
                            if initialSetMinutes < 120 {
                                initialSetMinutes += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .disabled(isRunning || initialSetMinutes == 120) // Disable based on initialSetMinutes
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.3))
                    .cornerRadius(15)
                    .opacity(isRunning ? 0.5 : 1.0) // Dim the picker when timer is running
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical)

                HStack {
                    Button("Start") {
                        startWorkTimer() // Call the new helper function
                    }
                    .disabled(isRunning)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding()

                    if isRunning {
                        Button("Stop") {
                            timer?.invalidate()
                            timer = nil
                            isRunning = false
                            endDate = nil
                            timerMinutes = initialSetMinutes // Reset to the stored initial value
                            timerSeconds = 0
                            let notificationCenter = UNUserNotificationCenter.current()
                            notificationCenter.removeAllDeliveredNotifications()
                            notificationCenter.removeAllPendingNotificationRequests()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .padding()
                    }
                }
            }
            .padding(.horizontal) // Apply horizontal padding to the content within the ZStack
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        // Present BreakView when showBreakView is true
        .fullScreenCover(isPresented: $showBreakView) {
            BreakView(onDismiss: {
                // This closure will be called when BreakView is dismissed
                startWorkTimer() // Automatically start the work timer again
            })
        }
    }

    // Helper function to encapsulate timer starting logic
    private func startWorkTimer() {
        if !isRunning { // Ensure timer isn't already running
            isRunning = true
            timerMinutes = initialSetMinutes // Initialize timerMinutes from initialSetMinutes
            timerSeconds = 0 // Ensure seconds start from 0 for a fresh start
            
            // Set the end date based on current time plus duration
            let totalSeconds = timerMinutes * 60 + timerSeconds
            endDate = Date().addingTimeInterval(TimeInterval(totalSeconds))

            #if !DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                scheduleNotificationsUpTo24Hours(totalSeconds: totalSeconds)
            }
            #else
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                scheduleNotificationsUpTo24Hours(totalSeconds: totalSeconds)
            }
            #endif

            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                guard let targetDate = endDate else {
                    timer?.invalidate()
                    timer = nil
                    isRunning = false
                    return
                }
                
                let remaining = targetDate.timeIntervalSinceNow
                
                if remaining <= 0 {
                    // Timer finished
                    timer?.invalidate()
                    timer = nil
                    isRunning = false
                    endDate = nil
                    timerMinutes = 0
                    timerSeconds = 0
                    audio.play(.upSound)
                    showBreakView = true
                } else {
                    // Update display based on remaining time
                    let minutes = Int(remaining) / 60
                    let seconds = Int(remaining) % 60
                    timerMinutes = minutes
                    timerSeconds = seconds
                }
            }
        }
    }
    
    // Schedule notifications for up to 24 hours
    private func scheduleNotificationsUpTo24Hours(totalSeconds: Int) {
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Remove all previous notifications
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Schedule main timer completion notification
        PomodoroNotification.scheduleNotification(
            seconds: Double(totalSeconds),
            title: "LightPomo",
            body: "Time for a break!"
        )
        
        // If timer is longer than 1 hour, schedule additional intermediate notifications
        // up to 24 hours (iOS limit) for better user awareness
        let maxNotificationTime = min(totalSeconds, 24 * 60 * 60) // Cap at 24 hours
        var notificationTimes: [Double] = []
        
        // Schedule notifications at intervals for user awareness of long running timers
        if totalSeconds > 3600 { // If more than 1 hour
            var currentTime = 3600.0 // Start at 1 hour
            while currentTime < Double(maxNotificationTime) {
                notificationTimes.append(currentTime)
                currentTime += 3600.0 // Every hour
            }
        }
        
        // Schedule the intermediate notifications
        for (index, time) in notificationTimes.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "LightPomo"
            content.body = "Timer still running..."
            content.sound = nil // Silent notification
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: time, repeats: false)
            let request = UNNotificationRequest(
                identifier: "intermediate-\(index)",
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request)
        }
    }
}

#Preview {
    WorkView()
}
