//
//  DBHelper.swift
//  WIApp Extension
//
//  Created by Jatin Garg on 14/07/21.
//

import Foundation
import RealmSwift

class DBHelper {
    static let realm = try! Realm()
    
    static func mapValuesToWorkout(heartRate: Double?,
                                   averageHeartRate: Double?,
                                   activeEnergy: Double?,
                                   stepsFromPedometer: Int?,
                                   distanceFromPedometer: Double?,
                                   stepsFromWorkout: Int?,
                                   distanceFromWorkout: Double?,
                                   startDate: Date? = Date(),
                                   endDate: Date? = Date()) -> Workout {
        let workout = Workout()
        workout.heartRate = heartRate
        workout.averageHeartRate = averageHeartRate
        workout.activeEnergy = activeEnergy
        workout.stepsFromPedometer = stepsFromPedometer
        workout.distaceFromPedometer = distanceFromPedometer
        workout.stepsFromWorkout = stepsFromWorkout
        workout.distaceFromWorkout = distanceFromWorkout
        workout.workoutStartDate = startDate
        workout.workoutEndDate = endDate
        return workout
    }
    
    static func addNew(workout: Workout) {
        do {
            try realm.write{
                realm.add(workout)
            }
        } catch {
            print("Error while adding the workout: \(error.localizedDescription)")
        }
    }
    
    static func fetchSavedWorkouts() -> Results<Workout> {
        return realm.objects(Workout.self)
    }
    
    static func clearRealm() {
        do {
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            print("Error while clearing the workout: \(error.localizedDescription)")
        }
    }
    
}
