//
//  response.swift
//  TaylorTest
//
//  Created by Jorge Izquierdo on 19/06/14.
//  Copyright (c) 2014 Jorge Izquierdo. All rights reserved.
//

import Foundation

public class TResponse: TResponseProtocol {
    
    private let socket: GCDAsyncSocket?
    private var statusLine: String = ""
    
    public var statusCode: Int = 200
    public var headers: Dictionary<String, String> = Dictionary<String, String>()
    
    public var sent: Bool = false
    
    public var body: NSData?
    public var bodyString: String? {
    didSet {
        if headers["Content-Type"] == nil {
            headers["Content-Type"] = Taylor.FileTypes.get("txt")
        }
    }
    }
    
    
    private let http_protocol: String = "HTTP/1.1"
    internal var codes = [
    200: "OK",
    201: "Created",
    202: "Accepted",
    
    300: "Multiple Choices",
    301: "Moved Permanently",
    302: "Found",
    303: "See other",
    
    400: "Bad TRequest",
    401: "Unauthorized",
    403: "Forbidden",
    404: "Not Found",
    
    500: "Internal Server Error",
    502: "Bad Gateway",
    503: "Service Unavailable"
    ]
    
    convenience init(){
        
        self.init(socket: nil)
    }

    
    init(socket s: GCDAsyncSocket?){
        
        socket = s
    }
    
    func redirect(url u: String) {
        
        self.statusCode = 302
        self.headers["Location"] = u
        self.send()
    }
    
    
    public func sendFile(data: NSData, fileType: NSString) {
        
        self.body = data
        self.headers["Content-Type"] = fileType
        
        self.send()
    }
    
    public func sendError(errorCode: Int){
        
        self.statusCode = errorCode
        
        if let a = self.codes[self.statusCode]{
            
            self.bodyString = a
        }
        
        self.send()
        
    }
    public func send() {
        
        assert(!self.sent)
        self.sent = true
        
        if socket != nil {
            
            socket!.writeData(self.generateResponse(), withTimeout: 10, tag: 1)
        }
        
    }
    
    internal func generateResponse() -> NSData {
        
        if let a = self.codes[self.statusCode]{
            
            self.statusLine = a
        }
        
        var bodyData: NSData = NSData()
        
        if body != nil {
            bodyData = body!
        } else if bodyString != nil {
            bodyData = NSData(data: bodyString!.dataUsingEncoding(NSUTF8StringEncoding))
        }
        
        if headers["Content-Length"] == nil{
            headers["Content-Length"] = String(bodyData.length)
        }
        
        var startLine = "\(self.http_protocol) \(String(self.statusCode)) \(self.statusLine)\r\n"
        
        var headersStr = ""
        for (k, v) in self.headers {
            
            headersStr += "\(k): \(v)\r\n"
        }
        
        headersStr += "\r\n"
        var finalStr = String(format: startLine+headersStr)
        
        var data: NSMutableData = NSMutableData(data: finalStr.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false))
        data.appendData(bodyData)
        
        return data as NSData
    }
}