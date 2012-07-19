//
//  FRSecondViewController.m
//  FacialRecognition
//
//  Created by Mohit Athwani on 15/11/11.
//  Copyright (c) 2011 Geeks Incorporated. All rights reserved.
//

#import "FRSecondViewController.h"
#include <stdio.h>
#include <vector>
#include <string>

using namespace std;
//File name for the Haar Cascade XML file
static const char *HAAR_RESOURCE = "haarcascade_frontalface_alt_tree.xml";

//Temporary storage for the Haar resource
static CvMemStorage *cvStorage = NULL;

//Pointer to the Resource
static CvHaarClassifierCascade *haarCascade = NULL;

@implementation FRSecondViewController
IplImage ** faceImgArr1        = 0; // array of face images
CvMat    *  personNumTruthMat1 = 0; // array of person numbers
std::vector<std::string> personNames1;			// array of person names (indexed by the person number). Added by Shervin.

int nPersons1                  = 0; // the number of people in the training set. Added by Shervin.
int nTrainFaces1               = 0; // the number of training images
CvMat * projectedTrainFaceMat1 = 0; // projected training faces
int nEigens1                   = 0; // the number of eigenvalues
IplImage ** eigenVectArr1      = 0; // eigenvectors
IplImage * pAvgTrainImg1       = 0; // the average image
CvMat * eigenValMat1           = 0; // eigenvalues
int number;
float conf;
@synthesize nameLabel;
@synthesize confidenceLabel;
@synthesize imageView;
int  loadTrainingData(CvMat ** pTrainPersonNumMat);
int findNearestNeighbor(float * projectedTestFace, float *pConfidence);

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Second", @"Second");
        self.tabBarItem.image = [UIImage imageNamed:@"second"];
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
    inputString = [[NSMutableString alloc] init];
    outputString = [NSString alloc];

}

- (void)viewDidUnload
{
    [self setNameLabel:nil];
    [self setConfidenceLabel:nil];
    [self setImageView:nil];
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
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

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

#pragma mark Recognition Code
// Find the most likely person based on a detection. Returns the index, and stores the confidence value into pConfidence.
int findNearestNeighbor(float * projectedTestFace, float *pConfidence)
{
	//double leastDistSq = 1e12;
	double leastDistSq = DBL_MAX;
	int i, iTrain, iNearest = 0;
    
	for(iTrain=0; iTrain<nTrainFaces1; iTrain++)
	{
		double distSq=0;
        
		for(i=0; i<nEigens1; i++)
		{
			float d_i = projectedTestFace[i] - projectedTrainFaceMat1->data.fl[iTrain*nEigens1 + i];
#ifdef USE_MAHALANOBIS_DISTANCE
			distSq += d_i*d_i / eigenValMat1->data.fl[i];  // Mahalanobis distance (might give better results than Eucalidean distance)
#else
			distSq += d_i*d_i; // Euclidean distance.
#endif
		}
        
		if(distSq < leastDistSq)
		{
			leastDistSq = distSq;
			iNearest = iTrain;
		}
	}
    
	// Return the confidence level based on the Euclidean distance,
	// so that similar images should give a confidence between 0.5 to 1.0,
	// and very different images should give a confidence between 0.0 to 0.5.
	*pConfidence = 1.0f - sqrt( leastDistSq / (float)(nTrainFaces1 * nEigens1) ) / 255.0f;
    
	// Return the found index.
	return iNearest;
}

// Open the training data from the file 'facedata.xml'.
int loadTrainingData(CvMat ** pTrainPersonNumMat)
{
	CvFileStorage * fileStorage;
	int i;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); //create an array and store result of our search for the documents directory in it
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; //create NSString object, that holds our exact path to the documents directory
    
    NSString *filePath = [documentsDirectory 
                          stringByAppendingPathComponent:@"facedata.xml"]; //creating the text file to act as the database
    
	// create a file-storage interface
	fileStorage = cvOpenFileStorage( [filePath UTF8String], 0, CV_STORAGE_READ );
	if( !fileStorage ) {
		printf("Can't open training database file 'facedata.xml'.\n");
		return 0;
	}
    
	// Load the person names. Added by Shervin.
	personNames1.clear();	// Make sure it starts as empty.
	nPersons1 = cvReadIntByName( fileStorage, 0, "nPersons", 0 );
	if (nPersons1 == 0) {
		printf("No people found in the training database 'facedata.xml'.\n");
		return 0;
	}
	// Load each person's name.
	for (i=0; i<nPersons1; i++) {
        std::string sPersonName;
		char varname[200];
		sprintf( varname, "personName_%d", (i+1) );
		sPersonName = cvReadStringByName(fileStorage, 0, varname );
		personNames1.push_back( sPersonName );
	}
    
	// Load the data
	nEigens1 = cvReadIntByName(fileStorage, 0, "nEigens", 0);
	nTrainFaces1 = cvReadIntByName(fileStorage, 0, "nTrainFaces", 0);
	*pTrainPersonNumMat = (CvMat *)cvReadByName(fileStorage, 0, "trainPersonNumMat", 0);
	eigenValMat1  = (CvMat *)cvReadByName(fileStorage, 0, "eigenValMat", 0);
	projectedTrainFaceMat1 = (CvMat *)cvReadByName(fileStorage, 0, "projectedTrainFaceMat", 0);
	pAvgTrainImg1 = (IplImage *)cvReadByName(fileStorage, 0, "avgTrainImg", 0);
	eigenVectArr1 = (IplImage **)cvAlloc(nTrainFaces1*sizeof(IplImage *));
	for(i=0; i<nEigens1-1; i++) //we have to write nEigens1-1 otherwise the code generates problems
	{
		char varname[200];
		sprintf( varname, "eigenVect_%d", i );
		eigenVectArr1[i] = (IplImage *)cvReadByName(fileStorage, 0, varname, 0);
	}    
	// release the file-storage interface
	cvReleaseFileStorage( &fileStorage );
    
	printf("Training data loaded (%d training images of %d people):\n", nTrainFaces1, nPersons1);
	printf("People: ");
	if (nPersons1 > 0)
		printf("<%s>", personNames1[0].c_str());
	for (i=1; i<nPersons1; i++) {
		printf(", <%s>", personNames1[i].c_str());
	}
	printf(".\n");
    
	return 1;
}

int loadFaceImgArray ()
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); //create an array and store result of our search for the documents directory in it
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; //create NSString object, that holds our exact path to the documents directory
    
    NSString *filePath = [documentsDirectory 
                          stringByAppendingPathComponent:@"recognize.txt"]; //creating the text file to act as the database
    
    
    
	FILE * imgListFile = 0;
	char imgFilename[512];
	int iFace, nFaces=0;
	int i;
    
	// open the input file
	if( !(imgListFile = fopen([filePath UTF8String], "r")) )
	{
		fprintf(stderr, "Can\'t open file %s\n", [filePath UTF8String]);
		return 0;
	}
    
	// count the number of faces
	while( fgets(imgFilename, 512, imgListFile) ) ++nFaces;
	rewind(imgListFile);
    
	// allocate the face-image array and person number matrix
	faceImgArr1        = (IplImage **)cvAlloc( nFaces*sizeof(IplImage *) );
	personNumTruthMat1 = cvCreateMat( 1, nFaces, CV_32SC1 );
    
	personNames1.clear();	// Make sure it starts as empty.
	nPersons1 = 0;
    
	// store the face images in an array
	for(iFace=0; iFace<nFaces; iFace++)
	{
		char personName[256];
        std::string sPersonName;
		int personNumber;
        
		// read person number (beginning with 1), their name and the image filename.
		fscanf(imgListFile, "%d %s %s", &personNumber, personName, imgFilename);
		sPersonName = personName;
		//printf("Got %d: %d, <%s>, <%s>.\n", iFace, personNumber, personName, imgFilename);
        
		// Check if a new person is being loaded.
		if (personNumber > nPersons1) {
			// Allocate memory for the extra person (or possibly multiple), using this new person's name.
			for (i=nPersons1; i < personNumber; i++) {
				personNames1.push_back( sPersonName );
			}
			nPersons1 = personNumber;
			//printf("Got new person <%s> -> nPersons = %d [%d]\n", sPersonName.c_str(), nPersons, personNames.size());
		}
        
		// Keep the data
		personNumTruthMat1->data.i[iFace] = personNumber;
        
		// load the face image
		faceImgArr1[iFace] = cvLoadImage(imgFilename, CV_LOAD_IMAGE_GRAYSCALE);
        
		if( !faceImgArr1[iFace] )
		{
			fprintf(stderr, "Can\'t load image from %s\n", imgFilename);
			return 0;
		}
	}
    
	fclose(imgListFile);
    
	printf("Data loaded from '%s': (%d images of %d people).\n", [filePath UTF8String], nFaces, nPersons1);
	printf("People: ");
	if (nPersons1 > 0)
		printf("<%s>", personNames1[0].c_str());
	for (i=1; i<nPersons1; i++) {
		printf(", <%s>", personNames1[i].c_str());
	}
	printf(".\n");
    //learn([filePath UTF8String]);
    //doPCA();
    
	return nFaces;
}


void recognizeFileList()
{
	int i, nTestFaces  = 1;         // the number of test images
	CvMat * trainPersonNumMat = 0;  // the person numbers during training
	float * projectedTestFace = 0;
	char *answer;
	int nCorrect = 0;
	int nWrong = 0;
	double timeFaceRecognizeStart;
	double tallyFaceRecognizeTime;
	float confidence;
    
	// load test images and ground truth for person number
	nTestFaces = loadFaceImgArray();
	printf("%d test faces loaded\n", nTestFaces);
    
	// load the saved training data
	if( !loadTrainingData( &trainPersonNumMat ) ) return;
    
	// project the test images onto the PCA subspace
	projectedTestFace = (float *)cvAlloc( nEigens1*sizeof(float) );
	timeFaceRecognizeStart = (double)cvGetTickCount();	// Record the timing.
	for(i=0; i<nTestFaces; i++)
	{
		int iNearest, nearest, truth;
        
		// project the test image onto the PCA subspace
		cvEigenDecomposite(
                           faceImgArr1[i],
                           nEigens1-1, //we have to write nEigens1-1 otherwise the code generates problems

                           eigenVectArr1,
                           0, 0,
                           pAvgTrainImg1,
                           projectedTestFace);
        
		iNearest = findNearestNeighbor(projectedTestFace, &confidence);
		truth    = personNumTruthMat1->data.i[i];
		nearest  = trainPersonNumMat->data.i[iNearest];
        
		if (nearest == truth) {
			answer = "Correct";
			nCorrect++;
		}
		else {
			answer = "WRONG!";
			nWrong++;
		}
		printf("nearest = %d, Truth = %d (%s). Confidence = %f\n", nearest, truth, answer, confidence);
        number = nearest;
        conf = confidence;
        
	}
	tallyFaceRecognizeTime = (double)cvGetTickCount() - timeFaceRecognizeStart;
	if (nCorrect+nWrong > 0) {
		printf("TOTAL ACCURACY: %d%% out of %d tests.\n", nCorrect * 100/(nCorrect+nWrong), (nCorrect+nWrong));
		printf("TOTAL TIME: %.1fms average.\n", tallyFaceRecognizeTime/((double)cvGetTickFrequency() * 1000.0 * (nCorrect+nWrong) ) );
	}
    
}

#pragma mark Saving Image
//saving an image

- (void)saveImage:(UIImage*)image {
    
    NSError *error;
    
    NSData *imageData = UIImagePNGRepresentation(image); //convert image into .png format.
    
    NSFileManager *fileManager = [NSFileManager defaultManager];//create instance of NSFileManager
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); //create an array and store result of our search for the documents directory in it
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; //create NSString object, that holds our exact path to the documents directory
    
    NSString *filePath = [documentsDirectory 
                          stringByAppendingPathComponent:@"recognize.txt"]; //creating the text file to act as the database
    
    
//    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",personName]]; // dataPath is for the folder within Documents
    
//    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
//        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
//        
//        [namesOfPeople addObject:name];
//    }
//    
//    personName = [personName stringByAppendingFormat:@"%d",count];
    
    
    
    NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:@"recognize.png"]; //add our image to the path
    
    
    [fileManager createFileAtPath:fullPath contents:imageData attributes:nil]; //finally save the path (image)
    
//    
//    for (int i=0;i<[namesOfPeople count];i++) {
//        if([name isEqualToString:[namesOfPeople objectAtIndex:i]])
//            //[inputString stringByAppendingFormat:@"%d %@ %@",i+1,name,fullPath];
//            //[inputString appendFormat:@"%d %@ %@ \n",i+1,name,fullPath];
//            [inputString setString:[NSString stringWithFormat:@"%d %@ %@",i+1,name,fullPath]];
//        
//    }
    
    [inputString setString:[NSString stringWithFormat:@"1 Mohit %@",fullPath]];
    //[inputString setString:@"2 Phani /var/mobile/Applications/B555B5BF-0AD1-4AFB-913D-F737E859BF0D/Documents/Julka/Julka3.png"];
    
//    if (!isFirstEntry || [fileManager fileExistsAtPath:filePath]) {
//        NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
//        [fileHandler seekToEndOfFile];
//        [fileHandler writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
//        [fileHandler seekToEndOfFile];
//        [fileHandler writeData:[inputString dataUsingEncoding:NSUTF8StringEncoding]];
//        [fileHandler closeFile];
//    }
    
//    else {
        
        [inputString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
//        isFirstEntry = FALSE;
//    }
    
//    count++;
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
//    [FRBackend learn];
    //remove these lines if you wanna see the original image
//    imageView.image = [UIImage imageWithContentsOfFile:[documentsDirectory stringByAppendingPathComponent:@"out_averageImage.png"]];
//    imageView.contentMode = UIViewContentModeScaleAspectFit;
    NSLog(@"Documents directory from second view: %@",
          [fileManager contentsOfDirectoryAtPath:documentsDirectory error:&error]);
//    NSLog(@"Documents directory: %@",[fileManager contentsOfDirectoryAtPath:dataPath error:&error]);
    recognizeFileList();
    //nameLabel.text = [NSString stringWithFormat:@"%d",number];
    
    if (number ==1) {
        nameLabel.text=[NSString stringWithString:@"Mohit"];
    }
    
    else if (number == 2) {
        nameLabel.text=[NSString stringWithString:@"Phani"];
    }
    
    else if (number == 3) {
        nameLabel.text=[NSString stringWithString:@"Julka"];
    }
    if(conf<0)
        confidenceLabel.text=@"-ve";
    else
        confidenceLabel.text=@"+ve";
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
    //imageView.image=newImage;
    //imageView.contentMode=UIViewContentModeCenter;
    
    
    
    
    [self saveImage:newImage];
    
    
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


- (IBAction)clickButtonPressed:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.delegate = self;
    picker.allowsEditing = YES;
    [self presentModalViewController:picker animated:YES];

}

#pragma mark UIImagePickerControllerDelegate method



-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    //imageView.image = UIImagePNGRepresentation([info objectForKey:UIImagePickerControllerEditedImage]);
    
    clickedImage = [UIImage imageWithData:UIImagePNGRepresentation([info objectForKey:UIImagePickerControllerEditedImage])];
    
    imageView.image = clickedImage;
    
    [self dismissModalViewControllerAnimated:YES];
    
    //[self CreateIplImageFromUIImage:clickedImage];
    [self detectFaces];
}

@end
