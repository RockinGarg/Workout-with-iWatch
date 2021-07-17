//
//  InterfaceController.swift
//  WIApp Extension
//
//  Created by Jatin Garg on 08/07/21.
//

import WatchKit
import Foundation

class InterfaceController: WKInterfaceController {
    @IBOutlet weak var checkButton: WKInterfaceButton!
    @IBOutlet weak var fetchStepButton: WKInterfaceButton!
    let deviceInterface = WKInterfaceDevice()
    var isPermissionToAcessData = false
    
    
    
    @IBOutlet weak var startStopWorkoutButton: WKInterfaceButton!
    
    
    @IBAction func startStopWorkoutAction() {
        self.pushController(withName: "WorkoutController", context: nil)
    }
    
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).dataDidFlow(_:)),
            name: .dataDidFlow, object: nil
        )
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
    }
    
    override func didAppear() {
        HKHealthHelper.requestAuthorization()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
    }
    
    
    
    func checkWristLocation() -> String {
        switch deviceInterface.wristLocation {
        case .left:
            return "Left"
        default:
            return "Right"
        }
    }
    
    private func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: [String:Any]? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: name, object: object)
        }
    }
    
    @objc
    func dataDidFlow(_ notification: Notification) {
        guard let commandStatus = notification.object as? [String:Any] else { return }
        print("Rx message is: \(String(describing: commandStatus["Message"]))")
    }

    @IBAction func sendDataButtonAction() {
        let alert = WKAlertAction(title: "Ok", style: .default, handler: {
            print("Ok Pressed")
        })
        self.presentAlert(withTitle: "Send Data", message: "Pending To Integrate", preferredStyle: .alert, actions: [alert])
        //postNotificationOnMainQueueAsync(name: .sendDataFromWatch, object: ["Message": "Jatin Garg"])
    }
    
    @IBAction func authorizeHealthKit() {
        /// Get Permission
        HKHealthHelper.authorizeHealthKit { success, error in
            self.isPermissionToAcessData = success
            DispatchQueue.main.async {
                self.fetchStepButton.setEnabled(self.isPermissionToAcessData)
            }
        }
    }
    
    @IBAction func fetchSteps() {
        if !isPermissionToAcessData {
            print("App is not authrised to fetch the steps")
            return
        }
        
        /// Start Fethcing Steps Process
        HKHealthHelper.getTodayStepMovedWith(startDate: Date(), timeRange: 7) { value, error in
            print("Value with time range: \(round(value ?? 0))")
        }
        HKHealthHelper.getTodayStepsMoved { value, error in
            let alert = WKAlertAction(title: "Ok", style: .default, handler: {
                print("Ok Pressed")
            })
            self.presentAlert(withTitle: "Steps", message: String(round(value ?? 0)), preferredStyle: .alert, actions: [alert])
        }    }
    
    @IBAction func checkButtonAction() {
        let alert = WKAlertAction(title: "Ok", style: .default, handler: {
            print("Ok Pressed")
        })
        self.presentAlert(withTitle: "Wrist Location", message: checkWristLocation(), preferredStyle: .alert, actions: [alert])
    }
    
    @IBAction func showAllWorkouts() {
        self.pushController(withName: "WorkoutListController", context: nil)
    }
    
}
