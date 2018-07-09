//
//  TextToSpeechManager.swift
//  SpeechToTextDemo
//
//  Created by Mohit Kapadia on 01/06/18.
//  Copyright © 2018 Mohit Kapadia. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation


//MARK: --- LanguageInfo ---
/// Model to store language information
struct LanguageInfo : Equatable{
    var name: String
    var code: String
    
    static func ==(_ lhs: LanguageInfo, _ rhs:LanguageInfo)->Bool {
        return lhs.code == rhs.code
    }
    
    static func !=(_ lhs: LanguageInfo, _ rhs:LanguageInfo)->Bool {
        return lhs.code != rhs.code
    }
}

//MARK: --- Utterance ---
class Utterance: AVSpeechUtterance {
    var tag: Int? = nil
}


//MARK: --- SpeechText ----

/// Data Model to hold Text to Speak
class SpeechText {
    var stringToSpeak : String? = nil
    var language : LanguageInfo?
    
    var utteranceRate : Float = AVSpeechUtteranceDefaultSpeechRate
    var utterancePitch : Float = 1.0
    var utteranceVolume : Float = 1.0
    
    
    init(text:String, language:LanguageInfo?) {
        self.stringToSpeak = text
        self.language = language
    }
    
    func setRate(_ rate:Float) {
        self.utteranceRate = rate
    }
    
    func setPitch(_ pitch:Float) {
        self.utterancePitch = pitch
    }
    
    func setVolume(_ volume: Float) {
        self.utteranceVolume = volume
    }
    
}

//MARK: --- TTSManagerDelegate ---
/// TTSManagerDelegate: Updates the conforming 'Type' about AVSpeechSynthesizerDelegate and Progress of the speech
protocol TTSManagerDelegate  {
    func didStartSpeaking(speechText:SpeechText)
    func didPauseSpeaking(speechText:SpeechText)
    func didCancelSpeaking(speechText:SpeechText)
    func didContinueSpeaking(speechText:SpeechText)
    func didFinishSpeaking(speechText:SpeechText)
    func willSpeakString(characterRange: NSRange, word:String)

    func updateProgress(value:Float)
    
}

//MARK: --- TextToSpeechManager ---
/// TextToSpeechManager:
class TextToSpeechManager : NSObject {
    
    static let shared : TextToSpeechManager = TextToSpeechManager()
    
    var synthesizer : AVSpeechSynthesizer!
    var progress: Float = 0.0
    var spokenTextLength : Int = 0
    var currentUtteranceSpokenTextLength : Int = 0
    var totalTextLength: Int = 0
    var texts: [SpeechText] = []
    
    var delegate: TTSManagerDelegate? = nil
    var currentUtterance: Int? = nil
    var preUtteranceDelay : TimeInterval = 0.0
    var postUtteranceDelay : TimeInterval = 0.0
    
    
    //Initialiser
    private override init(){
        super.init()
        self.synthesizer = AVSpeechSynthesizer()
        self.synthesizer.delegate = self
    }
    
    lazy var speechVoices : [LanguageInfo] = {
        return AVSpeechSynthesisVoice.speechVoices().flatMap({ (voice) -> LanguageInfo? in
            let voiceLanguageCode = voice.language
            if let languageName = (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier, value: voiceLanguageCode) {
                return LanguageInfo(name: languageName, code: voiceLanguageCode)
            }
            return nil
        })
    }()
    
    var isSpeaking : Bool {
        return self.synthesizer.isSpeaking
    }
    
    var isPaused : Bool {
        return self.synthesizer.isPaused
    }
    
    let getMaximumUtteranceRate = {
        return AVSpeechUtteranceMaximumSpeechRate
    }
    
    let getMinimumUtteranceRate = {
        return AVSpeechUtteranceMinimumSpeechRate
    }
    
    private func setupSpeechSynthesiser() {
        if !self.synthesizer.isSpeaking {
            self.totalTextLength = 0
            self.spokenTextLength = 0
            self.progress = 0
            self.currentUtterance = nil
            for (idx , speechText) in texts.enumerated() {
                
                if let str = speechText.stringToSpeak {
                    print("Text to Speak:%@",str)
                    self.totalTextLength = self.totalTextLength + str.utf16.count
                    
                    let utterance = Utterance(string: str)  
                    utterance.tag = idx
                    
                    if let language = speechText.language?.code {
                        utterance.voice = AVSpeechSynthesisVoice(language: language)
                    }
                    
                    utterance.volume = speechText.utteranceVolume
                    utterance.rate = speechText.utteranceRate
                    utterance.pitchMultiplier = speechText.utterancePitch
                    
                    self.synthesizer.speak(utterance)
                }
            }
        } else {
            self.synthesizer.continueSpeaking()
        }
    }
    
    func startSpeaking(text:SpeechText...) {
        self.texts = text
        self.setupSpeechSynthesiser()
    }
    
    
    func pauseSpeech() {
        if self.synthesizer.isPaused {
            //if already paused, then play
            self.synthesizer.continueSpeaking()
        } else {
            //if not paused, then pause
            self.synthesizer.pauseSpeaking(at: AVSpeechBoundary.word)
        }
    }
    
    
    func stopSpeech() {
        self.synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
    }
    
    func setSpeechVolume(value:Float) {
        if let currentIndex = currentUtterance {
            let speech = self.texts[currentIndex]
            speech.setVolume(value)
            print("\nupdated volume:\(value)\n")
        }
    }
    
    func setUtteranceRate(value: Float) {
        if let currentIndex = currentUtterance {
            let speech = self.texts[currentIndex]
            speech.setRate(value)
            print("\nupdated rate:\(value)\n")
        }
    }
}


extension TextToSpeechManager : AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.spokenTextLength = self.spokenTextLength + self.currentUtteranceSpokenTextLength
        self.currentUtterance = nil
        self.currentUtteranceSpokenTextLength = 0

        if let tag = (utterance as! Utterance).tag, tag == texts.count - 1 {
            print("completed all texts")
            self.delegate?.updateProgress(value: self.progress)
            let speechInfo = self.texts[tag]
            self.delegate?.didFinishSpeaking(speechText: speechInfo)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        //Spaces not counted when this delegate is called hence spokenlength should be increased by 1.
        self.currentUtteranceSpokenTextLength = characterRange.location + characterRange.length

        let temp = self.spokenTextLength + self.currentUtteranceSpokenTextLength
        print("Total length to Speak: \(self.totalTextLength), Total Words Spoken: \(temp), Curren Word Length: \(characterRange.length)")
        let tempProgress : Float = Float(temp) / Float(totalTextLength)
        
        //Update only when there is atleast 1% progress. For more precise update comment this check
        if abs(tempProgress - self.progress) >= 0.01 {
            self.progress = tempProgress
            print("Progress:\(self.progress)")
            self.delegate?.updateProgress(value: self.progress )
        }
        
        if let tag = (utterance as! Utterance).tag {
            let speechInfo = self.texts[tag]
            let willSpeakWord = (speechInfo.stringToSpeak! as NSString).substring(with: characterRange)
            self.delegate?.willSpeakString(characterRange: characterRange, word: willSpeakWord)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        if let tag = (utterance as! Utterance).tag {
            print("speaking utterance with tag:\(tag)")
            self.currentUtterance = tag
            self.currentUtteranceSpokenTextLength = 0
            print("Did Start called")
            
            let speechInfo = self.texts[tag]
            self.delegate?.didStartSpeaking(speechText: speechInfo)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        
        if let tag = (utterance as! Utterance).tag {
            print("Did Pause called")
            let speechInfo = self.texts[tag]
            self.delegate?.didPauseSpeaking(speechText: speechInfo)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        self.spokenTextLength = 0
        self.currentUtterance = nil
        self.currentUtteranceSpokenTextLength = 0
        
        if let tag = (utterance as! Utterance).tag {
            print("Did Cancel Cancel")
            let speechInfo = self.texts[tag]
            self.delegate?.didCancelSpeaking(speechText: speechInfo)
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        if let tag = (utterance as! Utterance).tag {
            print("Did Continue Cancel")
            let speechInfo = self.texts[tag]
            self.delegate?.didContinueSpeaking(speechText: speechInfo)
        }
    }
    
    
}

