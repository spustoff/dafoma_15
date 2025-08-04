import SwiftUI
import CoreLocation

struct TripPlanView: View {
    @StateObject private var tripViewModel = TripViewModel()
    @StateObject private var locationService = LocationService()
    @EnvironmentObject var userPreferences: UserPreferencesViewModel
    
    @State private var showingNewTripSheet = false
    @State private var selectedTrip: Trip?
    @State private var searchText = ""
    @State private var nearbyPOIs: [POI] = []
    @State private var searchResults: [POI] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#3e4464").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    TripPlanHeader(
                        showingNewTripSheet: $showingNewTripSheet,
                        searchText: $searchText,
                        onSearch: performSearch
                    )
                    
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Current Trip Section
                            if let currentTrip = tripViewModel.currentTrip {
                                CurrentTripSection(
                                    trip: currentTrip,
                                    tripViewModel: tripViewModel,
                                    onTripSelected: { selectedTrip = $0 }
                                )
                                .padding(.horizontal, 20)
                            }
                            
                            // My Trips Section
                            MyTripsSection(
                                trips: tripViewModel.trips,
                                onTripSelected: { selectedTrip = $0 },
                                onNewTrip: { showingNewTripSheet = true }
                            )
                            .padding(.horizontal, 20)
                            
                            // POI Discovery Section
                            if !searchText.isEmpty {
                                POISearchResults(
                                    searchResults: searchResults,
                                    onPOISelected: addPOIToCurrentTrip
                                )
                                .padding(.horizontal, 20)
                            } else {
                                NearbyPOIsSection(
                                    nearbyPOIs: nearbyPOIs,
                                    onPOISelected: addPOIToCurrentTrip
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingNewTripSheet) {
            NewTripSheet(tripViewModel: tripViewModel)
        }
        .sheet(item: $selectedTrip) { trip in
            TripDetailView(trip: trip, tripViewModel: tripViewModel)
        }
        .onAppear {
            locationService.requestLocationPermission()
            loadNearbyPOIs()
        }
        .onChange(of: locationService.currentLocation) { _ in
            loadNearbyPOIs()
        }
    }
    
    private func performSearch() {
        if !searchText.isEmpty {
            searchResults = locationService.searchPOIs(query: searchText)
        } else {
            searchResults = []
        }
    }
    
    private func loadNearbyPOIs() {
        nearbyPOIs = locationService.getNearbyPOIs()
    }
    
    private func addPOIToCurrentTrip(_ poi: POI) {
        guard let currentTrip = tripViewModel.currentTrip else {
            // Show alert to select a trip first
            return
        }
        tripViewModel.addPOIToTrip(poi, to: currentTrip)
    }
}

struct TripPlanHeader: View {
    @Binding var showingNewTripSheet: Bool
    @Binding var searchText: String
    let onSearch: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Title and New Trip Button
            HStack {
                Text("Trip Planner")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showingNewTripSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "#fcc418"))
                }
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Search places to visit...", text: $searchText)
                    .foregroundColor(.white)
                    .onChange(of: searchText) { _ in onSearch() }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        onSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

struct CurrentTripSection: View {
    let trip: Trip
    let tripViewModel: TripViewModel
    let onTripSelected: (Trip) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Trip")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            CurrentTripCard(
                trip: trip,
                onTap: { onTripSelected(trip) }
            )
            
            // Quick itinerary view
            if let itinerary = trip.itinerary, !itinerary.pointsOfInterest.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Itinerary")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    ForEach(Array(itinerary.pointsOfInterest.prefix(3)), id: \.id) { poi in
                        POIRowView(poi: poi, showDistance: false)
                    }
                    
                    if itinerary.pointsOfInterest.count > 3 {
                        Button("View Full Itinerary") {
                            onTripSelected(trip)
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#fcc418"))
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

struct CurrentTripCard: View {
    let trip: Trip
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(trip.destination)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(trip.duration) days")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "#fcc418"))
                        
                        Text("\(Int(trip.completionPercentage * 100))% complete")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                ProgressView(value: trip.completionPercentage)
                    .tint(Color(hex: "#3cc45b"))
                    .background(Color.white.opacity(0.2))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#fcc418").opacity(0.2), Color(hex: "#3cc45b").opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
        }
    }
}

struct MyTripsSection: View {
    let trips: [Trip]
    let onTripSelected: (Trip) -> Void
    let onNewTrip: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Trips")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if trips.isEmpty {
                    Button("Create First Trip") {
                        onNewTrip()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#fcc418"))
                }
            }
            
            if trips.isEmpty {
                EmptyTripsView(onCreateTrip: onNewTrip)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(trips, id: \.id) { trip in
                            TripCard(trip: trip, onTap: { onTripSelected(trip) })
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            }
        }
    }
}

struct TripCard: View {
    let trip: Trip
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(trip.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if trip.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "#3cc45b"))
                    }
                }
                
                Text(trip.destination)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                
                HStack {
                    Text(DateFormatter.shortDate.string(from: trip.startDate))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text("\(trip.visitedPOIs.count) visited")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#fcc418"))
                }
            }
            .padding(16)
            .frame(width: 200)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct EmptyTripsView: View {
    let onCreateTrip: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.6))
            
            Text("No trips yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            
            Text("Create your first trip to start planning your adventure")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button("Create Trip") {
                onCreateTrip()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color(hex: "#3e4464"))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(hex: "#fcc418"))
            .cornerRadius(20)
        }
        .padding(32)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct NearbyPOIsSection: View {
    let nearbyPOIs: [POI]
    let onPOISelected: (POI) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Discover Nearby")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            if nearbyPOIs.isEmpty {
                POILoadingView()
            } else {
                ForEach(nearbyPOIs.prefix(5), id: \.id) { poi in
                    POIRowView(poi: poi, showDistance: true)
                        .onTapGesture {
                            onPOISelected(poi)
                        }
                }
                
                if nearbyPOIs.count > 5 {
                    Button("Show More Places") {
                        // Show more POIs
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#fcc418"))
                    .padding(.top, 8)
                }
            }
        }
    }
}

struct POISearchResults: View {
    let searchResults: [POI]
    let onPOISelected: (POI) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search Results")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            if searchResults.isEmpty {
                Text("No results found")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.vertical, 32)
            } else {
                ForEach(searchResults, id: \.id) { poi in
                    POIRowView(poi: poi, showDistance: true)
                        .onTapGesture {
                            onPOISelected(poi)
                        }
                }
            }
        }
    }
}

struct POIRowView: View {
    let poi: POI
    let showDistance: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(Color(hex: poi.category.color))
                    .frame(width: 40, height: 40)
                
                Image(systemName: poi.category.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            // POI Info
            VStack(alignment: .leading, spacing: 4) {
                Text(poi.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(poi.category.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                
                HStack(spacing: 8) {
                    // Rating
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#fcc418"))
                        
                        Text(String(format: "%.1f", poi.rating))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Price Level
                    Text(poi.priceLevel.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#3cc45b"))
                    
                    if showDistance {
                        Text("• 1.2 km") // Mock distance
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            // Add Button
            Button(action: {}) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#3cc45b"))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct POILoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color(hex: "#fcc418"))
            
            Text("Discovering nearby places...")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 32)
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

#Preview {
    TripPlanView()
        .environmentObject(UserPreferencesViewModel())
} 