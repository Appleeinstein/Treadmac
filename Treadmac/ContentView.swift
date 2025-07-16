import SwiftUI
import SwiftData
import AppKit
import Charts

struct ContentView: View {
    @Query private var scrollData: [ScrollData]
    @State private var selectedTab: Int = 0
    @State private var appListRange: AppListRange = .today
    @Namespace private var animation
    
    enum AppListRange: String, CaseIterable {
        case today = "Today"
        case week = "Past 7 Days"
        case all = "All Time"
    }
    
    private func pixelsToMeters(_ pixels: Int) -> Double {
        Double(pixels) / 1000.0
    }
    
    private var todayData: ScrollData? {
        scrollData.first(where: { Calendar.current.isDateInToday($0.date) })
    }
    
    private var allTimeData: ScrollData? {
        let allTimePixels = scrollData.reduce(0) { $0 + $1.totalScrollPixels }
        var allTimePerApp: [String: Int] = [:]
        for data in scrollData {
            for (app, pixels) in data.perAppScroll {
                allTimePerApp[app, default: 0] += pixels
            }
        }
        return ScrollData(date: Date(), totalScrollPixels: allTimePixels, perAppScroll: allTimePerApp)
    }
    
    private var weekData: [ScrollData] {
        let calendar = Calendar.current
        let now = Date()
        return scrollData.filter { data in
            calendar.isDate(data.date, equalTo: now, toGranularity: .weekOfYear)
        }
    }
    
    private var appListFilteredApps: [(String, Int)] {
        switch appListRange {
        case .today:
            guard let data = todayData else { return [] }
            return data.perAppScroll.filter { $0.value > 0 }.sorted { $0.value > $1.value }
        case .week:
            var appTotals: [String: Int] = [:]
            for d in weekData {
                for (app, px) in d.perAppScroll {
                    appTotals[app, default: 0] += px
                }
            }
            return appTotals.filter { $0.value > 0 }.sorted { $0.value > $1.value }
        case .all:
            guard let data = allTimeData else { return [] }
            return data.perAppScroll.filter { $0.value > 0 }.sorted { $0.value > $1.value }
        }
    }
    
    // For stats dashboard (Tab 2)
    private var filteredData: [ScrollData] {
        let calendar = Calendar.current
        let now = Date()
        switch appListRange {
        case .today:
            return scrollData.filter { Calendar.current.isDateInToday($0.date) }
        case .week:
            return scrollData.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear) }
        case .all:
            return scrollData
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.85), Color.accentColor.opacity(0.15)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        VStack(spacing: 0) {
                HeaderView(todayData: todayData, allTimeData: allTimeData)
                    .padding(.top, 12)
                
                // Segmented control for Today / Past 7 Days / All Time (Persistent)
                HStack(spacing: 12) {
                    ForEach(AppListRange.allCases, id: \ .self) { range in
                        Button(action: { appListRange = range }) {
                            Text(range.rawValue)
                                .font(.subheadline)
                                .fontWeight(appListRange == range ? .bold : .regular)
                                .foregroundColor(appListRange == range ? .accentColor : .white.opacity(0.7))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(appListRange == range ? Color.accentColor.opacity(0.15) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Tab Bar
                HStack(spacing: 0) {
                    TabButton(title: "App Activity", isSelected: selectedTab == 0, namespace: animation) {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = 0 }
                    }
                    TabButton(title: "Stats", isSelected: selectedTab == 1, namespace: animation) {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = 1 }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Tab Content
                if selectedTab == 0 {
                    // App Activity Tab
                    ScrollView(showsIndicators: false) {
                        AppListView(apps: appListFilteredApps, pixelsToMeters: pixelsToMeters)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                    }
                } else {
                    // Stats Tab
                    StatsDashboardView(
                        todayData: todayData,
                        allTimeData: allTimeData,
                        filteredData: filteredData,
                        range: appListRange
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .id(appListRange)
                }
                FooterView()
                    .padding(.top, 8)
            }
            .frame(maxWidth: 420)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .background(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 8)
            )
            .padding(.vertical, 16)
        }
        .animation(nil, value: selectedTab)
        .animation(nil, value: appListRange)
    }
}

// Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .background(
                    Group {
                        if isSelected {
                            Color.white.opacity(0.1)
                                .matchedGeometryEffect(id: "tab_background_\(title)", in: namespace)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

// Stats Dashboard View (for Tab 2)
struct StatsDashboardView: View {
    let todayData: ScrollData?
    let allTimeData: ScrollData?
    let filteredData: [ScrollData]
    let range: ContentView.AppListRange
    
    private func pixelsToMeters(_ px: Int) -> Double { Double(px) / 1000.0 }
    private var avgScroll: Int {
        guard !filteredData.isEmpty else { return 0 }
        let total = filteredData.reduce(0) { $0 + $1.totalScrollPixels }
        return total / filteredData.count
    }
    private var mostActiveApp: String? {
        var appTotals: [String: Int] = [:]
        for d in filteredData {
            for (app, px) in d.perAppScroll {
                appTotals[app, default: 0] += px
            }
        }
        return appTotals.max(by: { $0.value < $1.value })?.key
    }
    private func combineHourlyData(_ data: [ScrollData]) -> [Int: Int] {
        var combined: [Int: Int] = [:]
        for d in data {
            if let hourly = d.hourlyScroll {
                for (hour, px) in hourly {
                    combined[hour, default: 0] += px
                }
            }
        }
        return combined
    }
    private func maxHourlyValue(_ data: [ScrollData]) -> Int {
        combineHourlyData(data).values.max() ?? 0
    }
    var body: some View {
        VStack(spacing: 20) {
            StatsGridView(todayData: todayData, allTimeData: allTimeData, filteredData: filteredData, range: .week) // Always show week for grid
            TrendChartView(filteredData: filteredData)
            HeatmapView(hourlyData: combineHourlyData(filteredData), maxValue: maxHourlyValue(filteredData))
        }
    }
}

// MARK: - Header
struct HeaderView: View {
    let todayData: ScrollData?
    let allTimeData: ScrollData?
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.accentColor)
                .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 2)
            VStack(alignment: .leading, spacing: 2) {
                Text("TreadMac Dashboard")
                    .font(.title2).fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Track your scrolling journey")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            // Removed settings button
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }
}

// MARK: - Stats Grid
struct StatsGridView: View {
    let todayData: ScrollData?
    let allTimeData: ScrollData?
    let filteredData: [ScrollData]
    let range: ContentView.AppListRange
    
    private func pixelsToMeters(_ px: Int) -> Double { Double(px) / 1000.0 }
    private var avgScroll: Int {
        guard !filteredData.isEmpty else { return 0 }
        let total = filteredData.reduce(0) { $0 + $1.totalScrollPixels }
        return total / filteredData.count
    }
    private var mostActiveApp: String? {
        var appTotals: [String: Int] = [:]
        for d in filteredData {
            for (app, px) in d.perAppScroll {
                appTotals[app, default: 0] += px
            }
        }
        return appTotals.max(by: { $0.value < $1.value })?.key
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatRow(label: "Today", value: "\(todayData?.totalScrollPixels ?? 0) px (\(String(format: "%.1f", pixelsToMeters(todayData?.totalScrollPixels ?? 0))) m)")
            StatRow(label: "All Time", value: "\(allTimeData?.totalScrollPixels ?? 0) px (\(String(format: "%.1f", pixelsToMeters(allTimeData?.totalScrollPixels ?? 0))) m)")
            StatRow(label: "Avg/Day", value: "\(avgScroll) px (\(String(format: "%.1f", pixelsToMeters(avgScroll))) m)")
            StatRow(label: "Top App", value: mostActiveApp ?? "-")
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Trend Chart
struct TrendChartView: View {
    let filteredData: [ScrollData]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scroll Trend")
                .font(.headline)
                .foregroundColor(.white)
            if #available(macOS 13.0, *) {
                VStack(spacing: 0) {
                    Chart {
                        ForEach(filteredData, id: \ .date) { data in
                            LineMark(
                                x: .value("Date", data.date),
                                y: .value("Pixels", data.totalScrollPixels)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(Color.accentColor.gradient)
                        }
                    }
                    .frame(height: 100)
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { label in
                                Text(label)
                                    .foregroundColor(.white)
                                    .font(.caption2)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(width: geo.size.width * 0.92, alignment: .leading)
                        .padding(.top, 2)
                    }
                    .frame(height: 16)
                }
            } else {
                Text("Charts require macOS 13+")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

// MARK: - App List
struct AppListView: View {
    let apps: [(String, Int)]
    let pixelsToMeters: (Int) -> Double
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("App Breakdown")
                .font(.headline)
                .foregroundColor(.white)
            if apps.isEmpty {
                Text("No app scroll activity yet.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(apps, id: \ .0) { app, pixels in
                    AppRow(app: app, pixels: pixels, meters: pixelsToMeters(pixels))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

struct AppRow: View {
    let app: String
    let pixels: Int
    let meters: Double
    
    // Helper to find .app bundle path by name
    private func appBundlePath(for appName: String) -> String? {
        let fm = FileManager.default
        let searchPaths = ["/Applications", "/System/Applications"]
        for dir in searchPaths {
            if let contents = try? fm.contentsOfDirectory(atPath: dir) {
                if let match = contents.first(where: { $0.hasSuffix(".app") && $0.dropLast(4) == appName }) {
                    return dir + "/" + match
                }
            }
        }
        return nil
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Try running app icon first
            if let appURL = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == app })?.bundleURL {
                Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                    .resizable()
                    .frame(width: 20, height: 20)
                    .cornerRadius(5)
            } else if let bundlePath = appBundlePath(for: app) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: bundlePath))
                    .resizable()
                    .frame(width: 20, height: 20)
                    .cornerRadius(5)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.white)
            }
            Text(app)
                .foregroundColor(.white)
                .font(.body)
                .lineLimit(1)
                .help(app)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(pixels.formatted()) px")
                    .foregroundColor(.white)
                    .font(.callout)
                    .monospacedDigit()
                Text("(\(String(format: "%.0f", meters)) m)")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.caption)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - Footer
struct FooterView: View {
    var body: some View {
        HStack {
            Text("TreadMac v1.0")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
            Spacer()
            Text("Made with ❤️ by Harsh")
                .font(.caption2)
                .foregroundColor(.accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}



