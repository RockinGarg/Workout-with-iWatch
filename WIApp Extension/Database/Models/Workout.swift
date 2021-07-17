//
//  Workout.swift
//  WIApp Extension
//
//  Created by Jatin Garg on 14/07/21.
//

import Foundation
import RealmSwift

@objcMembers class Workout: Object {
    @Persisted dynamic var heartRate: Double? = nil
    @Persisted dynamic var averageHeartRate: Double? = nil
    @Persisted dynamic var activeEnergy: Double? = nil
    @Persisted dynamic var stepsFromPedometer: Int? = nil
    @Persisted dynamic var distaceFromPedometer: Double? = nil
    @Persisted dynamic var stepsFromWorkout: Int? = nil
    @Persisted dynamic var distaceFromWorkout: Double? = nil
    @Persisted dynamic var workoutStartDate: Date? = nil
    @Persisted dynamic var workoutEndDate: Date? = nil
}
