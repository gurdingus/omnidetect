//
//  ContentView.swift
//  VoCAnalyzer
//
//  Created by Gurudas

import Observation
import AVFoundation
import AVKit
import AudioToolbox
import Charts
import PhotosUI
import SwiftUI
import UIKit
import WebKit

struct ContentView: View {
    @State private var authModel = GoogleAuthViewModel()
    @State private var signedInScreen: SignedInScreen = .welcome
    @State private var profile = UserProfile()
    @State private var hasLoadedProfile = false
    @State private var selectedPantryItem = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.96, blue: 1.0),
                    Color.white,
                    Color(red: 0.93, green: 0.98, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    AppLogo(size: 64)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Omnidetect")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.09, green: 0.17, blue: 0.31))

                        Text("Monitor breath, food, and health signals in one place.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)

                if let user = authModel.user {
                    SignedInScreenView(
                        user: user,
                        screen: $signedInScreen,
                        profile: $profile,
                        selectedPantryItem: $selectedPantryItem,
                        onLogout: {
                            authModel.signOut()
                            signedInScreen = .welcome
                        }
                    )
                        .padding(.horizontal, 24)
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Sign in to your workspace")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.20))

                        Text("Connect your Google account to open the Omnidetect dashboard.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button {
                            Task {
                                await authModel.signIn()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                GoogleMark(size: 18)

                                Text(authModel.isSigningIn ? "Signing in..." : "Continue with Google")
                                    .fontWeight(.medium)
                                    .foregroundStyle(.black.opacity(0.82))

                                Spacer()

                                if authModel.isSigningIn {
                                    ProgressView()
                                        .tint(.gray)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(authModel.isSigningIn)

                        if let errorMessage = authModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(Color(red: 0.72, green: 0.18, blue: 0.16))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(red: 1.0, green: 0.95, blue: 0.94))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        Text("Use an iOS OAuth client in Google Cloud for bundle ID `codingbunnies.VoCAnalyzer`, then replace the placeholder values in `Info.plist`.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(28)
                    .frame(maxWidth: 460, alignment: .leading)
                    .background(.white.opacity(0.94))
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 30, y: 14)
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: 0)
            }
            .padding(.bottom, 20)
        }
        .task {
            guard !hasLoadedProfile else { return }
            profile = ProfileStorage.load()
            hasLoadedProfile = true
        }
    }
}

private enum SignedInScreen {
    case welcome
    case home
    case health
    case breathScan
    case profile
    case pantry
    case pantryRecipes
    case fridge
    case fridgeRecipes
    case shelf
    case shelfRecipes
    case petFood
}

private struct SignedInScreenView: View {
    let user: GoogleUser
    @Binding var screen: SignedInScreen
    @Binding var profile: UserProfile
    @Binding var selectedPantryItem: String
    let onLogout: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()

                Button(action: onLogout) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline.weight(.semibold))

                        Text("Log Out")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundStyle(Color(red: 0.70, green: 0.21, blue: 0.18))
                    .background(Color(red: 1.0, green: 0.95, blue: 0.94))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Group {
                if screen == .welcome {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("Welcome, \(user.name)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.20))

                            Text("Choose where you want to go next.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 14) {
                            Button("Home") {
                                screen = .home
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.14, green: 0.38, blue: 0.86))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            Button("Health") {
                                screen = .health
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.08, green: 0.67, blue: 0.52))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                } else if screen == .home {
                    HomeHealthView(screen: $screen, selectedPantryItem: $selectedPantryItem)
                } else if screen == .pantry {
                    PantryHealthView(screen: $screen, selectedPantryItem: $selectedPantryItem)
                } else if screen == .pantryRecipes {
                    PantryRecipeSearchView(screen: $screen, itemName: selectedPantryItem)
                } else if screen == .fridge {
                    FridgeHealthView(screen: $screen, selectedPantryItem: $selectedPantryItem)
                } else if screen == .fridgeRecipes {
                    FridgeRecipeSearchView(screen: $screen, itemName: selectedPantryItem)
                } else if screen == .shelf {
                    ShelfHealthView(screen: $screen, selectedPantryItem: $selectedPantryItem)
                } else if screen == .shelfRecipes {
                    ShelfRecipeSearchView(screen: $screen, itemName: selectedPantryItem)
                } else if screen == .petFood {
                    PetFoodHealthView()
                } else if screen == .health {
                    HealthView(screen: $screen)
                } else if screen == .breathScan {
                    BreathScanView()
                } else {
                    ProfileView(user: user, screen: $screen, profile: $profile)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            SignedInNavBar(screen: $screen)
        }
        .padding(32)
        .frame(maxWidth: 520)
        .frame(height: 640)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.65), lineWidth: 1)
        }
        .shadow(color: Color(red: 0.14, green: 0.38, blue: 0.86).opacity(0.12), radius: 30, y: 14)
    }
}

private struct UserProfile: Codable {
    var profileImageData: Data?
    var age = ""
    var gender = ""
    var heightFeet = ""
    var heightInches = ""
    var weightLbs = ""
    var streetAddress = ""
    var city = ""
    var state = "CA"
    var zipCode = ""
    var phoneAreaCode = ""
    var phonePrefix = ""
    var phoneLineNumber = ""
}

private struct HomeHealthView: View {
    @Binding var screen: SignedInScreen
    @Binding var selectedPantryItem: String

    private let items = [
        "Pantry Health",
        "Fridge Health",
        "Fruitbowl Health",
        "Pet Food Health",
        "Diabetic Food"
    ]

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Home")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.20))

                Text("Choose a health area to review.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 14) {
                ForEach(items, id: \.self) { item in
                    Button(item) {
                        if item == "Pantry Health" {
                            selectedPantryItem = ""
                            screen = .pantry
                        } else if item == "Fridge Health" {
                            selectedPantryItem = ""
                            screen = .fridge
                        } else if item == "Fruitbowl Health" {
                            selectedPantryItem = ""
                            screen = .shelf
                        } else if item == "Pet Food Health" {
                            selectedPantryItem = ""
                            screen = .petFood
                        }
                    }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.93, green: 0.97, blue: 1.0),
                                    Color(red: 0.91, green: 0.97, blue: 0.95)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(Color(red: 0.09, green: 0.17, blue: 0.31))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(red: 0.78, green: 0.87, blue: 0.98), lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .buttonStyle(.plain)

            Button(action: {}) {
                HStack(spacing: 12) {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color(red: 0.14, green: 0.38, blue: 0.86))
                        .clipShape(Circle())

                    Text("Add a new health indicator")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(red: 0.09, green: 0.17, blue: 0.31))

                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(Color.white.opacity(0.96))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(red: 0.84, green: 0.90, blue: 0.98), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .help("Add a new home health indicator")
            .hoverEffect(.lift)
        }
    }
}

private struct PantryHealthView: View {
    @Binding var screen: SignedInScreen
    @Binding var selectedPantryItem: String

    private let items: [InventoryStatusItem] = [
        InventoryStatusItem(name: "Bread", systemImage: "birthday.cake.fill", status: "Good", tint: Color(red: 0.88, green: 0.64, blue: 0.34)),
        InventoryStatusItem(name: "Cup Noodles", systemImage: "cup.and.saucer.fill", status: "Throw away, styrofoam rotting", tint: Color(red: 0.86, green: 0.42, blue: 0.27)),
        InventoryStatusItem(name: "Potatoes", systemImage: "circle.fill", status: "Good", tint: Color(red: 0.67, green: 0.52, blue: 0.29)),
        InventoryStatusItem(name: "Onions", systemImage: "smallcircle.filled.circle.fill", status: "Getting old", tint: Color(red: 0.76, green: 0.63, blue: 0.33)),
        InventoryStatusItem(name: "Fruit Basket", systemImage: "basket.fill", status: "Getting old", tint: Color(red: 0.80, green: 0.31, blue: 0.26))
    ]

    var body: some View {
        InventoryCategoryView(title: "Pantry Health", subtitle: "Current pantry item status.", items: items) { item in
            selectedPantryItem = item.name
            screen = .pantryRecipes
        }
    }
}

private struct FridgeHealthView: View {
    @Binding var screen: SignedInScreen
    @Binding var selectedPantryItem: String

    private let items: [InventoryStatusItem] = [
        InventoryStatusItem(name: "Cabbage", systemImage: "circle.grid.2x2.fill", status: "Use soon", tint: Color(red: 0.62, green: 0.76, blue: 0.93)),
        InventoryStatusItem(name: "Tomatoes", systemImage: "circle.fill", status: "Good", tint: Color(red: 0.93, green: 0.24, blue: 0.26)),
        InventoryStatusItem(name: "Cucumber", systemImage: "leaf.fill", status: "Good", tint: Color(red: 0.26, green: 0.63, blue: 0.34)),
        InventoryStatusItem(name: "Carrot", systemImage: "triangle.fill", status: "Good", tint: Color(red: 0.97, green: 0.56, blue: 0.18))
    ]

    var body: some View {
        InventoryCategoryView(title: "Fridge Health", subtitle: "Current fridge item status.", items: items) { item in
            selectedPantryItem = item.name
            screen = .fridgeRecipes
        }
    }
}

private struct ShelfHealthView: View {
    @Binding var screen: SignedInScreen
    @Binding var selectedPantryItem: String

    private let items: [InventoryStatusItem] = [
        InventoryStatusItem(name: "Banana", systemImage: "leaf.fill", status: "Good", tint: Color(red: 0.96, green: 0.82, blue: 0.20)),
        InventoryStatusItem(name: "Apple", systemImage: "apple.logo", status: "Good", tint: Color(red: 0.83, green: 0.17, blue: 0.20)),
        InventoryStatusItem(name: "Pear", systemImage: "leaf.circle.fill", status: "Good", tint: Color(red: 0.62, green: 0.78, blue: 0.29)),
        InventoryStatusItem(name: "Mango", systemImage: "sun.max.fill", status: "Good", tint: Color(red: 0.98, green: 0.63, blue: 0.18)),
        InventoryStatusItem(name: "Plum", systemImage: "moon.circle.fill", status: "Good", tint: Color(red: 0.53, green: 0.31, blue: 0.64))
    ]

    var body: some View {
        InventoryCategoryView(title: "Fruitbowl Health", subtitle: "Current fruitbowl item status.", items: items) { item in
            selectedPantryItem = item.name
            screen = .shelfRecipes
        }
    }
}

private struct PetFoodHealthView: View {
    private let items: [InventoryStatusItem] = [
        InventoryStatusItem(name: "Dry Kibble", systemImage: "pawprint.fill", status: "Good", tint: Color(red: 0.67, green: 0.47, blue: 0.28)),
        InventoryStatusItem(name: "Dog Treats", systemImage: "bone.fill", status: "Good", tint: Color(red: 0.87, green: 0.75, blue: 0.52)),
        InventoryStatusItem(name: "Cat Treats", systemImage: "fish.fill", status: "Getting old", tint: Color(red: 0.31, green: 0.61, blue: 0.76))
    ]

    var body: some View {
        InventoryCategoryView(title: "Pet Food Health", subtitle: "Current pet food item status.", items: items, onSelect: nil)
    }
}

private struct InventoryCategoryView: View {
    let title: String
    let subtitle: String
    let items: [InventoryStatusItem]
    let onSelect: ((InventoryStatusItem) -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.20))

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        Button {
                            onSelect?(item)
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(item.tint.opacity(0.14))

                                    Image(systemName: item.systemImage)
                                        .font(.title2)
                                        .foregroundStyle(item.tint)
                                }
                                .frame(width: 58, height: 58)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.headline)
                                        .foregroundStyle(Color(red: 0.09, green: 0.17, blue: 0.31))

                                    Text(item.status)
                                        .font(.subheadline)
                                        .foregroundStyle(inventoryStatusColor(for: item.status))
                                }

                                Spacer()
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.96))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color(red: 0.84, green: 0.90, blue: 0.98), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(onSelect == nil)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct PantryRecipeSearchView: View {
    @Binding var screen: SignedInScreen
    let itemName: String

    var body: some View {
        RecipeSearchView(screen: $screen, itemName: itemName, title: "Pantry Recipes", backScreen: .pantry)
    }
}

private struct FridgeRecipeSearchView: View {
    @Binding var screen: SignedInScreen
    let itemName: String

    var body: some View {
        RecipeSearchView(screen: $screen, itemName: itemName, title: "Fridge Recipes", backScreen: .fridge)
    }
}

private struct ShelfRecipeSearchView: View {
    @Binding var screen: SignedInScreen
    let itemName: String

    var body: some View {
        RecipeSearchView(screen: $screen, itemName: itemName, title: "Shelf Recipes", backScreen: .shelf)
    }
}

private struct RecipeSearchView: View {
    @Binding var screen: SignedInScreen
    let itemName: String
    let title: String
    let backScreen: SignedInScreen

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text(itemName.isEmpty ? title : "\(itemName) Recipes")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.20))

                Text("Google recipe ideas using this item.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button("Back") {
                screen = backScreen
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(Color(red: 0.14, green: 0.38, blue: 0.86))
            .buttonStyle(.plain)

            RecipeSearchWebView(itemName: itemName)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(red: 0.84, green: 0.90, blue: 0.98), lineWidth: 1)
                }
        }
    }
}

private struct InventoryStatusItem: Identifiable {
    let id = UUID()
    let name: String
    let systemImage: String
    let status: String
    let tint: Color
}

private func inventoryStatusColor(for status: String) -> Color {
    switch status {
    case "Good":
        return Color(red: 0.17, green: 0.55, blue: 0.30)
    case "Getting old", "Use soon":
        return Color(red: 0.78, green: 0.50, blue: 0.15)
    default:
        return Color(red: 0.76, green: 0.21, blue: 0.18)
    }
}

private struct HealthView: View {
    @Binding var screen: SignedInScreen

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Health")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.20))

                Text("Run a focused health check from here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button("Diagnose my breath") {
                screen = .breathScan
            }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.58, blue: 0.82),
                            Color(red: 0.07, green: 0.70, blue: 0.56)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color(red: 0.07, green: 0.70, blue: 0.56).opacity(0.2), radius: 16, y: 8)
                .buttonStyle(.plain)

            Spacer(minLength: 0)

        }
    }
}

private struct BreathScanView: View {
    @State private var phase: BreathScanPhase = .instruction
    @State private var activeTimer = BreathScanTimer(seconds: 3, message: "Start in 3 seconds")
    @State private var analysisMessage = "Your health is normal."
    @State private var hasPlayedInstructionVoiceOver = false

    private let speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                VStack(spacing: 8) {
                    Text("Diagnose My Breath")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.20))

                    Text("Follow the guided scan to begin breath analysis.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                switch phase {
                case .instruction:
                    VStack(spacing: 18) {
                        BreathInstructionVideo()
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color(red: 0.84, green: 0.90, blue: 0.98), lineWidth: 1)
                            }

                        Text("Place the device close to your mouth and breathe out steadily for 3 seconds.")
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .foregroundStyle(.secondary)

                        Button("Start Scan Now") {
                            startScanSequence()
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.14, green: 0.38, blue: 0.86),
                                    Color(red: 0.08, green: 0.67, blue: 0.52)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .buttonStyle(.plain)
                    }
                    .onAppear {
                        guard !hasPlayedInstructionVoiceOver else { return }
                        hasPlayedInstructionVoiceOver = true
                        speak("Place the device close to your mouth and breathe out for 3 seconds.")
                    }

                case .countdown, .breathingOut:
                    VStack(spacing: 20) {
                        CircularCountdownView(timer: activeTimer)
                            .frame(width: 220, height: 220)

                        Text(phase == .countdown ? "Get ready for the breath scan." : "Keep breathing out until the tone.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }

                case .analyzing:
                    VStack(spacing: 20) {
                        ProgressView()
                            .controlSize(.large)
                            .tint(Color(red: 0.14, green: 0.38, blue: 0.86))

                        Text("Starting analysis now, you can stop breathing out.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color(red: 0.09, green: 0.17, blue: 0.31))
                    }

                case .result:
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.90, green: 0.98, blue: 0.92))
                                .frame(width: 110, height: 110)

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 54))
                                .foregroundStyle(Color(red: 0.17, green: 0.55, blue: 0.30))
                        }

                        Text(analysisMessage)
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color(red: 0.09, green: 0.17, blue: 0.31))

                        Text("Scan complete. You can run another scan whenever needed.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)

                        BreathResultChart()
                            .frame(height: 200)

                        Button("Run Another Scan") {
                            phase = .instruction
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.96))
                        .foregroundStyle(Color(red: 0.14, green: 0.38, blue: 0.86))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(red: 0.84, green: 0.90, blue: 0.98), lineWidth: 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    private func startScanSequence() {
        Task {
            phase = .countdown
            activeTimer = BreathScanTimer(seconds: 3, message: "Start in 3 seconds")

            try? await Task.sleep(for: .seconds(3))
            playTone()
            speak("Breathe out through your mouth.")

            phase = .breathingOut
            activeTimer = BreathScanTimer(seconds: 3, message: "Breathe out")

            try? await Task.sleep(for: .seconds(3))
            playTone()
            speak("Starting analysis now, you can stop breathing out.")

            phase = .analyzing
            try? await Task.sleep(for: .seconds(2))

            analysisMessage = "Your health is normal."
            phase = .result
        }
    }

    private func playTone() {
        AudioServicesPlaySystemSound(1113)
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)
    }
}

private struct BreathResultChart: View {
    private let points: [BreathChartPoint]

    init() {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -14, to: calendar.startOfDay(for: .now)) ?? .now
        let totalDays = max(calendar.dateComponents([.day], from: startDate, to: .now).day ?? 0, 1)
        var generatedPoints: [BreathChartPoint] = []

        for dayOffset in 0...totalDays {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) ?? .now
            let wave = sin(Double(dayOffset) * 0.37) * 0.16
            let ripple = cos(Double(dayOffset) * 0.19) * 0.11
            let stepBump = Double((dayOffset % 6) - 3) * 0.015
            let vocLevel = min(max(1.0 + wave + ripple + stepBump, 0.55), 1.45)
            generatedPoints.append(.init(date: date, vocLevel: vocLevel))
        }

        points = generatedPoints
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("VOC Trend")
                .font(.headline)
                .foregroundStyle(.white)

            Chart(points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("VOC Level", point.vocLevel)
                )
                .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                .foregroundStyle(.white)

                PointMark(x: .value("Date", point.date), y: .value("VOC Level", point.vocLevel))
                    .foregroundStyle(.white)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.white.opacity(0.22))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.month(.abbreviated).day())
                                .foregroundStyle(.white.opacity(0.92))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0.5, 0.75, 1.0, 1.25, 1.5]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(.white.opacity(0.22))
                    AxisValueLabel {
                        if let level = value.as(Double.self) {
                            Text(String(format: "%.2f", level))
                                .foregroundStyle(.white.opacity(0.92))
                        }
                    }
                }
            }
            .chartYScale(domain: 0.5...1.5)
            .chartXAxisLabel("Date")
            .chartYAxisLabel("VOC Level")
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color.clear)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.55, blue: 0.64),
                    Color(red: 0.09, green: 0.48, blue: 0.62)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct BreathChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let vocLevel: Double
}

private enum BreathScanPhase {
    case instruction
    case countdown
    case breathingOut
    case analyzing
    case result
}

private struct BreathScanTimer {
    let duration: TimeInterval
    let startDate: Date
    let message: String

    init(seconds: TimeInterval, message: String) {
        duration = seconds
        startDate = Date()
        self.message = message
    }
}

private struct CircularCountdownView: View {
    let timer: BreathScanTimer

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.02)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(timer.startDate)
            let remaining = max(timer.duration - elapsed, 0)
            let progress = max(remaining / timer.duration, 0)

            ZStack {
                Circle()
                    .stroke(Color(red: 0.88, green: 0.93, blue: 0.98), lineWidth: 16)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(red: 0.14, green: 0.38, blue: 0.86),
                                Color(red: 0.08, green: 0.67, blue: 0.52)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 6) {
                    Text(timer.message)
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.09, green: 0.17, blue: 0.31))

                    Text("\(Int(ceil(remaining)))")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.14, green: 0.38, blue: 0.86))
                }
            }
        }
    }
}

private struct BreathInstructionVideo: View {
    var body: some View {
        if let videoURL = Bundle.main.url(forResource: "demovideo", withExtension: "mp4") {
            InstructionVideoPlayer(url: videoURL)
        } else {
            ZStack {
                Color(red: 0.94, green: 0.96, blue: 0.99)

                VStack(spacing: 12) {
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Color(red: 0.58, green: 0.64, blue: 0.74))

                    Text("Instruction video not found.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(red: 0.09, green: 0.17, blue: 0.31))
                }
            }
        }
    }
}

private struct InstructionVideoPlayer: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill

        let player = AVPlayer(url: url)
        context.coordinator.player = player

        controller.player = player
        let startTime = CMTime(seconds: 2, preferredTimescale: 600)
        player.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            player.play()
        }
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if context.coordinator.player?.rate == 0 {
            context.coordinator.player?.play()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var player: AVPlayer?
    }
}

private struct SignedInNavBar: View {
    @Binding var screen: SignedInScreen

    var body: some View {
        HStack(spacing: 0) {
            BottomNavItem(
                title: "Home",
                systemImage: "house.fill",
                isSelected: screen == .home
            ) {
                screen = .home
            }

            BottomNavItem(
                title: "Health",
                systemImage: "cross.case.fill",
                isSelected: screen == .health
            ) {
                screen = .health
            }

            BottomNavItem(
                title: "Profile",
                systemImage: "person.crop.circle.fill",
                isSelected: screen == .profile
            ) {
                screen = .profile
            }
        }
        .padding(8)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.98),
                    Color(red: 0.95, green: 0.97, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(red: 0.84, green: 0.89, blue: 0.97), lineWidth: 1)
        }
    }
}

private struct ProfileView: View {
    let user: GoogleUser
    @Binding var screen: SignedInScreen
    @Binding var profile: UserProfile
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var saveMessage: String?

    private let states = [
        "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
        "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
        "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
        "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
        "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Profile")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.20))

                Text("Signed in as \(user.name)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        VStack(spacing: 10) {
                            Group {
                                if let uiImage = profile.uiImage {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(18)
                                        .foregroundStyle(Color(red: 0.14, green: 0.38, blue: 0.86))
                                }
                            }
                            .frame(width: 92, height: 92)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(Color(red: 0.80, green: 0.88, blue: 0.97), lineWidth: 2)
                            }

                            Text("Upload profile picture")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color(red: 0.09, green: 0.17, blue: 0.31))
                        }
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 12) {
                        ProfileField(title: "Age", text: $profile.age, keyboardType: .numberPad)
                        ProfileField(title: "Gender", text: $profile.gender)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Height")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(red: 0.34, green: 0.42, blue: 0.55))

                            HStack(spacing: 10) {
                                CompactProfileField(title: "Feet", text: $profile.heightFeet, keyboardType: .numberPad)
                                CompactProfileField(title: "Inches", text: $profile.heightInches, keyboardType: .numberPad)
                            }
                        }

                        ProfileField(title: "Weight (lbs)", text: $profile.weightLbs, keyboardType: .decimalPad)

                        ProfileField(title: "Street Address", text: $profile.streetAddress, capitalization: .words)
                        ProfileField(title: "City", text: $profile.city, capitalization: .words)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("State")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(red: 0.34, green: 0.42, blue: 0.55))

                            Picker("State", selection: $profile.state) {
                                ForEach(states, id: \.self) { state in
                                    Text(state).tag(state)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.96))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(red: 0.85, green: 0.90, blue: 0.98), lineWidth: 1)
                            }
                        }

                        ProfileField(title: "ZIP Code", text: $profile.zipCode, keyboardType: .numberPad)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Phone Number")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(red: 0.34, green: 0.42, blue: 0.55))

                            HStack(spacing: 10) {
                                CompactProfileField(title: "123", text: $profile.phoneAreaCode, keyboardType: .numberPad)
                                CompactProfileField(title: "456", text: $profile.phonePrefix, keyboardType: .numberPad)
                                CompactProfileField(title: "7890", text: $profile.phoneLineNumber, keyboardType: .numberPad)
                            }
                        }

                        Button("Save Profile") {
                            ProfileStorage.save(profile)
                            saveMessage = "Profile saved on this device."
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.14, green: 0.38, blue: 0.86),
                                    Color(red: 0.08, green: 0.67, blue: 0.52)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .buttonStyle(.plain)

                        if let saveMessage {
                            Text(saveMessage)
                                .font(.footnote)
                                .foregroundStyle(Color(red: 0.16, green: 0.46, blue: 0.28))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.93, green: 0.97, blue: 1.0),
                            Color.white
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(red: 0.84, green: 0.89, blue: 0.97), lineWidth: 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .task(id: selectedPhoto) {
            guard let selectedPhoto,
                  let data = try? await selectedPhoto.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                return
            }

            profile.profileImageData = uiImage.jpegData(compressionQuality: 0.9)
        }
    }
}

private extension UserProfile {
    var uiImage: UIImage? {
        guard let profileImageData else { return nil }
        return UIImage(data: profileImageData)
    }
}

private enum ProfileStorage {
    private static let key = "vocAnalyzer.userProfile"

    static func load() -> UserProfile {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
        else {
            return UserProfile()
        }

        return profile
    }

    static func save(_ profile: UserProfile) {
        guard let data = try? JSONEncoder().encode(profile) else {
            return
        }

        UserDefaults.standard.set(data, forKey: key)
    }
}

private struct ProfileField: View {
    let title: String
    @Binding var text: String
    var capitalization: TextInputAutocapitalization = .never
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 0.34, green: 0.42, blue: 0.55))

            TextField(title, text: $text)
                .textInputAutocapitalization(capitalization)
                .keyboardType(keyboardType)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.96))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(red: 0.85, green: 0.90, blue: 0.98), lineWidth: 1)
                }
        }
    }
}

private struct CompactProfileField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(keyboardType)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(red: 0.85, green: 0.90, blue: 0.98), lineWidth: 1)
            }
    }
}

private struct BottomNavItem: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.headline)

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(isSelected ? .white : Color(red: 0.09, green: 0.17, blue: 0.31))
            .background(
                isSelected
                ? Color(red: 0.14, green: 0.38, blue: 0.86)
                : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct RecipeSearchWebView: UIViewRepresentable {
    let itemName: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.showsVerticalScrollIndicator = true
        webView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let query = itemName.isEmpty ? "pantry recipes" : "recipes using \(itemName)"
        guard
            let escapedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://www.google.com/search?q=\(escapedQuery)")
        else {
            return
        }

        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
}

private struct AppLogo: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.38, blue: 0.86),
                            Color(red: 0.08, green: 0.67, blue: 0.52)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                .padding(size * 0.08)

            HStack(alignment: .bottom, spacing: size * 0.05) {
                Capsule().frame(width: size * 0.08, height: size * 0.22)
                Capsule().frame(width: size * 0.08, height: size * 0.36)
                Capsule().frame(width: size * 0.08, height: size * 0.52)
                Capsule().frame(width: size * 0.08, height: size * 0.30)
            }
            .foregroundStyle(.white)
            .offset(x: -size * 0.09, y: size * 0.03)

            Circle()
                .stroke(.white, lineWidth: size * 0.08)
                .frame(width: size * 0.34, height: size * 0.34)
                .offset(x: size * 0.16, y: -size * 0.05)

            Rectangle()
                .fill(.white)
                .frame(width: size * 0.08, height: size * 0.18)
                .rotationEffect(.degrees(-35))
                .offset(x: size * 0.28, y: size * 0.18)
        }
        .frame(width: size, height: size)
    }
}

private struct GoogleMark: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.00, to: 0.24)
                .stroke(Color(red: 0.26, green: 0.52, blue: 0.96), lineWidth: size * 0.22)

            Circle()
                .trim(from: 0.24, to: 0.49)
                .stroke(Color(red: 0.20, green: 0.66, blue: 0.33), lineWidth: size * 0.22)

            Circle()
                .trim(from: 0.49, to: 0.74)
                .stroke(Color(red: 0.98, green: 0.73, blue: 0.17), lineWidth: size * 0.22)

            Circle()
                .trim(from: 0.74, to: 0.96)
                .stroke(Color(red: 0.92, green: 0.30, blue: 0.24), lineWidth: size * 0.22)

            Rectangle()
                .fill(Color.white)
                .frame(width: size * 0.44, height: size * 0.34)
                .offset(x: size * 0.24)

            Rectangle()
                .fill(Color(red: 0.26, green: 0.52, blue: 0.96))
                .frame(width: size * 0.30, height: size * 0.10)
                .offset(x: size * 0.15, y: size * 0.04)
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(-12))
    }
}

#Preview {
    ContentView()
}
