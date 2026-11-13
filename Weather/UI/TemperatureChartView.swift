import SwiftUI
import Charts

struct TemperatureChartData: Equatable {
    static var highSeries: String { WeatherLocalization.string("weather.chart.high") }
    static var lowSeries: String { WeatherLocalization.string("weather.chart.low") }

    struct Point: Identifiable, Equatable {
        let id: String
        let label: String
        let series: String
        let value: Double
    }

    let points: [Point]
    let yDomain: ClosedRange<Double>

    init(days: [DayForecast], locale: Locale? = nil) {
        points = days.enumerated().flatMap { index, day -> [Point] in
            let label = index == 0 ? WeatherLocalization.string("weather.day.today", locale: locale) : String(day.weekday.prefix(3))
            return [
                Point(id: "max-\(day.id)", label: label, series: Self.highSeries, value: day.max),
                Point(id: "min-\(day.id)", label: label, series: Self.lowSeries, value: day.min)
            ]
        }

        if let low = days.map(\.min).min(), let high = days.map(\.max).max() {
            yDomain = (low - Self.verticalPadding)...(high + Self.verticalPadding)
        } else {
            yDomain = 0...30
        }
    }

    private static let verticalPadding = 4.0
}

struct TemperatureChartView: View {
    let days: [DayForecast]

    var body: some View {
        let data = TemperatureChartData(days: days)

        if !data.points.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                header
                chart(for: data)
            }
            .padding(20)
            .neuSurface(.raised, depth: 8)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Text("weather.chart.title")
                .font(.ubuntu(.bold, size: 18))
                .foregroundStyle(Neu.textPrimary)

            Spacer(minLength: 8)
            
            LegendItem(title: TemperatureChartData.highSeries, color: Neu.sun)
            LegendItem(title: TemperatureChartData.lowSeries, color: Neu.cloud)
        }
    }

    private func chart(for data: TemperatureChartData) -> some View {
        Chart(data.points) { point in
            LineMark(
                x: .value(WeatherLocalization.string("weather.chart.day"), point.label),
                y: .value(WeatherLocalization.string("weather.chart.temperature"), point.value)
            )
            .foregroundStyle(by: .value(WeatherLocalization.string("weather.chart.series"), point.series))
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

            PointMark(
                x: .value(WeatherLocalization.string("weather.chart.day"), point.label),
                y: .value(WeatherLocalization.string("weather.chart.temperature"), point.value)
            )
            .foregroundStyle(by: .value(WeatherLocalization.string("weather.chart.series"), point.series))
            .symbolSize(64)
            .annotation(position: point.series == TemperatureChartData.highSeries ? .top : .bottom,
                        spacing: 6) {
                Text("\(Int(point.value.rounded()))°")
                    .font(.ubuntu(.bold, size: 12))
                    .foregroundStyle(Neu.textPrimary)
            }
        }
        .chartForegroundStyleScale([
            TemperatureChartData.highSeries: Neu.sun,
            TemperatureChartData.lowSeries: Neu.cloud
        ])
        .chartLegend(.hidden)
        .chartYScale(domain: data.yDomain)
        .chartYAxis(.hidden)
        .chartXScale(range: .plotDimension(padding: 22))
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.ubuntu(.medium, size: 12))
                    .foregroundStyle(Neu.textSecondary)
            }
        }
        .chartPlotStyle { plot in
            plot.background {
                NeuSurface(style: .inset,
                           shape: AnyShape(RoundedRectangle(cornerRadius: 16, style: .continuous)),
                           depth: 4)
            }
        }
        .frame(height: 190)
    }
}

private struct LegendItem: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.ubuntu(.regular, size: 12))
                .foregroundStyle(Neu.textSecondary)
        }
        .accessibilityHidden(true)
    }
}

