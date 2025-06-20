//
//  LogView.swift
//  Celest-v2
//
//  Created by Türker Kızılcık on 12.06.2025.
//

import SwiftUI
import CoreData

// Temporary extension until Core Data generates the class
extension NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NSManagedObject> {
        return NSFetchRequest<NSManagedObject>(entityName: String(describing: self))
    }
}

struct LogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMealType: MealType = LogView.defaultMealType()
    @State private var mealName = ""
    @State private var mealWeight = ""
    @State private var mealCalorie = ""
    @State private var mealProtein = ""
    @State private var showingSaveAlert = false
    @State private var mealDate = Date()
    @State private var shouldRememberFood = true
    @State private var rememberedFood: NSManagedObject?
    @State private var showingFoodSuggestion = false
    @State private var isUsingFoodMemory = false
    @State private var caloriesPerGram: Double = 0
    @State private var proteinPerGram: Double = 0
    @State private var isKeyboardVisible = false
    @State private var isApplyingFood = false
    
    private var weightBinding: Binding<String> {
        Binding(
            get: { mealWeight },
            set: { newValue in
                mealWeight = newValue
                // Auto-calculate calories and protein if using food memory
                if isUsingFoodMemory {
                    calculateNutritionFromWeight()
                }
            }
        )
    }
    
    private var calorieBinding: Binding<String> {
        Binding(
            get: { mealCalorie },
            set: { newValue in
                // If user manually edits calories while using food memory, stop auto-calculation
                if isUsingFoodMemory && newValue != mealCalorie {
                    stopUsingFoodMemory()
                }
                mealCalorie = newValue
            }
        )
    }
    
    private var proteinBinding: Binding<String> {
        Binding(
            get: { mealProtein },
            set: { newValue in
                // If user manually edits protein while using food memory, stop auto-calculation
                if isUsingFoodMemory && newValue != mealProtein {
                    stopUsingFoodMemory()
                }
                mealProtein = newValue
            }
        )
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Meal Info"), footer: Text("Provide your meal's basics: choose a type, give it a name, and specify weight (g), calories (kcal) & protein (g).")) {
                    Picker("Type", selection: $selectedMealType) {
                        ForEach(MealType.types) { type in
                            Label(type.title, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    LabeledContent("Date & Time") {
                        DatePicker("", selection: $mealDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }

                    HStack {
                        Image(systemName: "pencil")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.secondary)
                        TextField("Name", text: $mealName)
                            .onChange(of: mealName) { oldValue, newValue in
                                // If user manually changes name while using food memory, stop auto-calculation
                                if isUsingFoodMemory && !isApplyingFood && oldValue != newValue {
                                    stopUsingFoodMemory()
                                }
                                checkForRememberedFood()
                            }
                    }
                    
                    if showingFoodSuggestion, let food = rememberedFood {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Found: \((food.value(forKey: "foodName") as? String) ?? "Unknown")")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                
                                let savedWeight = (food.value(forKey: "weight") as? Double) ?? 0
                                let savedCalories = (food.value(forKey: "calories") as? Double) ?? 0
                                let savedProtein = (food.value(forKey: "protein") as? Double) ?? 0
                                let calPerG = savedWeight > 0 ? savedCalories / savedWeight : 0
                                let protPerG = savedWeight > 0 ? savedProtein / savedWeight : 0
                                
                                Text(String(format: "%.1f kcal/g • %.1f protein/g", calPerG, protPerG))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Use") {
                                applyRememberedFood(food)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.yellow.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    if isUsingFoodMemory {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundStyle(.blue)
                            Text("Using saved nutrition ratios")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Spacer()
                            Button("Stop") {
                                stopUsingFoodMemory()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.blue.opacity(0.1))
                        .cornerRadius(8)
                    }

                    HStack {
                        Image(systemName: "scalemass")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.secondary)
                        Text("Weight")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("0", text: weightBinding)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Image(systemName: "flame")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.secondary)
                        Text("Calories")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("0", text: calorieBinding)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kcal")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.secondary)
                        Text("Protein")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("0", text: proteinBinding)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("g")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(footer: Text("Enable this to remember nutrition info for this food name for future use.")) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.secondary)
                        Text("Remember this food")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Toggle("", isOn: $shouldRememberFood)
                            .labelsHidden()
                    }
                }
            }
        }
        .navigationTitle("Log")
        .onAppear {
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        .overlay(alignment: .bottom) {
            Button(action: saveMealLog) {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save Log")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding()
                .background(
                    isKeyboardVisible ? 
                    .blue.opacity(0.7) : 
                    .blue
                )
                .cornerRadius(12)
            }
            .padding()
            .disabled(mealName.isEmpty)
        }
        .alert("Meal Saved!", isPresented: $showingSaveAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your meal has been logged successfully.")
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
    }
    
    private func saveMealLog() {
        let newMealLog = MealLog(context: viewContext)
        newMealLog.id = UUID()
        newMealLog.mealName = mealName
        newMealLog.mealTypeTitle = selectedMealType.title
        newMealLog.mealTypeIcon = selectedMealType.icon
        newMealLog.weight = Double(mealWeight) ?? 0.0
        newMealLog.calories = Double(mealCalorie) ?? 0.0
        newMealLog.protein = Double(mealProtein) ?? 0.0
        newMealLog.dateLogged = mealDate
        
        // Save food memory if enabled and has nutrition info
        if shouldRememberFood && !mealName.isEmpty {
            let weight = Double(mealWeight) ?? 0.0
            let calories = Double(mealCalorie) ?? 0.0
            let protein = Double(mealProtein) ?? 0.0
            
            if weight > 0 || calories > 0 || protein > 0 {
                saveFoodMemory()
            }
        }
        
        do {
            try viewContext.save()
            showingSaveAlert = true
        } catch {
            print("Error saving meal log: \(error)")
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isKeyboardVisible = true
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isKeyboardVisible = false
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func checkForRememberedFood() {
        guard mealName.count >= 3 && !isApplyingFood else {
            showingFoodSuggestion = false
            rememberedFood = nil
            return
        }
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "FoodMemory")
        // More precise matching: either starts with the text or contains it as a word
        request.predicate = NSPredicate(format: "foodName BEGINSWITH[cd] %@ OR foodName CONTAINS[cd] %@", mealName, " " + mealName)
        request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            
            // Additional filtering for better matches
            let filteredResults = results.filter { food in
                guard let savedName = food.value(forKey: "foodName") as? String else { return false }
                let savedNameLower = savedName.lowercased()
                let inputLower = mealName.lowercased()
                
                // Match if:
                // 1. Saved name starts with input
                // 2. Input is a significant portion of saved name (at least 50%)
                return savedNameLower.hasPrefix(inputLower) || 
                       (savedNameLower.contains(inputLower) && inputLower.count >= savedName.count / 2)
            }
            
            if let food = filteredResults.first {
                rememberedFood = food
                showingFoodSuggestion = true
            } else {
                showingFoodSuggestion = false
                rememberedFood = nil
            }
        } catch {
            print("Error fetching food memory: \(error)")
            showingFoodSuggestion = false
            rememberedFood = nil
        }
    }
    
    private func applyRememberedFood(_ food: NSManagedObject) {
        let savedWeight = (food.value(forKey: "weight") as? Double) ?? 0
        let savedCalories = (food.value(forKey: "calories") as? Double) ?? 0
        let savedProtein = (food.value(forKey: "protein") as? Double) ?? 0
        let savedName = (food.value(forKey: "foodName") as? String) ?? ""
        
        // Set flag to prevent recursive food checking
        isApplyingFood = true
        
        // Fill in the food name
        mealName = savedName
        
        // Calculate per-gram ratios
        if savedWeight > 0 {
            caloriesPerGram = savedCalories / savedWeight
            proteinPerGram = savedProtein / savedWeight
            
            // Start with empty weight - user will enter their portion
            mealWeight = ""
            mealCalorie = ""
            mealProtein = ""
            
            // Enable food memory mode
            isUsingFoodMemory = true
        }
        
        // Hide suggestion and clear remembered food to prevent showing again
        showingFoodSuggestion = false
        rememberedFood = nil
        
        // Reset flag after a short delay to allow normal searching again
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isApplyingFood = false
        }
    }
    
    private func saveFoodMemory() {
        // Check if food memory already exists for this name
        let request = NSFetchRequest<NSManagedObject>(entityName: "FoodMemory")
        request.predicate = NSPredicate(format: "foodName ==[cd] %@", mealName)
        
        do {
            let existingMemories = try viewContext.fetch(request)
            
            // Update existing or create new
            let foodMemory = existingMemories.first ?? NSEntityDescription.insertNewObject(forEntityName: "FoodMemory", into: viewContext)
            
            foodMemory.setValue(foodMemory.value(forKey: "id") ?? UUID(), forKey: "id")
            foodMemory.setValue(mealName, forKey: "foodName")
            foodMemory.setValue(Double(mealWeight) ?? 0.0, forKey: "weight")
            foodMemory.setValue(Double(mealCalorie) ?? 0.0, forKey: "calories")
            foodMemory.setValue(Double(mealProtein) ?? 0.0, forKey: "protein")
            foodMemory.setValue(Date(), forKey: "dateCreated")
            
        } catch {
            print("Error saving food memory: \(error)")
        }
    }
    
    private func calculateNutritionFromWeight() {
        guard let weight = Double(mealWeight), weight > 0, isUsingFoodMemory else { return }
        
        let calculatedCalories = weight * caloriesPerGram
        let calculatedProtein = weight * proteinPerGram
        
        mealCalorie = calculatedCalories > 0 ? String(Int(calculatedCalories.rounded())) : ""
        mealProtein = calculatedProtein > 0 ? String(format: "%.1f", calculatedProtein) : ""
    }
    
    private func stopUsingFoodMemory() {
        isUsingFoodMemory = false
        caloriesPerGram = 0
        proteinPerGram = 0
    }
    
    static func defaultMealType() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<11:
            return MealType.types.first { $0.title == "Breakfast" } ?? MealType.types.first!
        case 11..<16:
            return MealType.types.first { $0.title == "Lunch" } ?? MealType.types.first!
        case 16..<22:
            return MealType.types.first { $0.title == "Dinner" } ?? MealType.types.first!
        default:
            return MealType.types.first { $0.title == "Snack" } ?? MealType.types.first!
        }
    }
}

#Preview {
    LogView()
}
