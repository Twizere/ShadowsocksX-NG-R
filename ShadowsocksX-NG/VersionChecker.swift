//
//  VersionChecker.swift
//  ShadowsocksX-NG
//
//  Created by 秦宇航 on 2017/1/9.
//  Copyright © 2017年 qinyuhang. All rights reserved.
//

import Foundation

let _VERSION_XML_URL = "https://gitee.com/pacitwizere/AGAKOTI-APP-UPDATOR/raw/master/mac-updator.plist"
let _VERSION_XML_LOCAL:String = Bundle.main.bundlePath + "/Contents/Info.plist"

class VersionChecker: NSObject {
    var haveNewVersion: Bool = false
    enum versionError: Error {
        case CanNotGetOnlineData
    }
    func saveFile(fromURL: String, toPath: String, withName: String) -> Bool {
        let manager = FileManager.default
        let url = URL(string:fromURL)!
        do {
            let st = try String(contentsOf: url, encoding: String.Encoding.utf8)
            print(st)
            let data = st.data(using: String.Encoding.utf8)
            manager.createFile( atPath: toPath + withName , contents: data, attributes: nil)
            return true
            
        } catch {
            print(error)
            return false
        }
    }
    func showAlertView(Title: String, SubTitle: String, ConfirmBtn: String, CancelBtn: String) -> Int {
        let alertView = NSAlert()
        alertView.messageText = Title
        alertView.informativeText = SubTitle
        alertView.addButton(withTitle: ConfirmBtn)
        if CancelBtn != "" {
            alertView.addButton(withTitle: CancelBtn)
        }
        let action = alertView.runModal()
        return action.rawValue
    }
    func parserVersionString(strIn: String) -> Array<Int>{
        var strTmp = strIn
        if let index = strIn.range(of: "-")?.lowerBound {
            strTmp = String(strIn[..<index])
        }
        if !strTmp.hasSuffix(".") {
            strTmp += "."
        }
        var ret = [Int]()
        
        repeat {
            if let index = strTmp.range(of: ".")?.lowerBound, let num = Int(String(strTmp[..<index])) {
                ret.append(num)
                print(String(strTmp[..<index]))
            }
            if let index = strTmp.range(of: ".")?.upperBound {
                strTmp = String(strTmp[index...])
            }
        } while(strTmp.range(of: ".") != nil);
        
        return ret
    }
    func checkNewVersion() -> [String:Any] {
        // return 
        // newVersion: Bool, 
        // error: String,
        // alertTitle: String,
        // alertSubtitle: String,
        // alertConfirmBtn: String,
        // alertCancelBtn: String
        let showAlert: Bool = true
        func getOnlineData() throws -> NSDictionary{
            guard NSDictionary(contentsOf: URL(string:_VERSION_XML_URL)!) != nil else {
                throw versionError.CanNotGetOnlineData
            }
            return NSDictionary(contentsOf: URL(string:_VERSION_XML_URL)!)!
        }
        
        var localData: NSDictionary = NSDictionary()
        var onlineData: NSDictionary = NSDictionary()
        
        localData = NSDictionary(contentsOfFile: _VERSION_XML_LOCAL)!
        do{
            try onlineData = getOnlineData()
        }catch{
            return ["newVersion" : false,
                    "error": "network error",
                    "Title": "网络错误",
                    "SubTitle": "由于网络错误无法检查更新",
                    "ConfirmBtn": "确认",
                    "CancelBtn": ""
            ]
        }
        
        let versionString:String = onlineData["CFBundleShortVersionString"] as! String
        let buildString:String = onlineData["CFBundleVersion"] as! String
        let currentVersionString:String = localData["CFBundleShortVersionString"] as! String
        let currentBuildString:String = localData["CFBundleVersion"] as! String
        var subtitle:String
        if (versionString == currentVersionString){
            
            if buildString == currentBuildString {

                subtitle = "Current version is " + currentVersionString + " build " + currentBuildString
                return ["newVersion" : false,
                        "error": "",
                        "Title": "You have the latest version！",
                        "SubTitle": subtitle,
                        "ConfirmBtn": "OK",
                        "CancelBtn": ""
                ]
            }
            else {
                haveNewVersion = true
                
                subtitle = "New version is  " + versionString + " build " + buildString + "\n" + "This version is " + currentVersionString + " build " + currentBuildString
                return ["newVersion" : true,
                        "error": "",
                        "Title": "Update found！",
                        "SubTitle": subtitle,
                        "ConfirmBtn": "Download",
                        "CancelBtn": "Cancel"
                ]
            }
        }
        else{
            // 处理如果本地版本竟然比远程还新
            
            var versionArr = parserVersionString(strIn: onlineData["CFBundleShortVersionString"] as! String)
            var currentVersionArr = parserVersionString(strIn: localData["CFBundleShortVersionString"] as! String)
            
            // 做补0处理
            while (max(versionArr.count, currentVersionArr.count) != min(versionArr.count, currentVersionArr.count)) {
                if (versionArr.count < currentVersionArr.count) {
                    versionArr.append(0)
                }
                else {
                    currentVersionArr.append(0)
                }
            }
            
            for i in 0...(currentVersionArr.count - 1) {
                if versionArr[i] > currentVersionArr[i] {
                    haveNewVersion = true
                    subtitle = "New version is  " + versionString + " build " + buildString + "\n" + "This version is " + currentVersionString + " build " + currentBuildString
                    return ["newVersion" : true,
                            "error": "",
                            "Title": "Update found！",
                            "SubTitle": subtitle,
                            "ConfirmBtn": "Download",
                            "CancelBtn": "Cancel"
                    ]
                }
            }
            subtitle = "Current version " + currentVersionString + " build " + currentBuildString + "\n" + "remote version" + versionString + " build " + buildString
            return ["newVersion" : false,
                    "error": "",
                    "Title": "You have the latest version！",
                    "SubTitle": subtitle,
                    "ConfirmBtn": "OK",
                    "CancelBtn": ""
            ]
        }
    }
}
