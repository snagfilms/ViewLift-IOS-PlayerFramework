//
//  NetworkHandler.swift
//  SwiftPOCConfiguration
//
//  Created by Viewlift on 07/03/17.
//  Copyright © 2017 Viewlift. All rights reserved.
//

import Foundation
import AdSupport

enum RequestType: String
{
    case get    = "GET"
    case post   = "POST"
    case delete = "DELETE"
}

class NetworkHandler: NSObject {
    
    static let sharedInstance:NetworkHandler = {
        
        let instance = NetworkHandler()
        
        return instance
    }()

    //MARK: Method to fetch details from server
    /**
    - Remark:
     Method to Fetch API Token
     
    - Parameters:
     - apiURL: API Url of fetch content
     - requestType: Type of Request
     
    - Returns:
     - responseForConfiguration:
        - responseConfigData: Response received from server
        - isSuccess: Boolean flag to indicate if api response is success or not
     */
    func fetchDetailsFromServer(apiURL:String, requestType:RequestType, responseForConfiguration: @escaping ( (_ responseConfigData: Data?, _ isSuccess:Bool) -> Void)) -> Void {
        
        var requestHeaders:Dictionary<String, String> = [:]
        requestHeaders["x-api-key"] = AppDelegate.apiKey
        requestHeaders["Content-Type"] = "application/json"
        requestHeaders["Accept"] = "application/json"
        requestHeaders["Accept-Encoding"] = "gzip"
        
        guard let requestUrl = URL(string:apiURL) else { return responseForConfiguration(nil, false) }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = requestType.rawValue
        request.allHTTPHeaderFields = requestHeaders
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if error == nil,let usableData = data {
                
                responseForConfiguration(usableData, true)
            }
            else {
                responseForConfiguration(nil, false)
            }
        }
        
        task.resume()
    }
}
