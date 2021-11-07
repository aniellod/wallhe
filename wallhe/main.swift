//
//  main.swift
//  wallhe requires MacOS 10.15+
//
//  Swift 5
//
//  Created by Aniello Di Meglio on 2021-11-03.
//
//  Parts were converted to Swift 5.5 by Swiftify v5.5.22755 - https://swiftify.com/
//

import Foundation
import SwiftUI
import CoreGraphics

// setBackground: input=path to prepared image file. Updates the display with the new wallpaper on all screens.
func setBackground(theURL: String) {
    let workspace = NSWorkspace()
    let fixedURL = URL(string: theURL)
    var options = [NSWorkspace.DesktopImageOptionKey: Any]()
    options[.imageScaling] = NSImageScaling.scaleProportionallyUpOrDown.rawValue
    options[.allowClipping] = false
    let theScreens = NSScreen.screens
    for x in theScreens {
        do {
        try workspace.setDesktopImageURL(fixedURL!, for: x, options: options)
        } catch {print("Unable to update wallpaper!")}
    }
}

// fileName: outputs the filename to use. Can't use the same as MacOS will not update it otherwise.
func fileName() -> String {
    var fileName = "wallhe-wallpaper1.png"
    let path = NSSearchPathForDirectoriesInDomains(.picturesDirectory, .userDomainMask, true)[0] as String
    let url = NSURL(fileURLWithPath: path)
    if let pathComponent = url.appendingPathComponent(fileName) {
        let filePath = pathComponent.path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath) {
            fileName = "wallhe-wallpaper2.png"
            let deleted = FileManager()
            do {
                let fileToDeleteURL = url.appendingPathComponent("wallhe-wallpaper1.png")
                try deleted.removeItem(at: fileToDeleteURL!)
               } catch { print(error) }
        } else {
            fileName = "wallhe-wallpaper1.png"
            do {
                let deleted = FileManager()
                let fileToDeleteURL = url.appendingPathComponent("wallhe-wallpaper2.png")
                try deleted.removeItem(at: fileToDeleteURL!)
               } catch { print(error) }
        }
    }
    return fileName
}

// buildWallpaper: input is the image; output is the tiled wallpaper ready to go.
func buildWallpaper(sample: NSImage) -> NSImage {
    let screenSize = NSScreen.screenSize
    let sw = screenSize!.width
    let sh = screenSize!.height
    let tiles = Int(sw / sample.size.width)
    let resultImage = NSImage(size: (NSMakeSize(sw,sh)))
    
    resultImage.lockFocus()
    do {
        for x in 0...tiles {
            sample.draw(at: NSPoint(x: Int(sample.size.width) * x, y: 0), from: NSRect.zero, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
        }
        sample.draw(at: NSPoint(x: Int(sample.size.width) * tiles, y: 0), from: NSRect(x: 0, y:0, width: (sw - sample.size.width * 2), height: sh), operation: NSCompositingOperation.sourceOver, fraction: 1.0)
    }
    resultImage.unlockFocus()
    
    return resultImage
}

// extention to NSScreen to provide easy access screen to dimenstions
extension NSScreen{
    static let screenWidth = NSScreen.main?.frame.width
    static let screenHeight = NSScreen.main?.frame.height
    static let screenSize = NSScreen.main?.frame.size
}

// extension to NSImage to write PNG formatted images for the wallpaper
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

// resizedImage: input = URL of input image; size = new size of image; output = new resized image
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

// updateWallpaper: input path to image
func updateWallpaper(path: String) {
    let desktopURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
    let destinationURL: URL = desktopURL.appendingPathComponent(fileName())
    
    let theURL = URL(string: path)

    let origImage = NSImage(contentsOf: theURL!)
    let height = origImage!.size.height
    let ratio = NSScreen.screenHeight! / height
    let newWidth = (origImage!.size.width) * ratio

    let newImage = resizedImage(at: theURL!, for: CGSize(width: newWidth, height: 1080))
    let finalImage = buildWallpaper(sample: newImage!)
    
    guard finalImage.pngWrite(to: destinationURL) else {
        print("File count not be saved")
        return
    }
    setBackground(theURL: (destinationURL.absoluteString))
}

// begin "main" section

// set-up location where to read image files from
var debug:Bool = false
let filemgr = FileManager.default
var dirName = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!.path + "/"

// look to see if there is a command-line argument (at this time only -d is supported).
let argument = CommandLine.arguments

if argument.count != 1 {
    var isDir: ObjCBool = false
    if argument[1] == "-d" {
        guard filemgr.fileExists(atPath: argument[2], isDirectory: &isDir)
        else {
            print()
            print("Can't find directory \(argument[2])")
            print("Usage: wallhe -d \"/User/directory/where great/images/are\"")
            print()
            exit(1)
        }
        dirName = argument[2] + "/"
    } else {
        print()
        print("Usage: wallhe -d \"/User/directory/where great/images/are\"")
        print()
        exit(1)
    }
}

// we should have a directory
let directoryURL = URL(string: dirName)!

do {
    let filelist = try filemgr.contentsOfDirectory(atPath: dirName)
    if debug { print("filelist count = \(filelist.count)") }
    guard filelist.count > 0 else {
        print()
        print("No images found in directory \(directoryURL)")
        exit(1)
    }
    
    var pickedFile: String
    var checkRange: Int = 0
    repeat {
        pickedFile =  dirName + filelist.randomElement()!
        checkRange+=1
        guard checkRange<=filelist.count else {
            print()
            print("No images found in directory \(directoryURL)")
            exit(1)
        }
    } while (!(pickedFile.lowercased().contains(".jpg") || pickedFile.lowercased().contains(".jpeg") || pickedFile.lowercased().contains(".png")))
    
    let theNextUrl = "file://" + pickedFile
    updateWallpaper(path: theNextUrl)
    
} catch let error {
    print("Error: \(error.localizedDescription)")
}
