import SwiftUI

struct ParkDetailSheetContent: View {
    let detent: PresentationDetent
    let peekDetent: PresentationDetent
    let largeDetent: PresentationDetent
    let info: ParkDetailInfo
    let onPlanTrip: () -> Void
    let onSelectDay: (Int) -> Void

    private let accent = Color(red: 0.49, green: 0.36, blue: 0.96)

    private var isLarge: Bool { detent == largeDetent }
    private var isPeek: Bool { detent == peekDetent }
    @State private var isHoursExpanded = false

    private var cardBackground: AnyShapeStyle {
        isLarge ? AnyShapeStyle(Color(.secondarySystemGroupedBackground)) : AnyShapeStyle(.thinMaterial)
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

                ScrollView {
                    VStack(spacing: 16) {
                        infoRow
                        weatherCards
                        outfitCard
                        popularTimesCard
                        addressCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
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
        VStack(spacing: 2) {
            Text(info.name)
                .font(.title3.bold())
                .font(.system(size: 17))
            Text(info.city)
                .font(.subheadline)
                .font(.system(size:15))
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
                .frame(height: 52)
                .background(accent)
                .clipShape(RoundedRectangle(cornerRadius: 26))
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var infoRow: some View {
        HStack(spacing:41) {
            infoColumn(title: "Entrance", value: info.entrance, color: .primary)
            
            infoColumn(title: "Hours", value: info.hoursLabel, color: info.isOpen ? .green : .red)
            
            infoColumn(title: "Distance", value: "\(info.distanceKm) km", color: .primary)
        }
        .padding(.horizontal, 66)
    }

    private func infoColumn(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .font(.system(size:15))
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
                .font(.system(size:17))
        }
    }

    private var weatherCards: some View {
        HStack(spacing: 14) {
            metricCard(icon: "thermometer.medium", label: "Temperature", value: "\(info.temperatureCelsius)°")
            metricCard(icon: "humidity.fill", label: "Humidity", value: "\(info.humidityPercent)%")
        }
    }

    private func metricCard(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 40, weight: .regular))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var outfitCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(info.outfitHeadline)
                .font(.subheadline)

            Divider().font(.system(size : 2,weight:.bold))

            Text("Style it with:")
                .font(.subheadline.weight(.medium))

            HStack(spacing: 22) {
                ForEach(info.outfitEmojis, id: \.self) { emoji in
                    Text(emoji)
                        .font(.system(size: 50))
                }
            }.padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal,18)
        .padding(.top,14)
        .padding(.bottom,24)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var popularTimesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                Text("Popular Times")
                    .font(.headline)
            }

            dayTabs
            crowdBars

            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                Text("Recommended hours for optimal shade \(info.recommendedShadeWindow)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
                                .foregroundStyle(index == info.todayIndex ? accent : .secondary)
                            Circle()
                                .fill(index == info.todayIndex ? accent : .clear)
                                .frame(width: 4, height: 4)
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
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(slot.isNow ? Color.orange : accent.opacity(0.35))
                            .frame(height: max(6, CGFloat(slot.level) * 70))
                            .frame(maxWidth: .infinity)

                        Text("\(slot.hour)")
                            .font(.system(size: 9))
                            .foregroundStyle(slot.isNow ? .orange : .secondary)
                    }
                }
            }
            .frame(height: 90)
        }
    
    private func openInAppleMaps() {
            let query = "\(info.name), \(info.address)"
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            guard let url = URL(string: "maps://?q=\(encodedQuery)") else { return }
            UIApplication.shared.open(url)
        }
    
    private var addressCard: some View {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHoursExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.green)
                        Text(info.openHoursDetail)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.green)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.footnote)
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
                                        .foregroundStyle(.secondary)
                                    Text(info.address)
                                        .font(.subheadline)
                                        .foregroundStyle(Color(red: 0.20, green: 0.40, blue: 0.90))
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
}
