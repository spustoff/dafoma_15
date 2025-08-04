import SwiftUI

struct NewTripSheet: View {
    @ObservedObject var tripViewModel: TripViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var tripName = ""
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @State private var description = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#3e4464").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Plan Your Adventure")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Create a new trip to start exploring")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 20)
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            CustomFormField(
                                title: "Trip Name",
                                placeholder: "Weekend in Paris",
                                text: $tripName
                            )
                            
                            CustomFormField(
                                title: "Destination",
                                placeholder: "Paris, France",
                                text: $destination
                            )
                            
                            HStack(spacing: 16) {
                                DateFieldView(
                                    title: "Start Date",
                                    date: $startDate,
                                    displayedComponents: [.date]
                                )
                                
                                DateFieldView(
                                    title: "End Date",
                                    date: $endDate,
                                    displayedComponents: [.date]
                                )
                            }
                            
                            CustomFormField(
                                title: "Description (Optional)",
                                placeholder: "Describe your perfect trip...",
                                text: $description,
                                isMultiline: true
                            )
                        }
                        
                        // Duration Preview
                        if startDate <= endDate {
                            TripDurationPreview(startDate: startDate, endDate: endDate)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTrip()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canCreateTrip ? Color(hex: "#fcc418") : .white.opacity(0.5))
                    .disabled(!canCreateTrip)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var canCreateTrip: Bool {
        !tripName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !destination.trimmingCharacters(in: .whitespaces).isEmpty &&
        startDate <= endDate
    }
    
    private func createTrip() {
        guard canCreateTrip else {
            errorMessage = "Please fill in all required fields"
            showingError = true
            return
        }
        
        tripViewModel.createTrip(
            name: tripName.trimmingCharacters(in: .whitespaces),
            destination: destination.trimmingCharacters(in: .whitespaces),
            startDate: startDate,
            endDate: endDate,
            description: description.trimmingCharacters(in: .whitespaces)
        )
        
        dismiss()
    }
}

struct CustomFormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let isMultiline: Bool
    
    init(title: String, placeholder: String, text: Binding<String>, isMultiline: Bool = false) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.isMultiline = isMultiline
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            if isMultiline {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                    }
                    
                    TextEditor(text: $text)
                        .foregroundColor(.white)
                        .background(Color.clear)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }
                .frame(minHeight: 80)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }
}

struct DateFieldView: View {
    let title: String
    @Binding var date: Date
    let displayedComponents: DatePickerComponents
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            DatePicker("", selection: $date, displayedComponents: displayedComponents)
                .datePickerStyle(.compact)
                .colorScheme(.dark)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
        }
    }
}

struct TripDurationPreview: View {
    let startDate: Date
    let endDate: Date
    
    private var duration: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(Color(hex: "#fcc418"))
            
            Text("\(duration) day\(duration == 1 ? "" : "s") trip")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    NewTripSheet(tripViewModel: TripViewModel())
} 
