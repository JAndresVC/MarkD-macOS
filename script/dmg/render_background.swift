import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

precondition(CommandLine.arguments.count == 2, "Usage: render_background output.png")
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let context = CGContext(data: nil, width: 1320, height: 800,
                        bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
context.scaleBy(x: 2, y: 2)
context.setFillColor(CGColor(colorSpace: colorSpace, components: [0.945, 0.945, 0.961, 1])!)
context.fill(CGRect(x: 0, y: 0, width: 660, height: 400))
context.setStrokeColor(CGColor(gray: 0.04, alpha: 1))
context.setLineWidth(7)
context.setLineCap(.round)
context.setLineJoin(.round)
context.move(to: CGPoint(x: 321, y: 181))
context.addLine(to: CGPoint(x: 340, y: 200))
context.addLine(to: CGPoint(x: 321, y: 219))
context.strokePath()

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, context.makeImage()!, [
    kCGImagePropertyDPIWidth: 144, kCGImagePropertyDPIHeight: 144
] as CFDictionary)
precondition(CGImageDestinationFinalize(destination), "Could not write the installer background")
