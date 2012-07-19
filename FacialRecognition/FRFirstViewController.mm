//
//  FRFirstViewController.m
//  FacialRecognition
//
//  Created by Mohit Athwani on 15/11/11.
//  Copyright (c) 2011 Geeks Incorporated. All rights reserved.
//

#import "FRFirstViewController.h"
//File name for the Haar Cascade XML file
static const char *HAAR_RESOURCE = "haarcascade_frontalface_alt_tree.xml";

//Temporary storage for the Haar resource
static CvMemStorage *cvStorage = NULL;

//Pointer to the Resource
static CvHaarClassifierCascade *haarCascade = NULL;

@implementation FRFirstViewController
@synthesize theNewButton;
@synthesize clickButton;
@synthesize imageView;
@synthesize doneButton;
@synthesize nameTextField;
//@synthesize frBackend;
//@synthesize backend;

#pragma mark UIImage to IplImage
- (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
    // Getting CGImage from UIImage
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Creating temporal IplImage for drawing
    IplImage *iplimage = cvCreateImage(
                                       cvSize(image.size.width,image.size.height), IPL_DEPTH_8U, 4
                                       );
    // Creating CGContext for temporal IplImage
    CGContextRef contextRef = CGBitmapContextCreate(
                                                    iplimage->imageData, iplimage->width, iplimage->height,
                                                    iplimage->depth, iplimage->widthStep,
                                                    colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault
                                                    );
    // Drawing CGImage to CGContext
    CGContextDrawImage(
                       contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef
                       );
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    // Creating result IplImage
    IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplimage, ret, CV_RGB2BGR);
    cvReleaseImage(&iplimage);
    
    return ret;
}

#pragma mark Iplimage to UIImage
//Convert Image to RGB before calling this
- (UIImage *)UIImageFromIplImage:(IplImage *)image {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Allocating the buffer for CGImage
    NSData *data =
    [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    // Creating CGImage from chunk of IplImage
    CGImageRef imageRef = CGImageCreate(
                                        image->width, image->height,
                                        image->depth, image->depth * image->nChannels, image->widthStep,
                                        colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                        provider, NULL, false, kCGRenderingIntentDefault
                                        );
    // Getting UIImage from CGImage
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return ret;
}


#pragma mark Saving Image
//saving an image

- (void)saveImage:(UIImage*)image withName:(NSString*)personName {
    
    NSError *error;
    
    NSData *imageData = UIImagePNGRepresentation(image); //convert image into .png format.
    
    NSFileManager *fileManager = [NSFileManager defaultManager];//create instance of NSFileManager
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); //create an array and store result of our search for the documents directory in it
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; //create NSString object, that holds our exact path to the documents directory
    
    NSString *filePath = [documentsDirectory 
                          stringByAppendingPathComponent:@"file1.txt"]; //creating the text file to act as the database
    
        
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",personName]]; // dataPath is for the folder within Documents
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
        
        [namesOfPeople addObject:name];
    }
    
    personName = [personName stringByAppendingFormat:@"%d",count];
    

    
    NSString *fullPath = [dataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", personName]]; //add our image to the path
    
    
    [fileManager createFileAtPath:fullPath contents:imageData attributes:nil]; //finally save the path (image)
    
    
    for (int i=0;i<[namesOfPeople count];i++) {
        if([name isEqualToString:[namesOfPeople objectAtIndex:i]])
            //[inputString stringByAppendingFormat:@"%d %@ %@",i+1,name,fullPath];
        //[inputString appendFormat:@"%d %@ %@ \n",i+1,name,fullPath];
            [inputString setString:[NSString stringWithFormat:@"%d %@ %@",i+1,name,fullPath]];
            
    }
    
    if (!isFirstEntry || [fileManager fileExistsAtPath:filePath]) {
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    [fileHandler seekToEndOfFile];
    [fileHandler writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandler seekToEndOfFile];
    [fileHandler writeData:[inputString dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandler closeFile];
    }
    
    else {
    
    [inputString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        isFirstEntry = FALSE;
    }
    
    count++;
    outputString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
    NSLog(@"%@",outputString);
    //NSLog(@"%@ \n %@ \n %@",filePath,dataPath,fullPath);
    
    //Put all this rubbish in a separate function
//    char personNamezz[256];
//    char imgFilename[512];
//    int personNumber;
//    //fopen([filePath UTF8String], "r");
//    fscanf(fopen([filePath UTF8String], "r"), "%d %s %s", &personNumber, personNamezz, imgFilename);
//    NSLog(@"From Fscanf %d %s %s",personNumber,personNamezz,imgFilename);
    
    
    
//    char personNamezz[256];
//    char imgFilename[512];
//    int personNumber;
//    //fopen([filePath UTF8String], "r");
////    fscanf(fopen([filePath UTF8String], "r"), "%d %s %s", &personNumber, personName, imgFilename);
////    NSLog(@"From Fscanf %d %s %s",personNumber,personName,imgFilename);
////    
////    Now what I'm going to do is :
//    
//    NSArray *array = [outputString componentsSeparatedByString:@"\n"]; 
//    int lines = [array count];
//    FILE *file = fopen([filePath UTF8String],"r");
//    for (int i = 0; i<lines; i++) {
//        fscanf(file,"%d %s %s",&personNumber, personNamezz, imgFilename);
//        NSLog(@"From Fscanf %d %s %s",personNumber,personNamezz,imgFilename);
//    }
//    fclose(file);
//    
////    haven't tried the second part yet ... 
    // PUT all this rubbish in a different function ... 
    
//    [backend loadFaceImgArray:[filePath UTF8String]];
    //int n=[FRBackend loadFaceImgArray];
    [FRBackend learn]; //This is where we start training the program
    //remove these lines if you wanna see the original image
    imageView.image = [UIImage imageWithContentsOfFile:[documentsDirectory stringByAppendingPathComponent:@"out_averageImage.png"]];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    NSLog(@"Documents directory: %@",
          [fileManager contentsOfDirectoryAtPath:documentsDirectory error:&error]);
    NSLog(@"Documents directory: %@",
          [fileManager contentsOfDirectoryAtPath:dataPath error:&error]);
}

#pragma mark Crop Image
-(void) cropImage:(UIImage *)image {
    
   // CGSize size = [image size];
    // Create bitmap image from original image data,
    // using rectangle to specify desired crop area
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], faceRect);
    UIImage *img = [UIImage imageWithCGImage:imageRef]; 
    CGImageRelease(imageRef);
    
    IplImage *src = [self CreateIplImageFromUIImage:img];
    IplImage *imageGrey;
    if (src->nChannels == 3) {
        imageGrey = cvCreateImage( cvGetSize(src), IPL_DEPTH_8U, 1 );
        // Convert from RGB (actually it is BGR) to Greyscale.
        cvCvtColor( src, imageGrey, CV_BGR2GRAY );
    }
    else {
        // Just use the input image, since it is already Greyscale.
        imageGrey = src;
    }

    IplImage *imageProcessed;
    imageProcessed = cvCreateImage(cvSize(100, 100), IPL_DEPTH_8U, 1);
    // Make the image a fixed size.
    // CV_INTER_CUBIC or CV_INTER_LINEAR is good for enlarging, and
    // CV_INTER_AREA is good for shrinking / decimation, but bad at enlarging.
    cvResize(imageGrey, imageProcessed, CV_INTER_LINEAR);
    
    // Give the image a standard brightness and contrast.
    cvEqualizeHist(imageProcessed, imageProcessed);
    
    IplImage *imageProcessedColor = cvCreateImage(cvGetSize(imageProcessed), 8, 3);
    cvCvtColor(imageProcessed, imageProcessedColor, CV_GRAY2BGR);
    UIImage *newImage = [self UIImageFromIplImage:imageProcessedColor];
    // Create and show the new image from bitmap data
    imageView.image=newImage;
    imageView.contentMode=UIViewContentModeCenter;
    
    name = nameTextField.text;
    
    
    [self saveImage:newImage withName:name];
    
    
}

#pragma mark Face detection
-(void) drawOnFaceAt:(CvRect *)rect inImage:(IplImage *)image {
    
    //We need points to draw a rectangle
    //cvRectangle(image, cvPoint(rect->x, rect->y), cvPoint(rect->x+rect->width, rect->y+rect->height), cvScalar(255,0,0,255)/*RGBA*/,4,8,0);
    
    faceRect = CGRectMake(rect->x, rect->y, rect->width, rect->height);
}
-(void) detectFaces {
    IplImage *src = [self CreateIplImageFromUIImage:clickedImage];
    
    // Face detection logic comes here
    //Clear the memory incase previous faces were detected
    cvClearMemStorage(cvStorage);
    
    //Detect Faces and get rectangular coordinates
    CvSeq* faces = cvHaarDetectObjects(src, //Input Image
                                       haarCascade, // Cascade to be used
                                       cvStorage, //Temporary storage
                                       1.1,// Size increase for features at each scan
                                       2, //Min number of neighbouring rectangle matches
                                       CV_HAAR_DO_CANNY_PRUNING,//Optimization
                                       cvSize(30, 30)); // Starting feature size
    
    //CvSeq is a linked list with tree feeatures. "faces" is a list of bounding rectangles for each face
    
    for (int i=0; i<faces->total; i++) {
        //cvGetSeqElem is used for random access to CvSeqs
        CvRect *rect = (CvRect *)cvGetSeqElem(faces, i);
        [self drawOnFaceAt:rect inImage:src];
    }
    
    cvCvtColor(src, src, CV_BGR2RGB);
    
    IplImage *imageGrey;
    if (src->nChannels == 3) {
        imageGrey = cvCreateImage( cvGetSize(src), IPL_DEPTH_8U, 1 );
        // Convert from RGB (actually it is BGR) to Greyscale.
        cvCvtColor( src, imageGrey, CV_BGR2GRAY );
    }
    else {
        // Just use the input image, since it is already Greyscale.
        imageGrey = src;
    }
    
    // Resize the image to be a consistent size, even if the aspect ratio changes.
    IplImage *imageProcessed;
    imageProcessed = cvCreateImage(cvSize(src->width, src->height), IPL_DEPTH_8U, 1);
    // Make the image a fixed size.
    // CV_INTER_CUBIC or CV_INTER_LINEAR is good for enlarging, and
    // CV_INTER_AREA is good for shrinking / decimation, but bad at enlarging.
    cvResize(imageGrey, imageProcessed, CV_INTER_LINEAR);
    
    // Give the image a standard brightness and contrast.
    cvEqualizeHist(imageProcessed, imageProcessed);
    
    IplImage *imageProcessedColor = cvCreateImage(cvGetSize(src), 8, 3);
    cvCvtColor(imageProcessed, imageProcessedColor, CV_GRAY2BGR);
    UIImage *newImage = [self UIImageFromIplImage:imageProcessedColor];
    cvReleaseImage(&src);
    //cvCvtColor(newImage, newImage, CV_HSV2RGB);
    
    [self cropImage:newImage];
    //[imageView setImage:newImage];
    
    if (imageGrey)
        cvReleaseImage(&imageGrey);
    if (imageProcessed)
        cvReleaseImage(&imageProcessed);
}



- (IBAction)disablePressed:(id)sender {
    [theNewButton setEnabled:NO];
    [clickButton setEnabled:NO];
}

- (IBAction)newPersonClicked:(id)sender { 
    count = 1;
}

#pragma mark Camera Code
-(IBAction)takePictureButtonPressed:(id)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.delegate = self;
    picker.allowsEditing = YES;
    [self presentModalViewController:picker animated:YES];
    
    
}

- (IBAction)doneButtonPressed:(id)sender {
    [nameTextField resignFirstResponder];
}

#pragma mark UIImagePickerControllerDelegate method



-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    //imageView.image = UIImagePNGRepresentation([info objectForKey:UIImagePickerControllerEditedImage]);
    
    clickedImage = [UIImage imageWithData:UIImagePNGRepresentation([info objectForKey:UIImagePickerControllerEditedImage])];
    
    [self dismissModalViewControllerAnimated:YES];
    
    //[self CreateIplImageFromUIImage:clickedImage];
    [self detectFaces];
}

-(void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [self dismissModalViewControllerAnimated:YES];
    
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"First", @"First");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    return self;
}
							
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //Parsing the XML file
    cvStorage = cvCreateMemStorage(0);
    NSString *resourcePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithUTF8String:HAAR_RESOURCE]];
    
    haarCascade = (CvHaarClassifierCascade *)cvLoad([resourcePath UTF8String],0,0,0);
    count = 1;
    
    [nameTextField setDelegate:self];
    namesOfPeople = [[NSMutableArray alloc] init];
    inputString = [[NSMutableString alloc] init];
    outputString = [NSString alloc];
    
    isFirstEntry = TRUE;

}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [self setDoneButton:nil];
    [self setNameTextField:nil];
    [self setTheNewButton:nil];
    [self setClickButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    //return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    return YES;
    
}

@end
