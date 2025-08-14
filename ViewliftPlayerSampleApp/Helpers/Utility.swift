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
}
