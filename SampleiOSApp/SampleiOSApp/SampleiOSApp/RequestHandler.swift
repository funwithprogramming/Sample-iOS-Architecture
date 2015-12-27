
//  AMAppHandler.swift
//  AMCAT
//
//  Created by Alekh  on 11/05/15.
//  Copyright (c) 2015 Alekh Mittal. All rights reserved.
//


//this class handles tye network request and handles the repsosnse for VC Managers
//It also handles whether it has to create seperate thread for that particular network equest




import Foundation

//This encapsulates request

class CustomConnRequest{
    
    var route:Routes
    var methodType:MethodType?
    var arguments:Dictionary<String,String>?
    var routeAppendedPath:String?
    
    init(route:Routes,methodType:MethodType,argument:Dictionary<String,String>?){
        self.route = route
        self.methodType = methodType
        self.arguments  = argument
    }
    
    convenience init(route:Routes,methodType:MethodType){
        self.init(route:route,methodType:methodType,argument:nil)
    }
    
    
}


//This class encapsulates response
class CustomConnResponse {
    
    var jsonResponse:Dictionary<String,AnyObject>?
    var  responseClosure:(status:ServiceErrors?,message:String?,data:AnyObject? )->( )
    //the closure
    init(resclosure:(status:ServiceErrors?,message:String?,data:AnyObject?)->( )){
        self.responseClosure = resclosure
    }
    
}

enum Routes:String {
    case  Authenticate      = "api/v1/authenticate"
}

enum ServiceErrors:String {
    
    case  Success = "success"
    case  Failure = "error"
    case  ErrorJSON = "jsonError"
    case  NoNetwork = "no netwok"
    
}




//Error types

enum errorTypes{
    case NO_Network
}



//Singleton Class.

//We are inheriting this class from nsobject because we want to use this in objective c
class RequestHandler {
    
    class var sharedInstance: RequestHandler {
        struct Static {
            static var instance: RequestHandler?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = RequestHandler()
            
        }
        
        return Static.instance!
    }
    
    init(){
        singleserviceobject =  CustomConnection.sharedInstance
        let keys = getKeysFromDatabase()
        if let kys = keys{
            singleserviceobject.initAppsKeys(kys.0, tokenkey:kys.1)
        }
        
    }
    
    //The handler has one service object
    let singleserviceobject:CustomConnection
    
    var storedResponse:CustomConnResponse? = nil
    
    //login with username and password
    
    func loginRequest(request:CustomConnRequest,response:CustomConnResponse?){
        self.storedResponse = response
        singleserviceobject.initWithRequest(request, resonse:getResponseModifiedForLoginAndRegistration())
    }
    
    
    func registerRequest(request:CustomConnRequest,response:CustomConnResponse?){
        
        //TODO: repeated code. Please change
        self.storedResponse = response
        singleserviceobject.initWithRequest(request, resonse:getResponseModifiedForLoginAndRegistration())
    }
    
    func resetPasswordCode(request:CustomConnRequest,response:CustomConnResponse?){
        singleserviceobject.initWithRequest(request, resonse:response!)
    }
    
    
    
    
    func getResponseModifiedForLoginAndRegistration()->CustomConnResponse{
        
        let responseModified = CustomConnResponse {[weak self] (status, message, data) -> () in
            
            //let datadict = data as? NSDictionary
            
            var dict:NSDictionary? = data?.valueForKey("data") as? NSDictionary
            
            //this cheque is done because there is issue from srver side
            if (dict==nil){
                let array = data?.valueForKey("data") as? NSArray
                dict = array?.firstObject as? NSDictionary
            }
            
            //1. Now modify the headers
            self?.singleserviceobject.initAppsKeys((dict?.objectForKey("apiSecretKey") as? String), tokenkey:(dict?.objectForKey("apiToken") as? String))
            //2. Call the closure
            self?.storedResponse?.responseClosure(status: status, message: message, data: data)
            
        }
        
        return responseModified
    }
    
    func CommentRequest(request:CustomConnRequest,response:CustomConnResponse?){
        singleserviceobject.initWithRequest(request, resonse:response!)
    }
    
    //for downloading file
    
    func downloadRequest(urlString:String,delegateNew:ConnectionDownloadDelegate?){
        singleserviceobject.initDownlodTaskWithURLString(urlString, delegate: delegateNew)
    }
    
    //for uploading file
    //TODO: CHange its parameters
    func uploadImageRequest(fileformat:String,sendimageData:NSData,delegateNew:ConnectionUploadDelegate?){
        singleserviceobject.uploadImageTaskWithType("pic",fileFormat:fileformat,imageData:sendimageData, assineddelegate:delegateNew)
    }
    
    
    //Call from objective c. We need modification in Method
    
    
    func getReturnJSONStringForSlotID(slotID:String,returnedJson:(data:NSDictionary? )->( )){
        
//        let argument = ["slotID":slotID]
//        //self.returnClosure = data
//        
//        let amcrequest = AMCRequest(route:Routes.Slots, methodType:MethodType.POST, argument:argument)
//        let amresponse = AMCResponse { (status, message, data) -> () in
//            returnedJson(data:data as? NSDictionary)
//            
//        }
//        singleserviceobject.initWithRequest(amcrequest, resonse:amresponse)
    }
    
    
    
    //MARK: UTILITIES
    
    func getKeysFromDatabase()->(String?,String?)?{
     
        return nil
    }
}







