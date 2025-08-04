import Foundation
import Combine

class UserPreferencesViewModel: ObservableObject {
    @Published var user: User = User()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let userKey = "CurrentUser"
    
    init() {
        loadUser()
    }
    
    // MARK: - User Management
    
    func updateUserName(_ name: String) {
        objectWillChange.send()
        user.name = name
        saveUser()
    }
    
    func updateProfileImage(_ imageName: String) {
        objectWillChange.send()
        user.profileImageName = imageName
        saveUser()
    }
    
    func completeOnboarding() {
        print("🎯 UserPreferencesViewModel: Завершаем онбординг - hasCompletedOnboarding: \(user.hasCompletedOnboarding) -> true")
        
        // Обновляем синхронно
        objectWillChange.send()
        user.hasCompletedOnboarding = true
        saveUser()
        
        print("✅ UserPreferencesViewModel: Онбординг завершен успешно")
    }
    
    // MARK: - Preferences Management
    
    func updateTravelStyle(_ style: UserPreferences.TravelStyle) {
        objectWillChange.send()
        user.preferences.travelStyle = style
        saveUser()
    }
    
    func updateBudgetRange(_ range: UserPreferences.BudgetRange) {
        objectWillChange.send()
        user.preferences.budgetRange = range
        saveUser()
    }
    
    func updateFavoriteCategories(_ categories: [POI.POICategory]) {
        objectWillChange.send()
        user.preferences.favoriteCategories = categories
        saveUser()
    }
    
    func addFavoriteCategory(_ category: POI.POICategory) {
        if !user.preferences.favoriteCategories.contains(category) {
            user.preferences.favoriteCategories.append(category)
            saveUser()
        }
    }
    
    func removeFavoriteCategory(_ category: POI.POICategory) {
        user.preferences.favoriteCategories.removeAll { $0 == category }
        saveUser()
    }
    
    func updatePreferredTransport(_ modes: [UserPreferences.TransportMode]) {
        objectWillChange.send()
        user.preferences.preferredTransport = modes
        saveUser()
    }
    
    func updateInterests(_ interests: [String]) {
        user.preferences.interests = interests
        saveUser()
    }
    
    func addInterest(_ interest: String) {
        if !user.preferences.interests.contains(interest) {
            user.preferences.interests.append(interest)
            saveUser()
        }
    }
    
    func removeInterest(_ interest: String) {
        user.preferences.interests.removeAll { $0 == interest }
        saveUser()
    }
    
    func toggleNotifications() {
        objectWillChange.send()
        user.preferences.notificationsEnabled.toggle()
        saveUser()
    }
    
    func toggleARFeatures() {
        objectWillChange.send()
        user.preferences.arFeaturesEnabled.toggle()
        saveUser()
    }
    
    // MARK: - Travel Stats Management
    
    func updateTravelStats(from trip: Trip) {
        user.travelStats.totalTrips += 1
        user.travelStats.totalPlacesVisited += trip.visitedPOIs.count
        user.travelStats.totalDistanceTraveled += trip.totalDistance
        user.travelStats.totalPoints += trip.earnedPoints
        user.travelStats.badgesEarned.append(contentsOf: trip.badges)
        
        // Update longest trip
        if trip.duration > user.travelStats.longestTrip {
            user.travelStats.longestTrip = trip.duration
        }
        
        // Extract country from destination (simplified)
        let country = extractCountry(from: trip.destination)
        if !country.isEmpty {
            user.travelStats.countriesVisited.insert(country)
        }
        
        // Update favorite category
        updateFavoriteCategory()
        
        saveUser()
    }
    
    private func extractCountry(from destination: String) -> String {
        // Simplified country extraction - in real app would use geocoding
        let components = destination.components(separatedBy: ",")
        return components.last?.trimmingCharacters(in: .whitespaces) ?? ""
    }
    
    private func updateFavoriteCategory() {
        let categoryCount = Dictionary(grouping: user.travelStats.badgesEarned) { badge in
            badge.category
        }.mapValues { $0.count }
        
        if let topCategory = categoryCount.max(by: { $0.value < $1.value }) {
            // Map badge category to POI category
            switch topCategory.key {
            case .historical:
                user.travelStats.favoriteCategory = .historical
            case .culinary:
                user.travelStats.favoriteCategory = .restaurant
            case .nature:
                user.travelStats.favoriteCategory = .park
            case .culture:
                user.travelStats.favoriteCategory = .gallery
            case .adventure:
                user.travelStats.favoriteCategory = .shopping
            case .photography:
                user.travelStats.favoriteCategory = .viewpoint
            }
        }
    }
    
    func addBadge(_ badge: TravelBadge) {
        user.travelStats.badgesEarned.append(badge)
        user.travelStats.totalPoints += 25 // Bonus points for earning badge
        saveUser()
    }
    
    // MARK: - Data Persistence
    
    private func saveUser() {
        do {
            let data = try JSONEncoder().encode(user)
            userDefaults.set(data, forKey: userKey)
        } catch {
            print("Failed to save user: \(error)")
            errorMessage = "Failed to save user data"
        }
    }
    
    private func loadUser() {
        guard let data = userDefaults.data(forKey: userKey) else {
            // Create default user if none exists
            user = User()
            return
        }
        
        do {
            user = try JSONDecoder().decode(User.self, from: data)
        } catch {
            print("Failed to load user: \(error)")
            errorMessage = "Failed to load user data"
            user = User() // Fallback to default user
        }
    }
    
    // MARK: - Helper Methods
    
    func resetOnboarding() {
        objectWillChange.send()
        user.hasCompletedOnboarding = false
        saveUser()
    }
    
    func getRecommendedCategories() -> [POI.POICategory] {
        if user.preferences.favoriteCategories.isEmpty {
            // Return default recommendations based on travel style
            switch user.preferences.travelStyle {
            case .relaxed:
                return [.park, .cafe, .viewpoint]
            case .balanced:
                return [.restaurant, .museum, .shopping]
            case .intensive:
                return [.historical, .gallery, .entertainment]
            }
        }
        return user.preferences.favoriteCategories
    }
    
    func getLevelProgress() -> (current: Int, progress: Double, pointsToNext: Int) {
        let level = user.travelStats.level
        let progress = user.travelStats.progressToNextLevel
        let pointsToNext = Int((1.0 - progress) * 100)
        
        return (level, progress, pointsToNext)
    }
} 