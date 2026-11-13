import Foundation
import WidgetKit

struct WidgetWeatherSnapshot: Codable, Equatable {
    static let appGroupIdentifier = "group.weather.br.com.Weather"
    static let storageKey = "latest-weather-snapshot"
    static let currentWidgetKind = "WeatherCurrentWidget"
    static let forecastWidgetKind = "WeatherForecastWidget"

    let cityName: String
    let temperature: Double
    let conditionKey: String
    let conditionSymbol: String
    let forecasts: [WidgetForecastDay]

    var temperatureLabel: String {
        Self.temperatureLabel(for: temperature)
    }

    var conditionText: String { WeatherLocalization.string(conditionKey) }

    var forecastsForMediumWidget: [WidgetForecastDay] {
        Array(forecasts.prefix(5))
    }

    static func temperatureLabel(for temperature: Double) -> String {
        "\(Int(temperature.rounded()))°"
    }

    static var preview: WidgetWeatherSnapshot {
        WidgetWeatherSnapshot(
            cityName: "Campinas",
            temperature: 24.5,
            conditionKey: "weather.condition.cloudy",
            conditionSymbol: "cloud.fill",
            forecasts: [
                WidgetForecastDay(weekday: "Monday", conditionKey: "weather.condition.rain", conditionSymbol: "cloud.rain.fill", max: 28, min: 18),
                WidgetForecastDay(weekday: "Tuesday", conditionKey: "weather.condition.cloudy", conditionSymbol: "cloud.fill", max: 27, min: 19),
                WidgetForecastDay(weekday: "Wednesday", conditionKey: "weather.condition.clear", conditionSymbol: "sun.max.fill", max: 30, min: 18),
                WidgetForecastDay(weekday: "Thursday", conditionKey: "weather.condition.drizzle", conditionSymbol: "cloud.drizzle.fill", max: 25, min: 17),
                WidgetForecastDay(weekday: "Friday", conditionKey: "weather.condition.clear", conditionSymbol: "sun.max.fill", max: 29, min: 18),
            ]
        )
    }
}

struct WidgetForecastDay: Codable, Equatable, Identifiable {
    var id: String { "\(weekday)-\(conditionSymbol)" }

    let weekday: String
    let conditionKey: String
    let conditionSymbol: String
    let max: Double
    let min: Double

    func weekdayLabel(isToday: Bool, locale: Locale? = nil) -> String {
        isToday ? WeatherLocalization.string("weather.day.today", locale: locale) : String(weekday.prefix(3))
    }

    var conditionText: String { WeatherLocalization.string(conditionKey) }

    var highLabel: String { WidgetWeatherSnapshot.temperatureLabel(for: max) }
    var lowLabel: String { WidgetWeatherSnapshot.temperatureLabel(for: min) }
}

enum WidgetWeatherStore {
    static func save(_ snapshot: WidgetWeatherSnapshot) {
        guard let defaults = UserDefaults(suiteName: WidgetWeatherSnapshot.appGroupIdentifier),
              let data = try? JSONEncoder().encode(snapshot) else { return }

        defaults.set(data, forKey: WidgetWeatherSnapshot.storageKey)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetWeatherSnapshot.currentWidgetKind)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetWeatherSnapshot.forecastWidgetKind)
    }

    static func load() -> WidgetWeatherSnapshot? {
        guard let data = UserDefaults(suiteName: WidgetWeatherSnapshot.appGroupIdentifier)?
            .data(forKey: WidgetWeatherSnapshot.storageKey) else { return nil }
        return try? JSONDecoder().decode(WidgetWeatherSnapshot.self, from: data)
    }
}
