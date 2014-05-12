//
//  ArcIdentifier.m
//  ARC
//
//  Created by Nick Wroblewski on 3/28/13.
//
//

#import "FBEncryptorAES.h"
#import "ArcIdentifier.h"
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

@implementation ArcIdentifier


+ (NSString *)getArcIdentifier
{
    
    NSString *identString = @"";
    NSString *version = [[UIDevice currentDevice] systemVersion];
    BOOL isIos7 = [version floatValue] >= 7.0;
    
    if (isIos7) {
        identString = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    }else{
        int                 mgmtInfoBase[6];
        char                *msgBuffer = NULL;
        size_t              length;
        unsigned char       myUnique[6];
        struct if_msghdr    *interfaceMsgStruct;
        struct sockaddr_dl  *socketStruct;
        NSString            *errorFlag = NULL;
        
        // Setup the management Information Base (mib)
        mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
        mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
        mgmtInfoBase[2] = 0;
        mgmtInfoBase[3] = AF_LINK;        // Request link layer information
        mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
        
        // With all configured interfaces requested, get handle index
        if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
            errorFlag = @"if_nametoindex failure";
        else
        {
            // Get the size of the data available (store in len)
            if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
                errorFlag = @"sysctl mgmtInfoBase failure";
            else
            {
                // Alloc memory based on above call
                if ((msgBuffer = malloc(length)) == NULL)
                    errorFlag = @"buffer allocation failure";
                else
                {
                    // Get system information, store in buffer
                    if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                        errorFlag = @"sysctl msgBuffer failure";
                }
            }
        }
        
        // Befor going any further...
        if (errorFlag != NULL)
        {
            NSLog(@"Error: %@", errorFlag);
            return errorFlag;
        }
        
        // Map msgbuffer to interface message structure
        interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
        
        // Map to link-level socket structure
        socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
        
        // Copy link layer address data in socket structure to an array
        memcpy(&myUnique, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
        
        // Read from char array into a string object, into traditional Mac address format
        identString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                 myUnique[0], myUnique[1], myUnique[2],
                                 myUnique[3], myUnique[4], myUnique[5]];
        
        // Release the buffer memory
        free(msgBuffer);
    }
    
    
    NSString *returnString = [FBEncryptorAES encryptBase64String:identString keyString:@"93473kjhg67" separateLines:NO];
    
    return returnString;
}


@end
