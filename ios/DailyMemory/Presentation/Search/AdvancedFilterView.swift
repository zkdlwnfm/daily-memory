import SwiftUI

struct AdvancedFilter: Equatable {
    var startDate: Date?
    var endDate: Date?
    var categories: Set<Category> = []
    var personIds: Set<String> = []
    var minAmount: Double?
    var maxAmount: Double?
    var hasPhotos: Bool?
    var isLocked: Bool?

    var isActive: Bool {
        startDate != nil || endDate != nil ||
        !categories.isEmpty || !personIds.isEmpty ||
        minAmount != nil || maxAmount != nil ||
        hasPhotos != nil || isLocked != nil
    }

    var activeCount: Int {
        var count = 0
        if startDate != nil || endDate != nil { count += 1 }
        if !categories.isEmpty { count += 1 }
        if !personIds.isEmpty { count += 1 }
        if minAmount != nil || maxAmount != nil { count += 1 }
        if hasPhotos != nil { count += 1 }
        if isLocked != nil { count += 1 }
        return count
    }

    mutating func clear() {
        startDate = nil
        endDate = nil
        categories = []
        personIds = []
        minAmount = nil
        maxAmount = nil
        hasPhotos = nil
        isLocked = nil
    }
}

struct AdvancedFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filter: AdvancedFilter
    let availablePersons: [Person]
    let onApply: () -> Void

    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    @State private var minAmountText = ""
    @State private var maxAmountText = ""

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Date Range
                    filterSection(title: "Date Range") {
                        HStack(spacing: 12) {
                            dateButton(
                                label: "From",
                                date: filter.startDate,
                                showPicker: $showStartDatePicker,
                                onClear: { filter.startDate = nil }
                            )

                            dateButton(
                                label: "To",
                                date: filter.endDate,
                                showPicker: $showEndDatePicker,
                                onClear: { filter.endDate = nil }
                            )
                        }
                    }

                    // Categories
                    filterSection(title: "Categories") {
                        FlowLayout(spacing: 8) {
                            ForEach(Category.allCases, id: \.self) { category in
                                FilterChipView(
                                    label: category.displayName,
                                    isSelected: filter.categories.contains(category),
                                    onTap: {
                                        if filter.categories.contains(category) {
                                            filter.categories.remove(category)
                                        } else {
                                            filter.categories.insert(category)
                                        }
                                    }
                                )
                            }
                        }
                    }

                    // People
                    if !availablePersons.isEmpty {
                        filterSection(title: "People") {
                            FlowLayout(spacing: 8) {
                                ForEach(availablePersons) { person in
                                    FilterChipView(
                                        label: person.name,
                                        icon: "person",
                                        isSelected: filter.personIds.contains(person.id),
                                        onTap: {
                                            if filter.personIds.contains(person.id) {
                                                filter.personIds.remove(person.id)
                                            } else {
                                                filter.personIds.insert(person.id)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }

                    // Amount Range
                    filterSection(title: "Amount Range") {
                        HStack(spacing: 12) {
                            TextField("Min $", text: $minAmountText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: minAmountText) { newValue in
                                    filter.minAmount = Double(newValue)
                                }

                            TextField("Max $", text: $maxAmountText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: maxAmountText) { newValue in
                                    filter.maxAmount = Double(newValue)
                                }
                        }
                    }

                    // Additional Filters
                    filterSection(title: "Additional") {
                        HStack(spacing: 8) {
                            FilterChipView(
                                label: "Has Photos",
                                icon: "photo",
                                isSelected: filter.hasPhotos == true,
                                onTap: {
                                    filter.hasPhotos = filter.hasPhotos == true ? nil : true
                                }
                            )

                            FilterChipView(
                                label: "Locked",
                                icon: "lock",
                                isSelected: filter.isLocked == true,
                                onTap: {
                                    filter.isLocked = filter.isLocked == true ? nil : true
                                }
                            )
                        }
                    }

                    Spacer(minLength: 32)
                }
                .padding()
            }
            .navigationTitle("Advanced Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if filter.isActive {
                        Button("Clear All") {
                            filter.clear()
                            minAmountText = ""
                            maxAmountText = ""
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onApply()
                        dismiss()
                    }
                }
            }
            .onAppear {
                minAmountText = filter.minAmount.map { String($0) } ?? ""
                maxAmountText = filter.maxAmount.map { String($0) } ?? ""
            }
            .sheet(isPresented: $showStartDatePicker) {
                DatePickerSheet(
                    title: "Start Date",
                    date: Binding(
                        get: { filter.startDate ?? Date() },
                        set: { filter.startDate = $0 }
                    ),
                    onDone: { showStartDatePicker = false }
                )
            }
            .sheet(isPresented: $showEndDatePicker) {
                DatePickerSheet(
                    title: "End Date",
                    date: Binding(
                        get: { filter.endDate ?? Date() },
                        set: { filter.endDate = $0 }
                    ),
                    onDone: { showEndDatePicker = false }
                )
            }
        }
        .presentationDetents([.large])
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            content()
        }
    }

    private func dateButton(
        label: String,
        date: Date?,
        showPicker: Binding<Bool>,
        onClear: @escaping () -> Void
    ) -> some View {
        Button {
            showPicker.wrappedValue = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(date.map { dateFormatter.string(from: $0) } ?? "Select")
                        .font(.subheadline)
                        .fontWeight(date != nil ? .medium : .regular)
                        .foregroundColor(date != nil ? .primary : .secondary)
                }

                Spacer()

                if date != nil {
                    Button {
                        onClear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(date != nil ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct FilterChipView: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }

                Text(label)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

struct DatePickerSheet: View {
    let title: String
    @Binding var date: Date
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            DatePicker(
                title,
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            height = y + rowHeight
        }
    }
}

#Preview {
    AdvancedFilterSheet(
        filter: .constant(AdvancedFilter()),
        availablePersons: [],
        onApply: {}
    )
}
