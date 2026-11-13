import Foundation
import Observation
import CoreLocation

@MainActor
@Observable
final class WeatherViewModel {

    enum State {
        case idle
        case loading
        case loaded(CityWeather)
        case failed(String)
    }

    var city = ""
    private(set) var state: State = .idle

    private let service: WeatherServicing
    private let weatherLocationService: any WeatherLocationProviding

    init(service: WeatherServicing = WeatherService(),
         weatherLocationService: (any WeatherLocationProviding)? = nil) {
        self.service = service
        self.weatherLocationService = weatherLocationService ?? WeatherLocationService()
    }

    func search() async {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        state = .loading
        do {
            let weather = try await service.fetchWeather(for: trimmed)
            updateWidgetSnapshot(with: weather)
            state = .loaded(weather)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
    
    func searchByCurrentLocation() async {
        guard !isLoading else { return }

        state = .loading
        do {
            let userLocation = try await weatherLocationService.currentLocation()
            let name = await weatherLocationService.cityName(for: userLocation)
                ?? WeatherLocalization.string("weather.location.current")

            let place = Location(
                name: name,
                latitude: userLocation.coordinate.latitude,
                longitude: userLocation.coordinate.longitude,
                country: nil
            )

            let weather = try await service.fetchWeather(at: place)
            updateWidgetSnapshot(with: weather)
            city = name
            state = .loaded(weather)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
    
    private func updateWidgetSnapshot(with weather: CityWeather) {
        let snapshot = WidgetWeatherSnapshot(
            cityName: weather.cityName,
            temperature: weather.current.temperature,
            conditionKey: WeatherCondition(code: weather.current.weatherCode).localizationKey,
            conditionSymbol: WeatherCondition(code: weather.current.weatherCode).symbol,
            forecasts: weather.days.map { day in
                WidgetForecastDay(
                    weekday: day.weekday,
                    conditionKey: day.condition.localizationKey,
                    conditionSymbol: day.condition.symbol,
                    max: day.max,
                    min: day.min
                )
            }
        )
        WidgetWeatherStore.save(snapshot)
    }

    private var isLoading: Bool {
        if case .loading = state { true } else { false }
    }
}
