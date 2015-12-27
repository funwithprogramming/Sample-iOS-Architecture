//
//  ConnectionUtility.swift
//  AMCAT
//
//  Created by Alekh  on 15/05/15.
//  Copyright (c) 2015 Alekh Mittal. All rights reserved.
//

import UIKit

class ConnectionUtility {
   
    
    func parsedata(data:NSData)->NSDictionary?{
        let data: NSData = data
        var jsonError: NSError?
        let decodedJson:AnyObject?
        do {
            decodedJson = try NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            jsonError = error
            decodedJson = nil
        }
        let jsonObject  =  decodedJson as? NSDictionary
        let json = NSString(data:data, encoding:NSUTF8StringEncoding)
        print("JSON RESPONSE:")
        print(json)
        //TODO error handling
        return jsonObject
    }
    
    
    func getGetParametersForDictionary(dictionary:NSDictionary)->String{
        
        let array = NSMutableArray()
        for key in dictionary.allKeys{
            if let k  = key as? String , val = dictionary.valueForKey(k) as?String {
                let keyvalstring = k + "=" + val
                array.addObject(keyvalstring)
            }
        }
        let getString = array.componentsJoinedByString("&")
        return getString
    }
    

    
    
    func getParameterBodyForRequestDictionary(dictionary:NSDictionary)->NSData?{
        
        var keyvalfullstring = ""
        for key in dictionary.allKeys{
            if let k  = key as? String , val = dictionary.valueForKey(k) as?String {
                let keyvalstring = k + "=" + val
                keyvalfullstring += keyvalstring + "&"
            }
            
        }
        
        let myNSString = keyvalfullstring as NSString
        myNSString.substringWithRange(NSRange(location:0, length:myNSString.length))
        let data = (keyvalfullstring as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        if let unwrappedData = data {
            return unwrappedData
        }
            
        else {
            return nil
        }
    }
}
