import XCTest
@testable import Weather

@MainActor
final class TemperatureChartDataTests: XCTestCase {

    private func day(_ id: String, _ weekday: String, max: Double, min: Double) -> DayForecast {
        DayForecast(id: id, weekday: weekday, condition: .clear, max: max, min: min)
    }

    private var fiveDays: [DayForecast] {
        [
            day("2026-11-09", "Segunda-Feira", max: 29, min: 18),
            day("2026-11-10", "Terça-Feira",   max: 27, min: 18),
            day("2026-11-11", "Quarta-Feira",  max: 23, min: 17),
            day("2026-11-12", "Quinta-Feira",  max: 25, min: 16),
            day("2026-11-13", "Sexta-Feira",   max: 30, min: 18)
        ]
    }

    private func points(_ data: TemperatureChartData, series: String) -> [TemperatureChartData.Point] {
        data.points.filter { $0.series == series }
    }

    func test_points_haveOneMaxAndOneMinPerDay() {
        let data = TemperatureChartData(days: fiveDays, locale: Locale(identifier: "pt-BR"))

        XCTAssertEqual(data.points.count, 10)
        XCTAssertEqual(points(data, series: TemperatureChartData.highSeries).count, 5)
        XCTAssertEqual(points(data, series: TemperatureChartData.lowSeries).count, 5)
    }

    func test_points_valuesMatchEachDay() {
        let data = TemperatureChartData(days: fiveDays, locale: Locale(identifier: "pt-BR"))

        XCTAssertEqual(points(data, series: TemperatureChartData.highSeries).map(\.value), [29, 27, 23, 25, 30])
        XCTAssertEqual(points(data, series: TemperatureChartData.lowSeries).map(\.value), [18, 18, 17, 16, 18])
    }

    func test_points_labelFirstDayAsHoje_andOthersWithThreeLetters() {
        let data = TemperatureChartData(days: fiveDays, locale: Locale(identifier: "pt-BR"))

        let labels = points(data, series: TemperatureChartData.highSeries).map(\.label)

        XCTAssertEqual(labels, ["Hoje", "Ter", "Qua", "Qui", "Sex"])
    }

    func test_points_maxAndMinOfTheSameDayShareTheSameLabel() {
        let data = TemperatureChartData(days: fiveDays, locale: Locale(identifier: "pt-BR"))

        let highLabels = points(data, series: TemperatureChartData.highSeries).map(\.label)
        let lowLabels = points(data, series: TemperatureChartData.lowSeries).map(\.label)

        // As duas linhas precisam usar as mesmas categorias do eixo X
        XCTAssertEqual(highLabels, lowLabels)
    }

    func test_points_idsAreUnique() {
        let data = TemperatureChartData(days: fiveDays)

        XCTAssertEqual(Set(data.points.map(\.id)).count, data.points.count)
    }

    func test_points_labelsDoNotCollideAcrossAWeekBoundary() {

        let days = [
            day("2026-11-13", "Sexta-Feira",   max: 30, min: 18),
            day("2026-11-14", "Sábado",        max: 31, min: 19),
            day("2026-11-15", "Domingo",       max: 29, min: 18),
            day("2026-11-16", "Segunda-Feira", max: 27, min: 17),
            day("2026-11-17", "Terça-Feira",   max: 26, min: 16)
        ]

        let labels = points(TemperatureChartData(days: days, locale: Locale(identifier: "pt-BR")), series: TemperatureChartData.highSeries).map(\.label)

        XCTAssertEqual(labels, ["Hoje", "Sáb", "Dom", "Seg", "Ter"])
        XCTAssertEqual(Set(labels).count, labels.count)
    }

    func test_points_withSingleDay_hasOnlyHoje() {
        let data = TemperatureChartData(days: [day("2026-11-09", "Segunda-Feira", max: 29, min: 18)], locale: Locale(identifier: "pt-BR"))

        XCTAssertEqual(data.points.count, 2)
        XCTAssertEqual(Set(data.points.map(\.label)), ["Hoje"])
    }

    func test_yDomain_addsPaddingAroundTheExtremes() {
        let data = TemperatureChartData(days: fiveDays)

        // Menor mínima = 16, maior máxima = 30; folga de 4 graus para cada lado
        XCTAssertEqual(data.yDomain.lowerBound, 12)
        XCTAssertEqual(data.yDomain.upperBound, 34)
    }

    func test_yDomain_handlesNegativeTemperatures() {
        let days = [
            day("2026-01-10", "Sábado", max: -2, min: -10),
            day("2026-01-11", "Domingo", max: 1, min: -8)
        ]

        let data = TemperatureChartData(days: days)

        XCTAssertEqual(data.yDomain.lowerBound, -14)
        XCTAssertEqual(data.yDomain.upperBound, 5)
    }

    func test_emptyDays_produceNoPoints_andADefaultDomain() {
        let data = TemperatureChartData(days: [])

        XCTAssertTrue(data.points.isEmpty)
        XCTAssertEqual(data.yDomain, 0...30)
    }
}
