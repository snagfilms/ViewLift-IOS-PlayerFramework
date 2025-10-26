//
//  Utility.swift
//  ViewliftPlayerSampleApp
//
//  Created by Japneet Singh on 14/08/25.
//  Copyright © 2025 Viewlift. All rights reserved.
//

import UIKit

class Utility: NSObject {
    static let sharedUtility = Utility()
    
    private override init() {}
    
    //MARK: Method to get uuid from sskeychain
    func getUUID() -> String {
        guard let deviceIdentifier = UIDevice.current.identifierForVendor else { return "" }
        return deviceIdentifier.uuidString
    }
    
    class func hexStringToUIColor (hex:String, alpha:CGFloat = 1.0) -> UIColor {
        
        var cString:String = hex.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString = String(cString[cString.index(after: cString.startIndex)...])
        }
        
        if ((cString.count) != 6) {
            return UIColor.white
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
    
    func getUserAgent() -> String {
        // App Info
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "UnknownApp"
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0"
        // Device Info
        let device = UIDevice.current
        let systemName = device.systemName    // e.g. "iOS"
        let systemVersion = device.systemVersion // e.g. "17.0"
        let model = device.model         // e.g. "iPhone"
        // Screen Info
        let scale = UIScreen.main.scale     // e.g. 3.0
        // Get Darwin Kernel Version
        var systemInfo = utsname()
        uname(&systemInfo)
        let darwinVersion = withUnsafePointer(to: &systemInfo.release) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        // CFNetwork Version (from system bundle)
        let cfNetworkVersion =
        Bundle(identifier: "com.apple.CFNetwork")?.infoDictionary?["CFBundleShortVersionString"] as? String
        ?? "Unknown"
        // Construct UA
        let userAgent = "\(appName)/\(appVersion) (\(model); \(systemName) \(systemVersion)) " +
        "\(systemName) (\(model); scale/\(scale)) "
        return userAgent
    }
}
