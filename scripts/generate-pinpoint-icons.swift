#!/usr/bin/env swift
import AppKit
let sizes = ["20x20":20,"20x20@2x":40,"20x20@3x":60,"29x29":29,"29x29@2x":58,"29x29@3x":87,"40x40":40,"40x40@2x":80,"40x40@3x":120,"60x60@2x":120,"60x60@3x":180,"76x76":76,"76x76@2x":152,"83.5x83.5@2x":167]
func render(_ size: Int, _ path: String) throws {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let scale = CGFloat(size) / 1024
    let transform = NSAffineTransform()
    transform.scale(by: scale)
    transform.concat()
    NSColor(srgbRed: 0.04, green: 0.08, blue: 0.15, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x:0,y:0,width:1024,height:1024)).fill()
    NSColor(srgbRed: 0.16, green: 0.28, blue: 0.38, alpha: 1).setStroke()
    for r in [260.0,330.0] {
        let ring = NSBezierPath(ovalIn: NSRect(x:512-r,y:544-r,width:r*2,height:r*2))
        ring.lineWidth = 5
        ring.stroke()
    }
    let pin = NSBezierPath()
    pin.move(to: NSPoint(x:512,y:234))
    pin.curve(to: NSPoint(x:300,y:604), controlPoint1:NSPoint(x:450,y:324), controlPoint2:NSPoint(x:300,y:470))
    pin.curve(to: NSPoint(x:724,y:604), controlPoint1:NSPoint(x:300,y:887), controlPoint2:NSPoint(x:724,y:887))
    pin.curve(to: NSPoint(x:512,y:234), controlPoint1:NSPoint(x:724,y:470), controlPoint2:NSPoint(x:574,y:324))
    pin.close()
    NSColor(srgbRed:0.22,green:0.74,blue:0.97,alpha:1).setFill()
    pin.fill()
    NSColor(srgbRed:0.06,green:0.14,blue:0.24,alpha:1).setFill()
    NSBezierPath(ovalIn:NSRect(x:420,y:512,width:184,height:184)).fill()
    NSColor.white.setFill()
    NSBezierPath(ovalIn:NSRect(x:478,y:570,width:68,height:68)).fill()
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: NSBitmapImageRep.FileType.png,properties:[:])!.write(to:URL(fileURLWithPath:path))
}
for (name,size) in sizes { try render(size,"Waypoint/AppIcons/AppIcon\(name).png") }
try render(1024,"Waypoint/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
