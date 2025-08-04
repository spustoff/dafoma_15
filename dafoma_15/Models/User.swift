import Foundation

struct User: Identifiable, Codable {
    let id = UUID()
    var name: String = ""
    var profileImageName: String?
    var preferences: UserPreferences = UserPreferences()
    var travelStats: TravelStats = TravelStats()
    var hasCompletedOnboarding: Bool = false
    var createdDate: Date = Date()
}

struct UserPreferences: Codable {
    var favoriteCategories: [POI.POICategory] = []
    var travelStyle: TravelStyle = .balanced
    var budgetRange: BudgetRange = .moderate
    var preferredTransport: [TransportMode] = [.walking]
    var interests: [String] = []
    var languagePreference: String = "en"
    var notificationsEnabled: Bool = true
    var arFeaturesEnabled: Bool = true
    
    enum TravelStyle: String, CaseIterable, Codable {
        case relaxed = "Relaxed Explorer"
        case balanced = "Balanced Traveler"
        case intensive = "Adventure Seeker"
        
        var description: String {
            switch self {
            case .relaxed: return "Take your time and enjoy each moment"
            case .balanced: return "Mix of activities with rest periods"
            case .intensive: return "Pack as much as possible into your trip"
            }
        }
    }
    
    enum BudgetRange: String, CaseIterable, Codable {
        case budget = "Budget Traveler"
        case moderate = "Moderate Spender"
        case luxury = "Luxury Explorer"
        
        var dailyRange: String {
            switch self {
            case .budget: return "$0-50"
            case .moderate: return "$50-150"
            case .luxury: return "$150+"
            }
        }
    }
    
    enum TransportMode: String, CaseIterable, Codable {
        case walking = "Walking"
        case bicycle = "Bicycle"
        case publicTransport = "Public Transport"
        case car = "Car"
        case rideshare = "Rideshare"
        
        var iconName: String {
            switch self {
            case .walking: return "figure.walk"
            case .bicycle: return "bicycle"
            case .publicTransport: return "bus"
            case .car: return "car"
            case .rideshare: return "car.2"
            }
        }
    }
}

struct TravelStats: Codable {
    var totalTrips: Int = 0
    var totalPlacesVisited: Int = 0
    var totalDistanceTraveled: Double = 0.0 // in kilometers
    var totalPoints: Int = 0
    var badgesEarned: [TravelBadge] = []
    var countriesVisited: Set<String> = []
    var favoriteCategory: POI.POICategory?
    var longestTrip: Int = 0 // in days
    
    var level: Int {
        return min(totalPoints / 100 + 1, 50) // Level up every 100 points, max level 50
    }
    
    var progressToNextLevel: Double {
        let currentLevelPoints = (level - 1) * 100
        let pointsInCurrentLevel = totalPoints - currentLevelPoints
        return Double(pointsInCurrentLevel) / 100.0
    }
} 