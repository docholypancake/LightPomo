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
            
            Button("send notifications"){
                PomodoroNotification.scheduleWorkNotification(seconds: 10, title: "work", body: "test")
                
                PomodoroNotification.scheduleBreakNotification(seconds: 15, title: "break", body: "test")
            }
            
            Button("WorkView"){
//                WorkView()
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
