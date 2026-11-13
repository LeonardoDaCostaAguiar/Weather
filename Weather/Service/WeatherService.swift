import Foundation

enum WeatherError: LocalizedError {
    case cityNotFound
    case invalidURL
    case badResponse

    var errorDescription: String? {
        switch self {
        case .cityNotFound: WeatherLocalization.string("weather.error.cityNotFound")
        case .invalidURL: WeatherLocalization.string("weather.error.invalidURL")
        case .badResponse: WeatherLocalization.string("weather.error.badResponse")
        }
    }
}

protocol WeatherServicing {
    func fetchWeather(for city: String) async throws -> CityWeather
    func fetchWeather(at location: Location) async throws -> CityWeather
}

struct WeatherService: WeatherServicing {

    // Injetável para testes; no app, usa a sessão padrão.
    var session: URLSession = .shared

    func fetchWeather(for city: String) async throws -> CityWeather {
        let location = try await searchLocation(named: city)
        return try await fetchWeather(at: location)
    }

    func fetchWeather(at location: Location) async throws -> CityWeather {
        let forecast = try await fetchForecast(for: location)

        return CityWeather(
            cityName: location.name,
            current: forecast.current,
            days: makeDays(from: forecast.daily),
            latitude: location.latitude,
            longitude: location.longitude
        )
    }

    private func searchLocation(named city: String) async throws -> Location {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        components?.queryItems = [
            URLQueryItem(name: "name", value: city),
            URLQueryItem(name: "count", value: "1"),
            URLQueryItem(name: "language", value: Self.apiLanguageCode)
        ]
        guard let url = components?.url else { throw WeatherError.invalidURL }

        let response: GeocodingResponse = try await request(url)
        guard let first = response.results?.first else { throw WeatherError.cityNotFound }
        return first
    }

    private func fetchForecast(for location: Location) async throws -> ForecastResponse {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: "\(location.latitude)"),
            URLQueryItem(name: "longitude", value: "\(location.longitude)"),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        guard let url = components?.url else { throw WeatherError.invalidURL }
        return try await request(url)
    }

    private func request<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw WeatherError.badResponse
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func makeDays(from daily: ForecastResponse.Daily) -> [DayForecast] {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"

        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Self.preferredLocale
        weekdayFormatter.dateFormat = "EEEE"

        return daily.time.indices.map { i in
            let date = parser.date(from: daily.time[i])
            return DayForecast(
                id: daily.time[i],
                weekday: date.map { weekdayFormatter.string(from: $0).capitalized } ?? daily.time[i],
                condition: WeatherCondition(code: daily.weatherCode[i]),
                max: daily.maxTemperature[i],
                min: daily.minTemperature[i]
            )
        }
    }

    private static var apiLanguageCode: String {
        let language = preferredLocale.language.languageCode?.identifier ?? "en"
        return ["pt", "es"].contains(language) ? language : "en"
    }

    private static var preferredLocale: Locale {
        Locale(identifier: Bundle.main.preferredLocalizations.first ?? Locale.current.identifier)
    }
}
