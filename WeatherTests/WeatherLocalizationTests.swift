import XCTest
@testable import Weather

final class WeatherLocalizationTests: XCTestCase {

    func test_weatherConditionsAreTranslatedInPortugueseEnglishAndSpanish() {
        let locales: [(String, [String])] = [
            ("pt-BR", ["Céu limpo", "Nublado", "Neblina", "Garoa", "Chuva", "Neve", "Tempestade", "Indefinido"]),
            ("en", ["Clear", "Cloudy", "Fog", "Drizzle", "Rain", "Snow", "Thunderstorm", "Unknown"]),
            ("es", ["Despejado", "Nublado", "Niebla", "Llovizna", "Lluvia", "Nieve", "Tormenta", "Desconocido"])
        ]
        let conditions: [WeatherCondition] = [.clear, .cloudy, .fog, .drizzle, .rain, .snow, .thunderstorm, .unknown]

        for (identifier, expected) in locales {
            let locale = Locale(identifier: identifier)
            XCTAssertEqual(conditions.map { $0.localizedDescription(locale: locale) }, expected, "locale \(identifier)")
        }
    }

    func test_weatherInterfaceAndWidgetStringsExistForAllSupportedLocales() {
        let expectations: [(String, String, String, String)] = [
            ("weather.search.prompt", "Buscar cidade", "Search city", "Buscar ciudad"),
            ("weather.detail.feelsLike", "Sensação", "Feels Like", "Sensación"),
            ("weather.day.today", "Hoje", "Today", "Hoy"),
            ("widget.forecast.name", "Clima e previsão", "Weather Forecast", "Pronóstico del tiempo"),
            ("weather.error.cityNotFound", "Não encontramos essa cidade. Tente outro nome.", "We couldn't find that city. Try another name.", "No encontramos esa ciudad. Prueba con otro nombre.")
        ]

        for (key, portuguese, english, spanish) in expectations {
            XCTAssertEqual(WeatherLocalization.string(key, locale: Locale(identifier: "pt-BR")), portuguese, key)
            XCTAssertEqual(WeatherLocalization.string(key, locale: Locale(identifier: "en")), english, key)
            XCTAssertEqual(WeatherLocalization.string(key, locale: Locale(identifier: "es")), spanish, key)
        }
    }

    func test_todayWidgetLabelUsesSelectedLocale() {
        let day = WidgetWeatherDayFixture.makeDay()

        XCTAssertEqual(day.weekdayLabel(isToday: true, locale: Locale(identifier: "pt-BR")), "Hoje")
        XCTAssertEqual(day.weekdayLabel(isToday: true, locale: Locale(identifier: "en")), "Today")
        XCTAssertEqual(day.weekdayLabel(isToday: true, locale: Locale(identifier: "es")), "Hoy")
    }
}

private enum WidgetWeatherDayFixture {
    static func makeDay() -> WidgetForecastDay {
        WidgetForecastDay(weekday: "Monday", conditionKey: "weather.condition.clear", conditionSymbol: "sun.max.fill", max: 20, min: 10)
    }
}
