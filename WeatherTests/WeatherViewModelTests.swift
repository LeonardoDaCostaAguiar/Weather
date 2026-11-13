import XCTest
import CoreLocation
@testable import Weather

@MainActor
final class WeatherViewModelTests: XCTestCase {

    private var service: MockWeatherService!
    private var locationService: MockLocationService!
    private var sut: WeatherViewModel!

    override func setUp() async throws {
        try await super.setUp()

        let service = MockWeatherService()
        let locationService = MockLocationService()

        self.service = service
        self.locationService = locationService
        sut = WeatherViewModel(service: service, weatherLocationService: locationService)
    }

    override func tearDown() async throws {
        sut = nil
        locationService = nil
        service = nil
        try await super.tearDown()
    }

    // MARK: - Estado inicial

    func test_initialState_isIdleWithEmptyCity() {
        XCTAssertTrue(sut.state.isIdle)
        XCTAssertEqual(sut.city, "")
    }

    func test_search_withEmptyCity_doesNothing() async {
        sut.city = ""

        await sut.search()

        XCTAssertTrue(sut.state.isIdle)
        XCTAssertTrue(service.requestedCities.isEmpty)
    }

    func test_search_withWhitespaceOnlyCity_doesNothing() async {
        sut.city = "   \n  "

        await sut.search()

        XCTAssertTrue(sut.state.isIdle)
        XCTAssertTrue(service.requestedCities.isEmpty)
    }

    func test_search_trimsCityBeforeCallingService() async {
        service.result = .success(Fixtures.cityWeather())
        sut.city = "  Campinas \n"

        await sut.search()

        XCTAssertEqual(service.requestedCities, ["Campinas"])
    }

    func test_search_onSuccess_setsLoadedState() async throws {
        service.result = .success(Fixtures.cityWeather(name: "Campinas"))
        sut.city = "Campinas"

        await sut.search()

        let weather = try XCTUnwrap(sut.state.loadedWeather)
        XCTAssertEqual(weather.cityName, "Campinas")
        XCTAssertEqual(weather.days.count, 1)
    }

    func test_search_onFailure_setsFailedStateWithLocalizedMessage() async {
        service.result = .failure(WeatherError.cityNotFound)
        sut.city = "Xyzzy"

        await sut.search()

        XCTAssertEqual(sut.state.errorMessage, WeatherLocalization.string("weather.error.cityNotFound"))
    }

    func test_search_setsLoadingWhileRequestIsInFlight() async {
        service.shouldSuspend = true
        service.result = .success(Fixtures.cityWeather())
        sut.city = "Campinas"

        let task = Task { await sut.search() }
        await waitUntil { service.callCount == 1 }

        XCTAssertTrue(sut.state.isLoading)

        service.resume()
        await task.value

        XCTAssertNotNil(sut.state.loadedWeather)
    }

    func test_search_afterFailure_canSucceedOnNextAttempt() async {
        sut.city = "Campinas"

        service.result = .failure(WeatherError.badResponse)
        await sut.search()
        XCTAssertNotNil(sut.state.errorMessage)

        service.result = .success(Fixtures.cityWeather())
        await sut.search()
        XCTAssertNotNil(sut.state.loadedWeather)
        XCTAssertNil(sut.state.errorMessage)
    }

    func test_searchByCurrentLocation_onSuccess_usesCoordinatesAndCityName() async throws {
        locationService.locationResult = .success(CLLocation(latitude: -22.9, longitude: -47.06))
        locationService.cityNameResult = "Campinas"
        service.result = .success(Fixtures.cityWeather())

        await sut.searchByCurrentLocation()

        let place = try XCTUnwrap(service.requestedLocations.first)
        XCTAssertEqual(place.name, "Campinas")
        XCTAssertEqual(place.latitude, -22.9, accuracy: 0.0001)
        XCTAssertEqual(place.longitude, -47.06, accuracy: 0.0001)
        XCTAssertNil(place.country)

        XCTAssertEqual(sut.city, "Campinas")
        XCTAssertNotNil(sut.state.loadedWeather)
    }

    func test_searchByCurrentLocation_whenCityNameIsUnavailable_usesFallbackName() async throws {
        locationService.cityNameResult = nil
        let fallbackName = WeatherLocalization.string("weather.location.current")
        service.result = .success(Fixtures.cityWeather(name: fallbackName))

        await sut.searchByCurrentLocation()

        let place = try XCTUnwrap(service.requestedLocations.first)
        XCTAssertEqual(place.name, fallbackName)
        XCTAssertEqual(sut.city, fallbackName)
        XCTAssertNotNil(sut.state.loadedWeather)
    }

    func test_searchByCurrentLocation_whenPermissionDenied_setsFailedAndSkipsService() async {
        locationService.locationResult = .failure(LocationError.denied)

        await sut.searchByCurrentLocation()

        XCTAssertEqual(sut.state.errorMessage, LocationError.denied.errorDescription)
        XCTAssertEqual(service.callCount, 0)
        XCTAssertEqual(sut.city, "")
    }

    func test_searchByCurrentLocation_whenWeatherServiceFails_setsFailedAndKeepsCity() async {
        service.result = .failure(WeatherError.badResponse)

        await sut.searchByCurrentLocation()

        XCTAssertEqual(sut.state.errorMessage, WeatherError.badResponse.errorDescription)
        XCTAssertEqual(sut.city, "", "a cidade só deve ser preenchida quando a busca dá certo")
    }

    func test_searchByCurrentLocation_ignoresSecondCallWhileLoading() async {
        locationService.shouldSuspend = true
        service.result = .success(Fixtures.cityWeather())

        let first = Task { await sut.searchByCurrentLocation() }
        await waitUntil { locationService.currentLocationCallCount == 1 }
        XCTAssertTrue(sut.state.isLoading)

        await sut.searchByCurrentLocation()
        XCTAssertEqual(locationService.currentLocationCallCount, 1)

        locationService.resume()
        await first.value

        XCTAssertNotNil(sut.state.loadedWeather)
        XCTAssertEqual(service.requestedLocations.count, 1)
    }

    private func waitUntil(_ condition: () -> Bool,
                           file: StaticString = #filePath,
                           line: UInt = #line) async {
        for _ in 0..<1_000 {
            if condition() { return }
            await Task.yield()
        }
        XCTFail("A condição não foi satisfeita a tempo", file: file, line: line)
    }
}

private extension WeatherViewModel.State {

    var isIdle: Bool {
        if case .idle = self { true } else { false }
    }

    var isLoading: Bool {
        if case .loading = self { true } else { false }
    }

    var loadedWeather: CityWeather? {
        if case .loaded(let weather) = self { weather } else { nil }
    }

    var errorMessage: String? {
        if case .failed(let message) = self { message } else { nil }
    }
}
