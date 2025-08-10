import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @ObservedObject var tripViewModel: TripViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingItinerary = true
    @State private var selectedPOI: POI?
    @State private var showingEditSheet = false
    @State private var showingCalendarExport = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#3e4464").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Trip Header
                        TripDetailHeader(trip: trip)
                        
                        // Progress Section
                        TripProgressSection(trip: trip)
                        
                        // Tab Selector
                        TabSelector(showingItinerary: $showingItinerary)
                        
                        // Content
                        if showingItinerary {
                            ItinerarySection(
                                trip: trip,
                                tripViewModel: tripViewModel,
                                onPOISelected: { selectedPOI = $0 }
                            )
                        } else {
                            StatsSection(trip: trip)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Trip") {
                            showingEditSheet = true
                        }
                        Button("Export to Calendar") {
                            showingCalendarExport = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(item: $selectedPOI) { poi in
            POIDetailView(poi: poi, trip: trip, tripViewModel: tripViewModel)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTripSheet(trip: trip, tripViewModel: tripViewModel)
        }
        .alert("Export to Calendar", isPresented: $showingCalendarExport) {
            Button("Export") {
                exportToCalendar()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Add this trip to your calendar?")
        }
    }
    
    private func exportToCalendar() {
        // Placeholder for calendar export functionality
        // In a real app, you would use EventKit framework to add events
        print("Exporting trip '\(trip.name)' to calendar")
    }
}

struct TripDetailHeader: View {
    let trip: Trip
    
    var body: some View {
        VStack(spacing: 16) {
            Text(trip.name)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(trip.destination)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(hex: "#fcc418"))
            
            HStack(spacing: 20) {
                DetailBadge(
                    icon: "calendar",
                    value: "\(trip.duration)",
                    label: "Days"
                )
                
                DetailBadge(
                    icon: "mappin.and.ellipse",
                    value: "\(trip.visitedPOIs.count)",
                    label: "Visited"
                )
                
                DetailBadge(
                    icon: "star.fill",
                    value: "\(trip.earnedPoints)",
                    label: "Points"
                )
            }
        }
        .padding(.top, 20)
    }
}

struct DetailBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "#3cc45b"))
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 80)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TripProgressSection: View {
    let trip: Trip
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Trip Progress")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(trip.completionPercentage * 100))%")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#fcc418"))
            }
            
            ProgressView(value: trip.completionPercentage)
                .tint(Color(hex: "#3cc45b"))
                .background(Color.white.opacity(0.2))
                .scaleEffect(y: 2)
        }
        .padding(20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

struct TabSelector: View {
    @Binding var showingItinerary: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "Itinerary",
                isSelected: showingItinerary,
                onTap: { showingItinerary = true }
            )
            
            TabButton(
                title: "Stats",
                isSelected: !showingItinerary,
                onTap: { showingItinerary = false }
            )
        }
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? Color(hex: "#3e4464") : .white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color(hex: "#fcc418") : Color.clear)
                .cornerRadius(8)
        }
        .padding(4)
    }
}

struct ItinerarySection: View {
    let trip: Trip
    @ObservedObject var tripViewModel: TripViewModel
    let onPOISelected: (POI) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Itinerary")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            if let itinerary = trip.itinerary, !itinerary.pointsOfInterest.isEmpty {
                ForEach(Array(itinerary.pointsOfInterest.enumerated()), id: \.element.id) { index, poi in
                    ItineraryPOICard(
                        poi: poi,
                        dayNumber: index / 3 + 1, // Rough day grouping
                        onTap: { onPOISelected(poi) },
                        onMarkVisited: {
                            tripViewModel.markPOIAsVisited(poi, in: trip)
                        }
                    )
                }
            } else {
                EmptyItineraryView()
            }
        }
    }
}

struct ItineraryPOICard: View {
    let poi: POI
    let dayNumber: Int
    let onTap: () -> Void
    let onMarkVisited: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Day \(dayNumber)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#fcc418"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#fcc418").opacity(0.2))
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    if poi.isVisited {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "#3cc45b"))
                    } else {
                        Button(action: onMarkVisited) {
                            Image(systemName: "circle")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: poi.category.color))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: poi.category.iconName)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(poi.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(poi.category.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        
                        HStack(spacing: 8) {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color(hex: "#fcc418"))
                                
                                Text(String(format: "%.1f", poi.rating))
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Text(poi.priceLevel.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#3cc45b"))
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(16)
            .background(poi.isVisited ? Color(hex: "#3cc45b").opacity(0.1) : Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(poi.isVisited ? Color(hex: "#3cc45b") : Color.clear, lineWidth: 1)
            )
        }
    }
}

struct EmptyItineraryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.6))
            
            Text("No places added yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            
            Text("Start building your itinerary by adding places from the discovery section")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct StatsSection: View {
    let trip: Trip
    
    var body: some View {
        VStack(spacing: 20) {
            // Badges Section
            if !trip.badges.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Earned Badges")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(trip.badges, id: \.id) { badge in
                            BadgeCard(badge: badge)
                        }
                    }
                }
            }
            
            // Category Breakdown
            CategoryBreakdownView(trip: trip)
            
            // Trip Summary
            TripSummaryView(trip: trip)
        }
    }
}

struct BadgeCard: View {
    let badge: TravelBadge
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: badge.iconName)
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "#fcc418"))
            
            Text(badge.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(badge.description)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CategoryBreakdownView: View {
    let trip: Trip
    
    var categoryBreakdown: [(POI.POICategory, Int)] {
        let groups = Dictionary(grouping: trip.visitedPOIs) { $0.category }
        return groups.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Places by Category")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            if categoryBreakdown.isEmpty {
                Text("Visit places to see breakdown")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.vertical, 20)
            } else {
                ForEach(categoryBreakdown, id: \.0) { category, count in
                    HStack {
                        Image(systemName: category.iconName)
                            .foregroundColor(Color(hex: category.color))
                            .frame(width: 20)
                        
                        Text(category.rawValue)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(count)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#fcc418"))
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

struct TripSummaryView: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trip Summary")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                SummaryRow(title: "Duration", value: "\(trip.duration) days")
                SummaryRow(title: "Places Visited", value: "\(trip.visitedPOIs.count)")
                SummaryRow(title: "Points Earned", value: "\(trip.earnedPoints)")
                SummaryRow(title: "Badges Earned", value: "\(trip.badges.count)")
                SummaryRow(title: "Started", value: DateFormatter.shortDate.string(from: trip.startDate))
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

struct EditTripSheet: View {
    let trip: Trip
    @ObservedObject var tripViewModel: TripViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var destination: String
    @State private var description: String
    @State private var startDate: Date
    @State private var endDate: Date
    
    init(trip: Trip, tripViewModel: TripViewModel) {
        self.trip = trip
        self.tripViewModel = tripViewModel
        self._name = State(initialValue: trip.name)
        self._destination = State(initialValue: trip.destination)
        self._description = State(initialValue: trip.description)
        self._startDate = State(initialValue: trip.startDate)
        self._endDate = State(initialValue: trip.endDate)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#3e4464").ignoresSafeArea()
                
                Form {
                    Section("Trip Details") {
                        TextField("Trip Name", text: $name)
                        TextField("Destination", text: $destination)
                        TextField("Description", text: $description)
                    }
                    
                    Section("Dates") {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func saveChanges() {
        var updatedTrip = trip
        updatedTrip.name = name
        updatedTrip.destination = destination
        updatedTrip.description = description
        updatedTrip.startDate = startDate
        updatedTrip.endDate = endDate
        
        tripViewModel.updateTrip(updatedTrip)
    }
}



#Preview {
    TripDetailView(trip: Trip(
        name: "Paris Adventure",
        destination: "Paris, France",
        startDate: Date(),
        endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
        description: "Exploring the City of Light"
    ), tripViewModel: TripViewModel())
} 
