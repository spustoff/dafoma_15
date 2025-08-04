import Foundation
import CoreLocation

struct POI: Identifiable, Codable {
    let id = UUID()
    var name: String
    var description: String
    var category: POICategory
    var coordinate: CLLocationCoordinate2D
    var address: String
    var rating: Double = 0.0
    var priceLevel: PriceLevel = .free
    var estimatedVisitDuration: TimeInterval = 3600 // 1 hour default
    var imageNames: [String] = []
    var openingHours: [String] = []
    var website: String?
    var phoneNumber: String?
    var isVisited: Bool = false
    var visitedDate: Date?
    var userNotes: String = ""
    var arContentAvailable: Bool = false
    var historicalFacts: [String] = []
    
    enum POICategory: String, CaseIterable, Codable {
        case restaurant = "Restaurant"
        case museum = "Museum"
        case park = "Park"
        case historical = "Historical Site"
        case shopping = "Shopping"
        case entertainment = "Entertainment"
        case accommodation = "Hotel"
        case transport = "Transportation"
        case viewpoint = "Viewpoint"
        case cafe = "Cafe"
        case gallery = "Art Gallery"
        case beach = "Beach"
        case church = "Church"
        case market = "Market"
        
        var iconName: String {
            switch self {
            case .restaurant: return "fork.knife"
            case .museum: return "building.columns"
            case .park: return "tree"
            case .historical: return "building.2"
            case .shopping: return "bag"
            case .entertainment: return "theatermasks"
            case .accommodation: return "bed.double"
            case .transport: return "car"
            case .viewpoint: return "mountain.2"
            case .cafe: return "cup.and.saucer"
            case .gallery: return "paintbrush"
            case .beach: return "beach.umbrella"
            case .church: return "cross"
            case .market: return "cart"
            }
        }
        
        var color: String {
            switch self {
            case .restaurant, .cafe: return "#fcc418"
            case .museum, .gallery, .historical: return "#3cc45b"
            case .park, .beach, .viewpoint: return "#3cc45b"
            case .shopping, .market: return "#fcc418"
            case .entertainment: return "#fcc418"
            case .accommodation, .transport: return "#3e4464"
            case .church: return "#3cc45b"
            }
        }
    }
    
    enum PriceLevel: String, CaseIterable, Codable {
        case free = "Free"
        case budget = "$"
        case moderate = "$$"
        case expensive = "$$$"
        case luxury = "$$$$"
    }
}

// Extension to make CLLocationCoordinate2D Codable
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
} 