//
//  NetworkHandler.swift
//  ViewliftPlayerSampleApp
//
//  Created by Gaurav Vig on 18/11/21.
//  Copyright © 2021 Viewlift. All rights reserved.
//

import Foundation

class NetworkHandler {
    
    static let sharedInstance = NetworkHandler()
    private init() {}
    
    func fetchDataFromAPI(responseForConfiguration: @escaping ( (_ responseConfigData: Data?,_ responseErrorData: Data?, _ isSuccess:Bool) -> Void)) {
        guard let requestUrl = URL(string:"VideoFileListPath") else { return responseForConfiguration(nil, nil, false) }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if error == nil,let usableData = data {
                responseForConfiguration(usableData, nil, true)
            }
            else {
                responseForConfiguration(nil, data, false)
            }
        }
        task.resume()
    }
}
