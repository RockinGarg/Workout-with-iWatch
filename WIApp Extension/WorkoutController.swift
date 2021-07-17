//
//  WorkoutController.swift
//  WIApp Extension
//
//  Created by Jatin Garg on 12/07/21.
//

import WatchKit
import Foundation
import HealthKit
import CoreMotion

extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

extension Double {
    func isInteger() -> Any {
        let check = floor(self) == self
        if check {
            return Int(self)
        } else {
            return self
        }
    }
    
    func roundTo(places: Int) -> Double {
            let divisor = pow(10.0, Double(places))
            return (self * divisor).rounded() / divisor
    }
}

class WorkoutController: WKInterfaceController {
    
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var avgHeartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var energyLabel: WKInterfaceLabel!
    @IBOutlet weak var distanceLabel: WKInterfaceLabel!
    @IBOutlet weak var pauseContiueButton: WKInterfaceButton!
    @IBOutlet weak var stopWorkoutButton: WKInterfaceButton!
    @IBOutlet weak var stepsFromWorkoutLabel: WKInterfaceLabel!
    @IBOutlet weak var distanceFromPedLabel: WKInterfaceLabel!
    @IBOutlet weak var stepsFromPedLabel: WKInterfaceLabel!
    
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    var running = false
    var averageHeartRate: Double = 0
    var heartRate: Double = 0
    var activeEnergy: Double = 0
    var distance: Double = 0
    var workout: HKWorkout?
    var isWorkoutStarted = false
    var stepsQueryObserver: HKObserverQuery?
    var pedometer: CMPedometer?
    var initialStepsCountFromPedometer: Int = 0
    var initialDistaceFromPedometer: Double = 0.0
    var initialStepsCountFromWorkout: Int = 0
    var initialDistaceFromWorkout: Double = 0.0
    var isWorkoutEverPaused: Bool = false
    var isSessionRunning: Bool = false
    var workoutStartDate: Date?
    var workoutContinueDate: Date?
    var workoutEndDate: Date?
    
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
    
    override func didAppear() {
        HKHealthHelper.authorizeHealthKit { success, error in
            if success {
                print("Steps permission given")
                HKObjectType.activitySummaryType()
                self.workoutStartDate = Date()
                self.workoutContinueDate = Date()
                self.startWorkout()
                self.startPedometer()
                self.getStepsCount(start: true)
            }
        }
        
    }

    @IBAction func pauseContinueWorkoutAction() {
        self.isWorkoutEverPaused = true
        self.togglePause()
    }
    
    @IBAction func stopWorkoutAction() {
        if isWorkoutStarted {
            print("Stopping the ongoing workout")
            self.stopPedometer()
            self.endWorkout()
            self.getStepsCount(start: false)
            print("Workout: \(self.initialDistaceFromWorkout)m with steps \(initialStepsCountFromWorkout)")
            print("Pedometer: \(self.initialDistaceFromPedometer)m with steps \(initialStepsCountFromPedometer)")
            self.resetWorkout()
            guard let stepQueryObserving = self.stepsQueryObserver else {
                return
            }
            HKHealthStore().stop(stepQueryObserving)
        } else {
            print("Navigating Back")
            self.pop()
        }
    }
}

//MARK:- DB Operations
extension WorkoutController {
    func saveWorkoutInDB() {
        DBHelper.addNew(workout: DBHelper.mapValuesToWorkout(heartRate: self.heartRate,
                                                             averageHeartRate: self.averageHeartRate,
                                                             activeEnergy: self.activeEnergy,
                                                             stepsFromPedometer: self.initialStepsCountFromPedometer,
                                                             distanceFromPedometer: self.initialDistaceFromPedometer,
                                                             stepsFromWorkout: self.initialStepsCountFromWorkout,
                                                             distanceFromWorkout: self.initialDistaceFromWorkout,
                                                             startDate: self.workoutStartDate,
                                                             endDate: self.workoutEndDate))
    }
}

//MARK:- Pedometer functions
extension WorkoutController {
    func startPedometer() {
        if CMPedometer.isStepCountingAvailable() {
            pedometer!.startUpdates(from: Date(), withHandler: { data, error in
                if let error = error {
                    print("Error while starting ped updates: \(error.localizedDescription)")
                    return
                }
                print("Pedometer is started")
            })
        } else {
            print("Step counts are not avaialble on this device. Please check your compatiability")
        }
    }
    
    func stopPedometer() {
        guard let pedometer = self.pedometer else {
            return
        }
        
        pedometer.stopUpdates()
        print("Pedometer is stopped")
    }
    
    func getStepsCount(start: Bool) {
        pedometer = CMPedometer()
        pedometer?.queryPedometerData(from: self.workoutStartDate!, to: self.workoutEndDate ?? Date(), withHandler: { actualData, error in
            if let error = error {
                print("Error while getting steps count: \(error.localizedDescription)")
                return
            }
            
            guard let actualData = actualData else {
                print("Error getting actual Data")
                return
            }
            
            print("Updating the counts from ped data: \(actualData.numberOfSteps) and \(actualData.distance ?? 0)")
            self.initialStepsCountFromPedometer = actualData.numberOfSteps.intValue
            self.initialDistaceFromPedometer = actualData.distance!.doubleValue
            if !start {
                self.saveWorkoutInDB()
            }
            DispatchQueue.main.async {
                self.distanceFromPedLabel.setText(self.initialDistaceFromPedometer.format(f: ".2"))
                self.stepsFromPedLabel.setText(String(self.initialStepsCountFromPedometer))
            }
        })
    }
}

//MARK:- Workout functions
extension WorkoutController {
    func togglePause() {
        if running == true {
            self.pauseContiueButton.setTitle("Continue")
            self.pause()
        } else {
            self.pauseContiueButton.setTitle("Pause")
            resume()
        }
    }
    
    func pause() {
        print("Pausing the workout")
        session?.pause()
    }

    func resume() {
        print("Resuming the workout")
        self.workoutContinueDate = Date()
        session?.resume()
    }

    func endWorkout() {
        print("Ending Workout")
        guard let session = session else {
            print("Session not found")
            return
        }
        pauseContiueButton.setTitle("Stopped")
        pauseContiueButton.setEnabled(false)
        session.stopActivity(with: Date())
        session.end()
        self.workoutEndDate = Date()
        isWorkoutStarted = false
        isSessionRunning = false
        stopWorkoutButton.setTitle("Back")
    }
    
    func resetWorkout() {
        builder = nil
        workout = nil
        session = nil
    }
    
    func startWorkout() {
        print("Starting the workout")
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor

        // Create the session and obtain the workout builder.
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            // Handle any exceptions.
            return
        }

        // Setup session and builder.
        session?.delegate = self
        builder?.delegate = self

        // Set the workout builder's data source.
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: configuration)

        // Start the workout session and begin data collection.
        let startDate = Date()
        session?.startActivity(with: startDate)
        self.workoutStartDate = startDate
        self.workoutContinueDate = startDate
        builder?.beginCollection(withStart: startDate) { (success, error) in
            // The workout has started.
            print("Is the workout started? = \(success)")
            if success {
                self.isWorkoutStarted = true
                self.isSessionRunning = true
            }
            guard let stepsProperty = HKSampleType.quantityType(forIdentifier: .stepCount) else {
                return
            }
            var df = DateComponents()
            df.minute = 10
            let startOfDay = self.workoutStartDate
            let predicate = HKQuery.predicateForSamples(
                withStart: startOfDay,
                end: Calendar.current.date(byAdding: df, to: self.workoutStartDate!),
                options: .strictStartDate
            )
            self.stepsQueryObserver = HKObserverQuery(sampleType: stepsProperty, predicate: predicate) { (_, result, error) in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }
                HKHealthHelper.getTodayStepMovedWith(startDate: self.workoutContinueDate!, timeRange: 10) { val, error in
                    if self.isWorkoutStarted {
                        if self.running {
                            self.initialStepsCountFromWorkout = self.isWorkoutEverPaused ? (self.initialStepsCountFromWorkout+Int(round(val ?? 0))) : (Int(round(val ?? 0)))
                        }
                        DispatchQueue.main.async {
                            self.stepsFromWorkoutLabel.setText(String(self.initialStepsCountFromWorkout))
                        }
                    }
                }
            }
            HKHealthStore().execute(self.stepsQueryObserver!)
        }
    }
}

//MARK:- Workout Session Delegates
extension WorkoutController: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }

        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.heartRateLabel.setText(String(Int(round(self.heartRate))))
                self.avgHeartRateLabel.setText(String(Int(round(self.averageHeartRate))))
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                self.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
                self.energyLabel.setText(String(Int(round(self.activeEnergy))))
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning), HKQuantityType.quantityType(forIdentifier: .distanceCycling):
                let meterUnit = HKUnit.meter()
                self.distance = statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0
                self.initialDistaceFromWorkout = round(self.distance)
                self.distanceLabel.setText("\(round(self.distance).format(f: ".2"))m")
            default:
                return
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.running = toState == .running
        }
        
        if toState == .paused {
            print("Setting session as paused")
            self.running = false
        }

        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            builder?.endCollection(withEnd: date) { (success, error) in
                self.builder?.finishWorkout { (workout, error) in
                    DispatchQueue.main.async {
                        self.workout = workout
                    }
                }
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {

    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {

    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }

            let statistics = workoutBuilder.statistics(for: quantityType)

            // Update the published values.
            updateForStatistics(statistics)
        }
    }
}
