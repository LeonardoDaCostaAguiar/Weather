import XCTest
@testable import Weather

final class WeatherErrorsTests: XCTestCase {

    func test_weatherError_descriptions() {
        XCTAssertEqual(WeatherError.cityNotFound.errorDescription,
                       WeatherLocalization.string("weather.error.cityNotFound"))
        XCTAssertEqual(WeatherError.invalidURL.errorDescription,
                       WeatherLocalization.string("weather.error.invalidURL"))
        XCTAssertEqual(WeatherError.badResponse.errorDescription,
                       WeatherLocalization.string("weather.error.badResponse"))
    }

    func test_weatherError_localizedDescriptionUsesErrorDescription() {
        // É isso que o ViewModel mostra na tela via error.localizedDescription
        let error: Error = WeatherError.cityNotFound

        XCTAssertEqual(error.localizedDescription, WeatherLocalization.string("weather.error.cityNotFound"))
    }

    func test_locationError_denied_pointsUserToSettingsAndCitySearch() throws {
        let message = try XCTUnwrap(LocationError.denied.errorDescription)

        XCTAssertEqual(message, WeatherLocalization.string("weather.error.locationPermission"))
    }

    func test_locationError_localizedDescriptionUsesErrorDescription() {
        let error: Error = LocationError.denied

        XCTAssertEqual(error.localizedDescription, LocationError.denied.errorDescription)
    }
}
