import SwiftUI

struct HeatmapView: View {
    let hourlyData: [Int: Int]
    let maxValue: Int
    
    private let hours = Array(0...23)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 6)
    
    private func colorForValue(_ value: Int) -> Color {
        let intensity = Double(value) / Double(maxValue)
        if intensity == 0 {
            return Color.white.opacity(0.1)
        }
        // Use a gradient from blue to purple to red with higher thresholds
        if intensity < 0.5 {  // Increased from 0.33
            return Color.blue.opacity(0.4 + intensity * 0.3)  // Increased base opacity
        } else if intensity < 0.8 {  // Increased from 0.66
            return Color.purple.opacity(0.5 + intensity * 0.3)  // Increased base opacity
        } else {
            return Color.red.opacity(0.6 + intensity * 0.3)  // Increased base opacity
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Activity")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(hours, id: \.self) { hour in
                    let value = hourlyData[hour] ?? 0
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForValue(value))
                        .frame(height: 24)
                        .overlay(
                            Text(formatHour(hour))
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
            }
            
            // Legend
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    Text("Low Activity")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("High Activity")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                HStack(spacing: 4) {
                    ForEach([0.0, 0.33, 0.66, 1.0], id: \.self) { intensity in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorForValue(Int(Double(maxValue) * intensity)))
                            .frame(height: 12)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
} 