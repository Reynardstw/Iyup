import SwiftUI

struct ParkDetailSheetContent: View {
    let detent: PresentationDetent
    let peekDetent: PresentationDetent
    let largeDetent: PresentationDetent
    let info: ParkDetailInfo
    let onPlanTrip: () -> Void
    let onSelectDay: (Int) -> Void

    private let accent = Color(red: 0.60, green: 0.22, blue: 0.92)

    private var isLarge: Bool { detent == largeDetent }
    private var isPeek: Bool { detent == peekDetent }

    @State private var isHoursExpanded = false

    private var cardBackground: AnyShapeStyle {
        isLarge ? AnyShapeStyle(Color.white.opacity(0.58)) : AnyShapeStyle(.thinMaterial)
    }

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let revealStart: CGFloat = 110
            let revealEnd: CGFloat = 200
            let progress = min(1, max(0, (height - revealStart) / (revealEnd - revealStart)))

            VStack(spacing: 0) {
                header

                planTripButton
                    .opacity(progress)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        infoRow
                        weatherCards
                        popularTimesCard
                        addressCard
                        outfitCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 40)
                }
                .scrollDisabled(!isLarge)
                .scrollContentBackground(.hidden)
                .opacity(progress)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(isLarge ? Color(.systemGroupedBackground) : Color.clear)
        }
    }

    private var header: some View {
        VStack(spacing: 3) {
            Text(info.name)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.primary)

            Text(info.city)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, isPeek ? 17 : 29)
    }

    private var planTripButton: some View {
        Button(action: onPlanTrip) {
            Text("Plan Trip")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(accent)
                .clipShape(Capsule())
                .glassEffect(.regular, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var infoRow: some View {
        HStack(spacing: 0) {
            infoGlassSegment(title: "Entrance", value: info.entrance, color: .primary)

            infoGlassDivider

            infoGlassSegment(title: "Hours", value: info.hoursLabel, color: info.isOpen ? .green : .red)

            infoGlassDivider

            infoGlassSegment(title: "Distance", value: "\(info.distanceKm) km", color: .primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 66)
        .background(Color.white.opacity(0.20))
        .clipShape(Capsule())
        .glassEffect(.regular, in: Capsule())
    }

    private func infoGlassSegment(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 66)
        .contentShape(Rectangle())
    }

    private var infoGlassDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.09))
            .frame(width: 1)
            .padding(.vertical, 14)
    }

    private var weatherCards: some View {
        HStack(spacing: 14) {
            metricCard(icon: "thermometer.medium", label: "Temperature", value: "\(info.temperatureCelsius)°")
            metricCard(icon: "humidity.fill", label: "Humidity", value: "\(info.humidityPercent)%")
        }
    }

    private func metricCard(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.primary)

            Text(value)
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var popularTimesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                Text("Popular Times")
                    .font(.headline)
            }
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

                crowdBars
            }
            .padding(12)
            .background(Color.white.opacity(0.72))
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
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var dayTabs: some View {
        HStack {
            ForEach(Array(["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"].enumerated()), id: \.offset) { index, day in
                Button {
                    onSelectDay(index)
                } label: {
                    VStack(spacing: 4) {
                        Text(day)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(index == info.todayIndex ? accent : .secondary)

                        Rectangle()
                            .fill(index == info.todayIndex ? accent : .clear)
                            .frame(width: 18, height: 2)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var crowdBars: some View {
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(info.popularToday) { slot in
                RoundedRectangle(cornerRadius: 3)
                    .fill(slot.isNow ? Color.red.opacity(0.7) : Color.blue.opacity(0.45))
                    .frame(height: max(6, CGFloat(slot.level) * 70))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 86)
        .overlay(alignment: .bottom) {
            HStack {
                Text("6a")
                Spacer()
                Text("9a")
                Spacer()
                Text("12p")
                Spacer()
                Text("3p")
                Spacer()
                Text("6p")
                Spacer()
                Text("9p")
            }
            .font(.system(size: 8))
            .foregroundStyle(.secondary)
            .offset(y: 12)
        }
        .padding(.bottom, 14)
    }

    private var addressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHoursExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "clock")
                        .foregroundStyle(.green)
                    Text(info.openHoursDetail)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.green)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isHoursExpanded ? 180 : 0))
                }
            }
            .buttonStyle(.plain)

            if isHoursExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], id: \.self) { day in
                        HStack {
                            Text(day)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(info.openHoursDetail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()

            Button {
                openInAppleMaps()
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.primary)
                        .padding(.top, 2)
                    Text(info.address)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.blue)
                        .multilineTextAlignment(.leading)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var outfitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb")
                    .font(.title3)
                Text(info.outfitHeadline)
                    .font(.subheadline.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Text("Style it with:")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 26) {
                ForEach(info.outfitEmojis, id: \.self) { emoji in
                    Text(emoji)
                        .font(.system(size: 40))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func openInAppleMaps() {
        let query = "\(info.name), \(info.address)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "maps://?q=\(encodedQuery)") else { return }
        UIApplication.shared.open(url)
    }
}
