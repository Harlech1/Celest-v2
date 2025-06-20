import SwiftUI
import CoreData

struct FoodDatabaseView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var savedFoods: [NSManagedObject] = []
    @State private var editingFood: NSManagedObject?
    @State private var refreshTrigger = false
    
    var body: some View {
        Group {
            if savedFoods.isEmpty {
                ContentUnavailableView(
                    "No Foods Saved",
                    systemImage: "brain.head.profile",
                    description: Text("Save foods while logging meals to build your personal nutrition database")
                )
            } else {
                Form {
                    Section(header: Text("Saved Foods"), footer: Text("\(savedFoods.count) food\(savedFoods.count == 1 ? "" : "s") in your database")) {
                        ForEach(savedFoods, id: \.objectID) { food in
                            FoodRowView(food: food) {
                                editingFood = food
                            }
                            .contextMenu {
                                Button {
                                    editingFood = food
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    deleteFood(food)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Food Database")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            fetchSavedFoods()
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            fetchSavedFoods()
        }
        .sheet(item: Binding<FoodWrapper?>(
            get: { editingFood.map(FoodWrapper.init) },
            set: { _ in editingFood = nil }
        )) { wrapper in
            NavigationStack {
                EditFoodView(food: wrapper.food)
            }
        }
    }
    
    private func fetchSavedFoods() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "FoodMemory")
        request.sortDescriptors = [
            NSSortDescriptor(key: "dateCreated", ascending: false)
        ]
        
        do {
            savedFoods = try viewContext.fetch(request)
        } catch {
            print("Error fetching saved foods: \(error)")
            savedFoods = []
        }
    }
    
    private func deleteFood(_ food: NSManagedObject) {
        withAnimation {
            viewContext.delete(food)
            
            do {
                try viewContext.save()
                fetchSavedFoods()
            } catch {
                print("Error deleting food: \(error)")
            }
        }
    }
}

struct FoodRowView: View {
    let food: NSManagedObject
    let onEdit: () -> Void
    
    private var foodName: String {
        (food.value(forKey: "foodName") as? String) ?? "Unknown Food"
    }
    
    private var weight: Double {
        (food.value(forKey: "weight") as? Double) ?? 0
    }
    
    private var calories: Double {
        (food.value(forKey: "calories") as? Double) ?? 0
    }
    
    private var protein: Double {
        (food.value(forKey: "protein") as? Double) ?? 0
    }
    
    private var caloriesPerGram: Double {
        weight > 0 ? calories / weight : 0
    }
    
    private var proteinPerGram: Double {
        weight > 0 ? protein / weight : 0
    }
    
    private var dateCreated: Date {
        (food.value(forKey: "dateCreated") as? Date) ?? Date()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(foodName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text(dateCreated, style: .date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Nutrition ratios only
            HStack(spacing: 16) {
                if caloriesPerGram > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.red)
                        Text(String(format: "%.1f kcal/g", caloriesPerGram))
                            .font(.caption)
                            .fontWeight(.medium)
                            .fontDesign(.monospaced)
                            .foregroundStyle(.red)
                    }
                }
                
                if proteinPerGram > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        Text(String(format: "%.2f g/g", proteinPerGram))
                            .font(.caption)
                            .fontWeight(.medium)
                            .fontDesign(.monospaced)
                            .foregroundStyle(.orange)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

struct EditFoodView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let food: NSManagedObject
    
    @State private var foodName = ""
    @State private var weight = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var showingSaveAlert = false
    
    private var weightBinding: Binding<String> {
        Binding(
            get: { weight },
            set: { newValue in
                weight = newValue
            }
        )
    }
    
    private var calorieBinding: Binding<String> {
        Binding(
            get: { calories },
            set: { newValue in
                calories = newValue
            }
        )
    }
    
    private var proteinBinding: Binding<String> {
        Binding(
            get: { protein },
            set: { newValue in
                protein = newValue
            }
        )
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Food Info"), footer: Text("Update the nutrition information for this saved food.")) {
                    HStack {
                        Image(systemName: "pencil")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.secondary)
                        TextField("Food Name", text: $foodName)
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
            }
        }
        .navigationTitle("Edit Food")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFoodData()
        }
        .overlay(alignment: .bottom) {
            Button(action: updateFood) {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                    Text("Update Food")
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
            .disabled(foodName.isEmpty)
        }
        .alert("Food Updated!", isPresented: $showingSaveAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your food has been updated successfully.")
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
    
    private func loadFoodData() {
        foodName = (food.value(forKey: "foodName") as? String) ?? ""
        let weightValue = (food.value(forKey: "weight") as? Double) ?? 0
        let caloriesValue = (food.value(forKey: "calories") as? Double) ?? 0
        let proteinValue = (food.value(forKey: "protein") as? Double) ?? 0
        
        weight = weightValue > 0 ? String(Int(weightValue)) : ""
        calories = caloriesValue > 0 ? String(Int(caloriesValue)) : ""
        protein = proteinValue > 0 ? String(format: "%.1f", proteinValue) : ""
    }
    
    private func updateFood() {
        food.setValue(foodName, forKey: "foodName")
        food.setValue(Double(weight) ?? 0.0, forKey: "weight")
        food.setValue(Double(calories) ?? 0.0, forKey: "calories")
        food.setValue(Double(protein) ?? 0.0, forKey: "protein")
        food.setValue(Date(), forKey: "dateCreated")
        
        do {
            try viewContext.save()
            showingSaveAlert = true
        } catch {
            print("Error updating food: \(error)")
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Helper wrapper for Identifiable conformance
struct FoodWrapper: Identifiable {
    let id = UUID()
    let food: NSManagedObject
}

#Preview {
    FoodDatabaseView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}