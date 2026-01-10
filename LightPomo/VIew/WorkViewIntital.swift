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
    
    // New state variable to store the initial minutes set by the user
    @State private var initialSetMinutes: Int = 25

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
                            if initialSetMinutes > 1 { // Changed from timerMinutes to initialSetMinutes
                                initialSetMinutes -= 1
                                // No need to update initialSetMinutes = timerMinutes here,
                                // as initialSetMinutes is now the source of truth for the picker.
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
                            if initialSetMinutes < 120 { // Changed from timerMinutes to initialSetMinutes
                                initialSetMinutes += 1
                                // No need to update initialSetMinutes = timerMinutes here.
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
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical)

                HStack {
                    Button("Start") {
                        if !isRunning {
                            isRunning = true
                            timerMinutes = initialSetMinutes // Initialize timerMinutes from initialSetMinutes
                            timerSeconds = 0 // Ensure seconds start from 0 for a fresh start
                            #if !DEBUG
                            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                                PomodoroNotification.scheduleNotification(seconds: Double(timerMinutes * 60 + timerSeconds), title: "LightPomo", body: "Time for a break!")
                            }
                            #else
                            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                                PomodoroNotification.scheduleNotification(seconds: Double(timerMinutes * 60 + timerSeconds), title: "LightPomo", body: "Time for a break!")
                            }
                            #endif
                            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                                if timerSeconds == 0 {
                                    if timerMinutes == 0 {
                                        timer?.invalidate()
                                        timer = nil
                                        isRunning = false
                                        audio.play(.upSound)
                                        // Timer finished, reset to initialSetMinutes
                                        timerMinutes = initialSetMinutes
                                        timerSeconds = 0
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
            }
            .padding(.horizontal) // Apply horizontal padding to the content within the ZStack
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

#Preview {
    WorkView()
}
