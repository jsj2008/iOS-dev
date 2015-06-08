//
//  USAVGuidedDecryptViewController.m
//  uSav
//
//  Created by young dennis on 25/11/12.
//  Copyright (c) 2012 young dennis. All rights reserved.
//

#import "USAVGuidedDecryptViewController.h"
#import "WarningView.h"
#import "USAVClient.h"
#import "API.h"
#import "WarningView.h"
#import "GDataXMLNode.h"
#import "UsavCipher.h"
#import "NSData+Base64.h"
#import "USAVGuidedSetPermissionViewController.h"
#import "USAVGuidedExportViewController.h"
#import "SGDUtilities.h"
#import "FileBriefCell.h"
#import "UsavStreamCipher.h"
#import "BundleLocalization.h"

@interface USAVGuidedDecryptViewController ()
@property (strong, nonatomic) NSMutableArray *currentFileList;
@property (strong, nonatomic) NSString *currentPath;
@property (strong, nonatomic) NSString *currentFullPath;
// @property (strong, nonatomic) NSString *basePath;
@property (strong, nonatomic) NSFileManager *fileManager;
@property (strong, nonatomic) UIDocumentInteractionController *docInteractionController;
@property (strong, nonatomic) NSString *decryptedFileName;
@property (strong, nonatomic) NSString *decryptPath;
@property (strong, nonatomic) NSString *decryptFilePath;
@property (strong, nonatomic) UIAlertView *alert;
@end

@implementation USAVGuidedDecryptViewController

@synthesize currentFileList;
@synthesize currentPath;
@synthesize currentFullPath;
// @synthesize basePath;
@synthesize fileManager;
@synthesize docInteractionController;
@synthesize decryptedFileName = _decryptedFileName;
@synthesize decryptPath = _decryptPath;
@synthesize decryptFilePath = _decryptFilePath;
@synthesize alert = _alert;

#define ALERTVIEW_NO_FILE_IN_FOLDER 0

-(NSString *)filenameConflictSovlerForDecrypt:(NSString *)newFile forPath:(NSString *)path

{
    //newly added file's property
    NSString *newFilesExtension = [newFile pathExtension];
    NSString *newFileNameWithOutExtension = [newFile stringByDeletingPathExtension];
    
    if ([newFileNameWithOutExtension length] >= 3) {
        NSRange indexRange2 = {[newFileNameWithOutExtension length] -  3, 3};
        NSString *lastThreeChars = [newFileNameWithOutExtension substringWithRange:indexRange2];
        
        if ([lastThreeChars characterAtIndex:0] == '(') {
            NSRange withoutThree = {0,[newFileNameWithOutExtension length] - 3};
            newFileNameWithOutExtension = [newFileNameWithOutExtension substringWithRange:withoutThree];
        }
    }
    
    //file already in the folder
    
    NSString *existedFilesExtension; //This should be uSav
    NSString *existedFilesOriginExtension;
    NSString *existedFilesNameWithOutExtension;
    
    NSMutableArray *allFile = [NSMutableArray arrayWithCapacity:0];
    [allFile addObjectsFromArray:[self.fileManager contentsOfDirectoryAtPath:path error:nil]];
    
    NSInteger numAllfile = [allFile count];
    
    NSInteger postFix = 0;
    BOOL firstTime = true;
    
    for (NSInteger i = 0; i < numAllfile; i++) {
        //Get one file's full name
        NSString *singleFile = [allFile objectAtIndex:i];
        
        //existedFilesExtension = [singleFile pathExtension];
        existedFilesOriginExtension = [singleFile pathExtension];
        existedFilesNameWithOutExtension = [singleFile stringByDeletingPathExtension];
        
        NSString *potentialThreeChars;
        if ([existedFilesNameWithOutExtension length] >= 3) {
            NSRange indexRange = {[existedFilesNameWithOutExtension length] - 3, 3};
            potentialThreeChars = [existedFilesNameWithOutExtension substringWithRange:indexRange];
        }
        
        if (![existedFilesOriginExtension isEqualToString:newFilesExtension]) {
            //if no extension conflict then check next item
            continue;
        }
        
        if ([potentialThreeChars characterAtIndex:0] == '(') {
            NSRange withoutThree = {0,[existedFilesNameWithOutExtension length] - 3};
            if (![[existedFilesNameWithOutExtension substringWithRange:withoutThree] isEqualToString: newFileNameWithOutExtension])
                //if no file name conflict then check next item
                continue;
        } else if (![existedFilesNameWithOutExtension isEqualToString:newFileNameWithOutExtension]) {
            continue;
        }
        
        if ([potentialThreeChars characterAtIndex:0] == '(') {
            NSArray *removeClouse = [potentialThreeChars componentsSeparatedByString:@"("];
            NSInteger fileIndex = [[[[removeClouse objectAtIndex:1] componentsSeparatedByString:@"("] objectAtIndex:0] intValue];
            if (fileIndex >= postFix) {
                postFix  = fileIndex + 1;
            }
        } else if(firstTime){
            postFix = 1;
        }
        firstTime = false;
        
    }
    
    if (postFix == 0) {
        return [NSString stringWithFormat:@"%@", newFile];
    } else {
        return [NSString stringWithFormat:@"%@%@%zi%@%@", newFileNameWithOutExtension, @"(", postFix, @").", newFilesExtension];
    }
}

-(NSString *)filenameConflictSovler:(NSString *)originalFile forPath:(NSString *)path
{
    NSString *orgExtension = [originalFile pathExtension];
    NSString *orgNoExtension = [originalFile stringByDeletingPathExtension];
    
    NSMutableArray *allFile = [NSMutableArray arrayWithCapacity:0];
    [allFile addObjectsFromArray:[self.fileManager contentsOfDirectoryAtPath:path error:nil]];
    
    NSInteger numAllfile = [allFile count];
    
    NSInteger postFix = 0;
    BOOL firstTime = true;
    
    for (NSInteger i = 0; i < numAllfile; i++) {
        //if file name already exist
        NSString *singleFile = [allFile objectAtIndex:i];
        
        if ([[singleFile pathExtension] caseInsensitiveCompare:@"usav"] != NSOrderedSame) {
            
            NSArray *file = [[singleFile  stringByDeletingPathExtension] componentsSeparatedByString:@"("];
            NSString *fileExtension = [singleFile pathExtension];
            
            if ([[file objectAtIndex:0] isEqualToString:orgNoExtension] && [fileExtension isEqualToString:orgExtension]) {
                if([file count] > 1) {
                    postFix = [[file objectAtIndex:1] intValue] + 1;
                } else if(firstTime){
                    postFix = 1;
                }
                firstTime = false;
            }
        }
    }
    if (postFix == 0) {
        return originalFile;
    } else {
        return [NSString stringWithFormat:@"%@%@%zi%@%@", orgNoExtension, @"(", postFix, @").", orgExtension];
    }
}

-(BOOL) deleteFileAtCurrentFullPath
{
    
    NSError *ferror = nil;
    BOOL frc;
    frc = [self.fileManager removeItemAtPath:self.currentFullPath error:&ferror];
    [self.alert dismissWithClickedButtonIndex:0 animated:YES];
    if (frc == YES) {
        [self.currentFileList removeAllObjects];
        [self getDotUsavFileFromInBox: self.currentPath];
        //[self.currentFileList addObjectsFromArray:[self.fileManager contentsOfDirectoryAtPath: self.currentPath error:nil]];
        [self.tblView reloadData];
        return TRUE;
    }
    else {
        NSLog(@"%@ NSError:%@ successfully deleted key, but fail to delete file:%@", [self class], [ferror localizedDescription], self.currentFullPath);
        return FALSE;
    }
}

-(void) deleteKeyResult:(NSDictionary*)obj {
    if ([[obj objectForKey:@"statusCode"] integerValue] == 261 || [[obj objectForKey:@"statusCode"] integerValue] == 260) {
        [self.alert dismissWithClickedButtonIndex:0 animated:YES];
        WarningView *wv = [[WarningView alloc] initWithFrame:CGRectMake(0, 0, 280, 64) withFontSize:0];
        [wv setCenter:CGPointMake(MSG_POSITION_X, MSG_POSITION_Y)];
        [wv show:NSLocalizedString(@"TimeStampError", @"") inView:self.view];
        return;
    }
    [self.alert dismissWithClickedButtonIndex:0 animated:YES];
    [self deleteFileAtCurrentFullPath];
    
    
    /*
     if (obj == nil) {
     WarningView *wv = [[WarningView alloc] initWithFrame:CGRectMake(0, 0, 280, 64) withFontSize:0];
     [wv setCenter:CGPointMake(MSG_POSITION_X, MSG_POSITION_Y)];
     [wv show:NSLocalizedString(@"Timeout", @"") inView:self.view];
     
     return;
     }
     
     if ((obj != nil) && ([obj objectForKey:@"httpErrorCode"] == nil)) {
     NSLog(@"%@ deleteKeyResult: %@", [self class], obj);
     
     NSInteger rc;
     if ([obj objectForKey:@"statusCode"] != nil)
     rc = [[obj objectForKey:@"statusCode"] integerValue];
     else
     rc = [[obj objectForKey:@"rawStringStatus"] integerValue];
     
     switch (rc) {
     case SUCCESS:
     {
     // [self.fileManager fileExistsAtPath:fullTargetPath]
     [self deleteFileAtCurrentFullPath];
     return;
     }
     break;
     case KEY_NOT_FOUND:
     {
     WarningView *wv = [[WarningView alloc] initWithFrame:CGRectMake(0, 0, 280, 64) withFontSize:0];
     [wv setCenter:CGPointMake(MSG_POSITION_X, MSG_POSITION_Y)];
     [wv show:NSLocalizedString(@"FileEncryptionKeyNotFoundKey", @"") inView:self.view];
     return;
     }
     break;
     default:
     break;
     }
     
     }
     [self.alert dismissWithClickedButtonIndex:0 animated:YES];
     if ([obj objectForKey:@"httpErrorCode"] != nil)
     NSLog(@"%@ deleteKeyResult httpErrorCode: %@", [self class], [obj objectForKey:@"httpErrorCode"]);
     
     WarningView *wv = [[WarningView alloc] initWithFrame:CGRectMake(0, 0, 280, 64) withFontSize:0];
     [wv setCenter:CGPointMake(MSG_POSITION_X, MSG_POSITION_Y)];
     [wv show:NSLocalizedString(@"FileDeleteKeyUnknownErrorKey", @"") inView:self.view];*/
}

-(void) deleteKeyBuildRequest
{
    NSData *keyId = [[UsavFileHeader defaultHeader] getKeyIDFromFile:self.currentFullPath];
    
    NSString *keyIdString = [keyId base64EncodedString];
    
    USAVClient *client = [USAVClient current];
    
    NSString *stringToSign = [NSString stringWithFormat:@"%@%@%@%@%@%@", [client emailAddress], @"\n", [client getDateTimeStr], @"\n", keyIdString, @"\n"];
    
    NSLog(@"stringToSign: %@", stringToSign);
    
    NSString *signature = [client generateSignature:stringToSign withKey:client.password];
    
    NSLog(@"signature: %@", signature);
    
    GDataXMLElement * requestElement = [GDataXMLNode elementWithName:@"request"];
    GDataXMLElement * paramElement = [GDataXMLNode elementWithName:@"account" stringValue:[client emailAddress]];
    [requestElement addChild:paramElement];
    paramElement = [GDataXMLNode elementWithName:@"timestamp" stringValue:[[USAVClient current] getDateTimeStr]];
    [requestElement addChild:paramElement];
    paramElement = [GDataXMLNode elementWithName:@"signature" stringValue:signature];
    [requestElement addChild:paramElement];
    
    // add 'params' and the child parameters
    GDataXMLElement * paramsElement = [GDataXMLNode elementWithName:@"params"];
    paramElement = [GDataXMLNode elementWithName:@"keyId" stringValue:keyIdString];
    [paramsElement addChild:paramElement];
    
    [requestElement addChild:paramsElement];
    
    GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithRootElement:requestElement];
    NSData *xmlData = document.XMLData;
    
    NSString *getParam = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
    
    NSString *encodedGetParam = [[USAVClient current] encodeToPercentEscapeString:getParam];
    
    NSLog(@"getParam encoding: raw:%@ encoded:%@", getParam, encodedGetParam);
    
    [client.api deleteKey:encodedGetParam target:(id)self selector:@selector(deleteKeyResult:)];
}

-(void)deleteKeyAndFile:(NSString *)filenameStr
{
    [self deleteKeyBuildRequest];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"ExportSegue"]) {
        USAVGuidedExportViewController *fp = (USAVGuidedExportViewController *)segue.destinationViewController;
        fp.fileName = [self.decryptedFileName copy];
        fp.filePath = [self.decryptFilePath copy];
        //fp.filePath = [self.encryptedFilePath copy];
        //fp.keyId = [self.keyId copy];
    }
}

- (void)setupDocumentControllerWithURL:(NSURL *)url
{
    if (self.docInteractionController == nil)
    {
        self.docInteractionController = [UIDocumentInteractionController interactionControllerWithURL:url];
        self.docInteractionController.delegate = self;
    }
    else
    {
        self.docInteractionController.URL = url;
    }
}


-(void) getKeyResult:(NSDictionary*)obj {
    [self.alert dismissWithClickedButtonIndex:0 animated:YES];
    if (obj == nil) {
        WarningView *wv = [[WarningView alloc] initWithFrame:CGRectMake(0, 0, 280, 64) withFontSize:0];
        [wv setCenter:CGPointMake(MSG_POSITION_X, MSG_POSITION_Y)];
        [wv show:NSLocalizedString(@"Timeout", @"") inView:self.view];
       
        return;
    }
    if ([[obj objectForKey:@"statusCode"] integerValue] == 261 || [[obj objectForKey:@"statusCode"] integerValue] == 260) {
        [self.alert dismissWithClickedButtonIndex:0 animated:YES];
        WarningView *wv = [[WarningView alloc] initWithFrame:CGRectMake(0, 0, 280, 64) withFontSize:0];
        [wv setCenter:CGPointMake(MSG_POSITION_X, MSG_POSITION_Y)];
        [wv show:NSLocalizedString(@"TimeStampError", @"") inView:self.view];
        return;
    }
	if ((obj != nil) && ([obj objectForKey:@"httpErrorCode"] == nil)) {
        NSLog(@"%@ getKeyResult: %@", [self class], obj);
        
        NSInteger rc;
        if ([obj objectForKey:@"statusCode"] != nil)
            rc = [[obj objectForKey:@"statusCode"] integerValue];
        else
            rc = [[obj objectForKey:@"rawStringStatus"] integerValue];
        
        switch (rc) {
            case SUCCESS:
            {
                NSData *keyId = [NSData dataFromBase64String:[obj objectForKey:@"Id"]];
                NSData *keyContent = [NSData dataFromBase64String:[obj objectForKey:@"Content"]];
                NSInteger keySize = [[obj objectForKey:@"Size"] integerValue];
                
                NSLog(@"%zi %zi", [keyId length], [keyContent length]);
                
                // build target full path name for storing the encrypted file
                NSArray *components = [self.currentFullPath componentsSeparatedByString:@"/"];
                NSMutableString *fn = [[components lastObject] mutableCopy];
                
                fn = [[fn stringByReplacingOccurrencesOfString:@".usav" withString:@""] mutableCopy];
                fn = [self filenameConflictSovlerForDecrypt:fn forPath:self.decryptPath];
                
                NSString *extension = [[UsavFileHeader defaultHeader] getExtension:self.currentFullPath];
                if (extension) {
                    fn = [NSString stringWithFormat:@"%@%@%@", [fn stringByDeletingPathExtension],@".", extension];
                }
                
                NSString *targetFullPath = [NSString stringWithFormat:@"%@%@%@", self.decryptPath, @"/", fn];
                NSString *tempFullPath = [NSString stringWithFormat:@"%@%@%@%@", self.decryptPath, @"/", fn, @".usav-temp"];
                self.decryptedFileName = [fn copy];
                self.decryptFilePath = [targetFullPath copy];
                
                NSLog(@"%@ decrypt file path:%@ targetFullPath:%@", [self class], self.currentFullPath, targetFullPath);
                
                //BOOL rc = [[UsavCipher defualtCipher] decryptFile:self.currentFullPath targetFile:targetFullPath keyContent:keyContent];
                BOOL rc = [[UsavStreamCipher defualtCipher] decryptFile:self.currentFullPath targetFile:tempFullPath keyContent:keyContent];
                
                if (rc == TRUE) {
                    [[NSFileManager defaultManager] moveItemAtPath:tempFullPath toPath:targetFullPath error:nil];
                    [self performSegueWithIdentifier:@"ExportSegue" sender:self];
                }
                else {
                    WarningView *wv = [[WarningView alloc] initWithFrame:CGRectMake(0, 0, 280, 64) withFontSize:0];
                    [wv setCenter:CGPointMake(MSG_POSITION_X, MSG_POSITION_Y)];
                    [wv show:NSLocalizedString(@"FileDecryptionFailedKey", @"") inView:self.view];
                }
                
                return;
            }
                break;
            case KEY_NOT_FOUND:
            {
                WarningView *wv = [[WarningView alloc] initWithFrame:CGRectMake(0, 0, 280, 64) withFontSize:0];
                [wv setCenter:CGPointMake(MSG_POSITION_X, MSG_POSITION_Y)];
                [wv show:NSLocalizedString(@"FileEncryptionKeyNotFoundKey", @"") inView:self.view];
                return;
            }
                break;
            default:
                break;
        }
        
    }
    
    if ([obj objectForKey:@"httpErrorCode"] != nil)
        NSLog(@"ContactView addGroupResult httpErrorCode: %@", [obj objectForKey:@"httpErrorCode"]);
    
    WarningView *wv = [[WarningView alloc] initWithFrame:CGRectMake(0, 0, 280, 64) withFontSize:0];
    [wv setCenter:CGPointMake(MSG_POSITION_X, MSG_POSITION_Y)];
    [wv show:NSLocalizedString(@"Permission Denied", @"") inView:self.view];
    
}



-(void) getKeyBuildRequest
{
    self.alert = [SGDUtilities showLoadingMessageWithTitle:NSLocalizedString(@"ProcessBarDecrypt", @"")
                                                  delegate:self];
    NSData *keyId = [[UsavFileHeader defaultHeader] getKeyIDFromFile:self.currentFullPath];
    
    NSString *keyIdString = [keyId base64EncodedString];
    
    USAVClient *client = [USAVClient current];
    
    NSString *stringToSign = [NSString stringWithFormat:@"%@%@%@%@%@%@", [client emailAddress], @"\n", [client getDateTimeStr], @"\n", keyIdString, @"\n"];
    
    NSLog(@"stringToSign: %@", stringToSign);
    
    NSString *signature = [client generateSignature:stringToSign withKey:client.password];
    
    NSLog(@"signature: %@", signature);
    
    GDataXMLElement * requestElement = [GDataXMLNode elementWithName:@"request"];
    GDataXMLElement * paramElement = [GDataXMLNode elementWithName:@"account" stringValue:[client emailAddress]];
    [requestElement addChild:paramElement];
    paramElement = [GDataXMLNode elementWithName:@"timestamp" stringValue:[[USAVClient current] getDateTimeStr]];
    [requestElement addChild:paramElement];
    paramElement = [GDataXMLNode elementWithName:@"signature" stringValue:signature];
    [requestElement addChild:paramElement];
    
    // add 'params' and the child parameters
    GDataXMLElement * paramsElement = [GDataXMLNode elementWithName:@"params"];
    paramElement = [GDataXMLNode elementWithName:@"keyId" stringValue:keyIdString];
    [paramsElement addChild:paramElement];
    
    [requestElement addChild:paramsElement];
    
    GDataXMLDocument *document = [[GDataXMLDocument alloc] initWithRootElement:requestElement];
    NSData *xmlData = document.XMLData;
    
    NSString *getParam = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
    
    NSString *encodedGetParam = [[USAVClient current] encodeToPercentEscapeString:getParam];
    
    NSLog(@"getParam encoding: raw:%@ encoded:%@", getParam, encodedGetParam);
    
    [client.api getKey:encodedGetParam target:(id)self selector:@selector(getKeyResult:)];
}


- (void)viewDidLoad
{
    NSInteger time = [[[NSUserDefaults standardUserDefaults] objectForKey:@"timesDecryption"] intValue];
    
    if (time < 2) {
        // Do any additional setup after loading the view.
        WarningView *wv = [[WarningView alloc] initWithFrame:CGRectMake(0, 0, 280, 64) withFontSize:0];
        [wv setCenter:CGPointMake(MSG_POSITION_X, MSG_POSITION_Y)];
        [wv show:NSLocalizedString(@"InfoQuickDecrypt", @"") inView:self.view];
        time += 1;
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:time] forKey:@"timesDecryption"];
    }
    
    [super viewDidLoad];

    
    [self.navigationItem setTitle:NSLocalizedString(@"DecryptFileTitleKey", @"")];
    
    self.currentFileList = [NSMutableArray arrayWithCapacity:24];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                         NSDocumentDirectory, NSUserDomainMask, YES);
    NSLog(@"document paths: %@", paths);
    
    self.currentPath = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], @"Inbox"];
    self.decryptPath = [NSString stringWithFormat:@"%@/%zi/%@", [paths objectAtIndex:0], [[USAVClient current] uId], @"Decrypted"];
    // self.basePath = self.currentPath;
    
    self.fileManager = [NSFileManager defaultManager];
    
    [self.currentFileList removeAllObjects];
    [self getDotUsavFileFromInBox: self.currentPath];
    
    self.tblView.delegate = self;
    self.tblView.dataSource = self;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case ALERTVIEW_NO_FILE_IN_FOLDER:
            break;
            
        default:
            break;
    }
    
}


- (void) getDotUsavFileFromInBox:(NSString *) path
{
    NSMutableArray *allFile = [NSMutableArray arrayWithCapacity:0];
    [allFile addObjectsFromArray:[self.fileManager contentsOfDirectoryAtPath:path error:nil]];
    
    NSMutableArray *tmpFile = [NSMutableArray arrayWithCapacity:0];
    [tmpFile addObjectsFromArray:[self.fileManager contentsOfDirectoryAtPath:path error:nil]];
    
    NSInteger numDel = 0;
    
    NSInteger numAllfile = [allFile count];
    for (NSInteger i = 0; i < numAllfile; i++) {
        NSString *ext = [[allFile objectAtIndex:i] pathExtension];
        
        if ([ext caseInsensitiveCompare:@"USAV"] != NSOrderedSame) {
            NSInteger index = i - numDel;
            [tmpFile removeObjectAtIndex:index];
            
            numDel += 1;
        }
    }
    self.currentFileList = tmpFile;
    

    if ([self.currentFileList count] == 0) {
        if (numAllfile == 0) {
            /*
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Decrypt Folder Empty", @"")
                                                             message:NSLocalizedString(@"Decrypt Folder Empty Alert", @"")
                                                            delegate:self
                                                   cancelButtonTitle: NSLocalizedString(@"OkKey", @"") otherButtonTitles:nil];
            
            alert.alertViewStyle = UIAlertViewStyleDefault; // UIAlertViewStylePlainTextInput;
            alert.tag = ALERTVIEW_NO_FILE_IN_FOLDER;
            [alert show];
             */
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTblView:nil];
    [super viewDidUnload];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    NSLog(@"Group: section:%zi rowCount:%zi", section, [self.currentFileList count]);
    return [self.currentFileList count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
    
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    /*
     static NSString *CellIdentifier = @"Cell";
     
     UITableViewCell *cell = [tableView
     dequeueReusableCellWithIdentifier:CellIdentifier];
     if (cell == nil) {
     cell = [[UITableViewCell alloc]
     initWithStyle:UITableViewCellStyleSubtitle
     reuseIdentifier:CellIdentifier];
     }
     */
    static NSString *briefIdentifier = @"FileBriefCell";
    FileBriefCell *cell = (FileBriefCell *)[tableView dequeueReusableCellWithIdentifier:briefIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FileBriefCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    NSString *filenameStr = [self.currentFileList objectAtIndex:indexPath.row];
    
    cell.fileName.text = filenameStr;
    cell.fileImage.image = [self selectImgForFile:filenameStr];
    
    NSError *attributesError = nil;
    self.currentFullPath = [NSString stringWithFormat:@"%@/%@", self.currentPath, filenameStr];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.currentFullPath error:&attributesError];
    
    // get file size
    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
    
    cell.fileSize.text = [NSString stringWithFormat:@"Bytes:%@",
                          [USAVClient convertNumberToKMString:[fileSizeNumber integerValue]]];
    
    // get file mod time
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    // [dateFormatter setLocale:[NSLocale currentLocale]];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    [dateFormatter setDateFormat:@"MM/dd/yy hh:mm:ssa"];
    
    NSDate *fileModTime = [fileAttributes objectForKey:NSFileModificationDate];
    NSString *dateString = [dateFormatter stringFromDate:fileModTime];
    
    cell.fileModTime.text = [NSString stringWithFormat:@"MT:%@", dateString];
    
    /*
     cell.textLabel.text = filenameStr;
     cell.imageView.image = [self selectImgForFile:filenameStr];
     */
    
    return cell;
}


- (UIImage *)selectImgForFile:(NSString *) filename
{
    
    if ([[filename pathExtension] caseInsensitiveCompare:@"usav"] == NSOrderedSame) {
        return [USAVClient SelectImgForuSavFile:[filename stringByDeletingPathExtension]];
    } else {
        return [USAVClient SelectImgForOriginalFile:filename];
    }
}


#pragma mark - Table view delegate

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSString *filenameStr = [self.currentFileList objectAtIndex:indexPath.row];
        
        self.currentFullPath = [NSString stringWithFormat:@"%@/%@", self.currentPath, filenameStr];
        BOOL isDirectory = FALSE;
        if (isDirectory) {
            WarningView *wv = [[WarningView alloc] initWithFrame:CGRectMake(0, 0, 280, 64) withFontSize:0];
            [wv setCenter:CGPointMake(MSG_POSITION_X, MSG_POSITION_Y)];
            [wv show:NSLocalizedString(@"FileDeleteDirectoryNotAllowedKey", @"") inView:self.view];
        }
        else {
            self.alert = [SGDUtilities showLoadingMessageWithTitle:NSLocalizedString(@"ProcessBarDelete", @"")
                                                          delegate:self];
            if ([filenameStr hasSuffix:@".usav"]) {
                // [self openDocumentIn:filenameStr];
                [self deleteKeyAndFile:filenameStr];
            }
            else {
                [self deleteFileAtCurrentFullPath];
            }
        }
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 24;
}



- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // create the parent view that will hold header Label
    UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), 24.0)];
    
    // create the button object
    UILabel * headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    headerLabel.backgroundColor = [UIColor lightGrayColor];
    headerLabel.opaque = NO;
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.highlightedTextColor = [UIColor whiteColor];
    headerLabel.font = [UIFont boldSystemFontOfSize:13];
    headerLabel.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.bounds), 24.0);
    
    // If you want to align the header text as centered
    // headerLabel.frame = CGRectMake(160.0, 0.0, [[UIScreen mainScreen] bounds].size.width, 36.0);
    
    headerLabel.textAlignment = UITextAlignmentCenter;
    
    headerLabel.text = [NSString stringWithFormat:NSLocalizedString(@"QuickDecryptFolder", @"")];
    
    [customView addSubview:headerLabel];
    
    return customView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    
    //UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    //cell.contentView.backgroundColor = [UIColor whiteColor];
    
    NSString *filenameStr = [self.currentFileList objectAtIndex:indexPath.row];
    
    if (filenameStr) {
        // [self openDocumentIn:filenameStr];
        [self processFile:filenameStr];
    }
}

-(void)decryptFile:(NSString *)fullPath
{
    NSLog(@"DecryptFile: %@", fullPath);
}

-(void)encryptFile:(NSString *)fullPath
{
    NSLog(@"EncryptFile: %@", fullPath);
}

-(IBAction)processFile:(NSString *)filename {
    
    NSString *ext = [filename pathExtension];
    if ([ext caseInsensitiveCompare:@"USAV"] == NSOrderedSame) {
        self.currentFullPath = [NSString stringWithFormat:@"%@%@%@", self.currentPath, @"/", filename];
        
        [self getKeyBuildRequest];
        
        //[self performSegueWithIdentifier:@"ExportSegue" sender:self];
    }
    else {
        WarningView *wv = [[WarningView alloc] initWithFrame:CGRectMake(0, 0, 280, 64) withFontSize:0];
        [wv setCenter:CGPointMake(MSG_POSITION_X, MSG_POSITION_Y)];
        [wv show:NSLocalizedString(@"FileAlreadyDecryptedKey", @"") inView:self.view];
    }
}

-(void)openDocumentIn:(NSString *)filenameStr {
    
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@", self.currentPath, filenameStr];
    
	[self setupDocumentControllerWithURL:[NSURL fileURLWithPath:fullPath]];
    
    [self.docInteractionController presentOpenInMenuFromRect:CGRectZero
                                                      inView:self.view
                                                    animated:YES];
}

-(void)documentInteractionController:(UIDocumentInteractionController *)controller
       willBeginSendingToApplication:(NSString *)application {
}

-(void)documentInteractionController:(UIDocumentInteractionController *)controller
          didEndSendingToApplication:(NSString *)application {
}

-(void)documentInteractionControllerDidDismissOpenInMenu:
(UIDocumentInteractionController *)controller {
}

@end
