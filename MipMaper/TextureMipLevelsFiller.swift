//
//  TextureMipLevelsFiller.swift
//  MipMaper
//
//  Created by Andrew K. on 10/20/14.
//  Copyright (c) 2014 None. All rights reserved.
//

import UIKit

class TextureMipLevelsFiller: NSObject {
  
  class var sharedInstance : TextureMipLevelsFiller {
  struct Static {
    static var onceToken : dispatch_once_t = 0
    static var instance : TextureMipLevelsFiller? = nil
    }
    dispatch_once(&Static.onceToken) {
      Static.instance = TextureMipLevelsFiller()
    }
    return Static.instance!
  }
  
  var device: MTLDevice?
  var commandQ: MTLCommandQueue?
  
  func fillMipLevels(#texture: MetalTexture){
    
    if let commandQ = commandQ{
      if let device = device{
        var sourceTex = texture.texture
        var destinationTex = MetalTexture.textureCopy(source: sourceTex,device: device, mipmaped: true)
        
        fill(mipLevel: 1, source: sourceTex, destination: destinationTex, isLast: false, completionBlock: { () -> Void in
          texture.texture = destinationTex
        })
      }
    }
  }
  
  func fill(#mipLevel: Int, source: MTLTexture, destination: MTLTexture,isLast: Bool , completionBlock: ()->Void){
    
    var q = Int(powf(2, Float(mipLevel)))
    
    var commandBuffer = commandQ!.commandBuffer()
    
    commandBuffer.addCompletedHandler { (buffer) -> Void in
      if isLast{
        completionBlock()
      }else{
        MetalTexture.copyMipLayer(source: destination, destination: source, mipLvl: mipLevel)
        self.fill(mipLevel: mipLevel + 1, source: source, destination: destination, isLast: (mipLevel + 1) >= 8, completionBlock: completionBlock)
      }
    }
    
    var library = device!.newDefaultLibrary()
    var reflectFunc = library!.newFunctionWithName("populateMipmapLevels")
    
    var error = NSErrorPointer()
    
    var computeState = device!.newComputePipelineStateWithFunction(reflectFunc!, error: error)
    
    var computeEncoder = commandBuffer.computeCommandEncoder()
    computeEncoder.setComputePipelineState(computeState!)
    computeEncoder.setTexture(source, atIndex: 0)
    computeEncoder.setTexture(destination, atIndex: 1)
    var buffer = [mipLevel]
    var qBuf = device!.newBufferWithBytes(buffer, length: sizeof(Int), options: nil)
    computeEncoder.setBuffer(qBuf, offset: 0, atIndex: 0)
    
    var workGroupCount = MTLSizeMake(2, 2, 1)
    var workItemComplexity = MTLSize(width: max(Int(source.width/q),1), height: max(Int(source.height)/q,1), depth: 1)
    
    //Execute
    computeEncoder.dispatchThreadgroups(workItemComplexity, threadsPerThreadgroup: workGroupCount)
    
    //Finish encoding
    computeEncoder.endEncoding()
    
    
    commandBuffer.commit()
    
  }
  
}
