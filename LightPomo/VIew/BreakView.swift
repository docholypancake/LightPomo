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
            // Reset animation states for next appearance if needed
            showIcon = false
            showTitle = false
            showTimer = false
            showButton = false
        }
    }

    private func startBreakTimer() {
        breakTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timerSeconds == 0 {
                if timerMinutes == 0 {
                    breakTimer?.invalidate()
                    breakTimer = nil
                    audio.play(.upSound)
                    // Timer finished, automatically dismiss
                    dismiss()
                    onDismiss?()
                } else {
                    timerMinutes -= 1
                    timerSeconds = 59
                }
            } else {
                timerSeconds -= 1
            }
            // Ensure timer cannot go negative (safety)
            if timerMinutes < 0 { timerMinutes = 0 }
            if timerSeconds < 0 { timerSeconds = 0 }
        }
    }
}

#Preview {
    BreakView()
}
