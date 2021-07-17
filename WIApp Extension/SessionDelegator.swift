//
//  SessionDelegator.swift
//  WIApp Extension
//
//  Created by Jatin Garg on 08/07/21.
//

import Foundation
import WatchConnectivity

extension Notification.Name {
    static let dataDidFlow = Notification.Name("DataDidFlow")
    static let sendDataFromWatch = Notification.Name("SendDataFromWatch")
}

class SessionDelegater: NSObject, WCSessionDelegate {
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).dataDidFlow(_:)),
            name: .sendDataFromWatch, object: nil
        )
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch Kit Activation Did Complete")
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("Watch Kit Session Reachability did change")
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Watch Kit App context rx: \(applicationContext)")
    }
    
    // Without Response
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Watch Kit new message rx: \(message)")
        postNotificationOnMainQueueAsync(name: .dataDidFlow, object: message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("Watch Kit new message with response one: \(message)")
        replyHandler(message)
    }
    
    private func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: [String:Any]? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }
    
    @objc
    func dataDidFlow(_ notification: Notification) {
        guard let commandStatus = notification.object as? [String:Any] else { return }
        WCSession.default.sendMessage(commandStatus, replyHandler: nil, errorHandler: nil)
        WCSession.default.sendMessage(commandStatus) { replyHandler in
            print("Reply Response rx from iPhone to watch: \(replyHandler)")
        } errorHandler: { error in
            print("Error while sending data from watch to iPhone: \(error.localizedDescription)")
        }

    }
}
