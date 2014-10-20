//
//  ViewController.swift
//  MipMaper
//
//  Created by Andrew K. on 10/20/14.
//  Copyright (c) 2014 None. All rights reserved.
//

import UIKit
import Metal

class ViewController: UIViewController {
  
  
  @IBOutlet weak var label: UIBarButtonItem!
  @IBOutlet weak var imageView: UIImageView!
  
  var texture1: MetalTexture?
  
  @IBAction func sliderValueChanged(sender: UISlider) {
    var newValue = Int(sender.value)
    var image:UIImage = self.texture1!.image(mipLevel: newValue)
    self.imageView.image = image;
    label.title = "\(newValue)"
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    var device = MTLCreateSystemDefaultDevice()
    var commandQ = device.newCommandQueue()
    
    self.texture1 = MetalTexture(resourceName: "goat", ext: "png", mipmaped: true)
    self.texture1!.loadTexture(device: device, flip: true)
    
    var mipLevelsFiller = TextureMipLevelsFiller.sharedInstance
    mipLevelsFiller.device = device
    mipLevelsFiller.commandQ = commandQ
    
    mipLevelsFiller.fillMipLevels(texture: texture1!)
    
  }
}
