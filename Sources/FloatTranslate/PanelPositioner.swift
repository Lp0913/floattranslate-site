import CoreGraphics

enum PanelPositioner {
    static let cursorSpacing: CGFloat = 14
    static let screenInset: CGFloat = 12

    static func origin(
        near cursor: CGPoint,
        panelSize: CGSize,
        visibleFrame: CGRect
    ) -> CGPoint {
        var x = cursor.x + cursorSpacing
        var y = cursor.y - panelSize.height - cursorSpacing

        if x + panelSize.width > visibleFrame.maxX - screenInset {
            x = cursor.x - panelSize.width - cursorSpacing
        }
        if y < visibleFrame.minY + screenInset {
            y = cursor.y + cursorSpacing
        }

        x = min(max(x, visibleFrame.minX + screenInset), visibleFrame.maxX - panelSize.width - screenInset)
        y = min(max(y, visibleFrame.minY + screenInset), visibleFrame.maxY - panelSize.height - screenInset)
        return CGPoint(x: x, y: y)
    }
}
