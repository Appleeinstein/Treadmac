import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var scrollData: [ScrollData]
    @State private var timeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    private func pixelsToMeters(_ pixels: Int) -> Double {
        return Double(pixels) / 1000.0
    }
    
    private var filteredData: [ScrollData] {
        let calendar = Calendar.current
        let now = Date()
        
        return scrollData.filter { data in
            switch timeRange {
            case .week:
                return calendar.isDate(data.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(data.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(data.date, equalTo: now, toGranularity: .year)
            }
        }.sorted { $0.date < $1.date }
    }
    
    private var averageScrollPerDay: Double {
        guard !filteredData.isEmpty else { return 0 }
        let total = filteredData.reduce(0) { $0 + $1.totalScrollPixels }
        return Double(total) / Double(filteredData.count)
    }
    
    private var mostActiveHour: (hour: Int, count: Int)? {
        // Combine hourly data from all filtered days
        var hourlyTotals: [Int: Int] = [:]
        
        for data in filteredData {
            if let hourlyData = data.hourlyScroll {
                for (hour, pixels) in hourlyData {
                    hourlyTotals[hour, default: 0] += pixels
                }
            }
        }
        
        // Find the hour with the highest total
        return hourlyTotals.max(by: { $0.value < $1.value })
            .map { (hour: $0.key, count: $0.value) }
    }
    
    private var hourlyData: [Int: Int] {
        var combinedData: [Int: Int] = [:]
        for data in filteredData {
            if let hourlyData = data.hourlyScroll {
                for (hour, pixels) in hourlyData {
                    combinedData[hour, default: 0] += pixels
                }
            }
        }
        return combinedData
    }
    
    private var maxHourlyValue: Int {
        hourlyData.values.max() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Time Range Picker
            Picker("Time Range", selection: $timeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 8)
            
            // Stats List
            VStack(alignment: .leading, spacing: 8) {
                StatRow(label: "Avg. Daily Scroll", value: "\(Int(averageScrollPerDay)) px (\(String(format: "%.1f", pixelsToMeters(Int(averageScrollPerDay)))) m)")
                if let activeHour = mostActiveHour {
                    StatRow(label: "Most Active Hour", value: "\(activeHour.hour):00 (\(activeHour.count) px)")
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
            
            // Heatmap
            if !hourlyData.isEmpty {
                HeatmapView(hourlyData: hourlyData, maxValue: maxHourlyValue)
            }
            
            // Scroll Trend Chart
            if !filteredData.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scroll Trend")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Chart {
                        ForEach(filteredData, id: \.date) { data in
                            BarMark(
                                x: .value("Date", data.date, unit: .day),
                                y: .value("Pixels", data.totalScrollPixels)
                            )
                            .foregroundStyle(Color.accentColor.gradient)
                        }
                    }
                    .frame(height: 100)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.weekday())
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.white.opacity(0.8))
                .font(.subheadline)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .font(.subheadline).monospacedDigit()
        }
    }
} 