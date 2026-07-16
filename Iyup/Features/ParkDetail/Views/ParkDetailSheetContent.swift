import SwiftUI
import Charts

struct ParkDetailSheetContent: View {
    let detent: PresentationDetent
    let peekDetent: PresentationDetent
    let largeDetent: PresentationDetent
    let info: ParkDetailInfo
    let onPlanTrip: () -> Void
    let onSelectDay: (Int) -> Void

    private var isLarge: Bool { detent == largeDetent }

    @ScaledMetric(relativeTo: .largeTitle) private var metricValueSize: CGFloat = 40
    @ScaledMetric(relativeTo: .title3) private var headerTitleSize: CGFloat = 20

    private var cardBackground: Color {
        Color(.secondarySystemGroupedBackground)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    planTripButton
                    infoRow
                    weatherCards
                    popularTimesCard
                    addressCard
                    outfitCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .scrollDisabled(!isLarge)
            .background(isLarge ? Color(.systemGroupedBackground) : Color.clear)
            .navigationTitle(info.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationSubtitle(info.city)
        }
    }

    // MARK: - Pinned CTA

    private var planTripButton: some View {
        Button(action: onPlanTrip) {
            Text("Plan Trip")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
        }
        .buttonStyle(.glassProminent)
        .tint(.accentColor)
    }

    // MARK: - Info capsule (custom shell)

    private var infoRow: some View {
        HStack(spacing: 0) {
            infoSegment(title: "Entrance", value: info.entrance, color: .primary)
            infoSegment(title: "Hours", value: info.hoursLabel, color: info.isOpen ? .green : .red)
            infoSegment(title: "Distance", value: "\(info.distanceKm) km", color: .primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 66)
        .background(cardBackground)
        .clipShape(Capsule())
    }

    private func infoSegment(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.callout.weight(.medium))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 66)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Metrics (custom shells, side by side)

    private var weatherCards: some View {
        HStack(spacing: 14) {
            metricCard(icon: "thermometer.medium", label: "Temperature", value: "\(info.temperatureCelsius)°")
            metricCard(icon: "humidity.fill", label: "Humidity", value: "\(info.humidityPercent)%")
        }
    }

    private func metricCard(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 12) {
            Label(label, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            Text(value)
                .font(.system(size: metricValueSize, weight: .regular))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Popular Times (custom shell, native innards)

    private var popularTimesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Popular Times", systemImage: "person.3.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(spacing: 10) {
                dayTabs

                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.red.opacity(0.75))
                    Text("Live: Busier than usual")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)
                .accessibilityElement(children: .combine)

                Chart(Array(info.popularToday.enumerated()), id: \.offset) { index, slot in
                    BarMark(
                        x: .value("Hour", hourLabel(forSlot: index)),
                        y: .value("Crowd", slot.level)
                    )
                    .foregroundStyle(slot.isNow ? Color.red.opacity(0.7) : Color.blue.opacity(0.45))
                    .cornerRadius(3)
                }
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: labeledHours) { _ in
                        AxisValueLabel(centered: true)
                            .font(.caption2)
                    }
                }
                .frame(height: 92)
                .accessibilityLabel("Crowd levels throughout the day")
            }
            .padding(12)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 7) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.secondary)
                Text("Recommended hours for optimal shade \(info.recommendedShadeWindow)")
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var dayTabs: some View {
        HStack {
            ForEach(Array(["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"].enumerated()), id: \.offset) { index, day in
                Button {
                    onSelectDay(index)
                } label: {
                    VStack(spacing: 4) {
                        Text(day)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(index == info.todayIndex ? Color.accentColor : .secondary)

                        Capsule()
                            .fill(index == info.todayIndex ? Color.accentColor : .clear)
                            .frame(width: 18, height: 2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(fullDayName(index))
                .accessibilityAddTraits(index == info.todayIndex ? [.isSelected] : [])
            }
        }
    }

    private func fullDayName(_ index: Int) -> String {
        ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][index]
    }

    /// Hour categories that get an axis label (every 3rd slot).
    private var labeledHours: [String] {
        stride(from: 0, to: info.popularToday.count, by: 3).map { hourLabel(forSlot: $0) }
    }

    private var axisSlotValues: [Int] {
        let count = info.popularToday.count
        guard count > 0 else { return [] }
        var values = Array(stride(from: 0, to: count, by: 3))
        if values.last != count - 1 {
            values.append(count - 1)
        }
        return values
    }

    /// Slots start at 6 AM, 1 hour each.
    private func hourLabel(forSlot index: Int) -> String {
        let hour = (6 + index) % 24
        switch hour {
        case 0: return "12a"
        case 12: return "12p"
        case 1...11: return "\(hour)a"
        default: return "\(hour - 12)p"
        }
    }

    // MARK: - Hours + Address (custom shell, native innards)

    private var addressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], id: \.self) { day in
                        LabeledContent(day, value: info.openHoursDetail)
                            .font(.footnote)
                    }
                }
                .padding(.top, 8)
            } label: {
                Label {
                    Text(info.openHoursDetail)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(info.isOpen ? .green : .red)
                } icon: {
                    Image(systemName: "clock")
                        .foregroundStyle(info.isOpen ? .green : .red)
                }
            }
            .tint(.secondary)

            Divider()

            Button {
                openInAppleMaps()
            } label: {
                Label {
                    Text(info.address)
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.leading)
                } icon: {
                    Image(systemName: "mappin.and.ellipse")
                }
            }
            .buttonStyle(.borderless)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Outfit (custom shell)

    private var outfitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(info.outfitHeadline)
                    .font(.subheadline.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "lightbulb")
            }

            Divider()

            Text("Style it with:")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 26) {
                ForEach(info.outfitEmojis, id: \.self) { emoji in
                    Text(emoji)
                        .font(.largeTitle)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func openInAppleMaps() {
        let query = "\(info.name), \(info.address)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "maps://?q=\(encodedQuery)") else { return }
        UIApplication.shared.open(url)
    }
}
