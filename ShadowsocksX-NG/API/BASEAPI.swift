//
//  BASEAPI.swift
//  ShadowsocksX-NG
//
//  Created by Youma W Guedalia Floriane on 2/2/20.
//  Copyright © 2020 qiuyuzhou. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

 class BASEAPI{
    
    static var SEVER_ADD = "http://panel.agakoti.com"
    static var LOGIN = "/api/token"
    static var TOKEN_INFO = "/api/token/%@"
    static var GET_SERVERS = "/api/node?access_token=%@"
    static var GET_C0NFIGURATIONS = "/api/configuration"
    
    
    
    static func  Login(email:String, pwd:String) {
        
         var login = false
         var ret_msg = "Failed to Login"
        
        let url = SEVER_ADD + LOGIN
        var account = email;
        
        //Change phone number to email
        if Int(email) != nil {
         account = email + "@phone.com"
        }
        
        
        AF.request(url, method: .post, parameters: ["email":account,"passwd":pwd])
        .responseJSON { response in
            if response.data != nil {
                
                do{
                      let json = try JSON(data: response.data!)
                    if(json["ret"]==1){
                        
                        let userid = Int(json["data"]["userId"].stringValue)
                        let username = json["data"]["fullname"]
                        let token = json["data"]["token"]
                        
                        //Saving all the information
                        UserDefaults.standard.set(token.stringValue as String, forKey: "token")
                        UserDefaults.standard.set(userid , forKey: "userid")
                        UserDefaults.standard.set(username.stringValue as String, forKey: "username")
                        print("Login successfully")
                        
                        login = true;
                        ret_msg = json["msg"].stringValue
                        
                    }else{
                        
                        ret_msg = json["msg"].stringValue
                    }
                }catch{
                    print("Error during Login" )
                }
                
                if(login){
                    getTokenInfo(token: UserDefaults.standard.string(forKey: "token")!)
                    getServers(token: UserDefaults.standard.string(forKey: "token")!)
                }
                else{
                   
                    //Notfy login Window
                     let loginWindow = LoginWindowController.instance
                   if(loginWindow != nil){ loginWindow?.finishedLogin(isLogin:login,msg:ret_msg)
                   }
                }
            }
        }
        
       
    }
    
    static func getTokenInfo(token:String){
        
        let url = SEVER_ADD + String(format: TOKEN_INFO,token)
        
        AF.request(url, method: .get)
        .responseJSON { response in
            if response.data != nil {
                
                do{
                      let json = try JSON(data: response.data!)
                    if(json["ret"]==1){
                        let expire_date = json["data"]["expireTime"]
                        
                        //Saving all the information
                        UserDefaults.standard.set(expire_date.stringValue as String, forKey: "expireDate")
                        print("Got the expire date")

                    }else{
                        
                        print("failed to get expire Date")
                    }
                }catch{
                    print("Error getting token information" )
                }
                
            }
        }
        
    }
    static func getServers(token:String)  {
       let url = SEVER_ADD + String(format: GET_SERVERS,token)
        
        AF.request(url, method: .get)
        .responseJSON { response in
            if response.data != nil {
                
                do{
                      let json = try JSON(data: response.data!)
                    if(json["ret"]==1){
                       
                       //Saving the Servers
                      let profileMgr = ServerProfileManager.instance
                        profileMgr.profiles.removeAll()
                        for (_, object) in json["data"] {
                            let server = jsonToServerProfile(object:object)
                            if(server.isValid()){
                                profileMgr.profiles.append(server)
                                print("Added:" + server.remark)
                            }
                            profileMgr.save()
                            NotificationCenter.default
                            .post(name: Notification.Name(rawValue: NOTIFY_SERVER_PROFILES_CHANGED), object: nil)
                        }
                        
                        //Notfy login Window
                        let loginWindow = LoginWindowController.instance
                       
                        if(loginWindow != nil){ loginWindow?.finishedLogin(isLogin:true,msg:"Logged in succesfully")
                        }
                        
                        print("Got the servers")

                    }else{
                        
                        print("Failed to get Servers")
                    }
                }catch{
                    print("Error getting servers" )
                }
                
            }
        }
    }
    
    static func jsonToServerProfile(object:JSON) -> ServerProfile{
        let server = ServerProfile()
        
        server.remark = object["remarks"].stringValue
        server.serverHost = object["server"].stringValue
        server.serverPort = UInt16(object["server_port"].intValue)
        server.method = object["method"].stringValue
        server.ssrProtocol = object["protocol"].stringValue
        server.ssrObfs = object["obfs"].stringValue
        server.ssrObfsParam = object["obfsparam"].stringValue
        server.password = object["password"].stringValue
        
        
//missing parameters
//        "tcp_over_udp" : false,
//        "obfs_udp" : false,
//        "group" : "AGAKOTI",
//        "enable" : true,
//        "udp_over_tcp" : false
    
        return server;
    }
    
    
}
