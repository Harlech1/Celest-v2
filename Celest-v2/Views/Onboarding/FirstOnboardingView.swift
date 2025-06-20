import SwiftUI

struct FirstOnboardingView: View {
    @State private var userName = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // App Name at top
                HStack {
                    Image(systemName: "laser.burst")
                        .font(.largeTitle)
                    Text("Celest")
                        .font(.nostalgic(size: 56))
                        .foregroundStyle(.primary)
                }
                .padding(.top, 20)

                // Name Input Section
                VStack(spacing: 16) {
                    Text("What should we call you?")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    VStack(spacing: 8) {
                        TextField("Your name", text: $userName)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)

                        Text("We'll use this to personalize your experience")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
            .navigationBarHidden(true)
            .overlay(alignment: .bottom) {
                NavigationLink(destination: SecondOnboardingView(userName: userName.trimmingCharacters(in: .whitespacesAndNewlines))) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    FirstOnboardingView()
}
