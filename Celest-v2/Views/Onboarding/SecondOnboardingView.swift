import SwiftUI

struct SecondOnboardingView: View {
    let userName: String
    
    @State private var age = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Greeting
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Welcome to")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "laser.burst")
                                .font(.title2)
                            Text("Celest")
                                .font(.nostalgic(size: 32))
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.primary)
                    }
                    
                    Text(userName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                    .padding(.top, 20)
                
                // Age Input
                VStack(spacing: 16) {
                    Text("How old are you?")
                        .font(.title3)
                        .fontWeight(.semibold)
                    VStack(spacing: 8) {
                        TextField("Age", text: $age)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .keyboardType(.numberPad)
                            .padding(.horizontal, 24)

                        Text("This helps us provide better nutrition insights")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .overlay(alignment: .bottom) {
                HStack(spacing: 12) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Back")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.blue)
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                    }
                    .frame(maxWidth: 80)

                    NavigationLink(destination: ThirdOnboardingView(userName: userName, age: age)) {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.blue)
                            .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity)
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
    SecondOnboardingView(userName: "Türker")
} 
