//
//  ContentView.swift
//  LightPomo
//
//  Created by Oleh on 10.01.2026.
//

import SwiftUI
import UserNotifications
import UIKit // Required for UIApplication.openSettingsURLString

// Global constants for notification center and User Defaults key
let notificationCenter = UNUserNotificationCenter.current()
let workEndTimeKey = "WorkTimerEndTime"

struct WorkView: View {
    @State private var timerMinutes: Int = 25
    @State private var timerSeconds: Int = 0
    @State private var isRunning = false
    @State private var timer: Timer? = nil
    @State private var showWarning = false
    
    // Environment property to observe scene phase changes for foreground/background logic
    @Environment(\.scenePhase) var scenePhase
    
    // State variable to store the initial minutes set by the user for work
    @State private var initialSetMinutes: Int = 25
    // New state variable for break duration, configurable by the user
    @State private var initialSetBreakMinutes: Int = 5 // Default 5 minutes break

    // State variable to control the presentation of BreakView
    @State private var showBreakView = false

    // Audio player instance
    let audio = PomodoroAudio()

    var body: some View {
        ZStack { // Use a ZStack to ensure the background fills completely
            Color.red // This will be the full-screen background for WorkView
                .ignoresSafeArea()

            VStack {
                Text("Work")
                    .font(.system(size: 60, weight: .heavy)) // Large and bold title
                    .padding(.bottom, 20) // Add some space below the title
                    .foregroundColor(.white)

                Text(String(format: "%02d:%02d", timerMinutes, timerSeconds))
                    .font(.system(size: 80, weight: .black)) // Very large and bold timer display
                    .padding(.top)
                    .foregroundColor(.white)


                VStack {
                    // Custom Minute Picker for Work Duration
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
                        .disabled(isRunning || initialSetMinutes == 1) // Disable if timer is running or at min value

                        Text("\(initialSetMinutes) min Work") // Display initialSetMinutes
                            .font(.headline)
                            .fontWeight(.regular)
                            .frame(minWidth: 90) // Adjusted width for "min Work"
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
                        .disabled(isRunning || initialSetMinutes == 120) // Disable if timer is running or at max value
                    }
                    .padding(8)
                    .background(Color.red.opacity(0.3))
                    .cornerRadius(15)
                    .opacity(isRunning ? 0.5 : 1.0) // Dim the picker when timer is running
                    .padding(.bottom, 10) // Space between pickers

                    // Custom Minute Picker for Break Duration
                    HStack(spacing: 8) {
                        Button {
                            if initialSetBreakMinutes > 1 {
                                initialSetBreakMinutes -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .disabled(isRunning || initialSetBreakMinutes == 1) // Disable if timer is running or at min value

                        Text("\(initialSetBreakMinutes) min Break") // Display initialSetBreakMinutes
                            .font(.headline)
                            .fontWeight(.regular)
                            .frame(minWidth: 90) // Adjusted width for "min Break"
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)

                        Button {
                            if initialSetBreakMinutes < 60 {
                                initialSetBreakMinutes += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .disabled(isRunning || initialSetBreakMinutes == 60) // Disable if timer is running or at max value
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
                        startWorkTimer() // Call the helper function to start the timer and schedule notifications
                    }
                    .disabled(isRunning) // Disable if timer is already running
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding()

                    if isRunning { // Show Stop button only when timer is running
                        Button("Stop") {
                            timer?.invalidate() // Stop the internal timer
                            timer = nil
                            isRunning = false
                            timerMinutes = initialSetMinutes // Reset timer display to initial work duration
                            timerSeconds = 0
                            UserDefaults.standard.removeObject(forKey: workEndTimeKey) // Clear saved end time
                            
                            // Clear all delivered and pending notifications
                            let notificationCenter = UNUserNotificationCenter.current()
                            notificationCenter.removeAllDeliveredNotifications() // Clear visible notifications from Notification Center
                            notificationCenter.removeAllPendingNotificationRequests() // Clear all scheduled notifications
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .padding()
                    }
                }
                if showWarning{ // Display notification warning if authorization is denied
                    VStack{
                        Text ("Notifications are disabled")
                            .foregroundColor(.white) // Changed to white for better contrast on red background
                        Button("Enable"){
                            // Navigate to app settings to allow user to enable notifications
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                    .padding(.top, 10)
                }
            }
            .padding(.horizontal) // Apply horizontal padding to the content within the ZStack
            .onAppear {
                restoreTimerState() // Restore timer state when the view appears
            }
            // Observe scenePhase changes to handle app moving to/from background
            .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active { // When the app comes to the foreground
                        PomodoroNotification.checkAuth { authorized in // Check notification authorization status
                             showWarning = !authorized // Update warning display
                            // If authorized and the timer was running, ensure notifications are scheduled
                            if authorized && isRunning {
                                if let savedEndTime = UserDefaults.standard.object(forKey: workEndTimeKey) as? Date, savedEndTime > Date() {
                                    scheduleNotificationsForCurrentCycle() // Re-schedule notifications if the timer is still active
                                }
                            }
                        }
                        restoreTimerState() // Always restore timer state to sync with world clock
                    }
            }
        }
        .onDisappear {
            timer?.invalidate() // Invalidate timer when the view disappears
            timer = nil
        }
        // Present BreakView as a full-screen cover when showBreakView is true
        .fullScreenCover(isPresented: $showBreakView) {
            BreakView(initialBreakDurationMinutes: initialSetBreakMinutes, onDismiss: { // Pass configured break duration
                // This closure is called when BreakView is dismissed
                startWorkTimer() // Automatically start the next work timer (and reschedule notifications)
            })
        }
    }

    // Helper function to encapsulate notification scheduling logic
    private func scheduleNotificationsForCurrentCycle() {
        let currentWorkDurationSeconds = initialSetMinutes * 60
        let currentBreakDurationSeconds = initialSetBreakMinutes * 60

        // Only schedule if not in a SwiftUI Preview environment
        // The XCODE_RUNNING_FOR_PREVIEWS environment variable is reliable across Xcode versions
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return // Don't schedule notifications in SwiftUI Previews
        }
        
        // Clear all previous pending notifications before scheduling new ones for the current cycle
        notificationCenter.removeAllPendingNotificationRequests()

        // Schedule "Break Time" notification (when work ends)
        PomodoroNotification.scheduleBreakNotification(
            seconds: Double(currentWorkDurationSeconds),
            title: "LightPomo",
            body: "Time for a break!"
        )

        // Schedule "Back to Work" notification (when break ends)
        PomodoroNotification.scheduleWorkNotification(
            seconds: Double(currentWorkDurationSeconds + currentBreakDurationSeconds),
            title: "LightPomo",
            body: "Break is over, get back to work!"
        )
    }

    // Helper function to encapsulate timer starting logic
    private func startWorkTimer() {
        if !isRunning { // Ensure timer isn't already running
            isRunning = true
            timerMinutes = initialSetMinutes // Initialize timerMinutes from initialSetMinutes
            timerSeconds = 0 // Ensure seconds start from 0 for a fresh start
            
            // Calculate and save the exact end time to UserDefaults for persistence
            let endTime = Date().addingTimeInterval(TimeInterval(timerMinutes * 60 + timerSeconds))
            UserDefaults.standard.set(endTime, forKey: workEndTimeKey)

            // Schedule both break and back-to-work notifications for the current cycle
            scheduleNotificationsForCurrentCycle()

            // Start a new repeating timer
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                // For structs, 'self' is implicitly copied into the closure if mutable state is accessed,
                // or implicitly captured by value if only immutable state is accessed.
                // A strong reference cycle (leak) does not occur here with a Timer directly held by a struct @State.
                
                guard let savedEndTime = UserDefaults.standard.object(forKey: workEndTimeKey) as? Date else {
                    // If no end time is saved, something went wrong, reset the timer state
                    resetTimerState()
                    return
                }
                
                let remaining = Int(savedEndTime.timeIntervalSinceNow) // Calculate remaining time
                if remaining <= 0 {
                    resetTimerState() // Timer finished, reset state
                    audio.play(.upSound) // Play completion sound
                    showBreakView = true // Show the BreakView
                } else {
                    timerMinutes = remaining / 60 // Update minutes display
                    timerSeconds = remaining % 60 // Update seconds display
                }
            }
        }
    }
    
    // Function to restore timer state when the app becomes active or view appears
    private func restoreTimerState() {
        if let savedEndTime = UserDefaults.standard.object(forKey: workEndTimeKey) as? Date {
            let remaining = Int(savedEndTime.timeIntervalSinceNow) // Time left until saved end time
            if remaining > 0 {
                // If time is still remaining, resume the timer
                timerMinutes = remaining / 60
                timerSeconds = remaining % 60
                isRunning = true
                // If the timer is not already active, start a new one
                if timer == nil {
                    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                        // Same logic for structs applies here.
                        guard let savedEndTime = UserDefaults.standard.object(forKey: workEndTimeKey) as? Date else {
                            resetTimerState()
                            return
                        }
                        let remaining = Int(savedEndTime.timeIntervalSinceNow)
                        if remaining <= 0 {
                            resetTimerState()
                            audio.play(.upSound)
                            showBreakView = true
                        } else {
                            timerMinutes = remaining / 60
                            timerSeconds = remaining % 60
                        }
                    }
                }
                // Ensure notifications are correctly scheduled for the remaining time
                scheduleNotificationsForCurrentCycle()

            } else {
                // Timer expired while the app was inactive
                resetTimerState()
                audio.play(.upSound)
                showBreakView = true // Immediately show BreakView if the work timer is already over
            }
        } else {
            // No saved timer, reset to initial state
            resetTimerState()
        }
    }

    // Helper function to reset all timer-related state variables
    private func resetTimerState() {
        timer?.invalidate() // Stop the internal timer
        timer = nil
        isRunning = false
        timerMinutes = initialSetMinutes // Reset display to initial work minutes
        timerSeconds = 0
        UserDefaults.standard.removeObject(forKey: workEndTimeKey) // Clear saved end time
    }
}

#Preview {
    WorkView()
}
