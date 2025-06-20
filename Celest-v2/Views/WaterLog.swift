import SwiftUI
import CoreData

struct WaterLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedDate = Date()
    @State private var refreshTrigger = false
    @State private var dropScale: CGFloat = 1.0
    @State private var editWater: WaterLog?
    
    private var waterEntriesForSelectedDate: [WaterLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<WaterLog> = WaterLog.fetchRequest()
        request.predicate = NSPredicate(format: "dateLogged >= %@ AND dateLogged < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WaterLog.dateLogged, ascending: true)]
        
        do {
            _ = refreshTrigger
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching water entries: \(error)")
            return []
        }
    }
    
    private var totalWaterInML: Double {
        waterEntriesForSelectedDate.reduce(0) { total, entry in
            let amount = entry.amount
            let unit = entry.unit ?? defaultUnit
            
            if unit == "oz" {
                return total + (amount * 29.5735)
            } else {
                return total + amount
            }
        }
    }
    
    private var defaultUnit: String {
        Locale.current.region?.identifier == "US" ? "oz" : "ml"
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
                        
                        if !waterEntriesForSelectedDate.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "drop.fill")
                                    .font(.callout)
                                    .foregroundStyle(.blue)
                                    .scaleEffect(dropScale)
                                
                                Text("\(Int(totalWaterInML)) ml")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .fontDesign(.monospaced)
                                    .foregroundStyle(.blue)
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
                
                // Water Content
                ScrollView {
                    LazyVStack(spacing: 20) {
                        if waterEntriesForSelectedDate.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "drop.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundStyle(.secondary)
                                    .opacity(0.6)
                                
                                Text("No water logged")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                
                                Text("Start tracking your hydration by logging your first drink of the day")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.top, 80)
                        } else {
                            ForEach(waterEntriesForSelectedDate, id: \.objectID) { entry in
                                WaterEntryRowView(entry: entry)
                                    .padding(.horizontal, 16)
                                    .contextMenu {
                                        Button {
                                            editWater = entry
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            deleteWaterEntry(entry)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
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
                startDropAnimation()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                refreshData()
            }
            .sheet(item: $editWater) { entry in
                NavigationStack {
                    EditWaterView(waterEntry: entry)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack {
                        Image(systemName: "drop.fill")
                        Text("Hydration")
                            .font(.nostalgic(size: 24))
                            .foregroundStyle(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddWaterView()) {
                        Image(systemName: "drop.circle.fill")
                            .font(.title2)
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
    
    private func refreshData() {
        refreshTrigger.toggle()
    }
    
    private func startDropAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                dropScale = dropScale == 1.0 ? 1.2 : 1.0
            }
        }
    }
    
    private func deleteWaterEntry(_ entry: WaterLog) {
        withAnimation {
            viewContext.delete(entry)
            
            do {
                try viewContext.save()
                refreshData()
            } catch {
                print("Error deleting water entry: \(error)")
            }
        }
    }
}

struct WaterEntryRowView: View {
    let entry: WaterLog
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(entry.amount)) \(entry.unit ?? "ml")")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "drop")
                            .font(.caption2)
                        Text("Hydration")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.dateLogged ?? Date(), style: .time)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("logged")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct AddWaterView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var waterDate = Date()
    @State private var showingSaveAlert = false
    
    private var defaultUnit: String {
        Locale.current.region?.identifier == "US" ? "oz" : "ml"
    }
    
    private var amountBinding: Binding<String> {
        Binding(
            get: { amount },
            set: { newValue in
                amount = newValue
            }
        )
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Water Info"), footer: Text("Log your water intake with amount in \(defaultUnit) and time.")) {
                    LabeledContent("Date & Time") {
                        DatePicker("", selection: $waterDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }
                    
                    HStack {
                        Image(systemName: "drop")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.secondary)
                        Text("Amount")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("0", text: amountBinding)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(defaultUnit)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Log Water")
        .overlay(alignment: .bottom) {
            Button(action: saveWaterLog) {
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
                .background(.blue)
                .cornerRadius(12)
            }
            .padding()
            .disabled(amount.isEmpty)
        }
        .alert("Water Logged!", isPresented: $showingSaveAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your water intake has been logged successfully.")
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
    
    private func saveWaterLog() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        let entry = WaterLog(context: viewContext)
        entry.id = UUID()
        entry.amount = amountValue
        entry.unit = defaultUnit
        entry.dateLogged = waterDate
        
        do {
            try viewContext.save()
            showingSaveAlert = true
        } catch {
            print("Error saving water entry: \(error)")
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct EditWaterView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let waterEntry: WaterLog
    @State private var amount = ""
    @State private var waterDate = Date()
    @State private var showingSaveAlert = false
    
    private var defaultUnit: String {
        Locale.current.region?.identifier == "US" ? "oz" : "ml"
    }
    
    private var amountBinding: Binding<String> {
        Binding(
            get: { amount },
            set: { newValue in
                amount = newValue
            }
        )
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Water Info"), footer: Text("Edit your water intake with amount in \(defaultUnit) and time.")) {
                    LabeledContent("Date & Time") {
                        DatePicker("", selection: $waterDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }
                    
                    HStack {
                        Image(systemName: "drop")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.secondary)
                        Text("Amount")
                            .foregroundStyle(.secondary)
                        Spacer()
                        TextField("0", text: amountBinding)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(defaultUnit)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Edit Water")
        .onAppear {
            amount = String(Int(waterEntry.amount))
            waterDate = waterEntry.dateLogged ?? Date()
        }
        .overlay(alignment: .bottom) {
            Button(action: updateWaterLog) {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save Changes")
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
            .disabled(amount.isEmpty)
        }
        .alert("Water Updated!", isPresented: $showingSaveAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your water intake has been updated successfully.")
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
    
    private func updateWaterLog() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        
        waterEntry.amount = amountValue
        waterEntry.unit = defaultUnit
        waterEntry.dateLogged = waterDate
        
        do {
            try viewContext.save()
            showingSaveAlert = true
        } catch {
            print("Error updating water entry: \(error)")
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    WaterLogView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
