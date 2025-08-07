import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var userPreferences: UserPreferencesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var userName = ""
    @State private var selectedTravelStyle: UserPreferences.TravelStyle = .balanced
    @State private var selectedBudgetRange: UserPreferences.BudgetRange = .moderate
    @State private var selectedCategories: Set<POI.POICategory> = []
    @State private var selectedTransport: Set<UserPreferences.TransportMode> = [.walking]
    @State private var customInterests: [String] = []
    @State private var newInterest = ""
    
    private let totalSteps = 5
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#3e4464").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Header
                    ProgressHeader(currentStep: currentStep, totalSteps: totalSteps)
                        .padding(.top)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 32) {
                            switch currentStep {
                            case 0:
                                WelcomeStepView(userName: $userName)
                            case 1:
                                TravelStyleStepView(selectedStyle: $selectedTravelStyle)
                            case 2:
                                BudgetStepView(selectedBudget: $selectedBudgetRange)
                            case 3:
                                InterestsStepView(selectedCategories: $selectedCategories)
                            case 4:
                                TransportStepView(selectedTransport: $selectedTransport)
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Navigation Buttons
                    NavigationButtons(
                        currentStep: $currentStep,
                        totalSteps: totalSteps,
                        canProceed: canProceedToNextStep,
                        onComplete: completeSetup
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var canProceedToNextStep: Bool {
        switch currentStep {
        case 0: return !userName.trimmingCharacters(in: .whitespaces).isEmpty
        case 3: return !selectedCategories.isEmpty
        case 4: return !selectedTransport.isEmpty
        default: return true
        }
    }
    
    private func completeSetup() {
        print("🚀 ProfileSetupView: Сохраняем настройки и завершаем онбординг")
        
        // Сначала обновляем все настройки
        userPreferences.updateUserName(userName)
        userPreferences.updateTravelStyle(selectedTravelStyle)
        userPreferences.updateBudgetRange(selectedBudgetRange)
        userPreferences.updateFavoriteCategories(Array(selectedCategories))
        userPreferences.updatePreferredTransport(Array(selectedTransport))
        
        // Затем завершаем онбординг
        userPreferences.completeOnboarding()
        
        print("✅ ProfileSetupView: Настройка завершена, закрываем экран")
        dismiss()
    }
}

struct ProgressHeader: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color(hex: "#fcc418") : Color.white.opacity(0.3))
                        .frame(width: 12, height: 12)
                    
                    if step < totalSteps - 1 {
                        Rectangle()
                            .fill(step < currentStep ? Color(hex: "#fcc418") : Color.white.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Text("Step \(currentStep + 1) of \(totalSteps)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct WelcomeStepView: View {
    @Binding var userName: String
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What should we call you?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Let's personalize your VoyageCraft experience")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("Enter your name", text: $userName)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            .padding(.top, 16)
        }
    }
}

struct TravelStyleStepView: View {
    @Binding var selectedStyle: UserPreferences.TravelStyle
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What's your travel style?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("This helps us recommend the perfect pace for your trips")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                ForEach(UserPreferences.TravelStyle.allCases, id: \.self) { style in
                    TravelStyleCard(
                        style: style,
                        isSelected: selectedStyle == style,
                        onTap: { selectedStyle = style }
                    )
                }
            }
            .padding(.top, 16)
        }
    }
}

struct TravelStyleCard: View {
    let style: UserPreferences.TravelStyle
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(style.rawValue)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? Color(hex: "#3e4464") : .white)
                
                Text(style.description)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? Color(hex: "#3e4464").opacity(0.8) : .white.opacity(0.8))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(isSelected ? Color(hex: "#fcc418") : Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: "#fcc418") : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct BudgetStepView: View {
    @Binding var selectedBudget: UserPreferences.BudgetRange
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What's your budget range?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Daily spending for activities and dining")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                ForEach(UserPreferences.BudgetRange.allCases, id: \.self) { budget in
                    BudgetCard(
                        budget: budget,
                        isSelected: selectedBudget == budget,
                        onTap: { selectedBudget = budget }
                    )
                }
            }
            .padding(.top, 16)
        }
    }
}

struct BudgetCard: View {
    let budget: UserPreferences.BudgetRange
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.rawValue)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? Color(hex: "#3e4464") : .white)
                    
                    Text(budget.dailyRange)
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? Color(hex: "#3e4464").opacity(0.8) : .white.opacity(0.8))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#3cc45b"))
                }
            }
            .padding(20)
            .background(isSelected ? Color(hex: "#fcc418") : Color.white.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

struct InterestsStepView: View {
    @Binding var selectedCategories: Set<POI.POICategory>
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What interests you most?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Select categories you'd love to explore")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(POI.POICategory.allCases, id: \.self) { category in
                    InterestCard(
                        category: category,
                        isSelected: selectedCategories.contains(category),
                        onTap: {
                            if selectedCategories.contains(category) {
                                selectedCategories.remove(category)
                            } else {
                                selectedCategories.insert(category)
                            }
                        }
                    )
                }
            }
            .padding(.top, 16)
        }
    }
}

struct InterestCard: View {
    let category: POI.POICategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: category.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? Color(hex: "#3e4464") : .white)
                
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "#3e4464") : .white)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color(hex: "#fcc418") : Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: "#3cc45b") : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct TransportStepView: View {
    @Binding var selectedTransport: Set<UserPreferences.TransportMode>
    
    var body: some View {
        VStack(spacing: 24) {
            Text("How do you like to get around?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Select your preferred transportation methods")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                ForEach(UserPreferences.TransportMode.allCases, id: \.self) { transport in
                    TransportCard(
                        transport: transport,
                        isSelected: selectedTransport.contains(transport),
                        onTap: {
                            if selectedTransport.contains(transport) {
                                selectedTransport.remove(transport)
                            } else {
                                selectedTransport.insert(transport)
                            }
                        }
                    )
                }
            }
            .padding(.top, 16)
        }
    }
}

struct TransportCard: View {
    let transport: UserPreferences.TransportMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: transport.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color(hex: "#3e4464") : .white)
                    .frame(width: 30)
                
                Text(transport.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "#3e4464") : .white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#3cc45b"))
                }
            }
            .padding(16)
            .background(isSelected ? Color(hex: "#fcc418") : Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct NavigationButtons: View {
    @Binding var currentStep: Int
    let totalSteps: Int
    let canProceed: Bool
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white.opacity(0.1))
                .cornerRadius(25)
            }
            
            Button(currentStep == totalSteps - 1 ? "Complete Setup" : "Next") {
                if currentStep == totalSteps - 1 {
                    onComplete()
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(canProceed ? Color(hex: "#3e4464") : .white.opacity(0.5))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(canProceed ? Color(hex: "#fcc418") : Color.white.opacity(0.1))
            .cornerRadius(25)
            .disabled(!canProceed)
        }
    }
}



#Preview {
    ProfileSetupView()
        .environmentObject(UserPreferencesViewModel())
} 