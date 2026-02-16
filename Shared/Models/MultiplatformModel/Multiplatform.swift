//
//  Multiplatform.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 6/11/25.
//

//Unificando el uso de UIColor y UIFont para que pueda ejecutarse en macOS con el mismo nombre que en macOS.

#if os(macOS)
import AppKit
public typealias UIColor = NSColor
#endif

//Mismo caso para UIFont

#if os(macOS)
import AppKit
public typealias UIFont = NSFont
#endif


#if os(macOS)
import AppKit
public typealias UIImage = NSImage
#endif
