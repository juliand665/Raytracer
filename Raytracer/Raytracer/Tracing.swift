//
//  Tracing.swift
//  Raytracer
//
//  Created by Julian Dunskus on 26.08.17.
//  Copyright © 2017 Julian Dunskus. All rights reserved.
//

import Foundation

protocol Scene: Shape {
	mutating func add<S: Shape>(_ shape: S) where S.V == V
}

struct ArrayScene<V: Vector>: Scene {
	var shapes: [AnyShape<V>]
	
	mutating func add<S: Shape>(_ shape: S) where S.V == V {
		shapes.append(AnyShape(shape))
	}
	
	func firstIntersection(along ray: Ray<V>, after nearClipping: V.Component) -> Intersection<V>? {
		var min: Intersection<V>?
		for shape in shapes {
			if let new = shape.firstIntersection(along: ray, after: nearClipping), new.distance > nearClipping, min == nil || min!.distance > new.distance {
				min = new
			}
		}
		return min
	}
}

protocol Camera {
	associatedtype V: Vector
	associatedtype Offset: Vector
	
	var position: V { get set }
	var facing: (direction: V, up: V) { get set }
	var scene: [AnyShape<V>] { get set }
	var backgroundColor: Color { get set }
	var bounces: Int { get set }
	var nearClipping: V.Component { get set }
	
	/// - Parameter offset: components range from -1 to 1 
	func trace(through offset: Offset) -> Color
}

extension Camera {
	func trace(along ray: Ray<V>, currentBounce: Int = 0) -> Color {
//		print("tracing along", ray)
		var min: Intersection<V>?
		for shape in scene {
			if let new = shape.firstIntersection(along: ray, after: nearClipping), new.distance > nearClipping, min == nil || min!.distance > new.distance {
				min = new
			}
		}
		if let min = min {
			let behavior = min.behavior()
			if currentBounce < bounces, let next = behavior.nextBounce {
				return behavior.emission + behavior.color * trace(along: next, currentBounce: currentBounce + 1)
			} else {
				return behavior.emission
			}
		} else {
			return backgroundColor
		}
	}
}

/// 2D Camera in a 3D Scene
/// 
/// faces into z+ (y+ up) by default
class RegularCamera: Camera {
	var position: Vector3 = .zero
	var facing = (direction: Vector3(x: 0, y: 0, z: 1), up: Vector3(x: 0, y: 1, z: 0)) {
		didSet {
			updateAxes()
		}
	}
	var scene: [AnyShape<Vector3>] = []
	var backgroundColor: Color = .clear
	var bounces: Int = 5
	var nearClipping: F = 0.000001
	var xAxis, yAxis: Vector3!
	
	init() {
		updateAxes()
	}
	
	func updateAxes() {
		xAxis = (facing.up × facing.direction).normalized
		yAxis = facing.up.normalized
	}
	
	func trace(through offset: Vector2) -> Color {
//		print("tracing through", offset)
		let coord = xAxis * offset.x + yAxis * offset.y
		return trace(along: Ray(origin: position, direction: facing.direction + coord))
	}
}
