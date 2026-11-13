import SwiftUI

extension WeatherCondition {
    var conditionTint: Color { self == .clear ? Neu.sun : Neu.cloud }
}

struct SearchBarView: View {
    @Binding var city: String
    var onSearch: () -> Void
    var onLocation: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            TextField("weather.search.city",
                      text: $city,
                      prompt: Text("weather.search.prompt").font(.ubuntu(.regular, size: 16)).foregroundStyle(Neu.textSecondary))
                .font(.ubuntu(.regular, size: 16))
                .submitLabel(.search)
                .onSubmit(onSearch)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .foregroundStyle(Neu.textPrimary)
                .padding(.horizontal, 22)
                .frame(height: 52)
                .neuSurface(.inset, in: .capsule, depth: 6)

            Button(action: onLocation) {
                Image(systemName: "location.fill")
                    .font(.title3)
                    .foregroundStyle(Neu.accent)
                    .frame(width: 52, height: 52)
            }
            .buttonStyle(NeuButtonStyle(shape: .circle))
            .accessibilityLabel("weather.search.useLocation")
        }
    }
}

struct CurrentWeatherView: View {
    let cityName: String
    let current: ForecastResponse.Current

    @ScaledMetric(relativeTo: .largeTitle) private var temperatureSize: CGFloat = 56

    var body: some View {
        let condition = WeatherCondition(code: current.weatherCode)

        VStack(spacing: 14) {
            Text(cityName)
                .font(.ubuntu(.bold, size: 24))
                .foregroundStyle(Neu.textPrimary)

            VStack(spacing: 4) {
                Image(systemName: condition.symbol)
                    .font(.system(size: 52))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(condition.conditionTint)
                    .accessibilityHidden(true)

                Text("\(Int(current.temperature.rounded()))°")
                    .font(.ubuntu(.bold, size: temperatureSize))
                    .foregroundStyle(Neu.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(width: 188, height: 188)
            .neuSurface(.inset, in: .circle, depth: 6)
            .padding(24)
            .neuSurface(.raised, in: .circle, depth: 10)

            Text(condition.description)
                .font(.ubuntu(.medium, size: 20))
                .foregroundStyle(Neu.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

struct DetailCardsView: View {
    let current: ForecastResponse.Current

    var body: some View {
        HStack(spacing: 14) {
            DetailCard(value: "\(Int(current.apparentTemperature.rounded()))°", title: WeatherLocalization.string("weather.detail.feelsLike"))
            DetailCard(value: "\(current.humidity)%", title: WeatherLocalization.string("weather.detail.humidity"))
            DetailCard(value: "\(Int(current.windSpeed.rounded())) km/h", title: WeatherLocalization.string("weather.detail.wind"))
        }
    }
}

private struct DetailCard: View {
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.ubuntu(.bold, size: 20))
                .foregroundStyle(Neu.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.ubuntu(.regular, size: 12))
                .foregroundStyle(Neu.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .neuSurface(.raised, depth: 6)
        .accessibilityElement(children: .combine)
    }
}

struct ForecastView: View {
    let days: [DayForecast]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                DayCard(day: day, isToday: index == 0)
            }
        }
    }
}

private struct DayCard: View {
    let day: DayForecast
    let isToday: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(isToday ? WeatherLocalization.string("weather.day.today") : String(day.weekday.prefix(3)))
                .font(.ubuntu(isToday ? .bold : .medium, size: 12))
                .foregroundStyle(isToday ? Neu.accent : Neu.textSecondary)

            Image(systemName: day.condition.symbol)
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(day.condition.conditionTint)
                .frame(height: 28)

            Text("\(Int(day.max.rounded()))°")
                .font(.ubuntu(.bold, size: 15))
                .foregroundStyle(Neu.textPrimary)

            Text("\(Int(day.min.rounded()))°")
                .font(.ubuntu(.regular, size: 12))
                .foregroundStyle(Neu.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .neuSurface(isToday ? .inset : .raised, depth: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(format: WeatherLocalization.string("weather.accessibility.forecast"), locale: .autoupdatingCurrent,
                   isToday ? WeatherLocalization.string("weather.day.today") : day.weekday,
                   day.condition.description,
                   "\(Int(day.max.rounded()))°", "\(Int(day.min.rounded()))°")
        )
    }
}

struct StatusMessageView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 36))
                .foregroundStyle(Neu.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(.ubuntu(.bold, size: 18))
                .foregroundStyle(Neu.textPrimary)
            Text(message)
                .font(.ubuntu(.regular, size: 14))
                .multilineTextAlignment(.center)
                .foregroundStyle(Neu.textSecondary)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .neuSurface(.inset, depth: 6)
        .accessibilityElement(children: .combine)
    }
}

