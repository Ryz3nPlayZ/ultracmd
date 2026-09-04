import SwiftUI

/// Alpha mask that dissolves scrolling content under the floating search
/// bar (top) and the footer (bottom). Rows fade to transparent instead of
/// sliding under dim gradient bands — no darkened rectangles.
///
/// Top values are measured from the top edge of the modified view; bottom
/// values from the bottom edge. Content inside a fade band interpolates
/// from hidden to opaque; content fully inside the hidden extents is both
/// invisible and non-hit-testable (the mask clips pointer hits too).
struct EdgeFadeModifier: ViewModifier {
    /// Content above this y (from the top) is fully hidden.
    var topHiddenUntil: CGFloat
    /// Content below this y is fully opaque.
    var topOpaqueFrom: CGFloat
    /// Fade-to-hidden starts this far above the bottom edge.
    var bottomOpaqueUntil: CGFloat
    /// Content closer than this to the bottom edge is fully hidden.
    var bottomHiddenFrom: CGFloat

    func body(content: Content) -> some View {
        GeometryReader { geo in
            let h = max(geo.size.height, 1)
            content.mask(
                LinearGradient(
                    stops: stops(height: h),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private func stops(height h: CGFloat) -> [Gradient.Stop] {
        // Clamp to strictly-increasing locations so short views degenerate
        // gracefully instead of producing a zero-length ramp.
        var previous: Double = 0
        func loc(_ value: CGFloat) -> Double {
            let clamped = min(max(Double(value / h), previous + 0.002), 1)
            previous = clamped
            return clamped
        }
        let topHidden = loc(topHiddenUntil)
        let topOpaque = loc(topOpaqueFrom)
        let bottomOpaque = loc(h - bottomOpaqueUntil)
        let bottomHidden = loc(h - bottomHiddenFrom)
        return [
            .init(color: .clear, location: 0),
            .init(color: .clear, location: topHidden),
            .init(color: .black, location: topOpaque),
            .init(color: .black, location: bottomOpaque),
            .init(color: .clear, location: bottomHidden),
            .init(color: .clear, location: 1),
        ]
    }
}

extension View {
    func edgeFade(
        topHiddenUntil: CGFloat,
        topOpaqueFrom: CGFloat,
        bottomOpaqueUntil: CGFloat,
        bottomHiddenFrom: CGFloat
    ) -> some View {
        modifier(EdgeFadeModifier(
            topHiddenUntil: topHiddenUntil,
            topOpaqueFrom: topOpaqueFrom,
            bottomOpaqueUntil: bottomOpaqueUntil,
            bottomHiddenFrom: bottomHiddenFrom
        ))
    }

    /// Liquid Glass surface (swiftliquidglass.md / appkitliquidglass.md):
    /// on macOS 26 the real `glassEffect` material; on older systems a
    /// vibrancy-material stand-in with a hairline rim. No drop shadows —
    /// per apple.md, shadowing a material defeats the blur.
    @ViewBuilder
    func liquidGlass<S: InsettableShape>(in shape: S, interactive: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            self.background(
                shape
                    .fill(.ultraThinMaterial)
                    .overlay(shape.fill(Color.black.opacity(0.22)))
                    .overlay(shape.strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5))
            )
        }
    }

    /// Capsule variant for floating chrome (footer pills, dock buttons).
    func liquidGlassCapsule(interactive: Bool = false) -> some View {
        liquidGlass(in: Capsule(), interactive: interactive)
    }

    /// Rounded-rect variant for panels, menus and cards.
    func liquidGlassCard(cornerRadius: CGFloat = 14, interactive: Bool = false) -> some View {
        liquidGlass(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), interactive: interactive)
    }

    /// Never show scroll chrome anywhere in the HUD surfaces (issue #2).
    func noScrollIndicators() -> some View {
        self.scrollIndicators(.never)
    }
}
