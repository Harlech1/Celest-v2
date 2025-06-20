import SwiftUI

struct ThirdOnboardingView: View {
    let userName: String
    let age: String
    
    @State private var selectedGender = "Male"
    @Environment(\.dismiss) private var dismiss
    
    private let genders = ["Male", "Female", "Other"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Question and picker at the top
                VStack(spacing: 16) {
                    Text("What's your gender?")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Picker("Gender", selection: $selectedGender) {
                            ForEach(genders, id: \.self) { gender in
                                Text(gender).tag(gender)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 24)
                        
                        Text("This helps personalize your experience")
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

                    NavigationLink(destination: FourthOnboardingView(userName: userName, age: age, gender: selectedGender)) {
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
    ThirdOnboardingView(userName: "Türker", age: "25")
} 
