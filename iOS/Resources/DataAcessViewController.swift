//
//  DataAcessViewController.swift
//  WatchInterface (iOS)
//
//  Created by Jatin Garg on 08/07/21.
//

import UIKit
import WatchConnectivity

class DataAcessViewController: UIViewController {
    
    @IBOutlet weak var textMessageTF: UITextField!
    var lastMessage: CFAbsoluteTime = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if (WCSession.isSupported()) {
            /// Activate the session
            let session = WCSession.default
            session.delegate = self
            session.activate()
        } else {
            print("Session is not activated")
        }
    }
    
    func sendWatchMessage(message: String) {
        let currentTime = CFAbsoluteTimeGetCurrent()

        // if less than half a second has passed, bail out
        if lastMessage + 0.5 > currentTime {
            return
        }

        // send a message to the watch if it's reachable
        if (WCSession.default.isReachable) {
            // this is a meaningless message, but it's enough for our purposes
            let message = ["Message": message]
            WCSession.default.sendMessage(message, replyHandler: nil)
        }

        // update our rate limiting property
        lastMessage = CFAbsoluteTimeGetCurrent()
    }
    
    @IBAction func sendSampleMessage(_ sender: Any) {
        sendWatchMessage(message: textMessageTF.text?.trimmingCharacters(in: .whitespaces) ?? "")
        self.view.endEditing(true)
    }
    
}

extension DataAcessViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

extension DataAcessViewController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("iPhone rx a message: \(message)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("iPhone rx a message with reply: \(message)")
        replyHandler(message)
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Watch Session did became Inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("Watch Session did deactivated")
    }
}
