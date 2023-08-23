//
//  AppSettings.swift
//  wheel_uikit
//
//  Created by Lynn on 2023-08-17.
//

import Foundation

struct AppSettings {
    
    static var imageSource: ImageSource = .API

    enum ImageSource {
        
        case Local
        case API
        case Mock
    }
}
