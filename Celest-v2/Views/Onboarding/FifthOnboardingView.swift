import SwiftUI

struct FifthOnboardingView: View {
    let userName: String
    let age: String
    let gender: String
    let height: String
    let weight: String
    let measurementSystem: String
    
    @Environment(\.dismiss) private var dismiss
    
    private var bmi: Double {
        // Debug prints
        print("Height: '\(height)', Weight: '\(weight)', System: '\(measurementSystem)'")
        
        guard !height.isEmpty,
              !weight.isEmpty else { 
            print("BMI calculation failed - empty inputs")
            return 0 
        }
        
        // Handle both comma and period decimal separators
        let cleanHeight = height.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        let cleanWeight = weight.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        
        guard let heightValue = Double(cleanHeight),
              let weightValue = Double(cleanWeight),
              heightValue > 0,
              weightValue > 0 else { 
            print("BMI calculation failed - invalid numeric inputs: height='\(cleanHeight)', weight='\(cleanWeight)'")
            return 0 
        }
        
        let calculatedBMI: Double
        if measurementSystem == "EU" {
            // Height in cm, weight in kg
            let heightInMeters = heightValue / 100
            calculatedBMI = weightValue / (heightInMeters * heightInMeters)
        } else {
            // Height in ft, weight in lbs
            let heightInInches = heightValue * 12
            calculatedBMI = (weightValue / (heightInInches * heightInInches)) * 703
        }
        
        print("Calculated BMI: \(calculatedBMI)")
        return calculatedBMI
    }
    
    private var bmiCategory: String {
        if bmi == 0 {
            return "Enter your measurements"
        }
        
        switch bmi {
        case 0..<18.5:
            return "Underweight"
        case 18.5..<25:
            return "Normal weight"
        case 25..<30:
            return "Overweight"
        default:
            return "Obese"
        }
    }
    
    private var bmiColor: Color {
        if bmi == 0 {
            return .secondary
        }
        
        switch bmi {
        case 0..<18.5:
            return .blue
        case 18.5..<25:
            return .green
        case 25..<30:
            return .orange
        default:
            return .red
        }
    }
    
    private var currentWeight: Double {
        let cleanWeight = weight.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        return Double(cleanWeight) ?? 0
    }
    
    private var currentHeightInMeters: Double {
        let cleanHeight = height.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard let heightValue = Double(cleanHeight) else { return 0 }
        
        if measurementSystem == "EU" {
            return heightValue / 100 // cm to meters
        } else {
            return (heightValue * 12) * 0.0254 // ft to inches to meters
        }
    }
    
    private var idealWeight: Double {
        guard currentHeightInMeters > 0 else { return 0 }
        // Using BMI of 22 as ideal (middle of healthy range)
        return 22 * (currentHeightInMeters * currentHeightInMeters)
    }
    
    private var weightToLoseForNextCategory: Double {
        guard currentWeight > 0, currentHeightInMeters > 0 else { return 0 }
        
        let heightSquared = currentHeightInMeters * currentHeightInMeters
        
        switch bmi {
        case 30...:
            // Obese -> Overweight (BMI 30)
            return currentWeight - (30 * heightSquared)
        case 25..<30:
            // Overweight -> Normal (BMI 25)
            return currentWeight - (25 * heightSquared)
        case 18.5..<25:
            // Already normal weight
            return 0
        default:
            // Underweight - should gain weight
            return 0
        }
    }
    
    private var healthyWeightRange: String {
        guard currentHeightInMeters > 0 else { return "N/A" }
        
        let heightSquared = currentHeightInMeters * currentHeightInMeters
        let minHealthyWeight = 18.5 * heightSquared
        let maxHealthyWeight = 25 * heightSquared
        
        let unit = measurementSystem == "EU" ? "kg" : "lbs"
        
        if measurementSystem == "US" {
            // Convert kg to lbs
            let minLbs = minHealthyWeight * 2.20462
            let maxLbs = maxHealthyWeight * 2.20462
            return String(format: "%.0f - %.0f %@", minLbs, maxLbs, unit)
        } else {
            return String(format: "%.0f - %.0f %@", minHealthyWeight, maxHealthyWeight, unit)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                // BMI Display
                VStack(spacing: 16) {
                    Text("Your BMI")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Text(bmi == 0 ? "--" : String(format: "%.1f", bmi))
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundStyle(bmiColor)
                        
                        Text(bmiCategory)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(bmiColor)
                    }
                }
                
                // BMI Insights Card
                VStack(spacing: 16) {
                    Text("Health Insights")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        if bmi > 0 {
                            HStack {
                                Text("Healthy BMI Range")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("18.5 - 25.0")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Healthy Weight Range")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(healthyWeightRange)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Your Ideal Weight")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.1f %@", 
                                          measurementSystem == "US" ? idealWeight * 2.20462 : idealWeight,
                                          measurementSystem == "EU" ? "kg" : "lbs"))
                                    .fontWeight(.medium)
                            }
                            
                            if weightToLoseForNextCategory > 0 {
                                HStack {
                                    Text("Weight to lose")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(String(format: "%.1f %@", 
                                              measurementSystem == "US" ? weightToLoseForNextCategory * 2.20462 : weightToLoseForNextCategory,
                                              measurementSystem == "EU" ? "kg" : "lbs"))
                                        .fontWeight(.medium)
                                        .foregroundStyle(.orange)
                                }
                                
                                Text("To reach \(bmi >= 30 ? "overweight" : "normal weight") category")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            } else if bmi >= 18.5 && bmi < 25 {
                                HStack {
                                    Text("Status")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("You're in the healthy range! 🎉")
                                        .fontWeight(.medium)
                                        .foregroundStyle(.green)
                                }
                            }
                        } else {
                            Text("Enter your measurements to see health insights")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                
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

                    Button(action: completeOnboarding) {
                        Text("Get Started")
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
    
    private func completeOnboarding() {
        // Save all user data
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(age, forKey: "userAge")
        UserDefaults.standard.set(gender, forKey: "userGender")
        UserDefaults.standard.set(height, forKey: "userHeight")
        UserDefaults.standard.set(weight, forKey: "userWeight")
        UserDefaults.standard.set(measurementSystem, forKey: "userMeasurementSystem")
        UserDefaults.standard.set(bmi, forKey: "userBMI")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    FifthOnboardingView(userName: "Türker", age: "25", gender: "Male", height: "186", weight: "75", measurementSystem: "EU")
}
