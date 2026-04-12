import SwiftUI
import WidgetKit

/// Simple status widget to satisfy WidgetKit extension requirements
struct EA24StatusWidget: Widget {
    let kind: String = "EA24StatusWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatusProvider()) { entry in
            StatusWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("EA-24 Status")
        .description("Shows EA-24 trading system status")
        .supportedFamilies([.systemSmall])
    }
}

struct StatusEntry: TimelineEntry {
    let date: Date
}

struct StatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatusEntry {
        StatusEntry(date: .now)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StatusEntry) -> Void) {
        completion(StatusEntry(date: .now))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StatusEntry>) -> Void) {
        let entry = StatusEntry(date: .now)
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(300)))
        completion(timeline)
    }
}

struct StatusWidgetView: View {
    var entry: StatusEntry
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundStyle(.cyan)
            Text("EA-24")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text("Trading")
                .font(.caption2)
                .foregroundStyle(.gray)
        }
    }
}
