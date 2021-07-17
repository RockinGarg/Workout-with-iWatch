//
//  HKHealthHelper.swift
//  WIApp Extension
//
//  Created by Jatin Garg on 09/07/21.
//

import Foundation
import HealthKit
import RealmSwift

enum HealthKitError: Error {
    case notAvailable
    case stepsNotAvailable
    case stepsNoRecord
}

extension HealthKitError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notAvailable:
            return "Health kit isn't available."
        case .stepsNotAvailable:
            return "Steps aren't available"
        case .stepsNoRecord:
            return "Steps not logged for the date"
        }
    }
}

class HKHealthHelper {
    static let healthKitStore = HKHealthStore()
    static let stepsPropoerty = HKObjectType.quantityType(forIdentifier: .stepCount)
    
    static func requestAuthorization() {
        // The quantity type to write to the health store.
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]

        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.activitySummaryType()
        ]

        // Request authorization for those quantity types.
        healthKitStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            // Handle error.
        }
    }
    
    static func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthKitError.notAvailable)
            return
        }
        guard let permission = stepsPropoerty else {
            return
        }
        healthKitStore.requestAuthorization(toShare: Set([permission]), read: Set([permission])) { success, error in
            completion(success, error)
        }
    }
    
    static func getTodayStepMovedWith(startDate: Date, timeRange: Int, completion: @escaping(Double?, Error?) -> Void) {
        guard let stepsProperty = HKSampleType.quantityType(forIdentifier: .stepCount) else {
            completion(nil, HealthKitError.stepsNotAvailable)
            return
        }
        var df = DateComponents()
        df.minute = timeRange
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: Calendar.current.date(byAdding: df, to: startDate),
            options: .strictStartDate
        )
        let query = HKStatisticsQuery(
            quantityType: stepsProperty,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(nil, HealthKitError.stepsNoRecord)
                return
            }
            completion(sum.doubleValue(for: HKUnit.count()), nil)
        }
        
        HKHealthStore().execute(query)
    }
    
    static func getTodayStepMovedUsingObserverWith(timeRange: Int, completion: @escaping(Double?, Error?) -> Void) {
        guard let stepsProperty = HKSampleType.quantityType(forIdentifier: .stepCount) else {
            completion(nil, HealthKitError.stepsNotAvailable)
            return
        }
        let now = Date()
        var df = DateComponents()
        df.minute = -timeRange
        let startOfDay = Calendar.current.date(byAdding: df, to: now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )
        let observerQuery = HKObserverQuery(sampleType: stepsProperty, predicate: predicate) { (_, result, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            let query = HKStatisticsQuery(
                quantityType: stepsProperty,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                guard let result = result, let sum = result.sumQuantity() else {
                    completion(nil, HealthKitError.stepsNoRecord)
                    return
                }
                completion(sum.doubleValue(for: HKUnit.count()), nil)
            }
            HKHealthStore().execute(query)
        }
        HKHealthStore().execute(observerQuery)
        
       
    }
    
    static func getTodayStepsMoved(completion: @escaping(Double?, Error?) -> Void) {
        guard let stepsProperty = HKSampleType.quantityType(forIdentifier: .stepCount) else {
            completion(nil, HealthKitError.stepsNotAvailable)
            return
        }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )
        let query = HKStatisticsQuery(
            quantityType: stepsProperty,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(nil, HealthKitError.stepsNoRecord)
                return
            }
            completion(sum.doubleValue(for: HKUnit.count()), nil)
        }
        
        HKHealthStore().execute(query)
    }
}
