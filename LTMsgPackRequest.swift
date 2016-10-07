//
//  LTMsgPackRequest.swift
//  HealthGuard
//
//  Created by LaoTao on 16/3/3.
//  Copyright © 2016年 LaoTao. All rights reserved.
//

import UIKit

class LTMsgPackRequest: NSObject, NSURLConnectionDataDelegate {
    
    var mData = NSMutableData()
    var mArray: [AnyObject]!
    var connection: NSURLConnection?
    var deviceType: CIMDeviceMode!
    
    var isDetection = false
    
    class func requestHttp() -> LTMsgPackRequest {
        return LTMsgPackRequest()
    }
    
    override init() {
        super.init()
    }
    
    //MARK: >> 离线数据上传
    /** 离线数据上传 */
    func requestDetection(parameters: [AnyObject]) -> Void {
        mArray = parameters
         //数据数量数组：0头戴数,1血压数,2儿童手环体温数,3设备数,4儿童手环干预数据
        var first: MessagePackValue = 0
        var second: MessagePackValue = 0
        var third: MessagePackValue = 0
        var fourth: MessagePackValue = 0
        var fifth: MessagePackValue = 0
        
        for item in parameters {
            if item as? [DeviceData] != nil {
                first = MessagePackValue((item as! [DeviceData]).count)
            }else if item as? [PressureDataModel] != nil {
                second = MessagePackValue((item as! [PressureDataModel]).count)
            }else if item as? [BraceletModel] != nil {
                third = MessagePackValue((item as! [BraceletModel]).count)
            }else if item as? [BTDevice] != nil {
                fourth = MessagePackValue((item as! [BTDevice]).count)
            }else if item as? [String] != nil {
                fifth = MessagePackValue((item as! [String]).count)
            }
        }
        
        let count: MessagePackValue = [first, second, third, fourth, fifth]
        
        let token: MessagePackValue = MessagePackValue(CIMAccount.accountToken())   //token
        let profildId = MessagePackValue.Int(Int64(CIMAccount.profileId().intValue))
        let platform: MessagePackValue = "1"
        let r1 = pack(token)
        let r2 = pack(profildId)
        let r3 = pack(platform)
        let r4 = pack(count)
        
        //        print("\(token), \(platform), \(count)")
        let data = NSMutableData()
        data.appendData(NSData(bytes: r1, length: r1.count))
        data.appendData(NSData(bytes: r2, length: r2.count))
        data.appendData(NSData(bytes: r3, length: r3.count))
        data.appendData(NSData(bytes: r4, length: r4.count))

        
        for item in parameters {
            if item as? [DeviceData] != nil {
                data.appendData(analysisDevice(item as! [DeviceData]))
            }else if item as? [PressureDataModel] != nil {
                data.appendData(analysisPressure(item as! [PressureDataModel]))
            }else if item as? [BraceletModel] != nil {
                data.appendData(analysisBracelet(item as! [BraceletModel]))
            }else if item as? [BTDevice] != nil {
                data.appendData(analysisHardwareDevice(item as! [BTDevice]))
            }else if item as? [String] != nil {
                
            }
        }
        
        requestStart(data)
    }
    
    
    
    //MARK: 头带数据
    /** 头带数据 */
    func requestDevice(parameter: [DeviceData], type: CIMDeviceMode) {
        
        //没有profile不上传数据
        if CIMAccount.profileId().length < 1 {
            return
        }
        
        mArray = parameter
        
        let data = combineData(parameter, type: type)
        
        data.appendData(analysisDevice(parameter))
        
        requestStart(data)
    }
    
    //MARK: 血压数据
    /** 血压数据 */
    func requestPressure(parameter: [PressureDataModel], type: CIMDeviceMode) {
        
        //没有profile不上传数据
        if CIMAccount.profileId().length < 1 {
            return
        }
        
        mArray = parameter
        let data = combineData(parameter, type: type)
        data.appendData(analysisPressure(parameter))
        
        requestStart(data)
    }
    
    //MARK: 手环数据
    /** 手环数据 */
    func requestBracelet(parameter: [BraceletModel], type: CIMDeviceMode) {
        
        //没有profile不上传数据
        if CIMAccount.profileId().length < 1 {
            return
        }
        
        mArray = parameter
        
        let data = combineData(parameter, type: type)
        data.appendData(analysisBracelet(parameter))
        
        requestStart(data)
    }
    
    //MARK: 干预列表
    /** 干预列表 */
    func requestIntervent(interType: String, time: String, type: CIMDeviceMode) {
        
        //没有profile不上传数据
        if CIMAccount.profileId().length < 1 {
            return
        }
        
        mArray = []
        
        let data = combineData([], type: CIMDeviceMode.Intervent)
        let timeTuple = time.timeToDataAndTime
        let parameter: MessagePackValue = [
            MessagePackValue.Float(timeTuple.0.floatValue),
            MessagePackValue.Float(timeTuple.1.floatValue),
            MessagePackValue.Float(Float(interType.integerValue))
        ]
        let r = pack(parameter)
        data.appendData(NSData(bytes: r, length: r.count))
        requestStart(data)
    }
    
    func requestHardwareDevice(parameter: [BTDevice], type: CIMDeviceMode) {
        //这里 type 应为 CIMDeviceModeHardware。 硬件设备
        mArray = parameter
        let data = combineData(parameter, type: type)
        data.appendData(analysisHardwareDevice(parameter))
        
        requestStart(data)
    }
    
    //MARK: 开始请求网络
    /** 开始请求网络 */
    func requestStart(data: NSData) {
        
        var urlStr = ""
        if (deviceType == CIMDeviceMode.Intervent) {  //干预列表
            urlStr = UrlManager.addInterventionUrl()
        }else {
            urlStr = UrlManager.getUrlDeviceUpload()
        }
        
//        print("urlStr:\(urlStr)")
        let url = NSURL(string: urlStr)
        
        let request = NSMutableURLRequest(URL: url!, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringCacheData, timeoutInterval: 10)
        request.HTTPMethod = "POST"
        
        request.setValue("application/octet-stream;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        //        request.setValue("zlib", forHTTPHeaderField: "Accept-Encoding")
        //        request.addValue("application/octet-stream;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        //        request.addValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        
        let zip = data.zlibDeflate()
        request.HTTPBody = zip
        
        connection = NSURLConnection(request: request, delegate: self)
        
    }

    //MARK: 组合数据
    /** 组合数据 */
    func combineData(parameter: [AnyObject], type: CIMDeviceMode) -> NSMutableData {
        deviceType = type
        let token: MessagePackValue = MessagePackValue(CIMAccount.accountToken())   //token
        let profildId = MessagePackValue.Int(Int64(CIMAccount.profileId().intValue))
        let platform: MessagePackValue = "1"                            //手机平台
        
//        print("=====token:\(token)")
        //let array: MessagePackValue = [.Float(1), .Float(3), .Float(5), .Float(7)]
        //数据数量数组：0头戴数,1血压数,2儿童手环体温数,3设备数,4儿童手环干预数据
        
        let num: MessagePackValue = MessagePackValue(parameter.count)
        var count: MessagePackValue!
        switch (type) {
        case CIMDeviceMode.Device:
            count = [1, 0, 0, 0, 0]
        case CIMDeviceMode.Pressure:
            count = [0, num, 0, 0, 0]
        case CIMDeviceMode.Bracelet:
            count = [0, 0, num, 0, 0]
        case CIMDeviceMode.Hardware:
            count = [0, 0, 0, num, 0]
        case CIMDeviceMode.Intervent:
            count = [0, 0, 0, 0, 1]
        default:
            count = [0, 0, 0, 0, 0]
            break
        }
        
        let r1 = pack(token)
        let r2 = pack(profildId)
        let r3 = pack(platform)
        let r4 = pack(count)
        
//        print("\(token), \(platform), \(count)")
        let data = NSMutableData()
        data.appendData(NSData(bytes: r1, length: r1.count))
        data.appendData(NSData(bytes: r2, length: r2.count))
        data.appendData(NSData(bytes: r3, length: r3.count))
        data.appendData(NSData(bytes: r4, length: r4.count))
        return data
    }
    
    typealias connectSuccessClosure = () -> Void
    typealias connectFailureClosure = () -> Void
    
    var successClosure: connectSuccessClosure?
    var failureClosure: connectFailureClosure?
    
    //MARK: 设置闭包
    /** 设置请求回调 */
    func connectionClosure(success: connectSuccessClosure, failure: connectFailureClosure) {
        successClosure = success
        failureClosure = failure
    }

    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        mData.length = 0
    }

    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        mData.appendData(data)
    }

    //MARK: >> 请求完成
    func connectionDidFinishLoading(connection: NSURLConnection) {
//        dispatch_queue_t myQueue = dispatch_queue_create("putBraceletSDKData", NULL);
//        dispatch_async(myQueue, ^{
        
        changeNetworkState()
        
        let myResult = try? NSJSONSerialization.JSONObjectWithData(mData, options: NSJSONReadingOptions.MutableContainers) as? [String: AnyObject]
//        NSLog("Connection请求成功:\(myResult)")
        
//        let str = NSString(data: mData, encoding: NSUTF8StringEncoding)
//        print("\(str)")
        
        NSLog("Connection请求成功,\(deviceType),:\(NSString(data: mData, encoding: NSUTF8StringEncoding))")
        if (myResult != nil) {
            let code = myResult!!["code"] as? NSInteger
            if (code == 1) {
                if (successClosure != nil) {
                    successClosure!()
                }
                
                for item in mArray {
                    if item as? [DeviceData] != nil {
                        for model in item as! [DeviceData] {
                            FMDBManager.shareManager().changeDeviceDate(LTFunction.nowTimeTs().description, collectionTime: model.collection_time)
                        }
                    }else if item as? [PressureDataModel] != nil {
                        for model in item as! [PressureDataModel] {
                            FMDBManager.shareManager().changePressureData(LTFunction.nowTimeTs().description, collectionTime: model.collection_time)
                        }
                    }else if item as? [BraceletModel] != nil {
                        for model in item as! [BraceletModel] {
                            FMDBManager.shareManager().changeBraceletDate(LTFunction.nowTimeTs().description, collectionTime: model.collection_time)
                        }
                    }else if item as? [BTDevice] != nil {
                        for model in item as! [BTDevice] {
                            FMDBManager.shareManager().bindingDeviceUpdateBindingUpdate(model)
                        }
                    }else if item as? [String] != nil {
                        
                    }else if item as? DeviceData != nil {
                        FMDBManager.shareManager().changeDeviceDate(LTFunction.nowTimeTs().description, collectionTime: (item as! DeviceData).collection_time)
                    }else if item as? PressureDataModel != nil {
                        FMDBManager.shareManager().changePressureData(LTFunction.nowTimeTs().description, collectionTime: (item as! PressureDataModel).collection_time)
                    }else if item as? BraceletModel != nil {
                        FMDBManager.shareManager().changeBraceletDate(LTFunction.nowTimeTs().description, collectionTime: (item as! BraceletModel).collection_time)
                    }else if item as? BTDevice != nil {
                        FMDBManager.shareManager().bindingDeviceUpdateBindingUpdate(item as! BTDevice)
                    }
                }
                
                return
            }else if (code == 3001) {
                LTFunction.logoutHint()
            }
        }
        
        if (failureClosure != nil) {
            failureClosure!()
        }
    }

    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        print("Connection请求失败Error:\(error)")
        if (failureClosure != nil) {
            failureClosure!()
        }
        changeNetworkState()
    }
    
    //MARK: >> 解析头带数据
    /** 解析头带数据 */
    func analysisDevice(parameter: [DeviceData]) -> NSData {
        let data = NSMutableData()
        for model in parameter {
            let time = model.collection_time.timeTsToYYYYMMddHHmmss.timeToDataAndTime
            //            print("头带数据:\(model.heartRate), \(model.spO2), \(model.temperature), \(model.respirationRate), ")
            let deviceData: MessagePackValue =
                [
                    .Float(time.0.floatValue),
                    .Float(time.1.floatValue),
                    .Float(model.heartRate.floatValue),
                    .Float(model.spO2.floatValue),
                    .Float(model.temperature.floatValue),
                    .Float(model.environmentTem.floatValue),
                    .Float(model.bodyPosture.floatValue),
                    .Float(model.stepCount.floatValue),
                    .Float(model.getRed_AC.floatValue),
                    .Float(model.getIR_AC.floatValue),
                    
                    .Float(model.rawEnvironmentTem.floatValue),
                    .Float(model.dynamicDegree.floatValue),
                    .Float(model.breathPauseType.floatValue),
                    .Float(model.breathPauseDegree.floatValue),
                    .Float(model.respirationRate.floatValue),
                    
                    .Float(model.activityType.floatValue),
                    .Float(model.activityDegree.floatValue),
                    .Float(model.fallDetection.floatValue),
                    .Float(model.getRed_DC.floatValue),
                    .Float(model.getIR_DC.floatValue),
                    
                    .Float(model.signalState.floatValue),
                    .Float(model.overallHealthState.floatValue),
                    .Float(model.sleepQuality.floatValue),
                    .Float(model.caloriesEstimation.floatValue),
                    .Float(model.temperatureFromUnit.floatValue),
                    .Float(model.temperatureParm1.floatValue),
                    .Float(model.temperatureParm2.floatValue),
                    .Float(model.battery.floatValue),
                    .Float(model.rawSurfaceTemperature.floatValue),
                    
                    .Float(0),  //预留字段.....
                    .Float(0),
                    .Float(0),
                    .Float(0),
                    .Float(0),
                    ]
            let devicePack = pack(deviceData)
            data.appendData(NSData(bytes: devicePack, length: devicePack.count))
        }
        return data
    }
    
    func analysisPressure(parameter: [PressureDataModel]) -> NSData {
        let data = NSMutableData()
        for model in parameter {
            let time = model.collection_time.timeToDataAndTime
            //            print("=============\(time),\(model.sbp), \(model.dbp), \(model.pulse)")
            
            let packValue: MessagePackValue = [
                MessagePackValue.Float(Float(time.0.floatValue)),
                MessagePackValue.Float(Float(time.1.floatValue)),
                MessagePackValue.Float(Float(model.sbp)),
                MessagePackValue.Float(Float(model.dbp)),
                MessagePackValue.Float(Float(model.pulse))
            ]
            let pressurePack = pack(packValue)
            data.appendData(NSData(bytes: pressurePack, length: pressurePack.count))
        }
        return data
    }
    
    func analysisBracelet(parameter: [BraceletModel]) -> NSData {
        let data = NSMutableData()
        for model in parameter {
            //0-时间戳，1-体核温度，2-目标温度，3-环境温度 1456982000
            let time = model.collection_time.timeToDataAndTime
            let braceletData: MessagePackValue = [
                .Float(time.0.floatValue),
                .Float(time.1.floatValue),
                .Float(Float(model.TCTem)),
                .Float(Float(model.TOTem)),
                .Float(Float(model.TATem))
            ]
            let braceletPack = pack(braceletData)
            data.appendData(NSData(bytes: braceletPack, length: braceletPack.count))
        }
        return data
    }
    
    func  analysisHardwareDevice(parameter: [BTDevice]) -> NSData {
        let data = NSMutableData()
        for model in parameter {
            //            print("======绑定状态:\(model.createTime), \(model.status ? "0" : "1"), \(model.type.rawValue.description), \(model.bluetooth), \(model.name), \(model.version), default, default")
            let bindingData: MessagePackValue = [
                MessagePackValue(model.createTime),
                MessagePackValue(model.status ? "0" : "1"),   //-1默认,0绑定,1解绑
                MessagePackValue(model.type.rawValue.description),  //设备类型
                MessagePackValue(model.bluetooth),  //bluetooth
                MessagePackValue(model.name),       //
                MessagePackValue(model.version),    //版本
                MessagePackValue("default"),               //hardwareType
                MessagePackValue("default"),               //markettypeName
            ]
            let bindingPack = pack(bindingData)
            data.appendData(NSData(bytes: bindingPack, length: bindingPack.count))
        }
        
        return data
    }
    
    /** 结束指定的网络请求，修改其状态。 防止离线数据，多次上传 */
    func changeNetworkState() {
        if (isDetection) {
            LTManager.shareManager().detection.detection = false
        }
    }
}
