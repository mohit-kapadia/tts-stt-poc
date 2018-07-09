
//
//  ViewController.swift
//  SpeechToTextDemo
//
//  Created by Mohit Kapadia on 20/12/16.
//  Copyright © 2016 Mohit Kapadia. All rights reserved.
//

import UIKit
import AVFoundation



class ViewController: UIViewController {


    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var textField: SpeechTextField!
    var isDetailShown : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        statusLabel.text = "Not Listening"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.startedListening), name: kSpeechTextFieldListeningWillStartNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.stoppedListening), name: kSpeechTextFieldListeningWillEndNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    //MARK: --- Speech to text Notification ---
    func startedListening() {        
        statusLabel.text = "Listening..."
    }
    
    func stoppedListening() {
        statusLabel.text = "Not Listening"
    }
  
    @IBAction func textfieldTextDidChange(_ sender: SpeechTextField) {
        if sender.text!.lowercased().contains("text detail") {
            showTextDetailController()
        }
    }
    
}


extension ViewController {
    func showTextDetailController() {
        if !isDetailShown {
            if let textDetailViewController = self.storyboard?.instantiateViewController(withIdentifier: "TextDetailViewController") as? TextDetailViewController {
                self.isDetailShown = true
                textDetailViewController.delegate = self
                self.textField.stopListening()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 , execute: {
                    self.navigationController?.pushViewController(textDetailViewController, animated: true)
                })
                
            }
        }
    }
}

extension ViewController : DetailViewControllerDelegate {
    func shouldUpdateRootController() {
        self.isDetailShown = false
    }
}























