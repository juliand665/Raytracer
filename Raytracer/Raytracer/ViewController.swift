//
//  ViewController.swift
//  Raytracer
//
//  Created by Julian Dunskus on 25.08.17.
//  Copyright © 2017 Julian Dunskus. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
	@IBOutlet weak var imageView: NSImageView!
	
	let renderingQueue = DispatchQueue(label: "rendering")
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let (width, height) = (128, 128)
		
		imageView.addConstraint(NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: CGFloat(width)))
		imageView.addConstraint(NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: CGFloat(height)))
		
		let camera = RegularCamera()
		camera.backgroundColor = .black
		camera.bounces = 5
		
		let diffuse = DiffuseMaterial(color: Color(red: 0.8, green: 0.2, blue: 0.2))
		let light = FlatColorMaterial<Vector3>(color: .init(brightness: 5))
		let mirror = MirrorMaterial<Vector3>()
		
		let sphere = Sphere(at: .init(x: -2, y: -3, z: 7), radius: 2, material: mirror)
		camera.scene.append(AnyShape(sphere))
		
		let lightSphere = Sphere(at: .init(x: 0, y: 100, z: 5), radius: 90.2, material: light)
		camera.scene.append(AnyShape(lightSphere))
		
		do {
			let paleRed = Color(red: 0.75, green: 0.25, blue: 0.25)
			let paleBlue = Color(red: 0.25, green: 0.25, blue: 0.75)
			let colors: [Color] = [paleRed, paleBlue, .white, .white, .white, .white]
			let positions = [(-1000, 0, 0), (1000, 0, 0), (0, -1000, 5), (0, 1000, 5), (0, 0, 1005)].map(Vector3.init)
			for (position, color) in zip(positions, colors) {
				let material = DiffuseMaterial(color: color)
				let sphere = Sphere(at: position, radius: 990, material: material)
				camera.scene.append(AnyShape(sphere))
			}
		}
		
		renderImage(using: camera, resolution: (width: width, height: height), samples: 50, intermediateInterval: 1) { image in
			DispatchQueue.main.async {
				self.imageView.image = NSImage(cgImage: image, size: NSSize(width: width, height: height))
			}
		}
	}
}
