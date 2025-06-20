import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var refreshTrigger = false
    @State private var flameScale: CGFloat = 1.0
    @State private var editMeal: MealLog?

    private var mealsForSelectedDate: [MealLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<MealLog> = MealLog.fetchRequest()
        request.predicate = NSPredicate(format: "dateLogged >= %@ AND dateLogged < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MealLog.dateLogged, ascending: true)]

        do {
            _ = refreshTrigger
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching meals: \(error)")
            return []
        }
    }

    private var totalCalories: Double {
        mealsForSelectedDate.reduce(0) { $0 + $1.calories }
    }
    
    private var totalProtein: Double {
        mealsForSelectedDate.reduce(0) { $0 + $1.protein }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date Navigation Header
                HStack(spacing: 20) {
                    Button(action: previousDay) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title)
                            .foregroundStyle(.blue, .blue.opacity(0.2))
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Text(selectedDate, style: .date)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(dayDescription)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)

                        if !mealsForSelectedDate.isEmpty {
                            VStack(spacing: 2) {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill")
                                        .font(.callout)
                                        .foregroundStyle(.red)
                                        .scaleEffect(flameScale)

                                    Text("\(Int(totalCalories)) kcal")
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                        .fontDesign(.monospaced)
                                        .foregroundStyle(.red)
                                }
                                
                                if totalProtein > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "figure.strengthtraining.traditional")
                                            .font(.callout)
                                            .foregroundStyle(.orange)

                                        Text("\(Int(totalProtein))g protein")
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                            .fontDesign(.monospaced)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                        }
                    }

                    Spacer()
                    
                    Button(action: nextDay) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title)
                            .foregroundStyle(canGoToNextDay ? .blue : .gray, canGoToNextDay ? .blue.opacity(0.2) : .gray.opacity(0.2))
                    }
                    .disabled(!canGoToNextDay)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.thinMaterial)

                // Meals Content
                ScrollView {
                    LazyVStack(spacing: 20) {
                        if mealsForSelectedDate.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "fork.knife.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundStyle(.secondary)
                                    .opacity(0.6)

                                Text("No meals logged")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)

                                Text("Start tracking your nutrition by logging your first meal of the day")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.top, 80)
                        } else {
                            // Meals grouped by type
                            ForEach(groupMealsByType(mealsForSelectedDate), id: \.key) { typeGroup in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Meal Type Header
                                    HStack {
                                        Image(systemName: typeGroup.key.icon)
                                            .font(.title3)
                                            .foregroundStyle(.blue)
                                        Text(typeGroup.key.title)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Text("\(typeGroup.value.count) meal\(typeGroup.value.count == 1 ? "" : "s")")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)
                                            .textCase(.uppercase)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 8)

                                    // Individual meals of this type
                                    ForEach(typeGroup.value, id: \.objectID) { meal in
                                        MealRowView(meal: meal)
                                            .padding(.horizontal, 16)
                                            .contextMenu {
                                                Button {
                                                    editMeal = meal
                                                } label: {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                
                                                Button(role: .destructive) {
                                                    deleteMeal(meal)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                    .padding(.bottom, 8)
                                }
                                .padding(.vertical, 8)
                                .background(.regularMaterial)
                                .cornerRadius(16)
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                refreshData()
                startFlameAnimation()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                refreshData()
            }
            .sheet(item: $editMeal) { meal in
                NavigationStack {
                    EditMealView(meal: meal)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack {
                        Image(systemName: "laser.burst")
                        Text("Celest")
                            .font(.nostalgic(size: 24))
                            .foregroundStyle(.primary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: FoodDatabaseView()) {
                            Image(systemName: "brain.head.profile")
                                .font(.title2)
                        }
                        
                        NavigationLink(destination: LogView()) {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
        }
    }

    private var dayDescription: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: selectedDate)
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = "Türker"

        switch hour {
        case 5..<12:
            return "Good Morning, \(name)"
        case 12..<17:
            return "Good Afternoon, \(name)"
        case 17..<21:
            return "Good Evening, \(name)"
        default:
            return "Good Night, \(name)"
        }
    }

    private var canGoToNextDay: Bool {
        !Calendar.current.isDateInToday(selectedDate)
    }

    private func previousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }

    private func nextDay() {
        guard canGoToNextDay else { return }
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }

    private func groupMealsByType(_ meals: [MealLog]) -> [(key: MealTypeInfo, value: [MealLog])] {
        let grouped = Dictionary(grouping: meals) { meal in
            MealTypeInfo(title: meal.mealTypeTitle ?? "Unknown", icon: meal.mealTypeIcon ?? "questionmark")
        }
        return grouped.sorted { $0.key.title < $1.key.title }
    }

    private func refreshData() {
        refreshTrigger.toggle()
    }

    private func startFlameAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                flameScale = flameScale == 1.0 ? 1.2 : 1.0
            }
        }
    }

    private func deleteMeal(_ meal: MealLog) {
        withAnimation {
            viewContext.delete(meal)
            
            do {
                try viewContext.save()
                refreshData()
            } catch {
                print("Error deleting meal: \(error)")
            }
        }
    }
}

struct MealTypeInfo: Hashable {
    let title: String
    let icon: String
}

struct MealRowView: View {
    let meal: MealLog

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(meal.mealName ?? "Unknown Meal")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(meal.dateLogged ?? Date(), style: .time)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }

                HStack(spacing: 12) {
                    if meal.weight > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "scalemass")
                                .font(.caption2)
                            Text("\(Int(meal.weight))g")
                                .font(.caption)
                                .fontWeight(.medium)
                                .fontDesign(.monospaced)
                        }
                        .foregroundStyle(.secondary)
                    }

                    if meal.weight > 0 && (meal.calories > 0 || meal.protein > 0) {
                        Circle()
                            .fill(.secondary)
                            .frame(width: 3, height: 3)
                    }

                    if meal.calories > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame")
                                .font(.caption2)
                            Text("\(Int(meal.calories))kcal")
                                .font(.caption)
                                .fontWeight(.medium)
                                .fontDesign(.monospaced)
                        }
                        .foregroundStyle(.red)
                    }
                    
                    if meal.calories > 0 && meal.protein > 0 {
                        Circle()
                            .fill(.secondary)
                            .frame(width: 3, height: 3)
                    }
                    
                    if meal.protein > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.caption2)
                            Text("\(Int(meal.protein))g")
                                .font(.caption)
                                .fontWeight(.medium)
                                .fontDesign(.monospaced)
                        }
                        .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
