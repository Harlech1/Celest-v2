import SwiftUI

struct FourthOnboardingView: View {
    let userName: String
    let age: String
    let gender: String
    
    @State private var height = ""
    @State private var weight = ""
    @State private var selectedSystem = "EU"
    @Environment(\.dismiss) private var dismiss
    
    private let systems = ["EU", "US"]
    
    private var heightPlaceholder: String {
        selectedSystem == "EU" ? "Height in cm" : "Height in ft"
    }
    
    private var weightPlaceholder: String {
        selectedSystem == "EU" ? "Weight in kg" : "Weight in lbs"
    }
    
    private var heightUnit: String {
        selectedSystem == "EU" ? "cm" : "ft"
    }
    
    private var weightUnit: String {
        selectedSystem == "EU" ? "kg" : "lbs"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // Unit System Picker
                VStack(spacing: 16) {
                    Text("Choose your measurement system")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 20)
                    
                    VStack(spacing: 12) {
                        Picker("Measurement System", selection: $selectedSystem) {
                            ForEach(systems, id: \.self) { system in
                                Text(system).tag(system)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 24)
                        
                        Text("This determines the units for height and weight")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                
                // Height Input
                VStack(spacing: 12) {
                    Text("What's your height?")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        ZStack {
                            TextField(heightPlaceholder, text: $height)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 12)
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                                .keyboardType(.decimalPad)
                            
                            if !height.isEmpty {
                                HStack {
                                    Spacer()
                                    Text(heightUnit)
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                        .padding(.trailing, 16)
                                }
                                .allowsHitTesting(false)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                // Weight Input
                VStack(spacing: 12) {
                    Text("What's your weight?")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        ZStack {
                            TextField(weightPlaceholder, text: $weight)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 12)
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                                .keyboardType(.decimalPad)
                            
                            if !weight.isEmpty {
                                HStack {
                                    Spacer()
                                    Text(weightUnit)
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                        .padding(.trailing, 16)
                                }
                                .allowsHitTesting(false)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Text("This helps us calculate your daily nutrition needs")
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

                    NavigationLink(destination: FifthOnboardingView(userName: userName, age: age, gender: gender, height: height, weight: weight, measurementSystem: selectedSystem)) {
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
    FourthOnboardingView(userName: "Türker", age: "25", gender: "Male")
} 
