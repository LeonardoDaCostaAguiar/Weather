import SwiftUI
import MapKit

struct MapTarget: Equatable {
    let name: String
    let latitude: Double
    let longitude: Double
    let temperature: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension CityWeather {
    var mapTarget: MapTarget? {
        guard let latitude, let longitude else { return nil }
        return MapTarget(name: cityName, latitude: latitude, longitude: longitude, temperature: current.temperature)
    }
}

struct WeatherMapView: View {
    let target: MapTarget

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale

    @State private var phase: Phase = .loading
    @State private var attempt = 0

    private let frameInset: CGFloat = 12
    private let mapHeight: CGFloat = 240
    private let outerRadius: CGFloat = 30
    private let innerRadius: CGFloat = 18
    private let distance: CLLocationDistance = 35_000

    private enum Phase {
        case loading
        case ready(UIImage)
        case failed
    }

    private struct RenderKey: Equatable {
        let target: MapTarget
        let size: CGSize
        let isDark: Bool
        let attempt: Int
    }

    var body: some View {
        GeometryReader { proxy in
            content
                .frame(width: proxy.size.width, height: proxy.size.height)
                .task(id: RenderKey(target: target,
                                    size: proxy.size,
                                    isDark: colorScheme == .dark,
                                    attempt: attempt)) {
                    await render(size: proxy.size)
                }
        }
        .frame(height: mapHeight)
        .clipShape(RoundedRectangle(cornerRadius: innerRadius, style: .continuous))
        .overlay { InsetShadow(cornerRadius: innerRadius, depth: 8) }
        .padding(frameInset)
        .neuSurface(.raised, in: AnyShape(RoundedRectangle(cornerRadius: outerRadius, style: .continuous)), depth: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: WeatherLocalization.string("weather.map.accessibility"), target.name))
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            Neu.background
                .overlay { ProgressView().tint(Neu.accent) }

        case .ready(let image):
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipped()
                .overlay {
                    MapPin(temperature: target.temperature, name: target.name)
                        .alignmentGuide(VerticalAlignment.center) { $0[.bottom] }
                }

        case .failed:
            Button {
                attempt += 1
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "map")
                        .font(.title2)
                        .foregroundStyle(Neu.accent)
                    Text("weather.map.unavailable")
                        .font(.ubuntu(.medium, size: 13))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Neu.textSecondary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Neu.background)
            }
            .buttonStyle(.plain)
        }
    }

    private func render(size: CGSize) async {
        guard size.width > 0, size.height > 0 else { return }
        phase = .loading

        let options = MKMapSnapshotter.Options()
        options.camera = MKMapCamera(lookingAtCenter: target.coordinate,
                                     fromDistance: distance,
                                     pitch: 0,
                                     heading: 0)
        options.size = size
        options.scale = displayScale
        options.mapType = .mutedStandard
        options.pointOfInterestFilter = .excludingAll
        options.traitCollection = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)

        do {
            let snapshot = try await MKMapSnapshotter(options: options).start()
            guard !Task.isCancelled else { return }
            phase = .ready(snapshot.image)
        } catch {
            guard !Task.isCancelled else { return }
            phase = .failed
        }
    }
}

private struct MapPin: View {
    let temperature: Double
    let name: String

    var body: some View {
        VStack(spacing: 6) {
            VStack(spacing: 2) {
                Text("\(Int(temperature.rounded()))°")
                    .font(.ubuntu(.bold, size: 18))
                    .foregroundStyle(Neu.textPrimary)

                Text(name)
                    .font(.ubuntu(.medium, size: 11))
                    .foregroundStyle(Neu.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: 150)
            .neuSurface(.raised, in: .card, depth: 4)

            Circle()
                .fill(Neu.accent)
                .frame(width: 10, height: 10)
                .padding(4)
                .neuSurface(.raised, in: .circle, depth: 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: WeatherLocalization.string("weather.map.pinAccessibility"), name, Int(temperature.rounded())))
    }
}

private struct InsetShadow: View {
    let cornerRadius: CGFloat
    var depth: CGFloat = 8

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            edge(shape, color: Neu.shadowDark, direction: 1)
            edge(shape, color: Neu.shadowLight, direction: -1)
        }
        .allowsHitTesting(false)
    }

    private func edge(_ shape: RoundedRectangle, color: Color, direction: CGFloat) -> some View {
        shape
            .stroke(color, lineWidth: depth)
            .blur(radius: depth * 0.6)
            .offset(x: direction * depth * 0.6, y: direction * depth * 0.6)
            .mask(shape)
    }
}
