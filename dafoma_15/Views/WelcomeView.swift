import SwiftUI
import Combine

struct WelcomeView: View {
    @EnvironmentObject var userPreferences: UserPreferencesViewModel
    @State private var showingProfileSetup = false
    @State private var currentQuoteIndex = 0
    
    private let inspiringQuotes = [
        "Adventure awaits those who seek it",
        "The world is a book, and those who do not travel read only one page",
        "Not all those who wander are lost",
        "Travel makes one modest",
        "Life is either a daring adventure or nothing at all"
    ]
    
        var body: some View {
        // Если онбординг завершен, не показываем этот экран
        if userPreferences.user.hasCompletedOnboarding {
            EmptyView()
        } else {
            GeometryReader { geometry in
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: [
                            Color(hex: "#3e4464"),
                            Color(hex: "#3e4464").opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Hero Section
                        VStack(spacing: 24) {
                            // App Icon/Logo
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#fcc418"))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "airplane.departure")
                                    .font(.system(size: 50, weight: .light))
                                    .foregroundColor(Color(hex: "#3e4464"))
                            }
                            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                            
                            // App Title
                            Text("VoyageCraft")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            // Subtitle
                            Text("Craft Your Perfect Journey")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Inspiring Quote
                        VStack(spacing: 16) {
                            Text("\"")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(Color(hex: "#fcc418"))
                            
                            Text(inspiringQuotes[currentQuoteIndex])
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                                .animation(.easeInOut(duration: 0.5), value: currentQuoteIndex)
                            
                            Text("\"")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(Color(hex: "#fcc418"))
                                .scaleEffect(x: -1, y: 1)
                        }
                        .frame(height: 140)
                        
                        Spacer()
                        
                        // Feature Highlights
                        VStack(spacing: 20) {
                            FeatureHighlight(
                                icon: "map.fill",
                                title: "Smart Itineraries",
                                description: "AI-powered trip planning"
                            )
                            
                            FeatureHighlight(
                                icon: "location.fill",
                                title: "AR Navigation",
                                description: "Immersive exploration"
                            )
                            
                            FeatureHighlight(
                                icon: "trophy.fill",
                                title: "Travel Rewards",
                                description: "Earn badges & points"
                            )
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                        
                        // Get Started Button
                        Button(action: {
                            print("🎯 Нажата кнопка Begin Your Adventure")
                            showingProfileSetup = true
                        }) {
                            HStack {
                                Text("Begin Your Adventure")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(hex: "#3e4464"))
                                
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "#3e4464"))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "#fcc418"))
                            .cornerRadius(28)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 50)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingProfileSetup) {
                ProfileSetupView()
                    .environmentObject(userPreferences)
            }
            .onReceive(userPreferences.$user) { user in
                if user.hasCompletedOnboarding {
                    print("✅ WelcomeView: Онбординг завершен, скрываем ProfileSetup")
                    showingProfileSetup = false
                }
            }
            .onChange(of: userPreferences.user.hasCompletedOnboarding) { completed in
                if completed {
                    print("✅ WelcomeView: onChange обнаружил завершение онбординга")
                    showingProfileSetup = false
                }
            }
            .onAppear {
                startQuoteRotation()
            }
        }
    }
    
    private func startQuoteRotation() {
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentQuoteIndex = (currentQuoteIndex + 1) % inspiringQuotes.count
            }
        }
    }
}

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "#3cc45b"))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    WelcomeView()
} 