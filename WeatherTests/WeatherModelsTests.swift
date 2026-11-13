import XCTest
@testable import Weather

final class WeatherModelsTests: XCTestCase {

    func test_condition_mapsKnownCodes() {
        let expected: [(Int, WeatherCondition)] = [
            (0, .clear), (1, .clear),
            (2, .cloudy), (3, .cloudy),
            (45, .fog), (48, .fog),
            (51, .drizzle), (55, .drizzle), (57, .drizzle),
            (61, .rain), (65, .rain), (67, .rain), (80, .rain), (82, .rain),
            (71, .snow), (75, .snow), (77, .snow), (85, .snow), (86, .snow),
            (95, .thunderstorm), (99, .thunderstorm)
        ]

        for (code, condition) in expected {
            XCTAssertEqual(WeatherCondition(code: code), condition, "código \(code)")
        }
    }

    func test_condition_mapsUnmappedCodesToUnknown() {
        // Inclui os "buracos" entre as faixas e valores fora do intervalo
        let codes = [-1, 4, 44, 46, 58, 60, 68, 70, 78, 79, 83, 84, 87, 94, 100, 999]

        for code in codes {
            XCTAssertEqual(WeatherCondition(code: code), .unknown, "código \(code)")
        }
    }

    func test_condition_descriptions() {
        let expected: [(WeatherCondition, String)] = [
            (.clear, "Céu limpo"),
            (.cloudy, "Nublado"),
            (.fog, "Neblina"),
            (.drizzle, "Garoa"),
            (.rain, "Chuva"),
            (.snow, "Neve"),
            (.thunderstorm, "Tempestade"),
            (.unknown, "Indefinido")
        ]

        for (condition, text) in expected {
            XCTAssertEqual(condition.localizedDescription(locale: Locale(identifier: "pt-BR")), text)
        }
    }

    func test_condition_symbols() {
        let expected: [(WeatherCondition, String)] = [
            (.clear, "sun.max.fill"),
            (.cloudy, "cloud.fill"),
            (.fog, "cloud.fog.fill"),
            (.drizzle, "cloud.drizzle.fill"),
            (.rain, "cloud.rain.fill"),
            (.snow, "snowflake"),
            (.thunderstorm, "cloud.bolt.rain.fill"),
            (.unknown, "questionmark.circle")
        ]

        for (condition, symbol) in expected {
            XCTAssertEqual(condition.symbol, symbol)
        }
    }

    func test_geocodingResponse_decodesLocationWithCountry() throws {
        let data = Data(Fixtures.geocodingJSON.utf8)

        let response = try JSONDecoder().decode(GeocodingResponse.self, from: data)

        let location = try XCTUnwrap(response.results?.first)
        XCTAssertEqual(location.name, "Campinas")
        XCTAssertEqual(location.latitude, -22.90556, accuracy: 0.00001)
        XCTAssertEqual(location.longitude, -47.06083, accuracy: 0.00001)
        XCTAssertEqual(location.country, "Brasil")
    }

    func test_geocodingResponse_withoutResultsKey_hasNilResults() throws {
        let data = Data(#"{"generationtime_ms":0.5}"#.utf8)

        let response = try JSONDecoder().decode(GeocodingResponse.self, from: data)

        XCTAssertNil(response.results)
    }

    func test_location_withoutCountry_hasNilCountry() throws {
        let data = Data(#"{"name":"Lugar","latitude":1.5,"longitude":2.5}"#.utf8)

        let location = try JSONDecoder().decode(Location.self, from: data)

        XCTAssertEqual(location.name, "Lugar")
        XCTAssertNil(location.country)
    }

    func test_forecastResponse_translatesApiKeysToReadableNames() throws {
        let data = Data(Fixtures.forecastJSON.utf8)

        let forecast = try JSONDecoder().decode(ForecastResponse.self, from: data)

        XCTAssertEqual(forecast.current.temperature, 24.5)
        XCTAssertEqual(forecast.current.apparentTemperature, 26.1)
        XCTAssertEqual(forecast.current.humidity, 60)
        XCTAssertEqual(forecast.current.windSpeed, 12.3)
        XCTAssertEqual(forecast.current.weatherCode, 2)

        XCTAssertEqual(forecast.daily.time, ["2026-11-08", "2026-11-14"])
        XCTAssertEqual(forecast.daily.weatherCode, [61, 0])
        XCTAssertEqual(forecast.daily.maxTemperature, [28.0, 30.5])
        XCTAssertEqual(forecast.daily.minTemperature, [18.0, 19.5])
    }

    func test_forecastResponse_throwsWhenRequiredFieldIsMissing() {

        let json = Fixtures.makeForecastJSON()
            .replacingOccurrences(of: #""apparent_temperature": 26.1,"#, with: "")
        let data = Data(json.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(ForecastResponse.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError, "erro inesperado: \(error)")
        }
    }
}
