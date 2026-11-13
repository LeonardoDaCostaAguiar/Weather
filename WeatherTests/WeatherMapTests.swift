import XCTest
import CoreLocation
@testable import Weather

@MainActor
final class WeatherMapTests: XCTestCase {

    func test_mapTarget_withCoordinates_buildsTargetFromWeather() throws {
        let weather = CityWeather(cityName: "Campinas",
                                  current: Fixtures.current,
                                  days: [],
                                  latitude: -22.90556,
                                  longitude: -47.06083)

        let target = try XCTUnwrap(weather.mapTarget)

        XCTAssertEqual(target.name, "Campinas")
        XCTAssertEqual(target.latitude, -22.90556, accuracy: 0.00001)
        XCTAssertEqual(target.longitude, -47.06083, accuracy: 0.00001)
        XCTAssertEqual(target.temperature, 24.5)
    }

    func test_mapTarget_withoutLatitude_isNil() {
        let weather = CityWeather(cityName: "Campinas",
                                  current: Fixtures.current,
                                  days: [],
                                  latitude: nil,
                                  longitude: -47.06083)

        XCTAssertNil(weather.mapTarget)
    }

    func test_mapTarget_withoutLongitude_isNil() {
        let weather = CityWeather(cityName: "Campinas",
                                  current: Fixtures.current,
                                  days: [],
                                  latitude: -22.90556,
                                  longitude: nil)

        XCTAssertNil(weather.mapTarget)
    }

    func test_mapTarget_withoutCoordinates_isNil() {
        let weather = CityWeather(cityName: "Campinas", current: Fixtures.current, days: [])

        XCTAssertNil(weather.mapTarget)
    }

    func test_mapTarget_withZeroCoordinates_isNotNil() throws {

        let weather = CityWeather(cityName: "Ponto zero",
                                  current: Fixtures.current,
                                  days: [],
                                  latitude: 0,
                                  longitude: 0)

        let target = try XCTUnwrap(weather.mapTarget)

        XCTAssertEqual(target.latitude, 0)
        XCTAssertEqual(target.longitude, 0)
    }

    func test_mapTarget_acceptsSouthernAndWesternHemispheres() throws {
        let weather = CityWeather(cityName: "Rio de Janeiro",
                                  current: Fixtures.current,
                                  days: [],
                                  latitude: -22.9068,
                                  longitude: -43.1729)

        let target = try XCTUnwrap(weather.mapTarget)

        XCTAssertLessThan(target.latitude, 0)
        XCTAssertLessThan(target.longitude, 0)
    }

    func test_coordinate_matchesLatitudeAndLongitude() {
        let target = MapTarget(name: "Campinas", latitude: -22.90556, longitude: -47.06083, temperature: 24)

        XCTAssertEqual(target.coordinate.latitude, -22.90556, accuracy: 0.00001)
        XCTAssertEqual(target.coordinate.longitude, -47.06083, accuracy: 0.00001)
        XCTAssertTrue(CLLocationCoordinate2DIsValid(target.coordinate))
    }

    func test_mapTarget_equatable_isEqualWhenAllFieldsMatch() {
        let a = MapTarget(name: "Campinas", latitude: -22.9, longitude: -47.06, temperature: 24)
        let b = MapTarget(name: "Campinas", latitude: -22.9, longitude: -47.06, temperature: 24)

        XCTAssertEqual(a, b)
    }

    func test_mapTarget_equatable_detectsEachChange() {
        let base = MapTarget(name: "Campinas", latitude: -22.9, longitude: -47.06, temperature: 24)

        XCTAssertNotEqual(base, MapTarget(name: "Outra cidade", latitude: -22.9, longitude: -47.06, temperature: 24))
        XCTAssertNotEqual(base, MapTarget(name: "Campinas", latitude: -23.0, longitude: -47.06, temperature: 24))
        XCTAssertNotEqual(base, MapTarget(name: "Campinas", latitude: -22.9, longitude: -47.07, temperature: 24))
        XCTAssertNotEqual(base, MapTarget(name: "Campinas", latitude: -22.9, longitude: -47.06, temperature: 25))
    }
}

@MainActor
final class WeatherServiceCoordinatesTests: XCTestCase {

    private var sut: WeatherService!

    override func setUp() async throws {
        try await super.setUp()
        MockURLProtocol.reset()
        sut = WeatherService(session: .mocked())
    }

    override func tearDown() async throws {
        MockURLProtocol.reset()
        sut = nil
        try await super.tearDown()
    }

    func test_fetchWeatherForCity_carriesCoordinatesFromGeocoding() async throws {
        stubSuccess()

        let weather = try await sut.fetchWeather(for: "Campinas")

        XCTAssertEqual(try XCTUnwrap(weather.latitude), -22.90556, accuracy: 0.00001)
        XCTAssertEqual(try XCTUnwrap(weather.longitude), -47.06083, accuracy: 0.00001)
    }

    func test_fetchWeatherForCity_producesMapTargetWithNameAndTemperature() async throws {
        stubSuccess()

        let weather = try await sut.fetchWeather(for: "Campinas")

        let target = try XCTUnwrap(weather.mapTarget)
        XCTAssertEqual(target.name, "Campinas")
        XCTAssertEqual(target.temperature, 24.5)      // current.temperature_2m da previsão
        XCTAssertEqual(target.latitude, -22.90556, accuracy: 0.00001)
        XCTAssertEqual(target.longitude, -47.06083, accuracy: 0.00001)
    }

    func test_fetchWeatherAtLocation_carriesTheGivenCoordinates() async throws {
        stubSuccess()
        let location = Location(name: "Minha localização", latitude: -22.9, longitude: -47.06, country: nil)

        let weather = try await sut.fetchWeather(at: location)

        XCTAssertEqual(try XCTUnwrap(weather.latitude), -22.9, accuracy: 0.00001)
        XCTAssertEqual(try XCTUnwrap(weather.longitude), -47.06, accuracy: 0.00001)

        let target = try XCTUnwrap(weather.mapTarget)
        XCTAssertEqual(target.name, "Minha localização")
    }

    private func stubSuccess() {
        MockURLProtocol.handler = { request in
            let json = request.url?.host == "geocoding-api.open-meteo.com"
                ? Fixtures.geocodingJSON
                : Fixtures.forecastJSON
            return (MockURLProtocol.response(for: request), Data(json.utf8))
        }
    }
}
