//
//  ContentView.swift
//  dafoma_15
//
//  Created by Вячеслав on 8/4/25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var userPreferences = UserPreferencesViewModel()
    @State private var selectedTab = 0
    @State private var forceRefresh = false
    
    var body: some View {
        ZStack {
            if !userPreferences.user.hasCompletedOnboarding {
                WelcomeView()
                    .environmentObject(userPreferences)
                    .transition(.opacity)
            } else {
                MainTabView(selectedTab: $selectedTab)
                    .environmentObject(userPreferences)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: userPreferences.user.hasCompletedOnboarding)
        .onReceive(userPreferences.$user) { user in
            if user.hasCompletedOnboarding {
                print("✅ ContentView: Переключаемся на основное приложение")
            }
                        // Принудительно обновляем состояние
            forceRefresh.toggle()
        }
        .id(forceRefresh) // Принудительное обновление при изменении forceRefresh
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var userPreferences: UserPreferencesViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TripPlanView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "map.fill" : "map")
                    Text("Explore")
                }
                .tag(0)
            
            AnalyticsView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "chart.bar.fill" : "chart.bar")
                    Text("Analytics")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "person.crop.circle.fill" : "person.crop.circle")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(Color(hex: "#fcc418"))
        .onAppear {
            configureTabBarAppearance()
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#3e4464"))
        
        // Configure normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.6),
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        
        // Configure selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "#fcc418"))
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "#fcc418")),
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var userPreferences: UserPreferencesViewModel
    @State private var showingSettings = false
    @State private var showingProfileEdit = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#3e4464").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        ProfileHeaderView(user: userPreferences.user)
                        
                        // Quick Stats
                        ProfileStatsView(user: userPreferences.user)
                        
                        // Preferences Section
                        PreferencesSection(userPreferences: userPreferences)
                        
                        // Settings Section
                        SettingsSection(
                            showingSettings: $showingSettings,
                            showingProfileEdit: $showingProfileEdit,
                            userPreferences: userPreferences
                        )
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileEditView()
                .environmentObject(userPreferences)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(userPreferences)
        }
    }
}

struct ProfileHeaderView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(Color(hex: "#fcc418"))
                    .frame(width: 100, height: 100)
                
                if let imageName = user.profileImageName {
                    Image(imageName)
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 100, height: 100)
                } else {
                    Text(String(user.name.prefix(1)).uppercased())
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Color(hex: "#3e4464"))
                }
            }
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text(user.name.isEmpty ? "Traveler" : user.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Level \(user.travelStats.level) Explorer")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#fcc418"))
                
                Text("Member since \(DateFormatter.shortDate.string(from: user.createdDate))")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.top, 20)
    }
}

struct ProfileStatsView: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 20) {
            ProfileStatItem(
                value: "\(user.travelStats.totalTrips)",
                label: "Trips",
                icon: "airplane.departure"
            )
            
            ProfileStatItem(
                value: "\(user.travelStats.totalPlacesVisited)",
                label: "Places",
                icon: "mappin.and.ellipse"
            )
            
            ProfileStatItem(
                value: "\(user.travelStats.badgesEarned.count)",
                label: "Badges",
                icon: "rosette"
            )
        }
        .padding(20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

struct ProfileStatItem: View {
    let value: String
    let label: String
    let icon: String
    
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
        .frame(maxWidth: .infinity)
    }
}

struct PreferencesSection: View {
    @ObservedObject var userPreferences: UserPreferencesViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Travel Preferences")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                PreferenceRow(
                    title: "Travel Style",
                    value: userPreferences.user.preferences.travelStyle.rawValue,
                    icon: "figure.walk"
                )
                
                PreferenceRow(
                    title: "Budget Range",
                    value: userPreferences.user.preferences.budgetRange.rawValue,
                    icon: "dollarsign.circle"
                )
                
                PreferenceRow(
                    title: "Favorite Categories",
                    value: "\(userPreferences.user.preferences.favoriteCategories.count) selected",
                    icon: "heart"
                )
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

struct PreferenceRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#fcc418"))
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

struct SettingsSection: View {
    @Binding var showingSettings: Bool
    @Binding var showingProfileEdit: Bool
    @ObservedObject var userPreferences: UserPreferencesViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            SettingsButton(
                title: "Edit Profile",
                icon: "person.crop.circle",
                action: { showingProfileEdit = true }
            )
            
            SettingsButton(
                title: "Reset Onboarding",
                icon: "arrow.clockwise",
                action: {
                    userPreferences.resetOnboarding()
                }
            )
        }
    }
}

struct SettingsButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#fcc418"))
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct ProfileEditView: View {
    @EnvironmentObject var userPreferences: UserPreferencesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#3e4464").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Edit Profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        TextField("Your name", text: $name)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
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
                    Button("Save") {
                        userPreferences.updateUserName(name)
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#fcc418"))
                }
            }
        }
        .onAppear {
            name = userPreferences.user.name
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var userPreferences: UserPreferencesViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#3e4464").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        ToggleRow(
                            title: "Notifications",
                            isOn: userPreferences.user.preferences.notificationsEnabled,
                            onToggle: { userPreferences.toggleNotifications() }
                        )
                        
                        ToggleRow(
                            title: "AR Features",
                            isOn: userPreferences.user.preferences.arFeaturesEnabled,
                            onToggle: { userPreferences.toggleARFeatures() }
                        )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct ToggleRow: View {
    let title: String
    let isOn: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: .constant(isOn))
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#fcc418")))
                .onTapGesture {
                    onToggle()
                }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
