//
//  MetalTexture.swift
//  MetalKernelsPG
//
//  Created by Andrew K. on 10/20/14.
//  Copyright (c) 2014 Andrew K. All rights reserved.
//

import UIKit

class MetalTexture: NSObject {

  var texture: MTLTexture!
  var target: MTLTextureType!
  var width: UInt!
  var height: UInt!
  var depth: UInt!
  var format: MTLPixelFormat!
  var hasAlpha: Bool!
  var path: String!
  var isMipmaped: Bool!
  
  init(resourceName: String,ext: String, mipmaped:Bool){
    
    path = NSBundle.mainBundle().pathForResource(resourceName, ofType: ext)
    width    = 0
    height   = 0
    depth    = 1
    format   = MTLPixelFormat.RGBA8Unorm
    target   = MTLTextureType.Type2D
    texture  = nil
    isMipmaped = mipmaped
    
    super.init()
  }
  
  class func textureCopy(#source:MTLTexture,device: MTLDevice, mipmaped: Bool) -> MTLTexture {
    var texDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.RGBA8Unorm, width: Int(source.width), height: Int(source.height), mipmapped: mipmaped)
    var copyTexture = device.newTextureWithDescriptor(texDescriptor)
    
    
    var region = MTLRegionMake2D(0, 0, Int(source.width), Int(source.height))
    var pixelsData = malloc(UInt(source.width * source.height * 4))
    source.getBytes(pixelsData, bytesPerRow: Int(source.width) * 4, fromRegion: region, mipmapLevel: 0)
    copyTexture.replaceRegion(region, mipmapLevel: 0, withBytes: pixelsData, bytesPerRow: Int(source.width) * 4)
    return copyTexture
  }
  
  class func copyMipLayer(#source:MTLTexture, destination:MTLTexture, mipLvl: Int){
    var q = Int(powf(2, Float(mipLvl)))
    var mipmapedWidth = max(Int(source.width)/q,1)
    var mipmapedHeight = max(Int(source.height)/q,1)
    
    var region = MTLRegionMake2D(0, 0, mipmapedWidth, mipmapedHeight)
    var pixelsData = malloc(UInt(mipmapedHeight * mipmapedWidth * 4))
    source.getBytes(pixelsData, bytesPerRow: mipmapedWidth * 4, fromRegion: region, mipmapLevel: mipLvl)
    destination.replaceRegion(region, mipmapLevel: mipLvl, withBytes: pixelsData, bytesPerRow: mipmapedWidth * 4)
  }
  
  func loadTexture(#device: MTLDevice, flip: Bool){
    
    var image = UIImage(contentsOfFile: path)?.CGImage
    var colorSpace = CGColorSpaceCreateDeviceRGB()
    
    width = CGImageGetWidth(image)
    height = CGImageGetHeight(image)
    
    var rowBytes = width * 4
    
    var context = CGBitmapContextCreate(nil, width, height, 8, rowBytes, colorSpace, CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue))
    var bounds = CGRect(x: 0, y: 0, width: Int(width), height: Int(height))
    CGContextClearRect(context, bounds)
    
    if flip == false{
      CGContextTranslateCTM(context, 0, CGFloat(self.height))
      CGContextScaleCTM(context, 1.0, -1.0)
    }
    
    CGContextDrawImage(context, bounds, image)
    
    var texDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.RGBA8Unorm, width: Int(width), height: Int(height), mipmapped: isMipmaped)
    target = texDescriptor.textureType
    texture = device.newTextureWithDescriptor(texDescriptor)
    
    var pixelsData = CGBitmapContextGetData(context)
    var region = MTLRegionMake2D(0, 0, Int(width), Int(height))
    texture.replaceRegion(region, mipmapLevel: 0, withBytes: pixelsData, bytesPerRow: Int(rowBytes))
    println("mipCount:\(texture.mipmapLevelCount)")
  }
  
  func bytesForMipLevel(#mipLevel: Int) -> UnsafeMutablePointer<Void>{
    var q = Int(powf(2, Float(mipLevel)))
    var mipmapedWidth = max(Int(width) / q,1)
    var mipmapedHeight = max(Int(height) / q,1)
    
    var rowBytes = Int(mipmapedWidth * 4)
    
    var region = MTLRegionMake2D(0, 0, mipmapedWidth, mipmapedHeight)
    var pointer = malloc(UInt(rowBytes * mipmapedHeight))
    texture.getBytes(pointer, bytesPerRow: rowBytes, fromRegion: region, mipmapLevel: mipLevel)
    return pointer
  }
  
  func bytes() -> UnsafeMutablePointer<Void>{
    return bytesForMipLevel(mipLevel: 0)
  }
  
  func image(#mipLevel: Int) -> UIImage{
    
    var p = bytesForMipLevel(mipLevel: mipLevel)
    var q = UInt(powf(2, Float(mipLevel)))
    var mipmapedWidth = max(UInt(width) / q,1)
    var mipmapedHeight = max(UInt(height) / q,1)
    var rowBytes = UInt(mipmapedWidth * 4)
    
    var colorSpace = CGColorSpaceCreateDeviceRGB()
    
    var context = CGBitmapContextCreate(p, mipmapedWidth, mipmapedHeight, 8, rowBytes, colorSpace, CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue))
    var imgRef = CGBitmapContextCreateImage(context)
    var image = UIImage(CGImage: imgRef)
    return image!
  }
  
  func image() -> UIImage{
    return image(mipLevel: 0)
  }
  
}
