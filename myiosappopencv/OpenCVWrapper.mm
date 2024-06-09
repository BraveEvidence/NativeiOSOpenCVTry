#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "OpenCVWrapper.h"

@interface UIImage (OpenCVWrapper)
- (void)convertToMat: (cv::Mat *)pMat: (bool)alphaExists;
@end

@implementation UIImage (OpenCVWrapper)

- (void)convertToMat: (cv::Mat *)pMat: (bool)alphaExists {
    UIImageOrientation orientation = self.imageOrientation;
    cv::Mat mat;
    UIImageToMat(self, mat, alphaExists);
    
    switch (orientation) {
        case UIImageOrientationRight:
            cv::rotate(mat, *pMat, cv::ROTATE_90_CLOCKWISE);
            break;
        case UIImageOrientationLeft:
            cv::rotate(mat, *pMat, cv::ROTATE_90_COUNTERCLOCKWISE);
            break;
        case UIImageOrientationDown:
            cv::rotate(mat, *pMat, cv::ROTATE_180);
            break;
        case UIImageOrientationUp:
        default:
            *pMat = mat;
            break;
    }
}
@end

@implementation OpenCVWrapper

static cv::CascadeClassifier faceCascade;

+ (void)initialize {
    if (self == [OpenCVWrapper self]) {
        NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_default" ofType:@"xml"];
        if (!faceCascade.load([faceCascadePath UTF8String])) {
            NSLog(@"Error loading face detection model");
        }
    }
}

+ (NSArray<NSValue *> *)detectFaceRectsInUIImage:(UIImage *)image {
    // Convert UIImage to cv::Mat
    cv::Mat mat;
    [image convertToMat:&mat :false];

    // Convert the image to grayscale
    cv::Mat gray;
    cv::cvtColor(mat, gray, cv::COLOR_BGR2GRAY);
    cv::equalizeHist(gray, gray);

    // Detect faces
    std::vector<cv::Rect> faces;
    faceCascade.detectMultiScale(gray, faces, 1.1, 2, 0 | cv::CASCADE_SCALE_IMAGE, cv::Size(30, 30));

    // Convert cv::Rect to CGRect and wrap in NSValue
    NSMutableArray<NSValue *> *faceRects = [NSMutableArray arrayWithCapacity:faces.size()];
    for (const auto &face : faces) {
        CGRect faceRect = CGRectMake(face.x, face.y, face.width, face.height);
        [faceRects addObject:[NSValue valueWithCGRect:faceRect]];
    }

    return [faceRects copy];
}

@end
