import SwiftUI

// MARK: - Template Browser View

struct TemplateBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelectTemplate: (AircraftTemplate) -> Void
    
    @State private var selectedCategory: TemplateCategory = .cessna
    @State private var searchText = ""
    
    var filteredTemplates: [AircraftTemplate] {
        let templates = AircraftTemplateLibrary.templates(for: selectedCategory)
        
        if searchText.isEmpty {
            return templates
        }
        
        return templates.filter { template in
            template.manufacturer.localizedCaseInsensitiveContains(searchText) ||
            template.model.localizedCaseInsensitiveContains(searchText) ||
            template.variant.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondaryText)
                        
                        TextField("Search templates...", text: $searchText)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.primaryText)
                    }
                    .padding(12)
                    .background(Color.cardBackground)
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    // Category picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TemplateCategory.allCases) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedCategory = category
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 16)
                    
                    // Templates list
                    if filteredTemplates.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.secondaryText.opacity(0.5))
                            
                            Text("NO TEMPLATES YET")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondaryText)
                                .tracking(2)
                            
                            Text("Templates for this category\nare being added")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                            
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(filteredTemplates) { template in
                                    TemplateCard(template: template) {
                                        onSelectTemplate(template)
                                        dismiss()
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Aircraft Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentText)
                }
            }
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: TemplateCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : .secondaryText)
                .tracking(1)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentText : Color.cardBackground)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: AircraftTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.manufacturer.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondaryText)
                            .tracking(1)
                        
                        Text(template.model)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.primaryText)
                        
                        if !template.variant.isEmpty {
                            Text(template.variant)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.accentText)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondaryText)
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Info grid
                HStack(spacing: 20) {
                    TemplateInfoItem(
                        label: "ICAO",
                        value: template.icao
                    )
                    
                    TemplateInfoItem(
                        label: "FUEL",
                        value: template.fuelType.rawValue
                    )
                    
                    TemplateInfoItem(
                        label: "CAPACITY",
                        value: String(format: "%.0f GAL", template.totalCapacity)
                    )
                }
                
                // Tank configuration
                HStack(spacing: 8) {
                    ForEach(TankPosition.allCases, id: \.self) { position in
                        if let capacity = template.tankConfig[position] {
                            TankBadge(
                                position: position,
                                capacity: capacity
                            )
                        }
                    }
                }
                
                // Notes
                if let notes = template.notes {
                    Text(notes)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondaryText)
                        .padding(.top, 4)
                }
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Template Info Item

struct TemplateInfoItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(0.5)
            
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.primaryText)
        }
    }
}

// MARK: - Tank Badge

struct TankBadge: View {
    let position: TankPosition
    let capacity: Double
    
    var body: some View {
        VStack(spacing: 2) {
            Text(position.rawValue)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(.secondaryText)
            
            Text(String(format: "%.0f", capacity))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.accentText)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.appBackground)
        )
    }
}

// MARK: - Preview

#Preview {
    TemplateBrowserView { template in
        print("Selected: \(template.displayName)")
    }
}
