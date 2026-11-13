import XCTest
import CoreLocation
@testable import Weather


final class MockURLProtocol: URLProtocol {

    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    nonisolated(unsafe) static var requests: [URLRequest] = []

    static func reset() {
        handler = nil
        requests = []
    }

    static func response(for request: URLRequest, status: Int = 200) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(request)

        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

extension URLSession {

    static func mocked() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

enum Fixtures {

    static let geocodingJSON = #"""
    {"results":[{"name":"Campinas","latitude":-22.90556,"longitude":-47.06083,"country":"Brasil"}]}
    """#

    // 08/11/2026 é domingo e 14/11/2026 é sábado (evita o "-feira", que complica o capitalized)
    static let defaultDailyJSON = #"""
    {"time":["2026-11-08","2026-11-14"],"weather_code":[61,0],"temperature_2m_max":[28.0,30.5],"temperature_2m_min":[18.0,19.5]}
    """#

    static let forecastJSON = makeForecastJSON()

    static func makeForecastJSON(daily: String = defaultDailyJSON) -> String {
        """
        {
          "current": {
            "temperature_2m": 24.5,
            "apparent_temperature": 26.1,
            "relative_humidity_2m": 60,
            "wind_speed_10m": 12.3,
            "weather_code": 2
          },
          "daily": \(daily)
        }
        """
    }

    static let current = ForecastResponse.Current(
        temperature: 24.5,
        apparentTemperature: 26.1,
        humidity: 60,
        windSpeed: 12.3,
        weatherCode: 2
    )

    static func cityWeather(name: String = "Campinas") -> CityWeather {
        CityWeather(
            cityName: name,
            current: current,
            days: [
                DayForecast(id: "2026-11-08", weekday: "Domingo", condition: .rain, max: 28, min: 18)
            ]
        )
    }
}

@MainActor
final class MockWeatherService: WeatherServicing {

    var result: Result<CityWeather, Error> = .failure(WeatherError.badResponse)

    var shouldSuspend = false

    private(set) var requestedCities: [String] = []
    private(set) var requestedLocations: [Location] = []
    private var pending: CheckedContinuation<Void, Never>?

    var callCount: Int { requestedCities.count + requestedLocations.count }

    func fetchWeather(for city: String) async throws -> CityWeather {
        requestedCities.append(city)
        return try await respond()
    }

    func fetchWeather(at location: Location) async throws -> CityWeather {
        requestedLocations.append(location)
        return try await respond()
    }

    func resume() {
        pending?.resume()
        pending = nil
    }

    private func respond() async throws -> CityWeather {
        if shouldSuspend {
            await withCheckedContinuation { pending = $0 }
        }
        return try result.get()
    }
}

@MainActor
final class MockLocationService: WeatherLocationProviding {

    var locationResult: Result<CLLocation, Error> = .success(CLLocation(latitude: -22.9, longitude: -47.06))
    var cityNameResult: String? = "Campinas"
    var shouldSuspend = false

    private(set) var currentLocationCallCount = 0
    private var pending: CheckedContinuation<Void, Never>?

    func currentLocation() async throws -> CLLocation {
        currentLocationCallCount += 1
        if shouldSuspend {
            await withCheckedContinuation { pending = $0 }
        }
        return try locationResult.get()
    }

    func cityName(for location: CLLocation) async -> String? {
        cityNameResult
    }

    func resume() {
        pending?.resume()
        pending = nil
    }
}
