//
//  BaseConnection.swift
//  AMCAT
//
//  Created by Alekh  on 12/05/15.
//  Copyright (c) 2015 Alekh Mittal. All rights reserved.
//

import Foundation

enum MethodType:String{
    case GET = "GET"
    case POST  = "POST"
    case DELETE = "DELETE"
    case PUT = "PUT"
    
}

@objc protocol ConnectionDownloadDelegate {
    
    optional func isDownloadingWithProgress(progress:Double)
    optional func didFinishWithPath(path:NSURL)
    optional func didFinishWithError(error:String)
    
}




class BaseConnection: NSObject,NSURLSessionDownloadDelegate {
    
    let backgroundSessionIdentifier = "backgroundSessionIdentifier"
    let connectRequest = ""
    let opq:NSOperationQueue? = nil
    
    var secretKey:String?
    var tokenKey:String?
    var baseURL:String = "http://"
    
    private var sessionconfig:NSURLSessionConfiguration = NSURLSessionConfiguration()
    private var session:NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: nil, delegateQueue: nil)
    private var downloadDelegate:ConnectionDownloadDelegate?
    
    
    func setHeaders(authKey:String,sessionKey:String){
        self.secretKey = sessionKey;
        self.tokenKey = authKey;
    }
    
    
    //MARK: General Function
    func initWithURL(URL:String,method:MethodType,headers:Dictionary<String,String>?,parameters:NSDictionary?,urlresponse:(NSData?, NSURLResponse?, NSError? )->()){
        
        var fullUrl = baseURL+"/"+URL
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string:fullUrl)!)
        request.setValue(self.secretKey, forHTTPHeaderField:"X-Api-Signature")
        request.setValue(self.tokenKey, forHTTPHeaderField:"X-Api-AuthToken")
        request.HTTPMethod = method.rawValue
        
        //TODO:check
        switch method {
            
        case .GET:
            if let _ = parameters{
                fullUrl  = fullUrl + "?" + ConnectionUtility().getGetParametersForDictionary(parameters!)
                request.URL = NSURL(string:fullUrl)
            }
            //TODO: Change this
        case .DELETE: print("Delete request")
            
            
        default:
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.HTTPBody = ConnectionUtility().getParameterBodyForRequestDictionary(parameters!)
            
        }
        
        let task = session.dataTaskWithRequest(request, completionHandler:urlresponse)
        task.resume();
    }
    
    func initWithURL(URL:String,WithMethod:MethodType,urlresponse:(NSData?, NSURLResponse?, NSError?)->()){
        self.initWithURL(URL, method: WithMethod, headers:nil, parameters:nil, urlresponse: urlresponse)
    }
    
    func initWithURL(URL:String,WithMethod:MethodType,headers:Dictionary<String,String>,urlresponse:(NSData!, NSURLResponse!, NSError!)->()){
        //Empty implementation
    }
    func initWithURL(URL:String,WithMethod:MethodType,parameters:Dictionary<String,String>,urlresponse:(NSData!, NSURLResponse!, NSError!)->()){
        //Empty implementation
    }
    
    
    // MARK : Download Task
    func initDownlodTaskWithURLString(urlString:String,delegate:ConnectionDownloadDelegate?){
        
        downloadDelegate = delegate
        let   privatesessionconfig = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(backgroundSessionIdentifier)
        let downsession = NSURLSession(configuration:privatesessionconfig, delegate: self, delegateQueue: nil)
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string:urlString)!)
        let task =   downsession.downloadTaskWithRequest(request)
        task.resume()
    }
    
    //MARK:File Download delegate  methods
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
    }
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        downloadDelegate?.isDownloadingWithProgress? ((Double(totalBytesWritten))/(Double(totalBytesExpectedToWrite)))
        print("didWriteData")
    }
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL)  {
        downloadDelegate?.didFinishWithPath?(location)
        
    }
    
}
