//
//  OpenCVWrapper.h
//  myiosappopencv
//
//  Created by Student on 09/06/24.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

+ (NSArray<NSValue *> *)detectFaceRectsInUIImage:(UIImage *)image;

@end

