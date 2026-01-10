//
//  PomodoroAudio.swift
//  LightPomo
//
//  Created by Oleh on 10.01.2026.
//

import Foundation
import AVFoundation

enum PomodoroAudioSounds{
    case upSound
    case downSound
    
    var resource: String {
        switch self {
        case .upSound:
            return "up.wav"
        case .downSound:
            return "down.wav"
        }
    }
}

class PomodoroAudio {
    private var audioPlayer: AVAudioPlayer?
    
    func play(_ sound: PomodoroAudioSounds){
        let path = Bundle.main.path(forResource: sound.resource, ofType: nil)!
        let url = URL(filePath: path)
        
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print(error.localizedDescription)
        }
        
        
    }
}
