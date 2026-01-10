//
//  SwiftUIView.swift
//  LightPomo
//
//  Created by Oleh on 10.01.2026.
//



import SwiftUI

struct TestView: View {
    @State private var showWarning = false
    @Environment(\.scenePhase) var scenePhase
    
    var audioPlayer = PomodoroAudio()
    
    var body: some View {
        VStack{
            Button("Play up"){
                audioPlayer.play(.upSound)
            }
            Button("play down"){
                audioPlayer.play(.downSound)
            }
            
            Button("send notification"){
                PomodoroNotification.scheduleNotification(seconds: 5, title: "Test", body: "hi")
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
        .onChange(of: scenePhase){
                if scenePhase == .active{
                    PomodoroNotification.checkAuth { authorized in
                         showWarning = !authorized
                    }
                }
        }
        
    }
    
}

#Preview {
    TestView()
}
