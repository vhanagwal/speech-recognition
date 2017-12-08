//
//  ViewController.swift
//  Speech Recognization
//
//  Created by Vardhan Agrawal on 11/25/17.
//  Copyright © 2017 Vardhan Agrawal. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    // MARK: - Interface Builder Outlets
    @IBOutlet var promptLabel: UILabel!
    @IBOutlet var transcribedTextView: UITextView!
    @IBOutlet var dictationButton: UIButton!
    
    let audioEngine = AVAudioEngine()
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    var request: SFSpeechAudioBufferRecognitionRequest?
    var task: SFSpeechRecognitionTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dictationButton.isEnabled = false
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (status) in
            OperationQueue.main.addOperation {
                switch status {
                    
                case .authorized: self.dictationButton.isEnabled = true
                self.promptLabel.text = "Tap the button to dictate..."
                    
                default: self.dictationButton.isEnabled = false
                self.promptLabel.text = "Dictation not authorized..."
                    
                }
            }
        }
    }
    
    func startDictation() {
        
        task?.cancel()
        task = nil
        
        // Initializes the request variable
        request = SFSpeechAudioBufferRecognitionRequest()
        
        // Assigns the shared audio session instance to a constant
        let audioSession = AVAudioSession.sharedInstance()
        
        // Assigns the input node of the audio engine to a constant
        let inputNode = audioEngine.inputNode
        
        // If possible, the request variable is unwrapped and assigned to a local constant
        guard let request = request else { return }
        request.shouldReportPartialResults = true
        
        // Attempts to set various attributes and returns nil if fails
        try? audioSession.setCategory(AVAudioSessionCategoryRecord)
        try? audioSession.setMode(AVAudioSessionModeMeasurement)
        try? audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        // Initializes the task with a recognition task
        task = speechRecognizer.recognitionTask(with: request, resultHandler: { (result, error) in
            guard let result = result else { return }
            self.transcribedTextView.text = result.bestTranscription.formattedString
            
            if error != nil || result.isFinal {
                self.audioEngine.stop()
                self.request = nil
                self.task = nil
                
                inputNode.removeTap(onBus: 0)
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.request?.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            dictationButton.isEnabled = true
        } else {
            dictationButton.isEnabled = false
        }
    }
    
    @IBAction func dictationButtonTapped() {
        if audioEngine.isRunning {
            dictationButton.setTitle("Start Recording", for: .normal)
            promptLabel.text = "Tap the button to dictate..."
            
            request?.endAudio()
            audioEngine.stop()
        } else {
            dictationButton.setTitle("Stop Recording", for: .normal)
            promptLabel.text = "Go ahead. I'm listening..."
            
            startDictation()
        }
    }
}

