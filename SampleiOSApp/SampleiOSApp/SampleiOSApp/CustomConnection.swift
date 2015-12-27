//
//  CustomConnection.swift
//  AMCAT
//
//  Created by Alekh  on 11/05/15.
//  Copyright (c) 2015 Alekh Mittal. All rights reserved.
//

import Foundation

//This is singleton class


enum responseKeys:String{
    
    case data = "data"
    case message = "message"
    case status = "status"
    case errcode = "errorCode"
    
}


@objc protocol ConnectionUploadDelegate{
    
    optional func isUploadingWithProgress(progress:Double)
    optional func didFinishUploadingWithUploadURL(uploadURL:String)
    optional func didFinishWithError(error:String)
    
}

let serviesErrorNotification = "serviesNotificationError"

class CustomConnection:BaseConnection,NSURLSessionDataDelegate {
    
    private var uploadDelegate:ConnectionUploadDelegate?
    
    class var sharedInstance: CustomConnection {
        struct Static {
            static var instance: CustomConnection?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = CustomConnection()
        }
        return Static.instance!
    }
    
    //To initialize sec key and auth key
    
    func initAppsKeys(seckey:String?,tokenkey:String?){
        self.secretKey = seckey
        self.tokenKey = tokenkey
    }
    
    func initBaseURL(baseURL:String){
        self.baseURL = baseURL
    }
    
    func initWithRequest(request:CustomConnRequest?,resonse:CustomConnResponse) {
        //var passedheader:Dictionary<String,String>? = [self.secretKey,self.tokenKey]
        if let _:Dictionary = request?.arguments{
            //1. //set the argument here
            //2.
            self.initWithURL(request!.route.rawValue + (request?.routeAppendedPath ?? ""), method:request!.methodType!, headers:nil, parameters:request!.arguments!,urlresponse:{
                (data, urlresponse, error)->Void in
                let parresponse = self.processdataandrespond(data, res:urlresponse, error: error)
                if (parresponse.0 == ServiceErrors.Failure){
                    // NSNotificationCenter.defaultCenter().postNotificationName(serviesErrorNotification, object:self)
                    NSNotificationCenter.defaultCenter().postNotificationName(serviesErrorNotification, object: self, userInfo:["message":parresponse.1])
                }
                
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    resonse.responseClosure(status: parresponse.0, message:parresponse.1, data:parresponse.2)}
            })
        }
        else{
            
            self.initWithURL(request!.route.rawValue + (request?.routeAppendedPath ?? ""), WithMethod: request!.methodType!, urlresponse:{
                (data, urlresponse, error)->Void in
                let parresponse = self.processdataandrespond(data, res:urlresponse, error: error)
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    resonse.responseClosure(status: parresponse.0, message:parresponse.1, data:parresponse.2)}})
        }
        
    }
    
    override func initDownlodTaskWithURLString(urlString:String,delegate:ConnectionDownloadDelegate?){
        super.initDownlodTaskWithURLString(urlString, delegate:delegate)
    }
    
    
    func callResponseInmainThread(){
        
    }
    
    func processdataandrespond(data:NSData!,res:NSURLResponse!, error:NSError!)->(ServiceErrors,String,AnyObject?){
        
        let connUtility:ConnectionUtility = ConnectionUtility()
        //todo nil handling
        var parsedDict:NSDictionary? = nil
        if let unwarpped = data{
            parsedDict = connUtility.parsedata(unwarpped)
        }
        let responsestatus:ServiceErrors
        let responsemessage:String
        if let dict = parsedDict{
            
            //            responsestatus =  ServiceErrors(rawValue:dict.objectForKey(responseKeys.status.rawValue) as! String)!
            //responsestatus =  ServiceErrors.Success  //ServiceErrors(rawValue:dict.objectForKey(responseKeys.status.rawValue) as! String)!
            responsestatus = ServiceErrors(rawValue:dict.objectForKey(responseKeys.status.rawValue) as! String)!
            responsemessage = (dict.valueForKey(responseKeys.message.rawValue) as? String)!
        }
        else{
            responsestatus =  ServiceErrors.Failure
            responsemessage = "Error Reading JSON. Not a valid JSON"
        }
        return (responsestatus,responsemessage,parsedDict)
        
    }
    
    //TODO:this method should be converted to general file upload methods
    // Uploading image task methods.
    func uploadImageTaskWithType(type:String,fileFormat:String,imageData:NSData,assineddelegate:ConnectionUploadDelegate?){
        
        uploadDelegate = assineddelegate
        //Setting Parameter
        let boundary = "---011000010111000001101001"
        let dataBody = NSMutableData()
        dataBody.appendData(NSString(format:"--%@\r\n",boundary ).dataUsingEncoding(0)!)
        dataBody.appendData(NSString(format:"Content-Disposition: form-data; name=\"%@\"\r\n\r\n","type" ).dataUsingEncoding(0)!)
        dataBody.appendData(NSString(format:"profilePic\r\n" ).dataUsingEncoding(0)!)
        
        //setting file data
        //        let fileData = UIImageJPEGRepresentation(UIImage(named:name + "." + fileFormat)!, 0.6)
        let fileData = imageData
        dataBody.appendData(NSString(format:"--%@\r\n",boundary ).dataUsingEncoding(0)!)
        dataBody.appendData(NSString(format:"Content-Disposition: form-data; name=\"%@\"; filename=\"file.%@\"\r\n",type,fileFormat ).dataUsingEncoding(0)!)
        dataBody.appendData(NSString(format:"Content-Type: image/%@\r\n\r\n",fileFormat ).dataUsingEncoding(0)!)
        dataBody.appendData(fileData)
        dataBody.appendData(NSString(format:"\r\n" ).dataUsingEncoding(0)!)
        dataBody.appendData(NSString(format:"--%@--\r\n", boundary ).dataUsingEncoding(0)!)
        
        
        let uploadSessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(backgroundSessionIdentifier)
        let uploadSession = NSURLSession(configuration:uploadSessionConfiguration, delegate:self , delegateQueue: nil)
        let fullUrl = baseURL + "/"
        print("full url =\(fullUrl) ")
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string:fullUrl)!)
        request.HTTPMethod = MethodType.POST.rawValue
        
        //Headers
        request.setValue(self.secretKey, forHTTPHeaderField:"X-Api-Signature")
        request.setValue(self.tokenKey, forHTTPHeaderField:"X-Api-AuthToken")
        request.setValue("multipart/form-data; boundary=---011000010111000001101001", forHTTPHeaderField:"content-type")
        
        //Body
        request.HTTPBody = dataBody
        
        let uploadTask = uploadSession.dataTaskWithRequest(request)
        uploadTask.resume()
        
        
    }
    
    //MARK: Upload delegate methods
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        uploadDelegate?.isUploadingWithProgress? ((Double(bytesSent))/(Double(totalBytesSent)))
    }
    func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        //print("needNewBodyStream")
    }
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        let parresponse = self.processdataandrespond(data, res:nil, error: nil)
        guard let _ = parresponse.2 else {return}
        guard let _ = ((parresponse.2 as! [String:AnyObject])["data"] as? [String:AnyObject]) else {return}
        
        let url = ((parresponse.2 as! [String:AnyObject])["data"] as! [String:AnyObject])["pictureUrl"]
        uploadDelegate?.didFinishUploadingWithUploadURL?(url as! String)
    }
    func URLSession(session:NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        //print("didCompleteWithError")
        
    }
    
    
}