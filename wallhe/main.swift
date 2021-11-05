//
//  main.swift
//  wallhe
//
//  Created by Aniello Di Meglio (Admin) on 2021-11-03.
//

import Foundation
import SwiftUI
import CoreGraphics

func setBackground(theURL: String) {
    let workspace = NSWorkspace()
    let fixedURL = URL(string: theURL)
    //let imageScaling: NSWorkspace.DesktopImageOptionKey
    var options = [NSWorkspace.DesktopImageOptionKey: Any]()
    options[.imageScaling] = NSImageScaling.scaleProportionallyUpOrDown.rawValue
    options[.allowClipping] = false
    do {
//        try workspace.setDesktopImageURL(fixedURL!, for: NSScreen.screens[1])
        try workspace.setDesktopImageURL(fixedURL!, for: NSScreen.screens[1], options: options)
    } catch {print("duh")}
}

func buildWallpaper(sample: NSImage, sample2: NSImage, desktopSize: NSSize) -> NSImage {
    //  Converted to Swift 5.5 by Swiftify v5.5.22755 - https://swiftify.com/
    let resultImage = NSImage(size: (NSMakeSize(1920,1080)))
    resultImage.lockFocus()
    //let sample2 = sample
    //var anotherImage = NSImage(contentsOf: sample1)
    sample.draw(at: NSPoint(x: 0, y: 0), from: NSRect.zero, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
   
    sample.draw(at: NSPoint(x: sample.size.width, y: 0), from: NSRect.zero, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
    sample.draw(at: NSPoint(x: sample.size.width * 2, y: 0), from: NSRect(x: 0, y:0, width: (1920 - sample.size.width * 2), height: 1080), operation: NSCompositingOperation.sourceOver, fraction: 1.0)
    // sample2.draw(at: NSPoint(x: 1000, y: 0), from: NSRect.zero, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
     // Or any of the other about 6 options; see Apple's guide to pick.
    //anotherImage = NSImage(contentsOf: sample2)

    resultImage.unlockFocus()
    return resultImage
}

extension NSScreen{
    static let screenWidth = NSScreen.main?.frame.width
    static let screenHeight = NSScreen.main?.frame.height
    static let screenSize = NSScreen.main?.frame.size
}

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}

func resizedImage(at url: URL, for size: CGSize) -> NSImage? {
    guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
        let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    else {
        return nil
    }

    let context = CGContext(data: nil,
                            width: Int(size.width),
                            height: Int(size.height),
                            bitsPerComponent: image.bitsPerComponent,
                            bytesPerRow: 0,
                            space: image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: image.bitmapInfo.rawValue)
    context?.interpolationQuality = .high
    context?.draw(image, in: CGRect(origin: .zero, size: size))

    guard let scaledImage = context?.makeImage() else { return nil }

    return NSImage(cgImage: scaledImage,
                   size: CGSize(width: size.width,height: size.height))
}

let dirName = "file:///Users/dimeglio/Downloads/kc_nemutai-13/"

//let theURL = URL(string: "file:///Users/dimeglio/Downloads/kc_nemutai-13/kc_nemutai-1400405510063411204-20210603_065426-img2.jpg")
let theURL = URL(string: "file:///Users/dimeglio/Downloads/kc_nemutai-13/kc_nemutai-1405485960968556546-20210617_072220-img1.jpg")
let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!

let origImage = NSImage(contentsOf: theURL!)
let height = origImage!.size.height
let ratio = 1080.0 / height
let newWidth = (origImage!.size.width) * ratio

let newImage = resizedImage(at: theURL!, for: CGSize(width: newWidth, height: 1080))
let imageSize = newImage?.size.height
let finalImage = buildWallpaper(sample: newImage!, sample2: newImage!, desktopSize: NSSize(width: 1920, height: 1080))
let destinationURL: URL = desktopURL.appendingPathComponent("my-image23.png")
if finalImage.pngWrite(to: destinationURL) {
    print("File saved")
}

setBackground(theURL: (destinationURL.absoluteString))

