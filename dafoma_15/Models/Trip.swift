import Foundation
import CoreLocation

struct Trip: Identifiable, Codable {
    let id = UUID()
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date
    var description: String
    var itinerary: Itinerary?
    var coverImageName: String?
    var isCompleted: Bool = false
    var visitedPOIs: [POI] = []
    var totalDistance: Double = 0.0 // in kilometers
    var earnedPoints: Int = 0
    var badges: [TravelBadge] = []
    
    var duration: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var completionPercentage: Double {
        guard let itinerary = itinerary, !itinerary.pointsOfInterest.isEmpty else { return 0.0 }
        return Double(visitedPOIs.count) / Double(itinerary.pointsOfInterest.count)
    }
}

struct TravelBadge: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let iconName: String
    let category: BadgeCategory
    let earnedDate: Date
    
    enum BadgeCategory: String, CaseIterable, Codable {
        case historical = "Historical Explorer"
        case culinary = "Foodie Adventure"
        case nature = "Nature Lover"
        case culture = "Culture Enthusiast"
        case adventure = "Adventure Seeker"
        case photography = "Photo Hunter"
    }
} 