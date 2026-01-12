//
//  ContentView.swift
//  LightPomo
//
//  Created by Oleh on 10.01.2026.
//

import SwiftUI
import UserNotifications
let notificationCenter = UNUserNotificationCenter.current()

struct WorkView: View {
    @State private var timerMinutes: Int = 25
    @State private var timerSeconds: Int = 0
    @State private var isRunning = false
    @State private var timer: Timer? = nil
    @State private var showWarning = false
    
    // Here for the notification auth
    @Environment(\.scenePhase) var scenePhase
    
    
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
                if showWarning{
                    VStack{
                        Text ("Notifications are disabled")
                            .foregroundColor(.red)
                        Button("Enable"){
                            //settings
                        }
                    }
                }
            }
            .padding(.horizontal) // Apply horizontal padding to the content within the ZStack
            .onChange(of: scenePhase){
                    if scenePhase == .active{
                        PomodoroNotification.checkAuth { authorized in
                             showWarning = !authorized
                        }
                    }
            }
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

            #if !DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                PomodoroNotification.scheduleBreakNotification(seconds: Double(timerMinutes * 60 + timerSeconds), title: "LightPomo", body: "Time for a break!")
            }
            #else
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                PomodoroNotification.scheduleBreakNotification(seconds: Double(timerMinutes * 60 + timerSeconds), title: "LightPomo", body: "Time for a break!")
            }
            #endif

            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timerSeconds == 0 {
                    if timerMinutes == 0 {
                        timer?.invalidate()
                        timer = nil
                        isRunning = false
                        audio.play(.upSound)
                        // Timer finished, show break view
                        showBreakView = true
                    } else {
                        timerMinutes -= 1
                        timerSeconds = 59
                    }
                } else {
                    timerSeconds -= 1
                }
                if timerMinutes < 0 {
                    timerMinutes = 0
                }
                if timerSeconds < 0 {
                    timerSeconds = 0
                }
            }
        }
    }
}

#Preview {
    WorkView()
}
