//
//  FRSecondViewController.h
//  FacialRecognition
//
//  Created by Mohit Athwani on 15/11/11.
//  Copyright (c) 2011 Geeks Incorporated. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FRSecondViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITextFieldDelegate> {
    
    UIImage *clickedImage;
    CGRect faceRect;
    NSMutableString *inputString;
    NSString *outputString;
    
}
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *confidenceLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
- (IBAction)clickButtonPressed:(id)sender;
int loadFaceImgArray ();
void recognizeFileList();
@end
