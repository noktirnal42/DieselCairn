import SwiftUI

public enum DieselCairnBrand {
    public static let ink = Color(red: 0.055, green: 0.067, blue: 0.078)
    public static let panel = Color(red: 0.105, green: 0.12, blue: 0.132)
    public static let raised = Color(red: 0.145, green: 0.16, blue: 0.173)
    public static let border = Color.white.opacity(0.09)
    public static let accent = Color(red: 0.84, green: 0.53, blue: 0.19)
    static let actionFill = Color(red: 0.61, green: 0.34, blue: 0.10)
    public static let success = Color(red: 0.39, green: 0.65, blue: 0.47)
    public static let warning = Color(red: 0.84, green: 0.58, blue: 0.24)
    public static let danger = Color(red: 0.79, green: 0.34, blue: 0.31)
    public static let muted = Color.white.opacity(0.64)
    static let canvas = LinearGradient(
        colors: [Color(red: 0.082, green: 0.095, blue: 0.108), ink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

public struct BrandMark: View {
    public var size: CGFloat = 34
    public init(size: CGFloat = 34) { self.size = size }
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2).fill(DieselCairnBrand.ink)
            CairnGlyph().fill(Color(red: 0.81, green: 0.84, blue: 0.86))
                .padding(size * 0.2)
            Capsule().fill(DieselCairnBrand.accent)
                .frame(width: size * 0.08, height: size * 0.38)
                .offset(x: size * 0.26, y: size * 0.12)
        }
        .frame(width: size, height: size)
        .overlay(RoundedRectangle(cornerRadius: size * 0.2).stroke(DieselCairnBrand.border, lineWidth: 1))
        .accessibilityLabel("DieselCairn")
    }
}

private struct CairnGlyph: Shape {
    func path(in r: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: r.minX + r.width * x, y: r.minY + r.height * y)
        }
        return Path { p in
            p.move(to: point(0.50, 0.05)); p.addLine(to: point(0.62, 0.23)); p.addLine(to: point(0.38, 0.23)); p.closeSubpath()
            p.move(to: point(0.32, 0.29)); p.addLine(to: point(0.68, 0.29)); p.addLine(to: point(0.81, 0.50)); p.addLine(to: point(0.19, 0.50)); p.closeSubpath()
            p.move(to: point(0.18, 0.56)); p.addLine(to: point(0.82, 0.56)); p.addLine(to: point(0.94, 0.80)); p.addLine(to: point(0.06, 0.80)); p.closeSubpath()
        }
    }
}

struct SectionEyebrow: View {
    let text: String
    @ScaledMetric(relativeTo: .caption2) private var fontSize = 10.0

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: fontSize, weight: .semibold, design: .monospaced))
            .tracking(1.0)
            .foregroundStyle(DieselCairnBrand.muted)
    }
}

struct SurfaceCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(
                LinearGradient(
                    colors: [DieselCairnBrand.raised, DieselCairnBrand.panel],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(DieselCairnBrand.border, lineWidth: 1))
    }
}

struct StatusPill: View {
    let text: String
    let color: Color
    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text.uppercased()).font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(0.6)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(color.opacity(0.09), in: RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.32), lineWidth: 1))
        .foregroundStyle(color)
        .accessibilityElement(children: .combine)
    }
}
