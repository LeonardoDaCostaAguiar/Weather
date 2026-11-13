import SwiftUI
import WidgetKit

struct WeatherWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetWeatherSnapshot?
}

struct WeatherWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherWidgetEntry {
        WeatherWidgetEntry(date: .now, snapshot: .preview)
    }
    func getSnapshot(in context: Context, completion: @escaping (WeatherWidgetEntry) -> Void) {
        completion(WeatherWidgetEntry(date: .now, snapshot: WidgetWeatherStore.load() ?? (context.isPreview ? .preview : nil)))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherWidgetEntry>) -> Void) {
        let entry = WeatherWidgetEntry(date: .now, snapshot: WidgetWeatherStore.load())
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

struct WeatherCurrentWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetWeatherSnapshot.currentWidgetKind, provider: WeatherWidgetProvider()) { entry in
            SmallWeatherWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.current.name")
        .description("widget.current.description")
        .supportedFamilies([.systemSmall])
    }
}

struct WeatherForecastWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetWeatherSnapshot.forecastWidgetKind, provider: WeatherWidgetProvider()) { entry in
            MediumWeatherWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.forecast.name")
        .description("widget.forecast.description")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct WeatherWidgetBundle: WidgetBundle {
    var body: some Widget { WeatherCurrentWidget(); WeatherForecastWidget() }
}

private struct SmallWeatherWidgetView: View {
    let entry: WeatherWidgetEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                VStack(spacing: 3) {
                    temperatureCircle(snapshot, diameter: 102, iconSize: 25, fontSize: 28)
                    Text(snapshot.conditionText)
                        .font(.ubuntu(.medium, size: 13))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(Neu.textSecondary)
                    Text(snapshot.cityName)
                        .font(.ubuntu(.medium, size: 12))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(Neu.textPrimary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(8)
                .containerBackground(for: .widget) { Neu.background }
                .accessibilityElement(children: .combine)
            } else {
                emptyState("widget.empty.current")
            }
        }
    }

    private func temperatureCircle(_ snapshot: WidgetWeatherSnapshot, diameter: CGFloat, iconSize: CGFloat, fontSize: CGFloat) -> some View {
        VStack(spacing: -5) {
            Image(systemName: snapshot.conditionSymbol)
                .font(.system(size: iconSize, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(snapshot.conditionSymbol == "sun.max.fill" ? Neu.sun : Neu.cloud)
                .accessibilityHidden(true)
            Text(snapshot.temperatureLabel)
                .font(.ubuntu(.bold, size: fontSize))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundStyle(Neu.textPrimary)
        }
        .frame(width: diameter * 0.72, height: diameter * 0.72)
        .neuSurface(.inset, in: .circle, depth: 5)
        .padding(diameter * 0.14)
        .neuSurface(.raised, in: .circle, depth: 7)
    }

    private func emptyState(_ key: String) -> some View {
        Text(LocalizedStringKey(key))
            .font(.ubuntu(.medium, size: 14))
            .multilineTextAlignment(.center)
            .foregroundStyle(Neu.textSecondary)
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) { Neu.background }
    }
}

private struct MediumWeatherWidgetView: View {
    let entry: WeatherWidgetEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                HStack(spacing: 9) {
                    currentWeather(snapshot)
                        .frame(width: 89)
                    HStack(spacing: 5) {
                        ForEach(Array(snapshot.forecastsForMediumWidget.enumerated()), id: \.element.id) { index, day in
                            forecastColumn(day, isToday: index == 0)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(10)
                .containerBackground(for: .widget) { Neu.background }
            } else {
                Text("widget.empty.forecast")
                    .font(.ubuntu(.medium, size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Neu.textSecondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .containerBackground(for: .widget) { Neu.background }
            }
        }
    }

    private func currentWeather(_ snapshot: WidgetWeatherSnapshot) -> some View {
        VStack(spacing: 3) {
            VStack(spacing: -4) {
                Image(systemName: snapshot.conditionSymbol)
                    .font(.system(size: 20, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(snapshot.conditionSymbol == "sun.max.fill" ? Neu.sun : Neu.cloud)
                Text(snapshot.temperatureLabel)
                    .font(.ubuntu(.bold, size: 22))
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
                    .foregroundStyle(Neu.textPrimary)
            }
            .frame(width: 66, height: 66)
            .neuSurface(.inset, in: .circle, depth: 4)
            .padding(10)
            .neuSurface(.raised, in: .circle, depth: 5)
            Text(snapshot.conditionText)
                .font(.ubuntu(.medium, size: 10))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .foregroundStyle(Neu.textSecondary)
            Text(snapshot.cityName)
                .font(.ubuntu(.medium, size: 10))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .foregroundStyle(Neu.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func forecastColumn(_ day: WidgetForecastDay, isToday: Bool) -> some View {
        VStack(spacing: 5) {
            Text(day.weekdayLabel(isToday: isToday))
                .font(.ubuntu(isToday ? .bold : .medium, size: 10))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(isToday ? Neu.accent : Neu.textSecondary)
            Image(systemName: day.conditionSymbol)
                .font(.system(size: 15, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(day.conditionSymbol == "sun.max.fill" ? Neu.sun : Neu.cloud)
                .frame(height: 20)
                .accessibilityHidden(true)
            Text(day.highLabel)
                .font(.ubuntu(.bold, size: 12))
                .foregroundStyle(Neu.textPrimary)
            Text(day.lowLabel)
                .font(.ubuntu(.regular, size: 10))
                .foregroundStyle(Neu.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 7)
        .neuSurface(isToday ? .inset : .raised, depth: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: WeatherLocalization.string("weather.accessibility.forecast"), locale: .autoupdatingCurrent,
                                   day.weekdayLabel(isToday: isToday), day.conditionText, day.highLabel, day.lowLabel))
    }
}
