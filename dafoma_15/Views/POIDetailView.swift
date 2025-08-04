import SwiftUI
import MapKit

struct POIDetailView: View {
    let poi: POI
    let trip: Trip
    @ObservedObject var tripViewModel: TripViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingMap = false
    @State private var region: MKCoordinateRegion
    
    init(poi: POI, trip: Trip, tripViewModel: TripViewModel) {
        self.poi = poi
        self.trip = trip
        self.tripViewModel = tripViewModel
        
        self._region = State(initialValue: MKCoordinateRegion(
            center: poi.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#3e4464").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Image Placeholder
                        POIHeaderView(poi: poi)
                        
                        // Basic Info
                        POIBasicInfo(poi: poi)
                        
                        // Action Buttons
                        ActionButtonsSection(
                            poi: poi,
                            trip: trip,
                            tripViewModel: tripViewModel,
                            onMapToggle: { showingMap.toggle() }
                        )
                        
                        // Details Section
                        POIDetailsSection(poi: poi)
                        
                        // AR & Historical Facts
                        if poi.arContentAvailable || !poi.historicalFacts.isEmpty {
                            ARAndFactsSection(poi: poi)
                        }
                        
                        // Map Section
                        if showingMap {
                            POIMapSection(region: $region, poi: poi)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Share functionality
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct POIHeaderView: View {
    let poi: POI
    
    var body: some View {
        ZStack {
            // Placeholder background with gradient
            LinearGradient(
                colors: [Color(hex: poi.category.color), Color(hex: poi.category.color).opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 200)
            .cornerRadius(20)
            
            // Category Icon
            VStack {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: poi.category.iconName)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
        }
        .overlay(
            // Visited Badge
            VStack {
                HStack {
                    Spacer()
                    
                    if poi.isVisited {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#3cc45b"))
                            Text("Visited")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(15)
                        .padding()
                    }
                }
                
                Spacer()
            }
        )
    }
}

struct POIBasicInfo: View {
    let poi: POI
    
    var body: some View {
        VStack(spacing: 16) {
            Text(poi.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(poi.category.rawValue)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#fcc418"))
            
            HStack(spacing: 20) {
                InfoBadge(
                    icon: "star.fill",
                    value: String(format: "%.1f", poi.rating),
                    color: Color(hex: "#fcc418")
                )
                
                InfoBadge(
                    icon: "dollarsign.circle.fill",
                    value: poi.priceLevel.rawValue,
                    color: Color(hex: "#3cc45b")
                )
                
                InfoBadge(
                    icon: "clock.fill",
                    value: formatDuration(poi.estimatedVisitDuration),
                    color: Color(hex: "#fcc418")
                )
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        if hours > 0 {
            return "\(hours)h"
        } else {
            let minutes = Int(duration / 60)
            return "\(minutes)m"
        }
    }
}

struct InfoBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(width: 60)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

struct ActionButtonsSection: View {
    let poi: POI
    let trip: Trip
    @ObservedObject var tripViewModel: TripViewModel
    let onMapToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ActionButton(
                    title: poi.isVisited ? "Visited" : "Mark Visited",
                    icon: poi.isVisited ? "checkmark.circle.fill" : "circle",
                    backgroundColor: poi.isVisited ? Color(hex: "#3cc45b") : Color.white.opacity(0.1),
                    foregroundColor: poi.isVisited ? .white : Color(hex: "#3cc45b")
                ) {
                    if !poi.isVisited {
                        tripViewModel.markPOIAsVisited(poi, in: trip)
                    }
                }
                
                ActionButton(
                    title: "Directions",
                    icon: "location.fill",
                    backgroundColor: Color(hex: "#fcc418"),
                    foregroundColor: Color(hex: "#3e4464")
                ) {
                    // Open directions
                }
            }
            
            HStack(spacing: 12) {
                ActionButton(
                    title: "Show Map",
                    icon: "map.fill",
                    backgroundColor: Color.white.opacity(0.1),
                    foregroundColor: .white
                ) {
                    onMapToggle()
                }
                
                if poi.arContentAvailable {
                    ActionButton(
                        title: "AR View",
                        icon: "camera.viewfinder",
                        backgroundColor: Color(hex: "#3cc45b"),
                        foregroundColor: .white
                    ) {
                        // Open AR view
                    }
                }
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .cornerRadius(10)
        }
    }
}

struct POIDetailsSection: View {
    let poi: POI
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text(poi.description)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(nil)
            
            // Address
            if !poi.address.isEmpty {
                DetailRow(icon: "location", title: "Address", value: poi.address)
            }
            
            // Opening Hours
            if !poi.openingHours.isEmpty {
                DetailRow(icon: "clock", title: "Hours", value: poi.openingHours.first ?? "")
            }
            
            // Website
            if let website = poi.website {
                DetailRow(icon: "globe", title: "Website", value: website)
            }
            
            // Phone
            if let phone = poi.phoneNumber {
                DetailRow(icon: "phone", title: "Phone", value: phone)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#fcc418"))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
}

struct ARAndFactsSection: View {
    let poi: POI
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Discover More")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            if poi.arContentAvailable {
                FeatureCard(
                    icon: "camera.viewfinder",
                    title: "AR Experience Available",
                    description: "Point your camera to discover interactive content",
                    accentColor: Color(hex: "#3cc45b")
                )
            }
            
            if !poi.historicalFacts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Did You Know?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#fcc418"))
                    
                    ForEach(poi.historicalFacts, id: \.self) { fact in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Color(hex: "#fcc418"))
                                .frame(width: 6, height: 6)
                                .padding(.top, 8)
                            
                            Text(fact)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(nil)
                        }
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(accentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(16)
        .background(accentColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}

struct POIMapSection: View {
    @Binding var region: MKCoordinateRegion
    let poi: POI
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Map(coordinateRegion: $region, annotationItems: [poi]) { poi in
                MapPin(coordinate: poi.coordinate, tint: Color(hex: poi.category.color))
            }
            .frame(height: 200)
            .cornerRadius(12)
        }
        .padding(20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}



#Preview {
    POIDetailView(
        poi: POI(
            name: "Louvre Museum",
            description: "The world's largest art museum and historic monument in Paris",
            category: .museum,
            coordinate: CLLocationCoordinate2D(latitude: 48.8606, longitude: 2.3376),
            address: "Rue de Rivoli, 75001 Paris, France",
            rating: 4.5,
            arContentAvailable: true,
            historicalFacts: ["Built in the 12th century", "Home to the Mona Lisa"]
        ),
        trip: Trip(
            name: "Paris Adventure",
            destination: "Paris, France",
            startDate: Date(),
            endDate: Date(),
            description: ""
        ),
        tripViewModel: TripViewModel()
    )
} 