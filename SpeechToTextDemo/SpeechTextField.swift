//
//  SpeechTextField.swift
//  SpeechToTextDemo
//
//  Created by Mohit Kapadia on 20/12/16.
//  Copyright © 2016 Mohit Kapadia. All rights reserved.
//

import UIKit
import Speech

public let kSpeechTextFieldListeningWillStartNotification : NSNotification.Name = NSNotification.Name(rawValue: "SpeechTextFieldListeningWillStart")
public let kSpeechTextFieldListeningWillEndNotification : NSNotification.Name = NSNotification.Name(rawValue: "SpeechTextFieldListeningWillEnd")


class SpeechTextField: UITextField,SFSpeechRecognizerDelegate {
    
    //Mic Button properties
    var micButton : UIButton? = nil
    var sizeOfButton : CGSize? = nil
    var micButtonEnableImage : UIImage? = nil
    var micButtonDisableImage : UIImage? = nil
    var paddingToButton : CGFloat = 5
    
    var cancelButton:UIButton? = nil
    
    //Speech Recognizer properties
    
    //Can add multiple Local-->
    let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var query: String? = ""
    
    //Desc: Enum to handle errors
    enum ErrorMessage: String {
        case Denied = "To enable Speech Recognition go to Settings -> Privacy."
        case NotDetermined = "Authorization not determined - please try again."
        case Restricted = "Speech Recognition is restricted on this device."
        case NoResults = "No results found - please try a different search."
        case UnAvailable = "Speech Recognition is currently unavailable."
    }
    
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation. */
    override func draw(_ rect: CGRect) {
        // Drawing code
        if micButton == nil
        {
            self.addMicButton()
        }
    }
    
    //MARK: --- Set View ----
    func addMicButton(){
        if self.sizeOfButton == nil{
            //defualt size is equal to height of textfield
            self.sizeOfButton = CGSize(width: self.frame.size.height, height: self.frame.size.height)
        }
        
        
        // mic button frame
        let frameMicButton = CGRect(x: self.paddingToButton/2, y: self.paddingToButton/2, width: self.sizeOfButton!.width-self.paddingToButton, height: self.sizeOfButton!.height-self.paddingToButton)
        self.micButton = UIButton(frame: frameMicButton)
        self.micButton?.tag = 21021021
        
        //set mic button image
        if  self.micButtonEnableImage == nil{
            self.micButtonEnableImage = UIImage(named: "enable_mic")
            self.micButton?.setBackgroundImage(self.micButtonEnableImage, for: .normal)
        }
        
        //set mic button action
        self.micButton?.addTarget(self, action: #selector(SpeechTextField.micButtonAction), for: .touchUpInside)
        
        //set cancel button frame
        self.cancelButton = UIButton(frame: frameMicButton)
        self.cancelButton?.tag = 21021022
        if  self.micButtonDisableImage == nil{
            self.micButtonDisableImage = UIImage(named: "disable_mic")
            self.cancelButton?.setBackgroundImage(self.micButtonDisableImage, for: .normal)
        }
        
        self.cancelButton?.addTarget(self, action: #selector(SpeechTextField.cancelButtonAction), for: .touchUpInside)
        
        //set up right view of text field
        let frameRightViewButton = CGRect(x: 0, y: 0, width: self.sizeOfButton!.width, height: self.sizeOfButton!.height)
        
        let rightViewContainer = UIView(frame: frameRightViewButton)
        rightViewContainer.backgroundColor = UIColor.clear
        rightViewContainer.addSubview(self.cancelButton!)
        rightViewContainer.addSubview(self.micButton!)
        
        self.rightView = rightViewContainer
        self.rightViewMode = .always
        
        self.showCancelButton(isShown: false)
        
    }
    
    //Desc: Used to handle enabling and disabling of mic button
    func showCancelButton(isShown:Bool)
    {
        //toggle mic and stop button
        self.cancelButton?.isHidden = !isShown
        self.micButton?.isHidden = isShown
    }
    
    //MARK: --- Mic Button Action ---
    //Desc: called when enabled mic button is pressed
    func micButtonAction(sender:AnyObject)
    {
        
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            //start listening
            self.startListening()
            break
            
        case .denied:
            showErrorAlert(message: ErrorMessage.Denied)
            break
            
        case .notDetermined:
            //if not determined, ask for permissions
            self.requestSpeechAuthorization()
            break
            
        case .restricted:
            showErrorAlert(message: ErrorMessage.Restricted)
            break
        }
    }
    
    //Desc: called when disabled mic button is pressed
    func cancelButtonAction(sender:AnyObject)
    {
        //stop listening and show mic button again
        self.stopListening(isNotificationRequired: true)
    }
    
    //MARK: --- Permission check ---
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                self.startListening()
                
            case .denied:
                self.showErrorAlert(message: .Denied)
                
            case .notDetermined:
                self.showErrorAlert(message: .NotDetermined)
                
            case .restricted:
                self.showErrorAlert(message: .Restricted)
            }
        }
    }
    
    //MARK: --- Method to handle Listening ---
    //Desc: Intailizes speech recgnizer and hears to user voice
    func startListening()
    {
        #if DEBUG
            print("start called")
        #endif
        
        //stop any session before starting precautionarily else can cause crash if earlier session is not cleared
//        self.stopListening(isNotificationRequired: false)
        
        //Post notification for listening started
        DispatchQueue.main.async {
         NotificationCenter.default.post(name: kSpeechTextFieldListeningWillStartNotification, object: nil)
        }
        
        
        
        //show enable mic button
        self.showCancelButton(isShown: true)
        
        //Create SFSpeech request object
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = self.recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        //Bool, to show partial or similar recognized word
        recognitionRequest.shouldReportPartialResults = true
        
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session isn't configured correctly")
        }
        
        let recordingFormat = audioEngine.inputNode?.outputFormat(forBus: 0)
        audioEngine.inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, time) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine failed to start")
        }
        
        guard audioEngine.inputNode != nil else { fatalError("Audio engine has no input node") }
        
        self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            //Bool, to check if the resulted string is final interpretation or not
            var isFinal = false
            
            if result != nil {
                self.query = result?.bestTranscription.formattedString
//                self.text = self.query
                //Change to call the didChangeEditing Notification
                self.text = ""
                self.insertText(self.query ?? "")
                isFinal = (result?.isFinal)!
            }
            
            //stop listening once done
            if error != nil || isFinal {
                self.stopListening(isNotificationRequired: true)
            }
        })
        
        
    }
    
    //Desc: Stops speech recognizer and ends audio session
    func stopListening(isNotificationRequired:Bool)
    {
        #if DEBUG
        print("stop called")
        #endif
        
        if isNotificationRequired{
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: kSpeechTextFieldListeningWillEndNotification, object: nil)
            }
        }
        
        self.showCancelButton(isShown: false)
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(false, with: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session isn't configured correctly")
        }
        
        
        audioEngine.reset()
        audioEngine.stop()
        audioEngine.inputNode?.removeTap(onBus: 0)
        
        self.recognitionRequest?.endAudio()
        self.recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
    }
    
    //MARK: --- SFSpeechRecognizerDelegate ---
    // Called when the availability of the given recognizer changes
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool){
        if !available {
            self.showErrorAlert(message: ErrorMessage.UnAvailable)
        }
    }
    
    //MARK: --- Error Handling Alert ---
    //Desc: Shows alert
    func showErrorAlert(message: ErrorMessage) {
        let alertController = UIAlertController(title: nil,
                                                message: message.rawValue,
                                                preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(alertAction)
        OperationQueue.main.addOperation {
            UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true)
        }
    }
    
    
    func stopListening() {
        self.cancelButton?.sendActions(for: .touchUpInside)
    }
    
    
    
    
}
