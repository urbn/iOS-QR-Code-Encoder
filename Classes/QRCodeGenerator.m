//
// QR Code Generator - generates UIImage from NSString
//
// Copyright (C) 2012 http://moqod.com Andrew Kopanev <andrew@moqod.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy 
// of this software and associated documentation files (the "Software"), to deal 
// in the Software without restriction, including without limitation the rights 
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
// of the Software, and to permit persons to whom the Software is furnished to do so, 
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all 
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
// DEALINGS IN THE SOFTWARE.
//

#import "QRCodeGenerator.h"
#import "qrencode.h"

enum {
	qr_margin = 1
};

const NSInteger kMinContrastRatio = 4;
const CGFloat kRedLuminance = .2126f;
const CGFloat kGreenLuminance = .7152f;
const CGFloat kBlueLuminance = .0722f;
const CGFloat kLuminanceConstant = .03928f;

@interface QRCodeGenerator()

@property (nonatomic, strong) UIColor *qrColor;
@end

@implementation QRCodeGenerator


#pragma 
#pragma mark - Helper Methods

// for more info on QR code best practice see http://www.viu.ca/communications/docs/QR-Code-Best-Practices.pdf 
+(CGFloat)decodeColorValue:(CGFloat)value{
    if (value <= kLuminanceConstant) {
        value = value/12.92;
    }else{
        value = (value + .055)/1.055;
        value = powf(value, 2.4);
    }
    return value;
}
+(NSArray *)decodedRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue{
    NSMutableArray *morphed = [NSMutableArray arrayWithCapacity:3];
    NSArray *rgb = @[[NSNumber numberWithFloat:red], [NSNumber numberWithFloat:green], [NSNumber numberWithFloat:blue]];
    for (NSNumber *num in rgb) {
        [morphed addObject:[NSNumber numberWithFloat:[QRCodeGenerator decodeColorValue:num.floatValue]]];
    }
    return morphed;
}
+(CGFloat)luminanceForColor:(UIColor*)color{
    CGFloat r, g, b, a;
    if ([color respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
        [color getRed:&r green:&g blue:&b alpha:&a];
    }
    NSArray *morphed = [QRCodeGenerator decodedRed:r green:g blue:b];
    NSNumber *red = [morphed objectAtIndex:0];
    NSNumber *green = [morphed objectAtIndex:1];
    NSNumber *blue = [morphed objectAtIndex:2];
    CGFloat luminance = ((red.floatValue * kRedLuminance) + (green.floatValue * kGreenLuminance) + (blue.floatValue * kBlueLuminance));
    return luminance;
}
+ (void)drawQRCode:(QRcode *)code context:(CGContextRef)ctx size:(CGFloat)size color:(UIColor*)color{
	unsigned char *data = 0;
	int width;
	data = code->data;
	width = code->width;
	float zoom = (double)size / (code->width + 2.0 * qr_margin);
	CGRect rectDraw = CGRectMake(0, 0, zoom, zoom);
	
	CGContextSetFillColorWithColor(ctx, color.CGColor);
	for(int i = 0; i < width; ++i) {
		for(int j = 0; j < width; ++j) {
			if(*data & 1) {
				rectDraw.origin = CGPointMake((j + qr_margin) * zoom,(i + qr_margin) * zoom);
				CGContextAddRect(ctx, rectDraw);
			}
			++data;
		}
	}
	CGContextFillPath(ctx);
}

#pragma 
#pragma mark - Class Methods
+ (BOOL)CanUseForegroundColor:(UIColor*)foreground andBackgroundColor:(UIColor*)background{
    CGFloat color1 = [QRCodeGenerator luminanceForColor:foreground];
    CGFloat color2 = [QRCodeGenerator luminanceForColor:background];
    CGFloat ratio;
    
    if (color1 < color2) {
        ratio = color1/color2;
    }else{
        ratio = color2/color1;
    }
    if (ratio <= .40) {
        return YES;
    }
    
    return NO;
}
+ (UIImage *)qrImageForString:(NSString *)string imageSize:(CGFloat)size {
	return [QRCodeGenerator qrImageForString:string imageSize:size codeColor:nil];
}
+ (UIImage *)qrImageForString:(NSString *)string imageSize:(CGFloat)imageSize codeColor:(UIColor*)color{
    if (![string length]) {
		return nil;
	}
	if (color == nil) {
        color = [UIColor blackColor];
    }
	// generate QR
	QRcode *code = QRcode_encodeString([string UTF8String], 0, QR_ECLEVEL_H, QR_MODE_8, 1);
	if (!code) {
		return nil;
	}
	
	if (code->width > imageSize) {
		printf("Image size is less than qr code size (%d)\n", code->width);
		return nil;
	}
	// create context
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(0, imageSize, imageSize, 8, imageSize * 4, colorSpace, kCGImageAlphaPremultipliedLast);
	
	CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(0, -imageSize);
	CGAffineTransform scaleTransform = CGAffineTransformMakeScale(1, -1);
	CGContextConcatCTM(ctx, CGAffineTransformConcat(translateTransform, scaleTransform));
	
	// draw QR on this context
	[QRCodeGenerator drawQRCode:code context:ctx size:imageSize color:color];
	
	// get image
	CGImageRef qrCGImage = CGBitmapContextCreateImage(ctx);
	UIImage * qrImage = [UIImage imageWithCGImage:qrCGImage];
	
	// free memory
	CGContextRelease(ctx);
	CGImageRelease(qrCGImage);
	CGColorSpaceRelease(colorSpace);
	QRcode_free(code);
	
	return qrImage;
}
@end
