import AppKit
import SwiftUI

/// Rasterises `MenuBarIconContent` into a fixed-size `NSImage` on demand.
///
/// `MenuBarExtra`'s label view does not reliably composite overlapping
/// SwiftUI content (the ring / second circle was being silently clipped).
/// Rendering to a concrete bitmap up front and handing that bitmap to
/// `Image(nsImage:)` sidesteps that entirely — what you render is exactly
/// what appears in the menu bar.
@MainActor
enum MenuBarIconRenderer {
    static func render(_ content: MenuBarIconContent) -> NSImage {
        let renderer = ImageRenderer(content: content.frame(
            width: MenuBarIconContent.size.width,
            height: MenuBarIconContent.size.height
        ))
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        renderer.isOpaque = false

        let image = renderer.nsImage ?? NSImage(size: MenuBarIconContent.size)
        image.isTemplate = true // let macOS tint it for light/dark menu bars
        return image
    }
}
