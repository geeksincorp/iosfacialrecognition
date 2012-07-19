//
//  FRBackend.m
//  FacialRecognition
//
//  Created by Mohit Athwani on 23/11/11.
//  Copyright (c) 2011 Geeks Incorporated. All rights reserved.
//

#import "FRBackend.h"
#include <stdio.h>
#include <vector>
#include <string>

using namespace std;

@implementation FRBackend

int SAVE_EIGENFACE_IMAGES = 1;		// Set to 0 if you dont want images of the Eigenvectors saved to files (for debugging).

IplImage ** faceImgArr        = 0; // array of face images
CvMat    *  personNumTruthMat = 0; // array of person numbers
std::vector<std::string> personNames;			// array of person names (indexed by the person number). Added by Shervin.

int nPersons                  = 0; // the number of people in the training set. Added by Shervin.
int nTrainFaces               = 0; // the number of training images
CvMat * projectedTrainFaceMat = 0; // projected training faces
int nEigens                   = 0; // the number of eigenvalues
IplImage ** eigenVectArr      = 0; // eigenvectors
IplImage * pAvgTrainImg       = 0; // the average image
CvMat * eigenValMat           = 0; // eigenvalues

void learn(char *szFileTrain);
void doPCA();
void storeTrainingData();
void storeEigenfaceImages();
IplImage* convertFloatImageToUcharImage(const IplImage *srcImg);


+(void) learn
{
	int i, offset;
    
	// load training data
	//printf("Loading the training images in '%s'\n", szFileTrain);
	//nTrainFaces = loadFaceImgArray(szFileTrain);
    nTrainFaces = [FRBackend loadFaceImgArray];
	printf("Got %d training images.\n", nTrainFaces);
	if( nTrainFaces < 2 )
	{
		fprintf(stderr,
		        "Need 2 or more training faces\n"
		        "Input file contains only %d\n", nTrainFaces);
		return;
	}
    
	// do PCA on the training faces
	doPCA();
    //[self doPCA];
	// project the training images onto the PCA subspace
	projectedTrainFaceMat = cvCreateMat( nTrainFaces, nEigens, CV_32FC1 );
	offset = projectedTrainFaceMat->step / sizeof(float);
	for(i=0; i<nTrainFaces; i++)
	{
		//int offset = i * nEigens;
		cvEigenDecomposite(
                           faceImgArr[i],
                           nEigens,
                           eigenVectArr,
                           0, 0,
                           pAvgTrainImg,
                           //projectedTrainFaceMat->data.fl + i*nEigens);
                           projectedTrainFaceMat->data.fl + i*offset);
        
    
	}
    
	// store the recognition data as an xml file
	storeTrainingData();
    
	// Save all the eigenvectors as images, so that they can be checked.
	if (SAVE_EIGENFACE_IMAGES) {
		storeEigenfaceImages(); 	
    }
    
}

void doPCA ()
{
	int i;
	CvTermCriteria calcLimit;
	CvSize faceImgSize;
    
	// set the number of eigenvalues to use
	nEigens = nTrainFaces-1;
    
	// allocate the eigenvector images
	faceImgSize.width  = faceImgArr[0]->width;
	faceImgSize.height = faceImgArr[0]->height;
	eigenVectArr = (IplImage**)cvAlloc(sizeof(IplImage*) * nEigens);
	for(i=0; i<nEigens; i++)
		eigenVectArr[i] = cvCreateImage(faceImgSize, IPL_DEPTH_32F, 1);
    
	// allocate the eigenvalue array
	eigenValMat = cvCreateMat( 1, nEigens, CV_32FC1 );
    
	// allocate the averaged image
	pAvgTrainImg = cvCreateImage(faceImgSize, IPL_DEPTH_32F, 1);
    
	// set the PCA termination criterion
	calcLimit = cvTermCriteria( CV_TERMCRIT_ITER, nEigens, 1);
    
	// compute average image, eigenvalues, and eigenvectors
	cvCalcEigenObjects(
                       nTrainFaces,
                       (void*)faceImgArr,
                       (void*)eigenVectArr,
                       CV_EIGOBJ_NO_CALLBACK,
                       0,
                       0,
                       &calcLimit,
                       pAvgTrainImg,
                       eigenValMat->data.fl);
    
	cvNormalize(eigenValMat, eigenValMat, 1, 0, CV_L1, 0);
}

void storeTrainingData()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); //create an array and store result of our search for the documents directory in it
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; //create NSString object, that holds our exact path to the documents directory
    
    NSString *filePath = [documentsDirectory 
                          stringByAppendingPathComponent:@"facedata.xml"];
	CvFileStorage * fileStorage;
	int i;
    
	// create a file-storage interface
	fileStorage = cvOpenFileStorage( [filePath UTF8String], 0, CV_STORAGE_WRITE );
    
	// Store the person names. Added by Shervin.
	cvWriteInt( fileStorage, "nPersons", nPersons );
	for (i=0; i<nPersons; i++) {
		char varname[200];
		sprintf( varname, "personName_%d", (i+1) );
		cvWriteString(fileStorage, varname, personNames[i].c_str(), 0);
	}
    
	// store all the data
	cvWriteInt( fileStorage, "nEigens", nEigens );
	cvWriteInt( fileStorage, "nTrainFaces", nTrainFaces );
	cvWrite(fileStorage, "trainPersonNumMat", personNumTruthMat, cvAttrList(0,0));
	cvWrite(fileStorage, "eigenValMat", eigenValMat, cvAttrList(0,0));
	cvWrite(fileStorage, "projectedTrainFaceMat", projectedTrainFaceMat, cvAttrList(0,0));
	cvWrite(fileStorage, "avgTrainImg", pAvgTrainImg, cvAttrList(0,0));
	for(i=0; i<nEigens; i++)
	{
		char varname[200];
		sprintf( varname, "eigenVect_%d", i );
		cvWrite(fileStorage, varname, eigenVectArr[i], cvAttrList(0,0));
	}
    
	
//    char s[512];
//    FILE *imgListFile = fopen([filePath UTF8String], "r");
//    while( fgets(s, 512, imgListFile) ) printf("%s \n",s);
//    fclose(imgListFile)
// Incase I ever wanna see the contents of the XML file.	
    // release the file-storage interfacecvReleaseFileStorage( &fileStorage );
}

void storeEigenfaceImages()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); //create an array and store result of our search for the documents directory in it
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; //create NSString object, that holds our exact path to the documents directory

    NSString *filePathEigenAvg = [documentsDirectory 
                               stringByAppendingPathComponent:@"out_averageImage.png"];
	// Store the average image to a file
	printf("Saving the image of the average face as 'out_averageImage.png'.\n");
	cvSaveImage([filePathEigenAvg UTF8String], pAvgTrainImg);
	// Create a large image made of many eigenface images.
	// Must also convert each eigenface image to a normal 8-bit UCHAR image instead of a 32-bit float image.
	printf("Saving the %d eigenvector images as 'out_eigenfaces.png'\n", nEigens);
	if (nEigens > 0) {
		// Put all the eigenfaces next to each other.
		int COLUMNS = 8;	// Put upto 8 images on a row.
		int nCols = std::min(nEigens, COLUMNS);
		int nRows = 1 + (nEigens / COLUMNS);	// Put the rest on new rows.
		int w = eigenVectArr[0]->width;
		int h = eigenVectArr[0]->height;
		CvSize size;
		size = cvSize(nCols * w, nRows * h);
		IplImage *bigImg = cvCreateImage(size, IPL_DEPTH_8U, 1);	// 8-bit Greyscale UCHAR image
		for (int i=0; i<nEigens; i++) {
			// Get the eigenface image.
			IplImage *byteImg = convertFloatImageToUcharImage(eigenVectArr[i]);
			// Paste it into the correct position.
			int x = w * (i % COLUMNS);
			int y = h * (i / COLUMNS);
			CvRect ROI = cvRect(x, y, w, h);
			cvSetImageROI(bigImg, ROI);
			cvCopyImage(byteImg, bigImg);
			cvResetImageROI(bigImg);
			cvReleaseImage(&byteImg);
		}
        
                
        NSString *filePathEigen = [documentsDirectory 
                              stringByAppendingPathComponent:@"out_eigenfaces.png"];
		cvSaveImage([filePathEigen UTF8String], bigImg);
        
		cvReleaseImage(&bigImg);
	}
}

// Get an 8-bit equivalent of the 32-bit Float image.
// Returns a new image, so remember to call 'cvReleaseImage()' on the result.
IplImage* convertFloatImageToUcharImage(const IplImage *srcImg)
{
	IplImage *dstImg = 0;
	if ((srcImg) && (srcImg->width > 0 && srcImg->height > 0)) {
        
		// Spread the 32bit floating point pixels to fit within 8bit pixel range.
		double minVal, maxVal;
		cvMinMaxLoc(srcImg, &minVal, &maxVal);
        
		//cout << "FloatImage:(minV=" << minVal << ", maxV=" << maxVal << ")." << endl;
        
		// Deal with NaN and extreme values, since the DFT seems to give some NaN results.
		if (cvIsNaN(minVal) || minVal < -1e30)
			minVal = -1e30;
		if (cvIsNaN(maxVal) || maxVal > 1e30)
			maxVal = 1e30;
		if (maxVal-minVal == 0.0f)
			maxVal = minVal + 0.001;	// remove potential divide by zero errors.
        
		// Convert the format
		dstImg = cvCreateImage(cvSize(srcImg->width, srcImg->height), 8, 1);
		cvConvertScale(srcImg, dstImg, 255.0 / (maxVal - minVal), - minVal * 255.0 / (maxVal-minVal));
	}
	return dstImg;
}

+(int) loadFaceImgArray
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); //create an array and store result of our search for the documents directory in it
    
    NSString *documentsDirectory = [paths objectAtIndex:0]; //create NSString object, that holds our exact path to the documents directory
    
    NSString *filePath = [documentsDirectory 
                          stringByAppendingPathComponent:@"file1.txt"]; //creating the text file to act as the database
    
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
	faceImgArr        = (IplImage **)cvAlloc( nFaces*sizeof(IplImage *) );
	personNumTruthMat = cvCreateMat( 1, nFaces, CV_32SC1 );
    
	personNames.clear();	// Make sure it starts as empty.
	nPersons = 0;
    
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
		if (personNumber > nPersons) {
			// Allocate memory for the extra person (or possibly multiple), using this new person's name.
			for (i=nPersons; i < personNumber; i++) {
				personNames.push_back( sPersonName );
			}
			nPersons = personNumber;
			//printf("Got new person <%s> -> nPersons = %d [%d]\n", sPersonName.c_str(), nPersons, personNames.size());
		}
        
		// Keep the data
		personNumTruthMat->data.i[iFace] = personNumber;
        
		// load the face image
		faceImgArr[iFace] = cvLoadImage(imgFilename, CV_LOAD_IMAGE_GRAYSCALE);
        
		if( !faceImgArr[iFace] )
		{
			fprintf(stderr, "Can\'t load image from %s\n", imgFilename);
			return 0;
		}
	}
    
	fclose(imgListFile);
    
	printf("Data loaded from '%s': (%d images of %d people).\n", [filePath UTF8String], nFaces, nPersons);
	printf("People: ");
	if (nPersons > 0)
		printf("<%s>", personNames[0].c_str());
	for (i=1; i<nPersons; i++) {
		printf(", <%s>", personNames[i].c_str());
	}
	printf(".\n");
    //learn([filePath UTF8String]);
    //doPCA();
    
	return nFaces;
}

@end
