import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var pulseEffect = false

    var body: some View {
        if isActive {
            WeatherView()
        } else {
            ZStack {
                Neu.background
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    ZStack {
                        Circle()
                            .fill(Neu.background)
                            .frame(width: 160, height: 160)
                            .neuSurface(.inset, in: .circle, depth: 10)

                        // Composição visual de clima (Sol e Nuvens em harmonia)
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 64))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Neu.sun)
                                .offset(x: -12, y: -10)
                                .scaleEffect(pulseEffect ? 1.05 : 0.95)
                                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseEffect)

                            Image(systemName: "cloud.fill")
                                .font(.system(size: 50))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(Neu.cloud)
                                .offset(x: 14, y: 12)
                        }
                    }

                    VStack(spacing: 8) {
                        Text("Weather")
                            .font(.ubuntu(.bold, size: 32))
                            .foregroundStyle(Neu.textPrimary)
                            .tracking(0.5)

                        Text("weather.splash.tagline")
                            .font(.ubuntu(.regular, size: 14))
                            .foregroundStyle(Neu.textSecondary)
                    }

                    ProgressView()
                        .tint(Neu.accent)
                        .scaleEffect(1.1)
                        .padding(.top, 12)
                }
                .padding(24)
            }
            .onAppear {
                pulseEffect = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

