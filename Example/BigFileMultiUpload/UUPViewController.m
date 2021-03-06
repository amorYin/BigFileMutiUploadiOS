//
//  UUPViewController.m
//  BigFileMultiUpload
//
//  Created by droudrou@hotmail.com on 06/26/2020.
//  Copyright (c) 2020 droudrou@hotmail.com. All rights reserved.
//

#import "UUPViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <BigFileMultiUpload/BigFileMultiUpload-umbrella.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <Photos/Photos.h>
#import "UUPAppDelegate.h"

typedef NS_ENUM(NSUInteger, CNChooseMediaType) {
    CNChooseMediaTypeMovie = 0,
    CNChooseMediaTypeRecordMovie,
    CNChooseMediaTypePhoto,
    CNChooseMediaTypeTakePhoto
};

@interface UUPViewController ()<UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UUPItf>
{
    CNChooseMediaType mediaType;
    BOOL isFirstUpload;
    NSTimeInterval lastTime;
    UUPItem *ssitem;
}
@property(nonatomic,strong)UIActionSheet *imgPickSheet;
@property (weak, nonatomic) IBOutlet UILabel *text1;
@property (weak, nonatomic) IBOutlet UILabel *text2;
@property (weak, nonatomic) IBOutlet UILabel *text3;
@property (weak, nonatomic) IBOutlet UILabel *text4;
@property (weak, nonatomic) IBOutlet UILabel *text5;
@property (weak, nonatomic) IBOutlet UILabel *text6;
@end

@implementation UUPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)uplooadAction:(id)sender {
    if(ssitem == nil || ssitem.isFinished){
        if (self.imgPickSheet == nil) {
            UIActionSheet *imgPickSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"从本地选取",@"启用相机", nil];
            imgPickSheet.delegate = self;
            self.imgPickSheet = imgPickSheet;
        }
        self.imgPickSheet.tag = 1;
        [self.imgPickSheet dismissWithClickedButtonIndex:0 animated:NO];
        [self.imgPickSheet showInView:self.view];
    }else{
        if (ssitem.isExecuting) {
            [ssitem pause];
        }else{
            [ssitem start];
        }
    }
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (1 == actionSheet.tag) {
        if (0 == buttonIndex) {
            PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
            if (status == PHAuthorizationStatusRestricted ||
                status == PHAuthorizationStatusDenied) {
                [[UUPAppDelegate appDelegate] showErrorWithTitle:@"获取权限失败，请前往设置打开应用权限"];
                return;
            }
            mediaType = CNChooseMediaTypeMovie;
            UIImagePickerController *_pickerImage = [[UIImagePickerController alloc] init];
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                _pickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                _pickerImage.navigationBar.translucent = NO;
                _pickerImage.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
                _pickerImage.delegate = self;
                self.modalPresentationStyle=UIModalPresentationFullScreen;
                [self presentViewController:_pickerImage animated:YES completion:nil];
            }
        } else if (1 == buttonIndex) {
            AVAuthorizationStatus authStatus =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
            {
                [[UUPAppDelegate appDelegate] showErrorWithTitle:@"获取权限失败，请前往设置打开应用权限"];
                return;
            }
            mediaType = CNChooseMediaTypeRecordMovie;
            UIImagePickerController *_pickerImage = [[UIImagePickerController alloc] init];
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                _pickerImage.sourceType = UIImagePickerControllerSourceTypeCamera;
                _pickerImage.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
                _pickerImage.delegate = self;
                self.modalPresentationStyle=UIModalPresentationFullScreen;
                [self presentViewController:_pickerImage animated:YES completion:nil];
            }
        }
        
    } else {
        if (0 == buttonIndex) {
            PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
            if (status == PHAuthorizationStatusRestricted ||
                status == PHAuthorizationStatusDenied) {
                [[UUPAppDelegate appDelegate] showErrorWithTitle:@"获取权限失败，请前往设置打开应用权限"];
                return;
            }
            mediaType = CNChooseMediaTypePhoto;
            UIImagePickerController *_pickerImage = [[UIImagePickerController alloc] init];
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                _pickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                _pickerImage.navigationBar.translucent = NO;
                _pickerImage.delegate = self;
                self.modalPresentationStyle=UIModalPresentationFullScreen;
                [self presentViewController:_pickerImage animated:YES completion:nil];
            }
        } else if (1 == buttonIndex) {
            AVAuthorizationStatus authStatus =  [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
            {
                [[UUPAppDelegate appDelegate] showErrorWithTitle:@"获取权限失败，请前往设置打开应用权限"];
                return;
            }
            mediaType = CNChooseMediaTypeTakePhoto;
            UIImagePickerController *_pickerImage = [[UIImagePickerController alloc] init];
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                _pickerImage.sourceType = UIImagePickerControllerSourceTypeCamera;
                _pickerImage.delegate = self;
                self.modalPresentationStyle=UIModalPresentationFullScreen;
                [self presentViewController:_pickerImage animated:YES completion:nil];
            }
        }
    }
}

#pragma mark UIImagePickerControllerDelegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    if (CNChooseMediaTypePhoto == mediaType) {
        
        NSURL *url = [info objectForKey:UIImagePickerControllerReferenceURL];
        __weak typeof(self) weakSelf = self;
        [picker dismissViewControllerAnimated:YES completion:^{
            __strong typeof(self) strongSelf = weakSelf;
                       UUPItem *item = [[UUPItem alloc] initWith:url type:IMAGE];
                       [strongSelf upload:item];
                   }];
    } else if(CNChooseMediaTypeMovie == mediaType){
        
        NSURL *url = [info objectForKey:UIImagePickerControllerReferenceURL];
        __weak typeof(self) weakSelf = self;
        [picker dismissViewControllerAnimated:YES completion:^{
            __strong typeof(self) strongSelf = weakSelf;
                       UUPItem *item = [[UUPItem alloc] initWith:url type:VIDEO];
                       [strongSelf upload:item];
                   }];
        
    } else if (CNChooseMediaTypeTakePhoto == mediaType) {
        __weak typeof(self) weakSelf = self;
        UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
        PHAssetResourceManager *mana = [PHAssetResourceManager defaultManager];
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary writeImageDataToSavedPhotosAlbum:UIImageJPEGRepresentation(image,(CGFloat)1.0) metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            if (!error) {
              [picker dismissViewControllerAnimated:YES completion:^{
                        __strong typeof(self) strongSelf = weakSelf;
                        UUPItem *item = [[UUPItem alloc] initWith:assetURL type:IMAGE];
                        [strongSelf upload:item];
                     }];
            }else{
                [picker dismissViewControllerAnimated:YES completion:nil];
            }
        }];
     } else if (CNChooseMediaTypeRecordMovie == mediaType) {
        
        
        NSURL *infoM = [info objectForKey:UIImagePickerControllerMediaURL];
         __weak typeof(self) weakSelf = self;
         [picker dismissViewControllerAnimated:YES completion:^{
             __strong typeof(self) strongSelf = weakSelf;
                        UUPItem *item = [[UUPItem alloc] initWith:infoM type:VIDEO];
                        [strongSelf upload:item];
                    }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}


///
- (void)upload:(UUPItem*)item{
    ssitem = item;
    [[UUPManager shareInstance:self] start:item immediately:true];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [[UUPManager shareInstance:self] cancel:item];
//    });
}
- (nonnull UUPConfig *)onConfigure {
    UUPConfig *config = [[UUPConfig alloc] init];
    config.authSign = @"N2VmYWxlY21peHhUd3ovNG44cWhJSkhtN0tWeTN5bDk5R3pKTGtueHBWYTJ2bTJ5c0ZSZzNQVyszdmtCRFJlcUJ4TEF0ZG1UcUtIbldkenNVY0tmZWtSWUNuQ1VFVDdpRmgvNUZVUmpqWEhCaFN4ejBhTXJ3Y2JodnFqdzgvMFNpUlBUbVYzQTBDU0NLbmJSZGNoclh4dnd0bE9TUDk3clc4ejhObXlJakNxb2tMZjN3eXNMMTdFdTJTOEJBcUtYRW9zRkJxNUZOZE9YRnNIc3dJbVB2TDg3WmdTd1BkWmJMbjkwbmdOSzZmUlF6d1RqYTNIOEs0a3B2aTh1empQQUpsckw=";
    config.deviceToken = config.authSign;
    config.serverURi = @"https://upload.newscctv.net/2.64/ugc/chunk_upload.php";
    config.fuidURi = @"https://upload.newscctv.net/2.64/ugc/init_chunk_upload.php";
    return config;
}
- (void)onUPStart:(nonnull UUPItem *)item {
    NSLog(@"onUPStart UUPItem:%lu",(unsigned long)item.mError);
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.text1.text = [NSString stringWithFormat:@"%@【%@】",item.mDisplayName,item.mSizeStr];
        if(!strongSelf->isFirstUpload){
            strongSelf->lastTime = [[NSDate date] timeIntervalSince1970];
            strongSelf->isFirstUpload = true;
            strongSelf.text3.text = @"准备上传";
            strongSelf.text4.text = @"用时：0秒";
        }
    });
    
}

- (void)onUPError:(nonnull UUPItem *)item {
    NSLog(@"onUPProgress UUPItem Error:%lu",(unsigned long)item.mError);
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.text6.text = [NSString stringWithFormat:@"%lu",(unsigned long)item.mError];
    });
}

- (void)onUPFinish:(nonnull UUPItem *)item {
    NSLog(@"onUPProgress UUPItem Finish:%@ - %@",item.mDisplayName,item.mRemoteUri);
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.text2.text = [NSString stringWithFormat:@"上传进度：%.2f%%",item.mProgress * 100];
        strongSelf->isFirstUpload = false;
        strongSelf.text3.text = @"上传成功";
        NSTimeInterval yu = [[NSDate date] timeIntervalSince1970];
        strongSelf.text4.text = [NSString stringWithFormat:@"用时：%.0f秒",yu -lastTime];
    });
}

- (void)onUPProgress:(nonnull UUPItem *)item {
    NSLog(@"onUPProgress UUPItem Progress:%f",item.mProgress);
     __weak typeof(self) weakSelf = self;
     dispatch_async(dispatch_get_main_queue(), ^{
             __strong typeof(weakSelf) strongSelf = weakSelf;
         strongSelf.text2.text = [NSString stringWithFormat:@"上传进度：%.2f%%",item.mProgress * 100];
         strongSelf.text3.text = @"上传中";
         NSTimeInterval yu = [[NSDate date] timeIntervalSince1970];
         strongSelf.text4.text = [NSString stringWithFormat:@"用时：%.0f秒",yu -lastTime];
         strongSelf.text5.text = item.mSpeedStr;
     });
}

@end
