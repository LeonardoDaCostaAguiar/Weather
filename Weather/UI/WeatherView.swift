import SwiftUI

struct WeatherView: View {
    @State private var viewModel = WeatherViewModel()

    var body: some View {
        ZStack {
            Neu.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    SearchBarView(
                        city: $viewModel.city,
                        onSearch: { Task { await viewModel.search() } },
                        onLocation: { Task { await viewModel.searchByCurrentLocation() } }
                    )
                    content
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .scrollDismissesKeyboard(.interactively)
        }
        .task { await viewModel.searchByCurrentLocation() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            StatusMessageView(symbol: "magnifyingglass",
                              title: WeatherLocalization.string("weather.empty.title"),
                              message: WeatherLocalization.string("weather.empty.message"))
        case .loading:
            ProgressView(WeatherLocalization.string("weather.loading"))
                .tint(Neu.accent)
                .foregroundStyle(Neu.textSecondary)
                .padding(.top, 60)
        case .loaded(let weather):
            WeatherContentView(weather: weather)
        case .failed(let message):
            StatusMessageView(symbol: "exclamationmark.triangle",
                              title: WeatherLocalization.string("weather.error.title"),
                              message: message)
        }
    }
}

struct WeatherContentView: View {
    let weather: CityWeather

    private var days: [DayForecast] { Array(weather.days.prefix(5)) }

    var body: some View {
        VStack(spacing: 28) {
            CurrentWeatherView(cityName: weather.cityName, current: weather.current)
            DetailCardsView(current: weather.current)
            ForecastView(days: days)
            TemperatureChartView(days: days)

            if let target = weather.mapTarget {
                WeatherMapView(target: target)
            }

            Text("weather.poweredBy")
                .font(.ubuntu(.regular, size: 12))
                .foregroundStyle(Neu.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
    }
}

