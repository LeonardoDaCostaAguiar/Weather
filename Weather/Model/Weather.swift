import Foundation

struct GeocodingResponse: Decodable {
    let results: [Location]?
}

struct Location: Decodable {
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
}

struct ForecastResponse: Decodable {
    let current: Current
    let daily: Daily

    struct Current: Decodable {
        let temperature: Double
        let apparentTemperature: Double
        let humidity: Int
        let windSpeed: Double
        let weatherCode: Int

        // A API usa nomes como "temperature_2m"; aqui traduzimos para nomes legíveis
        enum CodingKeys: String, CodingKey {
            case temperature = "temperature_2m"
            case apparentTemperature = "apparent_temperature"
            case humidity = "relative_humidity_2m"
            case windSpeed = "wind_speed_10m"
            case weatherCode = "weather_code"
        }
    }

    struct Daily: Decodable {
        let time: [String]
        let weatherCode: [Int]
        let maxTemperature: [Double]
        let minTemperature: [Double]

        enum CodingKeys: String, CodingKey {
            case time
            case weatherCode = "weather_code"
            case maxTemperature = "temperature_2m_max"
            case minTemperature = "temperature_2m_min"
        }
    }
}

struct DayForecast: Identifiable {
    let id: String
    let weekday: String
    let condition: WeatherCondition
    let max: Double
    let min: Double
}

struct CityWeather {
    let cityName: String
    let current: ForecastResponse.Current
    let days: [DayForecast]

    var latitude: Double? = nil
    var longitude: Double? = nil
}

enum WeatherCondition {
    case clear, cloudy, fog, drizzle, rain, snow, thunderstorm, unknown

    init(code: Int) {
        switch code {
        case 0, 1:            self = .clear
        case 2, 3:            self = .cloudy
        case 45, 48:          self = .fog
        case 51...57:         self = .drizzle
        case 61...67, 80...82: self = .rain
        case 71...77, 85, 86: self = .snow
        case 95...99:         self = .thunderstorm
        default:              self = .unknown
        }
    }

    var description: String {
        WeatherLocalization.string(localizationKey)
    }

    func localizedDescription(locale: Locale) -> String {
        WeatherLocalization.string(localizationKey, locale: locale)
    }

    var localizationKey: String {
        switch self {
        case .clear: "weather.condition.clear"
        case .cloudy: "weather.condition.cloudy"
        case .fog: "weather.condition.fog"
        case .drizzle: "weather.condition.drizzle"
        case .rain: "weather.condition.rain"
        case .snow: "weather.condition.snow"
        case .thunderstorm: "weather.condition.thunderstorm"
        case .unknown: "weather.condition.unknown"
        }
    }

    var symbol: String {
        switch self {
        case .clear: "sun.max.fill"
        case .cloudy: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .drizzle: "cloud.drizzle.fill"
        case .rain: "cloud.rain.fill"
        case .snow: "snowflake"
        case .thunderstorm: "cloud.bolt.rain.fill"
        case .unknown: "questionmark.circle"
        }
    }
}
