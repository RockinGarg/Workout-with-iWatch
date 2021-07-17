//
//  WorkoutRowController.swift
//  WIApp Extension
//
//  Created by Jatin Garg on 14/07/21.
//

import WatchKit

class WorkoutRowController: NSObject {

    @IBOutlet weak var startDateLabel: WKInterfaceLabel!
    @IBOutlet weak var endDateLabel: WKInterfaceLabel!
    @IBOutlet weak var energyLabel: WKInterfaceLabel!
    @IBOutlet weak var pedometerDistanceLabel: WKInterfaceLabel!
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var stepsWorkoutLabel: WKInterfaceLabel!
    @IBOutlet weak var stepsPedometerLabel: WKInterfaceLabel!
    @IBOutlet weak var averageHRLabel: WKInterfaceLabel!
    @IBOutlet weak var distanceWorkoutLabel: WKInterfaceLabel!
}
