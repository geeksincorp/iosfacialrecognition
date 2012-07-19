//
//  FRFirstViewController.h
//  FacialRecognition
//
//  Created by Mohit Athwani on 15/11/11.
//  Copyright (c) 2011 Geeks Incorporated. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FRBackend.h"

@interface FRFirstViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITextFieldDelegate> {
    
    UIImage *clickedImage;
    CGRect faceRect;
    int count;
    NSString *name;
    NSMutableArray *namesOfPeople;
    NSMutableString *inputString;
    NSString *outputString;
    BOOL isFirstEntry;
    
   
    
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
//@property (weak, nonatomic) FRBackend *frBackend;
@property (weak, nonatomic) IBOutlet UIButton *theNewButton;
@property (weak, nonatomic) IBOutlet UIButton *clickButton;
- (IBAction)disablePressed:(id)sender;

- (IBAction)newPersonClicked:(id)sender;

-(IBAction)takePictureButtonPressed:(id)sender;
- (IBAction)doneButtonPressed:(id)sender;

@end
