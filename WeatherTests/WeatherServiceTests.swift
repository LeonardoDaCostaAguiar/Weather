import XCTest
@testable import Weather

final class WeatherServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        super.tearDown()
    }

    func test_fetchWeatherForCity_fetchesLocationAndForecast() async throws {
        MockURLProtocol.handler = { request in
            let url = try XCTUnwrap(request.url)
            if url.host == "geocoding-api.open-meteo.com" {
                let name = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "name" })?.value
                XCTAssertEqual(name, "Campinas")
                return (MockURLProtocol.response(for: request), Data(Fixtures.geocodingJSON.utf8))
            }
            if url.host == "api.open-meteo.com" {
                return (MockURLProtocol.response(for: request), Data(Fixtures.forecastJSON.utf8))
            }
            throw URLError(.badURL)
        }

        let service = WeatherService(session: .mocked())
        let weather = try await service.fetchWeather(for: "Campinas")

        XCTAssertEqual(weather.cityName, "Campinas")
        XCTAssertEqual(weather.current.temperature, 24.5)
        XCTAssertEqual(weather.days.count, 2)
        XCTAssertEqual(weather.days[0].id, "2026-11-08")
        XCTAssertEqual(weather.days[0].condition, .rain)
        XCTAssertEqual(weather.days[0].max, 28)
        XCTAssertEqual(weather.days[0].min, 18)
        XCTAssertEqual(MockURLProtocol.requests.count, 2)
    }

    func test_fetchWeatherForLocation_fetchesOnlyForecast() async throws {
        MockURLProtocol.handler = { request in
            (MockURLProtocol.response(for: request), Data(Fixtures.forecastJSON.utf8))
        }
        let service = WeatherService(session: .mocked())
        let location = Location(name: "Campinas", latitude: -22.9, longitude: -47.06, country: "Brasil")

        let weather = try await service.fetchWeather(at: location)

        XCTAssertEqual(weather.cityName, "Campinas")
        XCTAssertEqual(MockURLProtocol.requests.count, 1)
        XCTAssertEqual(MockURLProtocol.requests.first?.url?.host, "api.open-meteo.com")
    }

    func test_fetchWeatherForCity_withoutSearchResults_throwsCityNotFound() async {
        MockURLProtocol.handler = { request in
            (MockURLProtocol.response(for: request), Data(#"{"results":[]}"#.utf8))
        }
        let service = WeatherService(session: .mocked())

        do {
            _ = try await service.fetchWeather(for: "Cidade inexistente")
            XCTFail("Esperava WeatherError.cityNotFound")
        } catch {
            guard case WeatherError.cityNotFound = error else {
                return XCTFail("Erro inesperado: \(error)")
            }
        }
        XCTAssertEqual(MockURLProtocol.requests.count, 1)
    }

    func test_fetchWeather_whenServerReturnsError_throwsBadResponse() async {
        MockURLProtocol.handler = { request in
            (MockURLProtocol.response(for: request, status: 500), Data())
        }
        let service = WeatherService(session: .mocked())
        let location = Location(name: "Campinas", latitude: -22.9, longitude: -47.06, country: nil)

        do {
            _ = try await service.fetchWeather(at: location)
            XCTFail("Esperava WeatherError.badResponse")
        } catch {
            guard case WeatherError.badResponse = error else {
                return XCTFail("Erro inesperado: \(error)")
            }
        }
    }

    func test_fetchWeather_whenResponseIsInvalid_throwsDecodingError() async {
        MockURLProtocol.handler = { request in
            (MockURLProtocol.response(for: request), Data("{}".utf8))
        }
        let service = WeatherService(session: .mocked())
        let location = Location(name: "Campinas", latitude: -22.9, longitude: -47.06, country: nil)

        do {
            _ = try await service.fetchWeather(at: location)
            XCTFail("Esperava um erro de decodificação")
        } catch {
            XCTAssertTrue(error is DecodingError, "Erro inesperado: \(error)")
        }
    }
}
