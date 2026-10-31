import AppKit
let size = 1024
import UniformTypeIdentifiers
let cg = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: false)
func c(_ h: UInt32) -> NSColor { NSColor(srgbRed: CGFloat((h>>16)&255)/255, green: CGFloat((h>>8)&255)/255, blue: CGFloat(h&255)/255, alpha: 1) }
c(0xFFF3DC).setFill(); NSRect(x: 0, y: 0, width: size, height: size).fill()
// soft ground
c(0xF6E2B8).setFill(); NSBezierPath(ovalIn: NSRect(x: 132, y: 70, width: 760, height: 150)).fill()
// the numeral
let base = NSFont.systemFont(ofSize: 640, weight: .black)
let font = NSFont(descriptor: base.fontDescriptor.withDesign(.rounded)!, size: 640)!
let str = NSAttributedString(string: "2", attributes: [.font: font, .foregroundColor: c(0x2F6FD6)])
let b = str.boundingRect(with: NSSize(width: 2000, height: 2000), options: [.usesLineFragmentOrigin])
str.draw(at: NSPoint(x: (CGFloat(size) - b.width) / 2 - b.minX, y: 108))
// the sprout: stem from the top of the 2, two leaves
let green = c(0x2E9E5B)
let stem = NSBezierPath(); stem.move(to: NSPoint(x: 520, y: 740)); stem.curve(to: NSPoint(x: 512, y: 905), controlPoint1: NSPoint(x: 545, y: 800), controlPoint2: NSPoint(x: 490, y: 850))
stem.lineWidth = 34; stem.lineCapStyle = .round; green.setStroke(); stem.stroke()
func leaf(_ tip: NSPoint, _ c1: NSPoint, _ c2: NSPoint, _ c3: NSPoint, _ c4: NSPoint) {
  let p = NSBezierPath(); let o = NSPoint(x: 512, y: 900); p.move(to: o)
  p.curve(to: tip, controlPoint1: c1, controlPoint2: c2); p.curve(to: o, controlPoint1: c3, controlPoint2: c4); p.close(); green.setFill(); p.fill()
}
leaf(NSPoint(x: 330, y: 975), NSPoint(x: 460, y: 1000), NSPoint(x: 380, y: 1010), NSPoint(x: 330, y: 900), NSPoint(x: 420, y: 880))
c(0x5FD08A).setFill()
let p2 = NSBezierPath(); let o = NSPoint(x: 512, y: 900); p2.move(to: o)
p2.curve(to: NSPoint(x: 720, y: 990), controlPoint1: NSPoint(x: 560, y: 1010), controlPoint2: NSPoint(x: 660, y: 1020)); p2.curve(to: o, controlPoint1: NSPoint(x: 730, y: 905), controlPoint2: NSPoint(x: 610, y: 870)); p2.close(); p2.fill()
NSGraphicsContext.current?.flushGraphics()
let img = cg.makeImage()!
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil); CGImageDestinationFinalize(dest)
