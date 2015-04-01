//
//  ImageCache.swift
//  Yep
//
//  Created by NIX on 15/3/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Realm

class ImageCache {
    static let sharedInstance = ImageCache()

    var cache = NSCache()

    func rightMessageImageOfMessage(message: Message, completion: (UIImage) -> ()) {

        let imageKey = "image-\(message.messageID)-\(message.localAttachmentName)--\(message.attachmentURLString)"

        // 先看看缓存
        if let image = cache.objectForKey(imageKey) as? UIImage {
            completion(image)

        } else {

            let fileName = message.localAttachmentName
            let attachmentURLString = message.attachmentURLString

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {

                if !fileName.isEmpty {
                    if
                        let imageFileURL = NSFileManager.yepMessageImageURLWithName(fileName),
                        let image = UIImage(contentsOfFile: imageFileURL.path!) {

                            let rightMessageImage = image.bubbleImageWithTailDirection(.Right, size: CGSize(width: 200, height: 100))

                            self.cache.setObject(rightMessageImage, forKey: imageKey)
                            
                            completion(rightMessageImage)

                            return
                    }
                }

                // TODO: 下载

                if attachmentURLString.isEmpty {
                    completion(UIImage())

                    return
                }

                let url = NSURL(string: attachmentURLString)!

                if let data = NSData(contentsOfURL: url) {
                    let image = UIImage(data: data)!

                    let messageImageName = NSUUID().UUIDString

                    let messageImageURL = NSFileManager.saveMessageImageData(data, withName: messageImageName)

                    dispatch_async(dispatch_get_main_queue()) {
                        let realm = message.realm
                        realm.beginWriteTransaction()
                        message.localAttachmentName = messageImageName
                        realm.commitWriteTransaction()
                    }

                    let rightMessageImage = image.bubbleImageWithTailDirection(.Right, size: CGSize(width: 200, height: 100))

                    self.cache.setObject(rightMessageImage, forKey: imageKey)
                    
                    completion(rightMessageImage)
                }
            }



        }
    }
}