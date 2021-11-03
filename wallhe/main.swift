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
    do {
        try workspace.setDesktopImageURL(fixedURL!, for: NSScreen.screens[1])
    } catch {print("duh")}
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

let theURL = URL(string: "file:///Users/dimeglio/Downloads/kc_nemutai-13/kc_nemutai-1371059354284093441-20210314_072317-img1.jpg")

let newImage = resizedImage(at: theURL!, for: CGSize(width: 1920, height: 1080))
let imageSize = newImage?.size.height
let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
let destinationURL: URL = desktopURL.appendingPathComponent("my-image.png")
if newImage!.pngWrite(to: destinationURL) { //, options: .withoutOverwriting) {
            print("File saved")
        }
print("Hello, World!")
print(imageSize!,  newImage?.size.width as Any)

setBackground(theURL: (destinationURL.absoluteString))

