//
//  Helpers.swift
//  wheel_uikit
//
//  Created by Lynn on 2023-08-17.
//

import Foundation
import SwiftUI

struct Helpers {
    
    static func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
        return degrees * .pi / 180
    }

    static func radiansToDegrees(_ radians: CGFloat) -> CGFloat {
        return radians * 180 / .pi
    }
    
    static let themeColour = UIColor(named: "ThemeColour")
}


import OSLog

extension Logger {

    private static var subsystem = Bundle.main.bundleIdentifier!    
    static let poiLog = OSLog(subsystem: subsystem, category: .pointsOfInterest)

    static let startupActivities: StaticString = "Startup Activities"
    static let loadImageLocalActivities: StaticString = "Load Images - Local"
    static let loadImageAPIActivities: StaticString = "Load Images - API"
}
