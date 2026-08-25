import CoreGraphics

enum TranslationCardLayout {
    /// Visible card width. The panel adds `shadowMargin` on every side so the
    /// drop shadow and rounded corners are never clipped by the window edge.
    static let cardWidth: CGFloat = 390
    static let shadowMargin: CGFloat = 6

    /// Full panel width, including the transparent margin around the card.
    static let width: CGFloat = cardWidth + shadowMargin * 2

    static let minimumHeight: CGFloat = 150
    static let maximumHeight: CGFloat = 560

    /// Maximum height of the scrollable original/translation region. The header
    /// and footer always stay outside it, so they are never clipped; only this
    /// middle section scrolls once the text grows beyond the cap.
    static let scrollSectionMaxHeight: CGFloat = 320

    static func panelSize(forMeasuredContentHeight measuredHeight: CGFloat) -> CGSize {
        CGSize(
            width: width,
            height: min(max(measuredHeight, minimumHeight), maximumHeight)
        )
    }
}
