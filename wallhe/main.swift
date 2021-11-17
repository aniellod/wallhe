//
//  main.swift
//  wallhe requires MacOS 10.15+
//
//  Swift 5
//
//  Created by Aniello Di Meglio on 2021-11-03.
//
//  Parts were converted to Swift 5.5 from Objective-C by Swiftify v5.5.22755 - https://swiftify.com/
//  Inspired by Wally by Antonio Di Monaco
//
//  Warning - very buggy and little error checking. Lots of cargo culting...
//
//
//  Requirements:
//      Moderator command line parsing: https://github.com/kareman/Moderator
//      Swift-Image to handle .png:     https://github.com/koher/swift-image.git
//      Accessibility control to enable keyboard control of wallpaper
//
//  Command like based very basic wallpaper controler for MacOS 10.15+
//
//  Specify image folder and delay, Wallhe will randomly pick an image, resize/tile it to fit all visible desktops then loop through all images. Control-C to exit.
//

import Foundation
import SwiftUI
import CoreGraphics
import Moderator  // https://github.com/kareman/Moderator.git
import SwiftImage // https://github.com/koher/swift-image.git

class thread2 {
    
    var filelist: Array<String>
    var seconds: UInt32
    var currentImageFile: String
    var currentFullPath: String
    var count: Int
    
    init() {
        self.seconds = 0
        self.filelist = []
        self.currentImageFile = ""
        self.currentFullPath = ""
        self.count = 0
    }
    // because I don't really understand swift getter/setters
    func setFilelist(_ filelist: Array<String>) {
        self.filelist = filelist
    }
    
    func setSeconds(_ seconds: UInt32) {
        self.seconds = seconds
    }
    
    func getFilelist() -> Array<String> {
        return self.filelist
    }
    
    func getCurrentImageFile() -> String {
        return self.currentImageFile
    }
    
    func getCurrentFullPath() -> String {
        return self.currentFullPath
    }
    
    func getSeconds() -> UInt32 {
        return self.seconds
    }
    
    func start() {
        let thread = Thread.init(target: self, selector: #selector(mainLoop), object: nil)
        thread.start()
    }
    
    @objc func mainLoop() {
        self.filelist.shuffle()
            for imageFile in filelist {
                let fullpath = dirName + "/" + imageFile
                self.currentImageFile = imageFile
                self.currentFullPath = fullpath
                self.count+=1
                if debug { print("Image \(self.count) of \(filelist.count) - \(imageFile)") }
                autoreleasepool {
                        updateWallpaper(path: fullpath, name: imageFile)
                }
                sleep(self.seconds)
            }
        self.count = 0 //we're out of the loop, reset the count
        self.start() //restart loop, otherwise this thread terminates.
    }
}

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

// fileName: outputs the filename to use. This is a really silly hack as it should be able to tell
// MacOS to reload the wallpaper file. Need to switch names as otherwise MacOS will not update it otherwise.
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
               } catch { return fileName }
        } else {
            fileName = "wallhe-wallpaper1.png"
            do {
                let deleted = FileManager()
                let fileToDeleteURL = url.appendingPathComponent("wallhe-wallpaper2.png")
                try deleted.removeItem(at: fileToDeleteURL!)
               } catch { return fileName }
        }
    }
    return fileName
}

// buildWallpaper: input is the image; output is the tiled wallpaper ready to go.
func buildWallpaper(sample: NSImage, text: String...) -> NSImage {
    let textFont = NSFont(name: "Helvetica Bold", size: 18)!
    let textFontAttributes = [
        NSAttributedString.Key.font: textFont,
        NSAttributedString.Key.shadow: NSShadow(),
        NSAttributedString.Key.foregroundColor: NSColor.gray,
        NSAttributedString.Key.backgroundColor: NSColor.black
    ]
    
    let drawText=NSString(string: text[0])

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
    drawText.draw(at: NSPoint(x: 20, y: sh - 60), withAttributes: textFontAttributes)
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
            if (debug) { print(error) }
            return false
        }
    }
}

// resizedImage: input = URL of input image; size = new size of image; output = new resized image
func resizedImage(at url: URL, for size: CGSize) -> NSImage? {
    if url.path.lowercased().contains(".png") {
        let thisImage = SwiftImage.Image<RGB<UInt8>>(contentsOfFile: url.path)
        let result = thisImage?.resizedTo(width: Int(size.width), height: Int(size.height))
        let scaledImage = result?.nsImage
        return scaledImage
    } else { // this is faster but doesn't seem to handle png files.
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
}

// updateWallpaper: input path to image
func updateWallpaper(path: String, name: String) {
    let desktopURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
    let destinationURL: URL = desktopURL.appendingPathComponent(fileName())
    
    let theURL = URL(fileURLWithPath: path)
    let origImage = NSImage(contentsOf: theURL)
    guard let height = origImage?.size.height else {
        if (debug) { print("Error in calculating height of image at \(path)") }
        return
    }
    let ratio = NSScreen.screenHeight! / height
    let newWidth = (origImage!.size.width) * ratio

    guard let newImage = resizedImage(at: theURL, for: CGSize(width: newWidth, height: NSScreen.screenHeight!))
    else {
        print("Error \(theURL) cannot be opened.")
        return
    }
    var displayedText = ""
    if showPath.value {
        displayedText = path
    }
    if showName.value {
        displayedText = name
    }
    let finalImage = buildWallpaper(sample: newImage, text: displayedText)
    
    guard finalImage.pngWrite(to: destinationURL) else {
        print("File count not be saved")
        return
    }
    setBackground(theURL: (destinationURL.absoluteString))
}

class EditorWindow: NSApplication {
    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        Swift.print("Caught a key down: \(event.keyCode)!")
    }
}

func myCGEventCallback(proxy : CGEventTapProxy, type : CGEventType, event : CGEvent, refcon : Optional<UnsafeMutableRawPointer>) -> Unmanaged<CGEvent>? {

    if [.keyUp].contains(type) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        if keyCode == 100 {
            if (showPath.value == false && showName.value == false) {
                showName.value = true
            } else {
                if (showPath.value == false && showName.value == true) {
                    showPath.value = true
                    showName.value = false
                } else {
                    if (showPath.value == true && showName.value == false) {
                        showPath.value = false
                        showName.value = false
                    }
                }
            }
            updateWallpaper(path: theWork.getCurrentFullPath(), name: theWork.getCurrentImageFile())
        }
        if keyCode == 101 {
            theWork.setSeconds(theWork.getSeconds() + UInt32(5))
            print("Setting delay to \(theWork.getSeconds()) seconds.")
        }
        if keyCode == 98 {
            if theWork.getSeconds() - UInt32(5) > 0 {
                theWork.setSeconds(theWork.getSeconds() - UInt32(5))
            }
            print("Setting delay to \(theWork.getSeconds()) seconds.")
        }
        event.setIntegerValueField(.keyboardEventKeycode, value: keyCode)
        //print(keyCode)
    }
    return Unmanaged.passRetained(event)
}

let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                       place: .headInsertEventTap,
                                       options: .defaultTap,
                                       eventsOfInterest: CGEventMask(eventMask),
                                       callback: myCGEventCallback,
                                       userInfo: nil) else {
        print("failed to create event tap")
        exit(1)
}


// begin "main" section

let arguments = Moderator(description: "Wallpaper manager for MacOS. Select directory with images, Wallhe will resize and tile across all monitors.")
let help = arguments.add(.option("h","help", description: "Prints this message."))
let toDebug = arguments.add(.option("v","verbose", description: "Output messages."))
let showPath = arguments.add(.option("i","info", description: "Display image information on wallpaper."))
let showName = arguments.add(.option("n","name", description: "Show name of image."))
let directory = arguments.add(
            .optionWithValue("d", "directory", name: "\"/image/directory/path\"", description: "The full path to the image folder. Default is Picture folder.")
            .default("none"))
let delay = arguments.add(
            .optionWithValue("s", "seconds", name: "seconds delay", description: "The delay in seconds between each image.")
            .default("60"))
do {
   try arguments.parse()
} catch {
    print(error)
    exit(0) }

if help.value {
print("""

Wallpaper manager for MacOS. Select directory with images, Wallhe will resize and tile across all monitors. \
      
Usage: wallhe
  -h,--help:
      Prints this message.
  -v,--verbose:
      Output messages.
  -i,--info:
      Display image information.
  -d,--directory "/image/directory/path":
      The full path to the image folder. Default is Picture folder.
  -s,--seconds <seconds delay>:
      The delay in seconds between each image. Default = '60'.
"""
)
    exit(0)
}

var debug:Bool = false
if toDebug.value { debug = true }

if debug { print("Delay = \(delay)") }

// set-up location where to read image files from
let filemgr = FileManager.default
var dirName = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!.path + "/"

if directory.value != "none" {
    dirName = directory.value
}

if (debug) {print("directory = \(dirName)")}

// we should have a directory
let directoryURL = URL(fileURLWithPath: dirName)
if !directoryURL.isFileURL {
    print("directory is nil")
}

var filelist = try filemgr.contentsOfDirectory(atPath: dirName)
if debug { print("filelist count = \(filelist.count)") }

var seconds: UInt32 = UInt32(abs(Int(delay.value)!))
filelist = filelist.filter{
       $0.lowercased().contains(".jp")
    || $0.lowercased().contains(".png")
    || $0.lowercased().contains(".bmp")
}

guard filelist.count > 0 else {
    print()
    print("No images found in directory \(String(describing: directoryURL))")
    exit(1)
}

let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, CFRunLoopMode.commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)

let theWork = thread2()
theWork.setFilelist(filelist)
theWork.setSeconds(seconds)
theWork.start()
CFRunLoopRun()
