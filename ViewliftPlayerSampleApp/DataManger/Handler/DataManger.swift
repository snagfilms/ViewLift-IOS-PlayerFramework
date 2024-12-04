//
//  DataManger.swift
//  AppCMS
//
//  Created by Viewlift on 31/03/17.
//  Copyright © 2017 Viewlift. All rights reserved.
//

import UIKit

class DataManger: NSObject {
    
    /**
     - Remark:
     Singleton class
     */
    static let sharedInstance:DataManger = {
        
        let instance = DataManger()
        
        return instance
    }()
    
    
    /**
     - Remark:
     Base url of the site
     */
    let baseUrl = "https://prod-api.viewlift.com"
    
    //MARK: API to fetch Site Details
    /**
     - Remark:
     Method to Fetch Site Details
     
     - Returns:
     - siteDetailResponse:
        - siteName: Name of site
        - isSuccess: Boolean flag to indicate if api response is success or not
     */
    func fetchSiteDetails(siteDetailResponse: @escaping ((_ siteName:String?, _ isSuccess:Bool) -> Void))
    {
        let apiEndPoint = "\(baseUrl)/sites/validate"
        
        NetworkHandler.sharedInstance.fetchDetailsFromServer(apiURL: apiEndPoint, requestType: .get) { (_ responseConfigData:Data?, _ isSuccess:Bool) in
            
            if responseConfigData != nil  && isSuccess {
                
                let siteConfigJson = try? JSONSerialization.jsonObject(with: responseConfigData!)
                
                if siteConfigJson is Dictionary<String,AnyObject> {
                    
                    let siteConfigDict:Dictionary<String,AnyObject>? = siteConfigJson as? Dictionary<String,AnyObject>
                    
                    if siteConfigDict != nil
                    {
                        let siteName: String = siteConfigDict?["siteInternalName"] as? String ?? "snagfilmsdsa"
                        siteDetailResponse(siteName, true)
                    }
                    else
                    {
                        siteDetailResponse(nil, false)
                    }
                }
                else {
                    
                    siteDetailResponse(nil, false)
                }
            }
            else {
                
                siteDetailResponse(nil, false)
            }
        }
    }
    
    
    //MARK: API to get anonymous token
    /**
     - Remark:
     Method to Fetch API Token.
     
     - Parameters:
        - siteName: Name of the site.
     
     - Returns:
        - tokenResponse:
            - apiToken: API token.
            - isSuccess: Boolean flag to indicate if api response is success or not.
     */
    func fetchAPIToken(siteName:String, tokenResponse: @escaping ((_ apiToken:String?, _ isSuccess:Bool) -> Void)) {
        
//        let deviceUdid:String? = UIDevice.current.identifierForVendor?.uuidString
        let apiEndPoint = "\(baseUrl)/sites/generate-site-token?site=\(siteName)"//"&uin=\(deviceUdid ?? "")"
        
        NetworkHandler.sharedInstance.fetchDetailsFromServer(apiURL: apiEndPoint, requestType: .get) { (_ responseConfigData:Data?, _ isSuccess:Bool) in
            
            if responseConfigData != nil  && isSuccess {
                
                let tokenJson = try? JSONSerialization.jsonObject(with: responseConfigData!)
                
                if tokenJson is Dictionary<String,AnyObject> {
                    
                    let tokenDict:Dictionary<String,AnyObject>? = tokenJson as? Dictionary<String,AnyObject>
                    
                    if tokenDict != nil {
                        
                        let authorizationToken:String? = tokenDict?["authorizationToken"] as? String
                        
                        if authorizationToken != nil {
                            
                            
                            tokenResponse(authorizationToken, true)
                        }
                        else {
                            
                            tokenResponse(nil, false)
                        }
                    }
                    else {
                        
                        tokenResponse(nil, false)
                    }
                }
                else {
                    
                    tokenResponse(nil, false)
                }
            }
            else {
                
                tokenResponse(nil, false)
            }
        }
    }
}
