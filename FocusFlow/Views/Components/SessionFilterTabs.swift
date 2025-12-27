import SwiftUI

enum SessionFilter: String, CaseIterable {
    case all = "All"
    case work = "Work"
    case breakTime = "Break"

    var filterType: String? {
        switch self {
        case .all: return nil
        case .work: return "work"
        case .breakTime: return "break"
        }
    }
}

struct SessionFilterTabs: View {
    @Binding var selectedFilter: SessionFilter

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SessionFilter.allCases, id: \.self) { filter in
                Button(action: { selectedFilter = filter }) {
                    Text(filter.rawValue)
                        .font(.subheadline.weight(.medium))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(selectedFilter == filter ? Color.blue : Color(UIColor.systemGray6))
                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                        .cornerRadius(20)
                }
            }
        }
    }
}

struct SessionFilterTabs_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State var sel: SessionFilter = .all
        var body: some View { SessionFilterTabs(selectedFilter: $sel) }
    }
    static var previews: some View {
        PreviewWrapper()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
