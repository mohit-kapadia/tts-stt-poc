//
//  ViewController.swift
//  SpeechToTextDemo
//
//  Created by Mohit Kapadia on 20/12/16.
//  Copyright © 2016 Mohit Kapadia. All rights reserved.
//

import UIKit
import AVFoundation


protocol DetailViewControllerDelegate {
    func shouldUpdateRootController()
}

class TextDetailViewController: UIViewController {
    
    @IBOutlet var controlSlider: UISlider!
    @IBOutlet var speechActionContainer: UIView!
    @IBOutlet weak var containerStack: UIStackView!
    @IBOutlet weak var actionStackView: UIStackView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var textView: UITextView!
    
    
    var delegate : DetailViewControllerDelegate? = nil

    var demoString : String {
        return "The company's rapid growth since incorporation has triggered a chain of products, acquisitions, and partnerships beyond Google's core search engine (Google Search)."
    }
    
    var demoString2 : String {
        return "गूगल एक अमेरीकी बहुराष्ट्रीय सार्वजनिक कम्पनी है, जिसने इंटरनेट सर्च, क्लाउड कम्प्यूटिंग और विज्ञापन तंत्र में पूँजी लगायी है। यह इंटरनेट पर आधारित कई सेवाएँ और उत्पाद[2] बनाता तथा विकसित करता है और यह मुनाफा मुख्यतया अपने विज्ञापन कार्यक्रम ऐडवर्ड्स (AdWords) से कमाती है।[3][4] यह कम्पनी स्टैनफोर्ड विश्वविद्यालय से पी॰एच॰डी॰ के दो छात्र लैरी पेज और सर्गेई ब्रिन द्वारा स्थापित की गयी थी। इन्हें प्रायः 'गूगल गाइस'[5][6][7] के नाम से सम्बोधित किया जाता है।"
    }
    
    enum ControlType : Int {
        case play = 1001
        case pause = 1002
        case stop = 1003
        case mute = 1004
        case volume = 1005
        case rate = 1006
        case pitch = 1007
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let rightButtonItem = UIBarButtonItem.init(
            title: "Speak",
            style: .plain,
            target: self,
            action: #selector(rightButtonAction(sender:))
        )
        
        self.textView.text = demoString + demoString2
        self.navigationItem.rightBarButtonItem = rightButtonItem
        self.resetProgressBar()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        NotificationCenter.default.removeObserver(self)
        
        if self.navigationController?.viewControllers.index(of: self) == nil {
            self.stopSpeaking()
            TextToSpeechManager.shared.delegate = nil
            self.delegate?.shouldUpdateRootController()
        }
        
        super.viewWillDisappear(animated)
    }
    
    
    /// Call to toggle the right bar button title
    func toggleRightBarButton(){
        if let rightBarButton = self.navigationItem.rightBarButtonItem, let title = rightBarButton.title {
            if title == "Speak" {
                rightBarButton.title = "Stop"
            } else {
                rightBarButton.title = "Speak"
            }
        }
    }
    
    func startSpeaking() {
        self.addSpeechActionContainerView()
        self.resetProgressBar()
        
        //        let language = LanguageInfo(name: "English-US", code: "en-US")
        let speechText = SpeechText(text: demoString, language:nil)
        
        
        
        let language = LanguageInfo(name: "Hindi", code: "hi-IN")
        let speechText2 = SpeechText(text: demoString2, language: language)
        TextToSpeechManager.shared.delegate = self
        TextToSpeechManager.shared.startSpeaking(text: speechText,speechText2)
    }
    
    func stopSpeaking() {
        TextToSpeechManager.shared.stopSpeech()
        removeSpeechActionContainerView()
    }
    
    func pauseSpeaking() {
        TextToSpeechManager.shared.pauseSpeech()
    }
    
    //MARK: ---- IBAction ----
    func rightButtonAction(sender:UIBarButtonItem) {
        if let rightBarButton = self.navigationItem.rightBarButtonItem, let title = rightBarButton.title {
            if title == "Speak" {
                self.startSpeaking()
            } else {
                self.stopSpeaking()
            }
        }
        self.toggleRightBarButton()
    }
    
    
    @IBAction func pauseButtonAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        self.pauseSpeaking()
    }
    

    @IBAction func stopButtonAction(_ sender: UIButton) {
        self.stopSpeaking()
        self.toggleRightBarButton()

    }
    
    @IBAction func muteButtonAction(_ sender: UIButton) {
        /*TextToSpeechManager.shared.pauseSpeech()*/
    }
    
    @IBAction func volumeButtonAction(_ sender: UIButton) {
        /*self.removeSlider()
         self.addSlider(forControl: ControlType.volume)*/
    }
    
    @IBAction func utteranceSpeedButtonAction(_ sender: UIButton) {
        /*self.removeSlider()
         self.addSlider(forControl: ControlType.rate)*/
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        switch sender.tag {
        case ControlType.volume.rawValue:
            TextToSpeechManager.shared.setSpeechVolume(value: sender.value)
        case ControlType.rate.rawValue:
            TextToSpeechManager.shared.setUtteranceRate(value: sender.value)
        default:
            break
        }
    }
    
}



//MARK: ---- Helper Methods ----
extension TextDetailViewController {
    //Parent View
    func addSpeechActionContainerView() {
        /*self.speechActionContainer.heightAnchor.constraint(equalToConstant: 60).isActive = true
        self.view.addSubview(self.speechActionContainer)*/
    }
    
    func removeSpeechActionContainerView() {
        /*if let actionView = self.speechActionContainer {
            actionView.removeFromSuperview()
        }*/
    }
    
    //Slider View
    func addSlider(forControl tag:ControlType) {
        if let containerStack = self.containerStack {
            if containerStack.subviews.contains(self.controlSlider) {
                self.removeSlider()
            } else {
                self.speechActionContainer.heightAnchor.constraint(equalToConstant: 100).isActive = true
                self.controlSlider.tag = tag.rawValue
                containerStack.addArrangedSubview(self.controlSlider)
                self.resetSliderValues(type: tag)
            }
        }
    }
    
    func removeSlider() {
        if let containerStack = self.containerStack {
            containerStack.removeArrangedSubview(self.controlSlider)
            self.speechActionContainer.heightAnchor.constraint(equalToConstant: 60).isActive = true
        }
    }
    
    
    func resetSliderValues(type:ControlType) {
        if let slider = self.controlSlider {
            switch type {
            case .volume :
                slider.minimumValue = 0.0
                slider.maximumValue = 1.0
            case .rate:
                slider.minimumValue = TextToSpeechManager.shared.getMinimumUtteranceRate()
                slider.maximumValue = TextToSpeechManager.shared.getMaximumUtteranceRate()
            default:
                break
            }
        }
    }
    
    // Progress Bar
    func resetProgressBar(){
        self.progressBar.progress = 0.0
    }
    
    func updateProgress(newValue:Float) {
        self.progressBar.progress = newValue
    }
}



extension TextDetailViewController: TTSManagerDelegate {
    func updateProgress(value:Float) {
        print("\nViewController updateProgress:----\(value)------\n")
        self.updateProgress(newValue: value)
    }
    
    func didStartSpeaking(speechText:SpeechText) {
        print("\nViewController didStartSpeaking:----\(speechText.stringToSpeak!)------\n")
    }
    
    func didPauseSpeaking(speechText:SpeechText) {
        print("\nViewController didPauseSpeaking:----\(speechText.stringToSpeak!)------\n")
    }
    
    func didCancelSpeaking(speechText:SpeechText) {
        print("\nViewController didCancelSpeaking:----\(speechText.stringToSpeak!)------\n")
    }
    
    func didContinueSpeaking(speechText:SpeechText) {
        print("\nViewController didContinueSpeaking:----\(speechText.stringToSpeak!)------\n")
    }
    
    func didFinishSpeaking(speechText:SpeechText) {
        print("\nViewController didFinishSpeaking:----\(speechText.stringToSpeak!)------\n")
    }
    
    func willSpeakString(characterRange: NSRange, word: String) {
        print("\nViewController willSpeakString:----\(word)------\n")
    }
}




























