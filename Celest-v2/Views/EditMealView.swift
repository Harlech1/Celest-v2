import SwiftUI
import CoreData

struct EditMealView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let meal: MealLog
    
    @State private var selectedMealType: MealType
    @State private var mealName: String
    @State private var mealWeight: String
    @State private var mealCalorie: String
    @State private var mealProtein: String
    @State private var showingSaveAlert = false
    @State private var mealDate: Date
    @State private var shouldRememberFood = true
    
    init(meal: MealLog) {
        self.meal = meal
        
        // Initialize state from meal data
        let mealTypeTitle = meal.mealTypeTitle ?? "Breakfast"
        let matchingType = MealType.types.first { $0.title == mealTypeTitle } ?? MealType.types.first!
        _selectedMealType = State(initialValue: matchingType)
        _mealName = State(initialValue: meal.mealName ?? "")
        _mealWeight = State(initialValue: meal.weight > 0 ? String(Int(meal.weight)) : "")
        _mealCalorie = State(initialValue: meal.calories > 0 ? String(Int(meal.calories)) : "")
        _mealProtein = State(initialValue: meal.protein > 0 ? String(Int(meal.protein)) : "")
        _mealDate = State(initialValue: meal.dateLogged ?? Date())
    }
    
    private var weightBinding: Binding<String> {
        Binding(
            get: { mealWeight },
            set: { newValue in
                mealWeight = newValue
            }
        )
    }
    
    private var calorieBinding: Binding<String> {
        Binding(
            get: { mealCalorie },
            set: { newValue in
                mealCalorie = newValue
            }
        )
    }
    
    private var proteinBinding: Binding<String> {
        Binding(
            get: { mealProtein },
            set: { newValue in
                mealProtein = newValue
            }
        )
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Meal Info"), footer: Text("Update your meal details")) {
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
        .navigationTitle("Edit Meal")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            Button(action: updateMeal) {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                    Text("Update Meal")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding()
                .background(.blue)
                .cornerRadius(12)
            }
            .padding()
            .disabled(mealName.isEmpty)
        }
        .alert("Meal Updated!", isPresented: $showingSaveAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your meal has been updated successfully.")
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
    
    private func updateMeal() {
        meal.mealName = mealName
        meal.mealTypeTitle = selectedMealType.title
        meal.mealTypeIcon = selectedMealType.icon
        meal.weight = Double(mealWeight) ?? 0.0
        meal.calories = Double(mealCalorie) ?? 0.0
        meal.protein = Double(mealProtein) ?? 0.0
        meal.dateLogged = mealDate
        
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
            print("Error updating meal: \(error)")
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let sampleMeal = MealLog(context: context)
    sampleMeal.mealName = "Sample Meal"
    sampleMeal.mealTypeTitle = "Breakfast"
    sampleMeal.mealTypeIcon = "sunrise.fill"
    sampleMeal.weight = 150.0
    sampleMeal.calories = 300.0
    sampleMeal.protein = 25.0
    
    return NavigationStack {
        EditMealView(meal: sampleMeal)
            .environment(\.managedObjectContext, context)
    }
} 
