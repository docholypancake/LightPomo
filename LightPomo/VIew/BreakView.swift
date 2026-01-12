//
//  BreakView.swift
//  LightPomo
//
//  Created by Oleh on 10.01.2026.
//

import SwiftUI
import UserNotifications

struct BreakView: View {
    @Environment(\.dismiss) var dismiss // Use @Environment to dismiss the view
    var onDismiss: (() -> Void)? = nil // Closure to call when dismissing, typically to signal WorkView

    // Now accepts initialBreakDuration from WorkView to sync break times
    let initialBreakDurationMinutes: Int

    @State private var timerMinutes: Int // Will be initialized from initialBreakDurationMinutes
    @State private var timerSeconds: Int = 0
    @State private var breakTimer: Timer? = nil // Renamed to avoid conflict with WorkView's timer

    let audio = PomodoroAudio()

    // Animation states for internal elements to create a dynamic appearance
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showTimer = false
    @State private var showButton = false

    // Custom initializer to set the initial state for the timer from the passed-in duration
    init(initialBreakDurationMinutes: Int, onDismiss: (() -> Void)? = nil) {
        self.initialBreakDurationMinutes = initialBreakDurationMinutes
        self.onDismiss = onDismiss
        _timerMinutes = State(initialValue: initialBreakDurationMinutes) // Initialize @State timerMinutes
    }

    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea() // Background changed to green for break state

            VStack {
                Image(systemName: "cup.and.saucer.fill") // Coffee cup icon
                    .imageScale(.large)
                    .font(.system(size: 80)) // Larger icon
                    .foregroundStyle(.white)
                    .padding(.bottom, 20)
                    .opacity(showIcon ? 1 : 0) // Animate opacity for icon
                    .scaleEffect(showIcon ? 1 : 0.8) // Animate scale for icon

                Text("Short Break") // Break title
                    .font(.system(size: 60, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                    .opacity(showTitle ? 1 : 0) // Animate opacity for title
                    .offset(y: showTitle ? 0 : 20) // Animate vertical offset for title

                // Countdown Timer for Break
                Text(String(format: "%02d:%02d", timerMinutes, timerSeconds))
                    .font(.system(size: 80, weight: .black))
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                    .opacity(showTimer ? 1 : 0) // Animate opacity for timer
                    .scaleEffect(showTimer ? 1 : 0.8) // Animate scale for timer


                Button("Continue Work") { // Button to manually end break and return to work
                    audio.play(.upSound) // Play a sound on button tap
                    breakTimer?.invalidate() // Stop the break timer
                    breakTimer = nil
                    dismiss() // Dismiss the current view (BreakView)
                    onDismiss?() // Call the onDismiss closure, which signals WorkView to restart
                }
                .buttonStyle(.borderedProminent)
                .tint(.red) // Button color changed to red
                .controlSize(.large) // Make the button larger
                .opacity(showButton ? 1 : 0) // Animate opacity for button
                .offset(y: showButton ? 0 : 20) // Animate vertical offset for button
            }
        }
        .onAppear {
            startBreakTimer() // Start the break timer countdown when view appears

            // Sequential animations for the content elements upon appearance
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
            // Reset animation states for next appearance if needed
            showIcon = false
            showTitle = false
            showTimer = false
            showButton = false
        }
    }

    // Helper function to start and manage the break countdown timer
    private func startBreakTimer() {
        // BreakView no longer schedules notifications; WorkView is now responsible for scheduling both
        // the "break time" and "back to work" notifications for the entire cycle.
        
        breakTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in // Removed [weak self]
            // For structs, 'self' is implicitly copied into the closure if mutable state is accessed,
            // or implicitly captured by value if only immutable state is accessed.
            // A strong reference cycle (leak) does not occur here with a Timer directly held by a struct @State.

            if timerSeconds == 0 {
                if timerMinutes == 0 {
                    breakTimer?.invalidate() // Timer finished
                    breakTimer = nil
                    audio.play(.upSound) // Play completion sound
                    dismiss() // Automatically dismiss BreakView
                    onDismiss?() // Signal WorkView to restart work timer
                } else {
                    timerMinutes -= 1 // Decrement minutes
                    timerSeconds = 59 // Reset seconds to 59
                }
            } else {
                timerSeconds -= 1 // Decrement seconds
            }
            // Ensure timer cannot go negative (safety check)
            if timerMinutes < 0 { timerMinutes = 0 }
            if timerSeconds < 0 { timerSeconds = 0 }
        }
    }
}

#Preview {
    BreakView(initialBreakDurationMinutes: 5) // Provide a default for the preview
}
