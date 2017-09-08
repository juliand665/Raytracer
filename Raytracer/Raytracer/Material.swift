//
//  Material.swift
//  Raytracer
//
//  Created by Julian Dunskus on 27.08.17.
//  Copyright © 2017 Julian Dunskus. All rights reserved.
//

import Foundation

typealias Behavior<V: Vector> = (emission: Color, color: Color, nextBounce: Ray<V>?)

protocol Material {
	associatedtype V: Vector
	
	func behavior(from direction: V, at intersection: V, normal: V) -> Behavior<V>
}

// type erasure
struct AnyMaterial<V: Vector>: Material {
	init<M: Material>(_ material: M) where M.V == V {
		_behavior = material.behavior
	}
	
	private var _behavior: (V, V, V) -> Behavior<V>
	func behavior(from direction: V, at intersection: V, normal: V) -> Behavior<V> {
		return _behavior(direction, intersection, normal)
	}
}

struct FlatColorMaterial<V: Vector>: Material {
	var color: Color
	
	func behavior(from direction: V, at intersection: V, normal: V) -> Behavior<V> {
		return (emission: color, color: color, nextBounce: nil)
	}
}

struct MirrorMaterial<V: Vector>: Material {
	func behavior(from direction: V, at intersection: V, normal: V) -> Behavior<V> {
		let normal = normal.normalized // dunno if necessary
		let reflected = direction - 2 * (direction • normal) * normal
		let nextBounce = Ray(origin: intersection, direction: reflected)
		return (emission: .clear, color: .white, nextBounce: nextBounce)
	}
}

extension F {
	
	static func random() -> F {
		return F(arc4random()) / F(UInt32.max)
	}
}

struct DiffuseMaterial: Material {
	typealias V = Vector3
	
	var color: Color
	
	func behavior(from direction: V, at intersection: V, normal: V) -> Behavior<V> {
		let azimuth = F.random() * 2 * .pi
		let polar = F.random()
		let x = sin(polar) * cos(azimuth)
		let y = sin(polar) * sin(azimuth)
		let z = cos(polar) // TODO try exchanging some of these with basic random doubles
		
		let n = normal • direction > 0 ? normal * -1 : normal // TODO necessary? I don't think this is possible…
		let w: V = n.normalized
		let u: V = (V(x: 1, y: 0, z: 0) × w).normalized // could theoretically fail if w is exactly (1, 0, 0) -> division by zero
		let v: V = (w × u).normalized
		var r: V = u * x
		r = r + v * y
		r = r + w * z
		
		return (emission: .black, color: color, nextBounce: Ray(origin: intersection, direction: r))
	}
}

struct Color {
	typealias Component = CGFloat
	var red, green, blue, alpha: Component
	
	init(red: Component, green: Component, blue: Component, alpha: Component = 1) {
		self.red = red
		self.green = green
		self.blue = blue
		self.alpha = alpha
	}
	
	init(brightness: Component = 0, alpha: Component = 1) {
		self.init(red: brightness, green: brightness, blue: brightness, alpha: alpha)
	}
	
	static func +(lhs: Color, rhs: Color) -> Color {
		return Color(red: lhs.red + rhs.red,
		             green: lhs.green + rhs.green,
		             blue: lhs.blue + rhs.blue,
		             alpha: lhs.alpha + rhs.alpha)
	}
	
	static func *(lhs: Color, rhs: Color) -> Color {
		return Color(red: lhs.red * rhs.red,
		             green: lhs.green * rhs.green,
		             blue: lhs.blue * rhs.blue,
		             alpha: lhs.alpha * rhs.alpha)
	}
	
	static func /(color: Color, scale: Component) -> Color {
		return Color(red: color.red / scale,
		             green: color.green / scale,
		             blue: color.blue / scale,
		             alpha: color.alpha / scale)
	}
}

extension Color {
	static let clear = Color(alpha: 0)
	static let black = Color(brightness: 0)
	static let white = Color(brightness: 1)
	
	static let red     = Color(red: 1, green: 0, blue: 0)
	static let yellow  = Color(red: 1, green: 1, blue: 0)
	static let green   = Color(red: 0, green: 1, blue: 0)
	static let cyan    = Color(red: 0, green: 1, blue: 1)
	static let blue    = Color(red: 0, green: 0, blue: 1)
	static let magenta = Color(red: 1, green: 0, blue: 1)
}
