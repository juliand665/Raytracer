//
//  Rendering.swift
//  Raytracer
//
//  Created by Julian Dunskus on 27.08.17.
//  Copyright © 2017 Julian Dunskus. All rights reserved.
//

import AppKit

// 'ere be horrid CoreGraphics APIs

extension CGFloat {
	func clamped(to bounds: (min: CGFloat, max: CGFloat) = (0, 1)) -> CGFloat {
		return .minimum(bounds.max, .maximum(bounds.min, self))
	}
	
	var uInt8: UInt8 {
		return UInt8(255 * clamped())
	}
}

class Bitmap {
	struct Pixel {
		var r, g, b, a: UInt8
		
		static let clear = Pixel(r: 0, g: 0, b: 0, a: 0)
	}
	
	static let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
	static let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue) // TODO .premultipliedLast instead?
	
	var width, height: Int
	var data: [Pixel]
	
	init(width: Int, height: Int) {
		self.width = width
		self.height = height
		data = [Pixel](repeating: .clear, count: width * height)
	}
	
	subscript(x: Int, y: Int) -> Pixel {
		get {
			return data[x + y * width]
		}
		set {
			data[x + y * width] = newValue
		}
	}
	
	func cgImage() -> CGImage {
		let pixelSize = MemoryLayout<Pixel>.size
		let provider = CGDataProvider(data: NSData(bytes: &data, length: data.count * pixelSize))!
		return CGImage(width: width,
		               height: height,
		               bitsPerComponent: 8,
		               bitsPerPixel: 32,
		               bytesPerRow: width * pixelSize,
		               space: Bitmap.rgbColorSpace,
		               bitmapInfo: Bitmap.bitmapInfo,
		               provider: provider,
		               decode: nil,
		               shouldInterpolate: false,
		               intent: .defaultIntent)!
	}
}

func renderImage<C: Camera>(using camera: C, resolution: (width: Int, height: Int), samples: Int = 5, intermediateInterval: TimeInterval = 1, completion: @escaping (CGImage) -> Void) where C.Offset == Vector2 {
	let (width, height) = resolution
	let bitmap = Bitmap(width: width, height: height)
	let scaledWidth = F(width) / 2
	let scaledHeight = -F(height) / 2
	let cgSamples = CGFloat(samples)
	let xOffset = 1 / F(width) - 1
	let yOffset = 1 / F(height) + 1
	
	let queueCount = 4
	let group = DispatchGroup()
	
	let start = Date()
	let timer = Timer.scheduledTimer(withTimeInterval: intermediateInterval, repeats: true) { (timer) in
		print("timer fired!")
		completion(bitmap.cgImage())
	}
	for n in 0..<queueCount {
		let queue = DispatchQueue(label: "render thread \(n)")
		group.enter()
		queue.async {
			for y in 0..<height where y % queueCount == n {
				print("rendering line \(y)/\(height)")
				for x in 0..<width {
					//			print()
					let offset = Vector2(x: F(x) / scaledWidth + xOffset, y: F(y) / scaledHeight + yOffset)
					let color = (1...samples).map { _ in
						camera.trace(through: offset)
						}.reduce(.clear, +) / cgSamples
					bitmap[x, y] = .init(r: color.red.uInt8,
					                     g: color.green.uInt8,
					                     b: color.blue.uInt8,
					                     a: color.alpha.uInt8)
				}
			}
			group.leave()
		}
	}
	DispatchQueue(label: "finishing").async {
		group.wait()
		let diff = -start.timeIntervalSinceNow
		print("Took \(diff) seconds!")
		timer.fire()
		timer.invalidate()
	}
}
