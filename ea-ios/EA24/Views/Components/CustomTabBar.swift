import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    private let blue = Color(red: 0.18, green: 0.32, blue: 0.92)
    private let gray = Color.gray.opacity(0.52)

    private let tabs: [(sf: String, sfFilled: String, label: String)] = [
        ("house",     "house.fill",    "Home"),
        ("chart.xyaxis.line", "chart.xyaxis.line", "Trades"),
        ("cpu",       "cpu",           "Pipeline"),
        ("icloud.and.arrow.up", "icloud.and.arrow.up.fill", "Upload"),
        ("gearshape", "gearshape.fill","Settings"),
    ]

    var body: some View {
        HStack(alignment: .center) {
            ForEach(tabs.indices, id: \.self) { i in
                let active = selectedTab == i
                Button { selectedTab = i } label: {
                    VStack(spacing: 5) {
                        Image(systemName: active ? tabs[i].sfFilled : tabs[i].sf)
                            .font(.system(size: 22, weight: active ? .semibold : .regular, design: .rounded))
                            .foregroundStyle(active ? blue : gray)
                        Text(tabs[i].label)
                            .font(.system(size: 10, weight: active ? .bold : .medium, design: .rounded))
                            .foregroundStyle(active ? blue : gray)
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, max((UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0), 8))
        .background(
            Color.white
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: -3)
        )
    }
}
