import Foundation
import CoreLocation

struct Itinerary: Identifiable, Codable {
    let id = UUID()
    var tripId: UUID
    var pointsOfInterest: [POI] = []
    var dailyPlans: [DailyPlan] = []
    var totalEstimatedDuration: TimeInterval = 0
    var isDownloadedForOffline: Bool = false
    
    mutating func addPOI(_ poi: POI) {
        pointsOfInterest.append(poi)
        updateEstimatedDuration()
    }
    
    mutating func removePOI(withId id: UUID) {
        pointsOfInterest.removeAll { $0.id == id }
        updateEstimatedDuration()
    }
    
    mutating func reorderPOIs(from source: IndexSet, to destination: Int) {
        pointsOfInterest.move(fromOffsets: source, toOffset: destination)
        updateEstimatedDuration()
    }
    
    private mutating func updateEstimatedDuration() {
        totalEstimatedDuration = pointsOfInterest.reduce(0) { $0 + $1.estimatedVisitDuration }
    }
}

struct DailyPlan: Identifiable, Codable {
    let id = UUID()
    let date: Date
    var plannedPOIs: [POI]
    var notes: String = ""
    var estimatedBudget: Double = 0.0
    
    var totalDuration: TimeInterval {
        plannedPOIs.reduce(0) { $0 + $1.estimatedVisitDuration }
    }
} 