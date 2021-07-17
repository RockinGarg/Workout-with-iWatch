//
//  WorkoutListController.swift
//  WIApp Extension
//
//  Created by Jatin Garg on 14/07/21.
//

import WatchKit
import RealmSwift
import Foundation


class WorkoutListController: WKInterfaceController {
    
    @IBOutlet weak var workoutListingTable: WKInterfaceTable!
    var workouts: Results<Workout> {
        return DBHelper.fetchSavedWorkouts()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func loadTableDate() {
        let df = DateFormatter()
        df.dateFormat = "yy/MM/dd-HH:mm"
        workoutListingTable.setNumberOfRows(self.workouts.count, withRowType: "WorkoutRowController")
        for index in 0..<self.workouts.count {
            let row = workoutListingTable.rowController(at: index)
                as! WorkoutRowController
            let data = self.workouts[index]
            row.energyLabel.setText(String(Int(round(data.activeEnergy ?? 0))))
            row.heartRateLabel.setText(String(Int(round(data.heartRate ?? 0))))
            row.averageHRLabel.setText(String(Int(round(data.averageHeartRate ?? 0))))
            row.stepsWorkoutLabel.setText(String(Int(data.stepsFromWorkout ?? 0)))
            row.stepsPedometerLabel.setText(String(Int(data.stepsFromPedometer ?? 0)))
            row.distanceWorkoutLabel.setText(String(Int(round(data.distaceFromWorkout ?? 0))))
            row.pedometerDistanceLabel.setText(String(Int(round(data.distaceFromPedometer ?? 0))))
            row.startDateLabel.setText(df.string(from: data.workoutStartDate ?? Date()))
            row.endDateLabel.setText(df.string(from: data.workoutEndDate ?? Date()))
        }
        
    }
    
    override func didAppear() {
        DispatchQueue.main.async {
            self.loadTableDate()
        }
    }
    
}
