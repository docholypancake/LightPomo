//
//  BreakView.swift
//  LightPomo
//
//  Created by Oleh on 10.01.2026.
//

import SwiftUI

struct BreakView: View {
    @Environment(\.dismiss) var dismiss // Use @Environment to dismiss the view
    var onDismiss: (() -> Void)? = nil // Closure to call when dismissing

    @State private var timerMinutes: Int = 5 // 5 minutes for short break
    @State private var timerSeconds: Int = 0
    @State private var breakTimer: Timer? = nil // Renamed to avoid conflict with WorkView's timer
    @State private var breakEndDate: Date? = nil // Store the target end time for break

    let audio = PomodoroAudio()

    // Animation states for internal elements
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showTimer = false
    @State private var showButton = false

    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea() // Background changed to green

            VStack {
                Image(systemName: "cup.and.saucer.fill") 
                    .imageScale(.large)
                    .font(.system(size: 80)) // Larger icon
                    .foregroundStyle(.white)
                    .padding(.bottom, 20)
                    .opacity(showIcon ? 1 : 0) // Animate opacity
                    .scaleEffect(showIcon ? 1 : 0.8) // Animate scale

                Text("Short Break")
                    .font(.system(size: 60, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                    .opacity(showTitle ? 1 : 0) // Animate opacity
                    .offset(y: showTitle ? 0 : 20) // Animate vertical offset

                // Countdown Timer for Break
                Text(String(format: "%02d:%02d", timerMinutes, timerSeconds))
                    .font(.system(size: 80, weight: .black))
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                    .opacity(showTimer ? 1 : 0) // Animate opacity
                    .scaleEffect(showTimer ? 1 : 0.8) // Animate scale


                Button("Continue Work") {
                    audio.play(.upSound)
                    breakTimer?.invalidate() // Stop the break timer
                    breakTimer = nil
                    breakEndDate = nil
                    dismiss() // Dismiss the current view
                    onDismiss?() // Call the onDismiss closure
                }
                .buttonStyle(.borderedProminent)
                .tint(.red) // Button color changed to red
                .controlSize(.large) // Make the button larger
                .opacity(showButton ? 1 : 0) // Animate opacity
                .offset(y: showButton ? 0 : 20) // Animate vertical offset
            }
        }
        .onAppear {
            startBreakTimer() // Start the break timer when view appears

            // Sequential animations for the content
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showIcon = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showTitle = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                showTimer = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                showButton = true
            }
        }
        .onDisappear {
            breakTimer?.invalidate() // Invalidate timer when view disappears
            breakTimer = nil
            breakEndDate = nil
            // Reset animation states for next appearance if needed
            showIcon = false
            showTitle = false
            showTimer = false
            showButton = false
        }
    }

    private func startBreakTimer() {
        // Set the end date based on current time plus duration
        let totalSeconds = timerMinutes * 60 + timerSeconds
        breakEndDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
        
        // TODO: Schedule "back to work" notifications
        // scheduleBackToWorkNotifications(totalSeconds: totalSeconds)
        
        breakTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard let targetDate = breakEndDate else {
                breakTimer?.invalidate()
                breakTimer = nil
                return
            }
            
            let remaining = targetDate.timeIntervalSinceNow
            
            if remaining <= 0 {
                // Timer finished
                breakTimer?.invalidate()
                breakTimer = nil
                breakEndDate = nil
                timerMinutes = 0
                timerSeconds = 0
                audio.play(.upSound)
                dismiss()
                onDismiss?()
            } else {
                // Update display based on remaining time
                let minutes = Int(remaining) / 60
                let seconds = Int(remaining) % 60
                timerMinutes = minutes
                timerSeconds = seconds
            }
        }
    }
    
    // Placeholder for "back to work" notification scheduling
    // TODO: Implement this method later
    private func scheduleBackToWorkNotifications(totalSeconds: Int) {
        // This will schedule "back to work" notifications in a loop
        // Similar to break notifications: every (breaktime + 5) minutes up to 24 hours
        /*
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Remove all previous notifications
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Schedule main break completion notification
        PomodoroNotification.addNotification(
            seconds: Double(totalSeconds),
            title: "LightPomo",
            body: "Time to get back to work!",
            identifier: "break-complete"
        )
        
        // Schedule back to work notifications every (breaktime + 5) minutes up to 24 hours
        let breakTimeInSeconds = totalSeconds
        let notificationIntervalSeconds = breakTimeInSeconds + (5 * 60) // breaktime + 5 minutes
        let maxNotificationTime = 24 * 60 * 60 // 24 hours (iOS notification limit)
        
        var currentNotificationTime = notificationIntervalSeconds
        var notificationIndex = 0
        
        while currentNotificationTime <= maxNotificationTime {
            PomodoroNotification.addNotification(
                seconds: Double(currentNotificationTime),
                title: "LightPomo",
                body: "Time to get back to work!",
                identifier: "back-to-work-\(notificationIndex)"
            )
            
            currentNotificationTime += notificationIntervalSeconds
            notificationIndex += 1
        }
        */
    }
}

#Preview {
    BreakView()
}
