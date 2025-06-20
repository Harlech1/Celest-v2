import SwiftUI

struct SettingsView: View {
    @State private var userName = UserDefaults.standard.string(forKey: "userName") ?? "User"
    @State private var showingOnboardingAlert = false
    @State private var showingOnboarding = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("User Profile")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        Text("Name")
                        Spacer()
                        Text(userName)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(header: Text("App Settings")) {
                    Button(action: {
                        showingOnboarding = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle")
                                .font(.title3)
                                .foregroundStyle(.orange)
                            Text("View Onboarding")
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "star.circle")
                            .font(.title3)
                            .foregroundStyle(.yellow)
                        Text("Made with")
                        Spacer()
                        Text("❤️ by Türker")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .fullScreenCover(isPresented: $showingOnboarding) {
                FirstOnboardingView()
            }
        }
    }
}

#Preview {
    SettingsView()
} 