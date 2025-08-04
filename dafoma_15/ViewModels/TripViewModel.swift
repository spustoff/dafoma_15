import Foundation
import CoreLocation
import Combine

class TripViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var currentTrip: Trip?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let tripsKey = "SavedTrips"
    
    init() {
        loadTrips()
    }
    
    // MARK: - Trip Management
    
    func createTrip(name: String, destination: String, startDate: Date, endDate: Date, description: String) {
        let newTrip = Trip(
            name: name,
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            description: description
        )
        
        trips.append(newTrip)
        saveTrips()
    }
    
    func updateTrip(_ trip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index] = trip
            saveTrips()
        }
    }
    
    func deleteTrip(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }
        if currentTrip?.id == trip.id {
            currentTrip = nil
        }
        saveTrips()
    }
    
    func selectTrip(_ trip: Trip) {
        currentTrip = trip
    }
    
    // MARK: - Itinerary Management
    
    func createItinerary(for trip: Trip) -> Itinerary {
        return Itinerary(tripId: trip.id)
    }
    
    func addPOIToTrip(_ poi: POI, to trip: Trip) {
        var updatedTrip = trip
        
        if updatedTrip.itinerary == nil {
            updatedTrip.itinerary = createItinerary(for: trip)
        }
        
        updatedTrip.itinerary?.addPOI(poi)
        updateTrip(updatedTrip)
    }
    
    func removePOIFromTrip(poiId: UUID, from trip: Trip) {
        var updatedTrip = trip
        updatedTrip.itinerary?.removePOI(withId: poiId)
        updateTrip(updatedTrip)
    }
    
    func reorderPOIsInTrip(from source: IndexSet, to destination: Int, in trip: Trip) {
        var updatedTrip = trip
        updatedTrip.itinerary?.reorderPOIs(from: source, to: destination)
        updateTrip(updatedTrip)
    }
    
    // MARK: - Progress Tracking
    
    func markPOIAsVisited(_ poi: POI, in trip: Trip) {
        var updatedTrip = trip
        var updatedPOI = poi
        updatedPOI.isVisited = true
        updatedPOI.visitedDate = Date()
        
        // Add to visited POIs if not already there
        if !updatedTrip.visitedPOIs.contains(where: { $0.id == poi.id }) {
            updatedTrip.visitedPOIs.append(updatedPOI)
            updatedTrip.earnedPoints += calculatePointsForPOI(poi)
        }
        
        // Update the POI in the itinerary
        if var itinerary = updatedTrip.itinerary {
            if let index = itinerary.pointsOfInterest.firstIndex(where: { $0.id == poi.id }) {
                itinerary.pointsOfInterest[index] = updatedPOI
                updatedTrip.itinerary = itinerary
            }
        }
        
        updateTrip(updatedTrip)
        checkForNewBadges(updatedTrip)
    }
    
    private func calculatePointsForPOI(_ poi: POI) -> Int {
        switch poi.category {
        case .historical, .museum, .gallery: return 15
        case .restaurant, .cafe: return 10
        case .park, .beach, .viewpoint: return 12
        case .shopping, .market: return 8
        case .entertainment: return 10
        case .accommodation, .transport: return 5
        case .church: return 10
        }
    }
    
    private func checkForNewBadges(_ trip: Trip) {
        var newBadges: [TravelBadge] = []
        
        // Check for category-based badges
        let categoryGroups = Dictionary(grouping: trip.visitedPOIs) { $0.category }
        
        for (category, pois) in categoryGroups {
            if pois.count >= 3 {
                let badgeName = "\(category.rawValue) Explorer"
                
                // Check if badge doesn't already exist
                if !trip.badges.contains(where: { $0.name == badgeName }) {
                    let badge = TravelBadge(
                        name: badgeName,
                        description: "Visited 3+ \(category.rawValue.lowercased()) locations",
                        iconName: category.iconName,
                        category: getBadgeCategory(for: category),
                        earnedDate: Date()
                    )
                    newBadges.append(badge)
                }
            }
        }
        
        // Add new badges to trip
        if !newBadges.isEmpty {
            var updatedTrip = trip
            updatedTrip.badges.append(contentsOf: newBadges)
            updateTrip(updatedTrip)
        }
    }
    
    private func getBadgeCategory(for poiCategory: POI.POICategory) -> TravelBadge.BadgeCategory {
        switch poiCategory {
        case .historical, .museum, .church: return .historical
        case .restaurant, .cafe, .market: return .culinary
        case .park, .beach, .viewpoint: return .nature
        case .gallery, .entertainment: return .culture
        case .shopping: return .adventure
        default: return .photography
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveTrips() {
        do {
            let data = try JSONEncoder().encode(trips)
            userDefaults.set(data, forKey: tripsKey)
        } catch {
            print("Failed to save trips: \(error)")
            errorMessage = "Failed to save trips"
        }
    }
    
    private func loadTrips() {
        guard let data = userDefaults.data(forKey: tripsKey) else { return }
        
        do {
            trips = try JSONDecoder().decode([Trip].self, from: data)
        } catch {
            print("Failed to load trips: \(error)")
            errorMessage = "Failed to load trips"
        }
    }
    
    // MARK: - Helper Methods
    
    func getUpcomingTrips() -> [Trip] {
        return trips.filter { $0.startDate > Date() && !$0.isCompleted }
            .sorted { $0.startDate < $1.startDate }
    }
    
    func getCurrentTrips() -> [Trip] {
        let now = Date()
        return trips.filter { 
            $0.startDate <= now && $0.endDate >= now && !$0.isCompleted 
        }
    }
    
    func getPastTrips() -> [Trip] {
        return trips.filter { $0.endDate < Date() || $0.isCompleted }
            .sorted { $0.startDate > $1.startDate }
    }
} 