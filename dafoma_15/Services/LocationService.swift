import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Guide user to settings
            errorMessage = "Location access is required for navigation features. Please enable in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        
        locationManager.startUpdatingLocation()
        isLocationEnabled = true
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
    }
    
    // MARK: - Distance Calculations
    
    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000 // Convert to kilometers
    }
    
    func distanceFromCurrentLocation(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let currentLocation = currentLocation else { return nil }
        return distance(from: currentLocation.coordinate, to: coordinate)
    }
    
    // MARK: - POI Discovery
    
    func getNearbyPOIs(radius: Double = 5.0) -> [POI] {
        guard let currentLocation = currentLocation else { return [] }
        
        // Mock POI data - in real app would use MapKit or Google Places API
        return generateMockPOIs(around: currentLocation.coordinate, radius: radius)
    }
    
    func searchPOIs(query: String, location: CLLocationCoordinate2D? = nil) -> [POI] {
        let searchLocation = location ?? currentLocation?.coordinate
        guard let searchLocation = searchLocation else { return [] }
        
        // Mock search results - in real app would use search API
        return generateMockPOIs(around: searchLocation, radius: 10.0)
            .filter { poi in
                poi.name.localizedCaseInsensitiveContains(query) ||
                poi.description.localizedCaseInsensitiveContains(query) ||
                poi.category.rawValue.localizedCaseInsensitiveContains(query)
            }
    }
    
    private func generateMockPOIs(around center: CLLocationCoordinate2D, radius: Double) -> [POI] {
        let categories: [POI.POICategory] = [.restaurant, .museum, .park, .historical, .shopping, .cafe, .gallery]
        var pois: [POI] = []
        
        for i in 0..<20 {
            let category = categories.randomElement() ?? .restaurant
            let randomLat = center.latitude + Double.random(in: -0.01...0.01)
            let randomLon = center.longitude + Double.random(in: -0.01...0.01)
            
            let poi = POI(
                name: generatePOIName(for: category, index: i),
                description: generatePOIDescription(for: category),
                category: category,
                coordinate: CLLocationCoordinate2D(latitude: randomLat, longitude: randomLon),
                address: generateAddress(index: i),
                rating: Double.random(in: 3.0...5.0),
                priceLevel: POI.PriceLevel.allCases.randomElement() ?? .moderate,
                estimatedVisitDuration: TimeInterval.random(in: 1800...7200), // 30 minutes to 2 hours
                arContentAvailable: Bool.random(),
                historicalFacts: category == .historical ? generateHistoricalFacts() : []
            )
            
            pois.append(poi)
        }
        
        return pois
    }
    
    private func generatePOIName(for category: POI.POICategory, index: Int) -> String {
        switch category {
        case .restaurant:
            return ["The Golden Spoon", "Bistro Luna", "Coastal Kitchen", "Urban Garden", "Fire & Stone"][index % 5]
        case .museum:
            return ["City Art Museum", "History Center", "Science Discovery", "Cultural Heritage", "Modern Arts"][index % 5]
        case .park:
            return ["Central Park", "Riverside Gardens", "Mountain View Park", "Botanical Gardens", "City Square"][index % 5]
        case .historical:
            return ["Old Town Hall", "Heritage Church", "Ancient Castle", "Historic Bridge", "Memorial Plaza"][index % 5]
        case .shopping:
            return ["Market Square", "Fashion District", "Artisan Alley", "Downtown Mall", "Local Bazaar"][index % 5]
        case .cafe:
            return ["Coffee Corner", "Morning Brew", "Café Central", "Bean & Leaf", "Roasted Dreams"][index % 5]
        case .gallery:
            return ["Contemporary Gallery", "Local Artists", "Photo Exhibition", "Sculpture Hall", "Creative Space"][index % 5]
        default:
            return "Local \(category.rawValue) \(index + 1)"
        }
    }
    
    private func generatePOIDescription(for category: POI.POICategory) -> String {
        switch category {
        case .restaurant:
            return "Delicious local cuisine with fresh ingredients and authentic flavors."
        case .museum:
            return "Fascinating exhibits showcasing local history, art, and culture."
        case .park:
            return "Beautiful green space perfect for relaxation and outdoor activities."
        case .historical:
            return "Significant historical site with rich heritage and architecture."
        case .shopping:
            return "Unique shopping experience with local crafts and specialty items."
        case .cafe:
            return "Cozy atmosphere with excellent coffee and light refreshments."
        case .gallery:
            return "Inspiring art collection featuring local and international artists."
        default:
            return "Interesting local attraction worth visiting."
        }
    }
    
    private func generateAddress(index: Int) -> String {
        let streets = ["Main Street", "Oak Avenue", "River Road", "Park Lane", "First Street"]
        let numbers = [100, 250, 380, 450, 520]
        return "\(numbers[index % 5]) \(streets[index % 5])"
    }
    
    private func generateHistoricalFacts() -> [String] {
        return [
            "Built in the 18th century by local craftsmen",
            "Served as a gathering place for important historical events",
            "Features unique architectural elements from the colonial period",
            "Witnessed significant moments in local history"
        ]
    }
    
    // MARK: - Navigation Helpers
    
    func getDirections(to destination: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        guard let currentLocation = currentLocation else { return [] }
        
        // Mock route - in real app would use MapKit directions
        let steps = 10
        let latStep = (destination.latitude - currentLocation.coordinate.latitude) / Double(steps)
        let lonStep = (destination.longitude - currentLocation.coordinate.longitude) / Double(steps)
        
        var route: [CLLocationCoordinate2D] = []
        
        for i in 0...steps {
            let lat = currentLocation.coordinate.latitude + (latStep * Double(i))
            let lon = currentLocation.coordinate.longitude + (lonStep * Double(i))
            route.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        
        return route
    }
    
    func estimatedTravelTime(to destination: CLLocationCoordinate2D, transportMode: UserPreferences.TransportMode) -> TimeInterval {
        guard let distance = distanceFromCurrentLocation(to: destination) else { return 0 }
        
        let speedKmH: Double
        switch transportMode {
        case .walking:
            speedKmH = 5.0
        case .bicycle:
            speedKmH = 15.0
        case .publicTransport:
            speedKmH = 25.0
        case .car, .rideshare:
            speedKmH = 40.0
        }
        
        return (distance / speedKmH) * 3600 // Convert to seconds
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Failed to get location: \(error.localizedDescription)"
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            stopLocationUpdates()
            errorMessage = "Location access denied. Enable in Settings to use navigation features."
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
} 