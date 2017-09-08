//
//  Shape.swift
//  Raytracer
//
//  Created by Julian Dunskus on 25.08.17.
//  Copyright © 2017 Julian Dunskus. All rights reserved.
//

import Foundation

typealias Intersection<V: Vector> = (distance: V.Component, behavior: () -> Behavior<V>)

protocol Shape {
	associatedtype V: Vector
	
	func firstIntersection(along ray: Ray<V>, after nearClipping: V.Component) -> Intersection<V>?
}

// type erasure
struct AnyShape<V: Vector>: Shape {
	init<S: Shape>(_ shape: S) where S.V == V {
		_firstIntersection = shape.firstIntersection
	}
	
	private var _firstIntersection: (Ray<V>, V.Component) -> Intersection<V>?
	func firstIntersection(along ray: Ray<V>, after nearClipping: V.Component) -> Intersection<V>? {
		return _firstIntersection(ray, nearClipping)
	}
}

protocol MaterialShape: Shape {
	var material: AnyMaterial<V> { get }
}

protocol NSphere: MaterialShape {
	var center: V { get }
	var radius: V.Component { get }
	
	init<M: Material>(at center: V, radius: V.Component, material: M) where M.V == V
}

extension MaterialShape where Self: NSphere {
	func firstIntersection(along ray: Ray<V>, after nearClipping: V.Component) -> Intersection<V>? {
		let offsetCenter = center - ray.origin
		// check that sphere is in front of the ray
		guard offsetCenter • ray.direction > 0 else { return nil }
		// project sphere center onto ray
		let projectionLength = offsetCenter • ray.direction
		let projection = projectionLength * ray.direction
		// calculate distance from projection to sphere edge (pythagoras)
		let hypotenuse² = radius.squared
		let cathetus² = (offsetCenter - projection).squaredSum
		guard hypotenuse² > cathetus² else { return nil } // TODO when does this occur?
		let distance = projectionLength - (hypotenuse² - cathetus²).squareRoot()
		guard distance > nearClipping else { return nil }
		return (distance: distance, {
			let intersect = ray[distance]
			return self.material.behavior(from: ray.direction, at: intersect, normal: intersect - self.center)
		})
	}
}

struct Circle: NSphere {
	typealias V = Vector2
	
	var center: Vector2
	var radius: F
	var material: AnyMaterial<Vector2>
	
	init<M: Material>(at center: Vector2, radius: F, material: M) where M.V == Vector2 {
		self.center = center
		self.radius = radius
		self.material = AnyMaterial(material)
	}
}

struct Sphere: NSphere {
	typealias V = Vector3
	
	var center: Vector3
	var radius: F
	var material: AnyMaterial<Vector3>
	
	init<M: Material>(at center: Vector3, radius: F, material: M) where M.V == Vector3 {
		self.center = center
		self.radius = radius
		self.material = AnyMaterial(material)
	}
}

struct Hypersphere: NSphere {
	typealias V = Vector4
	
	var center: Vector4
	var radius: F
	var material: AnyMaterial<Vector4>
	
	init<M: Material>(at center: Vector4, radius: F, material: M) where M.V == Vector4 {
		self.center = center
		self.radius = radius
		self.material = AnyMaterial(material)
	}
}
