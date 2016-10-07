//
//  CIMHttpRequest.swift
//  cbai
//
//  Created by LaoTao on 16/7/3.
//  Copyright © 2016年 cim120. All rights reserved.
//

import UIKit
import AFNetworking
import SVProgressHUD

/**
 *  新的网络请求类，将会替代其他的网络请求类
 */
class CIMHttpRequest: NSObject, NSURLConnectionDataDelegate {
    
    /** 请求成功 */
    typealias connectSuccessClosure = (result: AnyObject) -> Void
    /** 请求失败 */
    typealias connectFailureClosure = () -> Void
    
    private var successClosure: connectSuccessClosure?
    private var failureClosure: connectFailureClosure?

    /** 是否检测code码 */
    var isCheckCode: Bool = true
    
    class func requestHttp() -> CIMHttpRequest {
        return CIMHttpRequest()
    }
    
    /**
     *  Post 网络请求
     *
     *  @param parameter             参数
     *  @param url                url地址
     *  @param contentType                  是否序列化
     *  @param connectSuccessClosure 成功回调
     *  @param connectFailureClosure 失败回调
     *
     */
    func postConnection(parameter: AnyObject?, url: String, isShowAlert: Bool, contentType: Bool, success: connectSuccessClosure, failure: connectFailureClosure) -> Void {
        successClosure = success
        failureClosure = failure
        print("-------开始网络请求:\(parameter)")
        /** 网络请求 */
        let session = getSession(contentType)
        
//        cbaPrint("-------开始网络请求:\(parameter)")
        session.POST(url, parameters: parameter, success: { (sessionDataTask, result) in
            
            print("HTTP Success:\(url), \(result)")
            
                if (result as? [String: AnyObject]) != nil {
                    let code = (result as! [String: AnyObject])["code"] as? Int
                    
                    if self.isCheckCode {
                        if code == 1 {
                            if ((result as! [String: AnyObject])["data"] as? [String: AnyObject]) != nil {
                                let data = (result as! [String: AnyObject])["data"] as! [String: AnyObject]
                                if self.successClosure != nil {
                                    self.successClosure!(result: data)
                                    return
                                }
                            }
                        }else {
                            LTErrorAlert.showErrorAlertView(code!, isShow: true)
                        }
                    }else {
                        if code == 3001 {
                            LTFunction.logoutHint()
                        }else if self.successClosure != nil {
                            self.successClosure!(result: result as! [String: AnyObject])
                            return
                        }
                    }
                }else {
                    SVProgressHUD.showErrorWithStatus(errorNetwork)
                }
                
                self.failureClosure!()

            }) { (sessionDataTask, error) in
                print("HTTP Error: \(error)")
                
                if isShowAlert {
                    SVProgressHUD.showErrorWithStatus(errorNetwork)
                }
                
                if self.failureClosure != nil {
                    self.failureClosure!()
                }
        }
    }
    
    /** GET 请求 */
    func getConnection(url: String, parameter: AnyObject? ,isShowAlert: Bool, contentType: Bool, success:
        connectSuccessClosure, failure: connectFailureClosure) -> Void {
        
        successClosure = success
        failureClosure = failure
        
        /** 网络请求 */
        let session = getSession(contentType)
        
        session.GET(url, parameters: parameter, success: { (sessionDataTask, result) in
                print("HTTP Success: \(result)")
                
                if (result as? [String: AnyObject]) != nil {
                    
                    let code = (result as! [String: AnyObject])["code"] as? Int
                    
                    if self.isCheckCode {
                        if code == 1 {
                            if ((result as! [String: AnyObject])["data"] as? [String: AnyObject]) != nil {
                                let data = (result as! [String: AnyObject])["data"] as! [String: AnyObject]
                                if self.successClosure != nil {
                                    self.successClosure!(result: data)
                                    return
                                }
                            }
                        }else {
                            LTErrorAlert.showErrorAlertView(code!, isShow: true)
                        }
                    }else {
                        if code == 3001 {
                            LTErrorAlert.showErrorAlertView(code!, isShow: true)
                        }else if self.successClosure != nil {
                            self.successClosure!(result: result as! [String: AnyObject])
                            return
                        }
                    }
                    
                } else  {
                    SVProgressHUD.showErrorWithStatus(errorNetwork)
                }
                
                self.failureClosure!()
            
            
            }) { (sessionDataTask, error) in
                print("HTTP Error: \(error)")
                if isShowAlert {
                    SVProgressHUD.showErrorWithStatus(errorNetwork)
                }
                
                if self.failureClosure != nil {
                    self.failureClosure!()
                }
        }

    }
    
    /** DELETE 请求 */
    func deleteConnection(url: String, isShowAlert: Bool, contentType: Bool, success: connectSuccessClosure, failure: connectFailureClosure) -> Void {
        successClosure = success
        failureClosure = failure
        
        /** 网络请求 */
        let session = getSession(contentType)
        
        session.DELETE(url, parameters: nil, success: { (sessionDataTask, result) in
                if (result as? [String: AnyObject]) != nil {
                    
                    let success = (result as! [String: AnyObject])["success"] as? Int
                    if success == 1 {
                        let code = (result as! [String: AnyObject])["code"] as? Int
                        
                        if code == 1 {
                            if ((result as! [String: AnyObject])["data"] as? [String: AnyObject]) != nil {
                                let data = (result as! [String: AnyObject])["data"] as! [String: AnyObject]
                                if self.successClosure != nil {
                                    self.successClosure!(result: data)
                                    return
                                }
                            }
                        }else {
                            LTErrorAlert.showErrorAlertView(code!, isShow: true)
                            return
                        }
                    }
                }
            }) { (sessionDataTask, error) in
                if isShowAlert {
                    SVProgressHUD.showErrorWithStatus(errorNetwork)
                }
                
                if self.failureClosure != nil {
                    self.failureClosure!()
                }
        }
    }
    
    //MARK: >> 获取 AFHTTPSessionManager
    /** 获取 AFHTTPSessionManager */
    private func getSession(contentType: Bool) -> AFHTTPSessionManager {
        /** 网络请求 */
        let session = AFHTTPSessionManager()
        session.responseSerializer.acceptableContentTypes = NSSet(objects: ["application/json", "text/json", "text/javascript", "application/x-json", "text/html"]) as? Set<String>
        
        if contentType {
            //            session.responseSerializer = AFJSONResponseSerializer
            session.requestSerializer = AFJSONRequestSerializer()
        }
        
        //超时设置
        session.requestSerializer.timeoutInterval = 30
        return session
    }
    
    //MARK: >> 解析数据的，后续继续
    func parseData(result: AnyObject) -> Void {
        if (result as? [String: AnyObject]) != nil {
            let code = (result as! [String: AnyObject])["code"] as? Int
            
            if code == 1 {
                if ((result as! [String: AnyObject])["data"] as? [String: AnyObject]) != nil {
                    let data = (result as! [String: AnyObject])["data"] as! [String: AnyObject]
                    if self.successClosure != nil {
                        self.successClosure!(result: data)
                        return
                    }
                }
            }else {
                LTErrorAlert.showErrorAlertView(code!, isShow: true)
            }
        }else {
            SVProgressHUD.showErrorWithStatus(errorNetwork)
        }
        
        self.failureClosure!()
    }
}
