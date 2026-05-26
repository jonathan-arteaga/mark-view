#!/usr/bin/env swift
import AppKit

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: generate_dmg_background.swift OUTPUT_PNG\n", stderr)
    exit(64)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let canvasSize = NSSize(width: 660, height: 380)
let image = NSImage(size: canvasSize)

image.lockFocus()

NSColor(calibratedWhite: 0.965, alpha: 1).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()

let titleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 26, weight: .semibold),
    .foregroundColor: NSColor.labelColor,
    .paragraphStyle: {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        return style
    }()
]

let subtitleAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 14, weight: .regular),
    .foregroundColor: NSColor.secondaryLabelColor,
    .paragraphStyle: {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        return style
    }()
]

"Install QuillLook".draw(
    in: NSRect(x: 0, y: 305, width: canvasSize.width, height: 34),
    withAttributes: titleAttributes
)

"Drag the app into Applications.".draw(
    in: NSRect(x: 0, y: 278, width: canvasSize.width, height: 22),
    withAttributes: subtitleAttributes
)

let arrow = NSBezierPath()
arrow.move(to: NSPoint(x: 285, y: 170))
arrow.line(to: NSPoint(x: 375, y: 170))
arrow.move(to: NSPoint(x: 360, y: 184))
arrow.line(to: NSPoint(x: 378, y: 170))
arrow.line(to: NSPoint(x: 360, y: 156))
arrow.lineWidth = 2.5
NSColor.separatorColor.withAlphaComponent(0.85).setStroke()
arrow.stroke()

image.unlockFocus()

guard
    let tiffData = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiffData),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Failed to render DMG background.\n", stderr)
    exit(1)
}

do {
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try pngData.write(to: outputURL, options: .atomic)
} catch {
    fputs("Failed to write DMG background: \(error)\n", stderr)
    exit(1)
}
