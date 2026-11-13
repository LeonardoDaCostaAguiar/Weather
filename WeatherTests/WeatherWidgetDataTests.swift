import XCTest
@testable import Weather

final class WeatherWidgetDataTests: XCTestCase {

    func test_temperatureLabel_roundsToNearestWholeDegree() {
        XCTAssertEqual(WidgetWeatherSnapshot.temperatureLabel(for: 24.4), "24°")
        XCTAssertEqual(WidgetWeatherSnapshot.temperatureLabel(for: 24.5), "25°")
        XCTAssertEqual(WidgetWeatherSnapshot.temperatureLabel(for: -2.6), "-3°")
    }

    func test_mediumWidget_showsFiveForecastDays() {
        let snapshot = makeSnapshot()

        XCTAssertEqual(snapshot.forecastsForMediumWidget.count, 5)
        XCTAssertEqual(snapshot.forecastsForMediumWidget.map(\.weekday), [
            "Segunda-Feira", "Terça-Feira", "Quarta-Feira", "Quinta-Feira", "Sexta-Feira"
        ])
    }

    func test_forecastDay_usesTodayAndThreeLetterWeekdayLabels() {
        let today = makeSnapshot().forecasts[0]
        let tomorrow = makeSnapshot().forecasts[1]

        XCTAssertEqual(today.weekdayLabel(isToday: true, locale: Locale(identifier: "pt-BR")), "Hoje")
        XCTAssertEqual(tomorrow.weekdayLabel(isToday: false, locale: Locale(identifier: "pt-BR")), "Ter")
        XCTAssertEqual(today.highLabel, "28°")
        XCTAssertEqual(today.lowLabel, "18°")
    }

    func test_snapshot_roundTripsThroughSharedWidgetEncoding() throws {
        let snapshot = makeSnapshot()
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(WidgetWeatherSnapshot.self, from: data)

        XCTAssertEqual(decoded, snapshot)
    }

    private func makeSnapshot() -> WidgetWeatherSnapshot {
        WidgetWeatherSnapshot(
            cityName: "Campinas",
            temperature: 24.5,
            conditionKey: "weather.condition.cloudy",
            conditionSymbol: "cloud.fill",
            forecasts: [
                WidgetForecastDay(weekday: "Segunda-Feira", conditionKey: "weather.condition.rain", conditionSymbol: "cloud.rain.fill", max: 28, min: 18),
                WidgetForecastDay(weekday: "Terça-Feira", conditionKey: "weather.condition.cloudy", conditionSymbol: "cloud.fill", max: 27, min: 19),
                WidgetForecastDay(weekday: "Quarta-Feira", conditionKey: "weather.condition.clear", conditionSymbol: "sun.max.fill", max: 30, min: 18),
                WidgetForecastDay(weekday: "Quinta-Feira", conditionKey: "weather.condition.drizzle", conditionSymbol: "cloud.drizzle.fill", max: 25, min: 17),
                WidgetForecastDay(weekday: "Sexta-Feira", conditionKey: "weather.condition.clear", conditionSymbol: "sun.max.fill", max: 29, min: 18),
                WidgetForecastDay(weekday: "Sábado", conditionKey: "weather.condition.clear", conditionSymbol: "sun.max.fill", max: 31, min: 20),
            ]
        )
    }
}
