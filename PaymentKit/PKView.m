//
//  PKPaymentField.m
//  PKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#define kPKRedColor [UIColor colorWithRed:253.0/255.0 green:0.0 blue:17.0/255.0 alpha:1.0]

#import <QuartzCore/QuartzCore.h>
#import "PKView.h"
#import "PKTextField.h"

@interface PKView () <UITextFieldDelegate> {
	
@private
    BOOL isInitialState;
    BOOL isValidState;
    
    CGRect placeholderFrame;
}

- (void)setup;
- (void)setupPlaceholderView;
- (void)setupCardNumberField;
- (void)setupCardExpiryField;
- (void)setupCardCVCField;

- (void)stateCardNumber;
- (void)stateMeta;
- (void)stateCardCVC;

- (void)setPlaceholderViewImage:(UIImage *)image;
- (void)setPlaceholderToCVC;
- (void)setPlaceholderToCardType;

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardNumberFieldShouldChangeCharactersInRange: (NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardExpiryShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardCVCShouldChangeCharactersInRange: (NSRange)range replacementString:(NSString *)replacementString;

- (void)checkValid;
- (void)textFieldIsValid:(UITextField *)textField;
- (void)textFieldIsInvalid:(UITextField *)textField withErrors:(BOOL)errors;
@end

@implementation PKView

@dynamic card;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setBorderStyle:(UITextBorderStyle)borderStyle
{
	_borderStyle = borderStyle;
	
	if (borderStyle == UITextBorderStyleRoundedRect) {
		self.layer.borderColor = [UIColor colorWithRed:191/255.0 green:192/255.0 blue:194/255.0 alpha:1.0].CGColor;
		self.layer.cornerRadius = 6.0;
		self.layer.borderWidth = 0.5;
	}
	else {
		self.layer.borderColor = nil;
		self.layer.cornerRadius = 0.0;
		self.layer.borderWidth = 0.0;
	}
}

- (void)setCountryCode:(NSString *)countryCode
{
    NSString *code = [countryCode uppercaseString];
    
    if ([_countryCode isEqualToString:code])
        return;
    
    _countryCode = [countryCode uppercaseString];
    _cardZipField.text = @"";
    if (_cardZipField.leftView) {
        [(UIButton *)_cardZipField.leftView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@.png", countryCode]] forState:UIControlStateNormal];
    }
    [self setNeedsLayout];
}

- (void)setDefaultTextAttributes:(NSDictionary *)defaultTextAttributes
{
	_defaultTextAttributes = [defaultTextAttributes copy];
	
	// We shouldn't need to set the font and textColor attributes, but a bug exists in 7.0 (fixed in 7.1/)
	
	NSArray *textFields = @[_cardNumberField, _cardExpiryField, _cardCVCField, _cardLastFourField, _cardZipField];
    for (PKTextField *textField in textFields) {
		textField.defaultTextAttributes = _defaultTextAttributes;
		textField.font = _defaultTextAttributes[NSFontAttributeName];
		textField.textColor = _defaultTextAttributes[NSForegroundColorAttributeName];
		textField.textAlignment = NSTextAlignmentLeft;
    }
	
	_cardExpiryField.textAlignment = NSTextAlignmentCenter;
	_cardCVCField.textAlignment = NSTextAlignmentCenter;
    _cardZipField.textAlignment = NSTextAlignmentCenter;
	
	[self setNeedsLayout];
}

- (void)setFont:(UIFont *)font
{
	NSMutableDictionary *defaultTextAttributes = [self.defaultTextAttributes mutableCopy];
	defaultTextAttributes[NSFontAttributeName] = font;
	
	self.defaultTextAttributes = [defaultTextAttributes copy];
}

- (UIFont *)font
{
	return self.defaultTextAttributes[NSFontAttributeName];
}

- (void)setTextColor:(UIColor *)textColor
{
	NSMutableDictionary *defaultTextAttributes = [self.defaultTextAttributes mutableCopy];
	defaultTextAttributes[NSForegroundColorAttributeName] = textColor;
	
	self.defaultTextAttributes = [defaultTextAttributes copy];
}

- (UIColor *)textColor
{
	return self.defaultTextAttributes[NSForegroundColorAttributeName];
}

- (void)setCardNumberAlignment:(NSTextAlignment)cardNumberAlignment
{
    if (_cardNumberAlignment != cardNumberAlignment) {
        _cardNumberAlignment = cardNumberAlignment;
        [self setNeedsLayout];
    }
}

- (void)setup
{
    _countryCode = @"US";
    _cardNumberAlignment = NSTextAlignmentLeft;
	self.imageStyle = PKViewImageStyleSmall;
	self.borderStyle = UITextBorderStyleRoundedRect;
	self.layer.masksToBounds = YES;
	self.backgroundColor = [UIColor whiteColor];
	
    isInitialState = YES;
    isValidState   = NO;
    
    [self setupPlaceholderView];
	
	self.innerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, self.frame.size.height)];
    self.innerView.clipsToBounds = YES;
	
	_cardLastFourField = [UITextField new];
	_cardLastFourField.defaultTextAttributes = _defaultTextAttributes;
	_cardLastFourField.backgroundColor = self.backgroundColor;
    _cardLastFourField.delegate = self;
	
    [self setupCardNumberField];
    [self setupCardExpiryField];
    [self setupCardCVCField];
    [self setupCardZipField];
	
	self.defaultTextAttributes = @{
								   NSFontAttributeName: [UIFont boldSystemFontOfSize:16.0],
								   NSForegroundColorAttributeName: [UIColor blackColor]};
	
    [self.innerView addSubview:_cardNumberField];
	
    [self addSubview:self.innerView];
    [self addSubview:_placeholderView];
    
    [self stateCardNumber];
}

- (PKTextField *)textFieldWithPlaceholder:(NSString *)placeholder
{
	PKTextField *textField = [PKTextField new];
	
	textField.delegate = self;
    textField.placeholder = placeholder;
    textField.keyboardType = UIKeyboardTypeNumberPad;
    textField.defaultTextAttributes = _defaultTextAttributes;
	textField.layer.masksToBounds = NO;
	
	return textField;
}

- (void)setupPlaceholderView
{
    _placeholderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"card_placeholder" inBundle:[NSBundle bundleForClass: PKView.class] compatibleWithTraitCollection: nil]];
	_placeholderView.backgroundColor = [UIColor whiteColor];
}

- (void)setupCardNumberField
{
	_cardNumberField = [self textFieldWithPlaceholder:@"1234 5678 9012 3456"];
}

- (void)setupCardExpiryField
{
	_cardExpiryField = [self textFieldWithPlaceholder:@"MM/YY"];
}

- (void)setupCardCVCField
{
	_cardCVCField = [self textFieldWithPlaceholder:@"CVC"];
}

- (void)setupCardZipField
{
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, -6, 20, _innerView.frame.size.height)];
    
    [button addTarget:self action:@selector(onTapCountryFlag:) forControlEvents:UIControlEventTouchUpInside];
    
    _cardZipField = [self textFieldWithPlaceholder:@"ZIP"];
    _cardZipField.leftView = button;
    _cardZipField.leftViewMode = UITextFieldViewModeAlways;
    
    button.contentMode = UIViewContentModeScaleAspectFit;
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    if (_countryCode)
        [button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@.png", _countryCode]] forState:UIControlStateNormal];
}


// Accessors

- (PKCardNumber *)cardNumber
{
    return [PKCardNumber cardNumberWithString:_cardNumberField.text];
}

- (void)setCardNumber:(PKCardNumber *)cardNumber
{
    if (cardNumber) {
        _cardNumberField.text = [cardNumber formattedString];
        [self setPlaceholderToCardType];
    }
}

- (PKCardExpiry *)cardExpiry
{
    return [PKCardExpiry cardExpiryWithString:_cardExpiryField.text];
}

- (void)setCardExpiry:(PKCardExpiry *)cardExpiry
{
    if (cardExpiry)
        _cardExpiryField.text = [cardExpiry formattedStringWithTrail];
}

- (PKCardCVC *)cardCVC
{
    return [PKCardCVC cardCVCWithString:_cardCVCField.text];
}

- (void)setCardCVC:(PKCardCVC *)cardCVC
{
    if (cardCVC)
        _cardCVCField.text = [cardCVC string];
}

- (PKAddressZip *)addressZip
{
    return [PKAddressZip addressZipWithString:_cardZipField.text countryCode:_countryCode];
}

- (void)setAddressZip:(PKAddressZip *)addressZip
{
    if (addressZip)
        _cardZipField.text = [addressZip string];
}

- (void)layoutSubviews
{
	if (self.imageStyle == PKViewImageStyleOutline) {
		CGFloat height = 18;
		CGFloat y = (self.frame.size.height - height) / 2;
		CGFloat width = 25 + y;
		
		_placeholderView.frame = CGRectMake(0, y, width, height);
		_placeholderView.contentMode = UIViewContentModeRight;
        placeholderFrame = _placeholderView.frame;
	}
    else if (self.imageStyle == PKViewImageStyleSmall) {
        placeholderFrame = CGRectMake(0, (self.frame.size.height - 32) / 2, 50, 32);
        _placeholderView.frame = CGRectInset(placeholderFrame, 8, 6);
    }
	else {
		_placeholderView.frame = CGRectMake(0, (self.frame.size.height - 32) / 2, 51, 32);
        placeholderFrame = _placeholderView.frame;
	}
	
	NSDictionary *attributes = self.defaultTextAttributes;
	
	CGSize lastGroupSize, cvcSize, cardNumberSize, cardZipSize;
	
	if (self.cardNumber.cardType == PKCardTypeAmex) {
		cardNumberSize = [@"0000 000000 00000" sizeWithAttributes:attributes];
		lastGroupSize = [@"00000" sizeWithAttributes:attributes];
		cvcSize = [@"0000" sizeWithAttributes:attributes];
	}
	else {
		if (self.cardNumber.cardType == PKCardTypeDinersClub) {
			cardNumberSize = [@"0000 000000 0000" sizeWithAttributes:attributes];
		}
		else {
			cardNumberSize = [@"0000 0000 0000 0000" sizeWithAttributes:attributes];
		}
		
		lastGroupSize = [@"0000" sizeWithAttributes:attributes];
		cvcSize = [_cardCVCField.placeholder sizeWithAttributes:attributes];
	}
    
    cardZipSize = _cardZipField.leftView.frame.size;
    cardZipSize.height = lastGroupSize.height;
    if ([_countryCode isEqualToString:@"US"]) {
        cardZipSize.width += [@"99999" sizeWithAttributes:attributes].width;
        _cardZipField.placeholder = @"ZIP";
    } else if ([_countryCode isEqualToString:@"CA"]) {
        cardZipSize.width += [@"A9A 9A9" sizeWithAttributes:attributes].width;
        _cardZipField.placeholder = @"ZIP";
    } else {
        _cardZipField.placeholder = @"";
    }
	
	CGSize expirySize = [_cardExpiryField.placeholder sizeWithAttributes:attributes];
	
	CGFloat textFieldY = (self.frame.size.height - lastGroupSize.height) / 2.0;
	
	CGFloat totalWidth = lastGroupSize.width + expirySize.width + cvcSize.width + cardZipSize.width;
	
	CGFloat innerWidth = self.frame.size.width - placeholderFrame.size.width;
	CGFloat multiplier = (100.0 / totalWidth);
	
	CGFloat newLastGroupWidth = (innerWidth * multiplier * lastGroupSize.width) / 100.0;
	CGFloat newExpiryWidth    = (innerWidth * multiplier * expirySize.width)    / 100.0;
	CGFloat newCVCWidth       = (innerWidth * multiplier * cvcSize.width)       / 100.0;
    CGFloat newZipWidth       = (innerWidth * multiplier * cardZipSize.width)       / 100.0;
	
	CGFloat lastGroupSidePadding = (newLastGroupWidth - lastGroupSize.width) / 2.0;
	
    
    if (_cardNumberAlignment == NSTextAlignmentLeft) {
        _cardNumberField.frame = CGRectMake(0,
                                            textFieldY,
                                            cardNumberSize.width,
                                            cardNumberSize.height);
    } else {
        _cardNumberField.frame = CGRectMake((innerWidth / 2.0) - (cardNumberSize.width / 2.0),
                                            textFieldY,
                                            cardNumberSize.width,
                                            cardNumberSize.height);
    }
	  
	
	_cardLastFourField.frame = CGRectMake(CGRectGetMaxX(_cardNumberField.frame) - lastGroupSize.width,
										  textFieldY,
										  lastGroupSize.width,
										  lastGroupSize.height);
	
	  _cardExpiryField.frame = CGRectMake(CGRectGetMaxX(_cardNumberField.frame) + lastGroupSidePadding,
										  textFieldY,
										  newExpiryWidth,
										  expirySize.height);

	     _cardCVCField.frame = CGRectMake(CGRectGetMaxX(_cardExpiryField.frame),
										  textFieldY,
										  newCVCWidth,
										  cvcSize.height);
    
    _cardZipField.frame = CGRectMake(CGRectGetMaxX(_cardCVCField.frame),
                                     textFieldY,
                                     newZipWidth,
                                     cardZipSize.height);
	
	CGFloat x;
	
	if (isInitialState) {
		x = placeholderFrame.size.width;
	}
	else {
		x = _innerView.frame.origin.x;
	}
	
	        _innerView.frame = CGRectMake(x,
										  0.0,
										  CGRectGetMaxX(_cardZipField.frame),
										  self.frame.size.height);
}

// State

- (void)stateCardNumber
{
	if ([self.delegate respondsToSelector:@selector(paymentView:didChangeState:)]) {
		[self.delegate paymentView:self didChangeState:PKViewStateCardNumber];
	}
	
    if (!isInitialState) {
        // Animate left
        isInitialState = YES;
		
		[UIView animateWithDuration:0.200 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			_cardExpiryField.leftView.alpha = 0.0;
		} completion:nil];
		
        [UIView animateWithDuration:0.400
                              delay:0
                            options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction)
                         animations:^{
							 _innerView.frame = CGRectMake(placeholderFrame.size.width,
														   0,
														   _innerView.frame.size.width,
														   _innerView.frame.size.height);
							 
							 _cardNumberField.alpha = 1.0;
                         }
                         completion:^(BOOL completed) {
                             [_cardExpiryField removeFromSuperview];
                             [_cardCVCField removeFromSuperview];
							 [_cardLastFourField removeFromSuperview];
                             [_cardZipField removeFromSuperview];
                         }];
    }
    
	if (self.isFirstResponder) {
    	[self.cardNumberField becomeFirstResponder];
	}
}

- (void)stateMeta
{
	if ([self.delegate respondsToSelector:@selector(paymentView:didChangeState:)]) {
		[self.delegate paymentView:self didChangeState:PKViewStateExpiry];
	}
	
    isInitialState = NO;
	
	_cardLastFourField.text = self.cardNumber.lastGroup;
	
	[_innerView addSubview:_cardLastFourField];
    
	[UIView animateWithDuration:0.200 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		_cardExpiryField.leftView.alpha = 1.0;
	} completion:nil];
	
	CGFloat difference = -(_innerView.frame.size.width - self.frame.size.width + placeholderFrame.size.width);
	
	[UIView animateWithDuration:0.400 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		_cardNumberField.alpha = 0.0;
		_innerView.frame = CGRectOffset(_innerView.frame, difference, 0);
    } completion:nil];
    
    [self.innerView addSubview:_cardExpiryField];
    [self.innerView addSubview:_cardCVCField];
    [self.innerView addSubview:_cardZipField];
    [_cardExpiryField becomeFirstResponder];
}

- (void)stateCardCVC
{
	if ([self.delegate respondsToSelector:@selector(paymentView:didChangeState:)]) {
		[self.delegate paymentView:self didChangeState:PKViewStateCVC];
	}
	
    [_cardCVCField becomeFirstResponder];
}

- (void)stateCardZip
{
    if ([self.delegate respondsToSelector:@selector(paymentView:didChangeState:)]) {
        [self.delegate paymentView:self didChangeState:PKViewStateZip];
    }
    
    [_cardZipField becomeFirstResponder];
}

- (BOOL)isValid
{
    return [self.cardNumber isValid] && [self.cardExpiry isValid] &&
	[self.cardCVC isValidWithType:self.cardNumber.cardType] && [self.addressZip isValid];
}

- (PKCard *)card
{
    PKCard *card    = [[PKCard alloc] init];
    card.number     = [self.cardNumber string];
    card.cvc        = [self.cardCVC string];
    card.expMonth   = [self.cardExpiry month];
    card.expYear    = [self.cardExpiry year];
    
    return card;
}

-(void) setCard:(PKCard *)card {
    [self reset];
    PKCardNumber *number = [[PKCardNumber alloc] initWithString:card.number];
    self.cardNumberField.text = [number formattedString];
    [self setPlaceholderToCardType];
    
    
    if (card.expMonth > 0 && card.expYear > 0) {
        NSString *month = [NSString stringWithFormat:@"%02d", (int)card.expMonth];
        NSString *year = [[NSString stringWithFormat:@"%lu", (unsigned long)card.expYear] substringFromIndex:2];
        
        self.cardExpiryField.text = [NSString stringWithFormat:@"%@/%@", month, year];
    } else {
        self.cardExpiryField.text = @"";
    }
    
   
    self.cardCVCField.text = card.cvc;
    [self stateMeta];
}

-(void) reset {
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self setup];
    [self layoutSubviews];
}

- (void)setPlaceholderViewImage:(UIImage *)image
{
    if (![_placeholderView.image isEqual:image]) {
        __block __unsafe_unretained UIView *previousPlaceholderView = _placeholderView;
        [UIView animateWithDuration:0.25 delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
							 _placeholderView.layer.opacity = 0.0;
							 _placeholderView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.2);
						 } completion:^(BOOL finished) {
							 [previousPlaceholderView removeFromSuperview];
						 }];
		
        _placeholderView = nil;
        
        [self setupPlaceholderView];
        _placeholderView.image = image;
        _placeholderView.layer.opacity = 0.0;
        _placeholderView.layer.transform = CATransform3DMakeScale(0.8, 0.8, 0.8);
        [self insertSubview:_placeholderView belowSubview:previousPlaceholderView];
        [UIView animateWithDuration:0.25 delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
							 _placeholderView.layer.opacity = 1.0;
							 _placeholderView.layer.transform = CATransform3DIdentity;
						 } completion:^(BOOL finished) {}];
    }
}

- (void)setPlaceholderToCVC
{
    PKCardNumber *cardNumber = [PKCardNumber cardNumberWithString:_cardNumberField.text];
    PKCardType cardType      = [cardNumber cardType];
    
    if (cardType == PKCardTypeAmex) {
        [self setPlaceholderViewImage:[UIImage imageNamed:@"cvc-amex" inBundle:[NSBundle bundleForClass: PKView.class] compatibleWithTraitCollection: nil]];
    } else {
        [self setPlaceholderViewImage:[UIImage imageNamed:@"cvc" inBundle:[NSBundle bundleForClass: PKView.class] compatibleWithTraitCollection: nil]];
    }
}

- (void)setPlaceholderToCardType
{
    PKCardNumber *cardNumber = [PKCardNumber cardNumberWithString:_cardNumberField.text];
    PKCardType cardType      = [cardNumber cardType];
    NSString *cardTypeName   = @"card_placeholder";
    
    switch (cardType) {
        case PKCardTypeAmex:
            cardTypeName = @"amex";
            break;
        case PKCardTypeDinersClub:
            cardTypeName = @"diners";
            break;
        case PKCardTypeDiscover:
            cardTypeName = @"discover";
            break;
        case PKCardTypeJCB:
            cardTypeName = @"jcb";
            break;
        case PKCardTypeMasterCard:
            cardTypeName = @"mastercard";
            break;
        case PKCardTypeVisa:
            cardTypeName = @"visa";
            break;
        default:
            break;
    }
	
	if (self.imageStyle == PKViewImageStyleOutline) {
		cardTypeName = [NSString stringWithFormat:@"%@-outline", cardTypeName];
	}
	
    [self setPlaceholderViewImage:[UIImage imageNamed:cardTypeName inBundle:[NSBundle bundleForClass: PKView.class] compatibleWithTraitCollection: nil]];
}

// Delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([textField isEqual:_cardCVCField]) {
        [self setPlaceholderToCVC];
    } else {
        [self setPlaceholderToCardType];
    }
    
    if ([textField isEqual:_cardNumberField] && !isInitialState) {
        [self stateCardNumber];
    } else if ([textField isEqual:_cardLastFourField]) {
        [self stateCardNumber];
        [_cardNumberField becomeFirstResponder];
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(paymentViewShouldBegingEditing:)])
        return [self.delegate paymentViewShouldBegingEditing:self];
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    if ([textField isEqual:_cardNumberField]) {
        return [self cardNumberFieldShouldChangeCharactersInRange:range replacementString:replacementString];
    }
    else if ([textField isEqual:_cardExpiryField]) {
        return [self cardExpiryShouldChangeCharactersInRange:range replacementString:replacementString];
    }
    else if ([textField isEqual:_cardCVCField]) {
        return [self cardCVCShouldChangeCharactersInRange:range replacementString:replacementString];
    }
    else if ([textField isEqual:_cardZipField]) {
        return [self cardZipShouldChangeCharactersInRange:range replacementString:replacementString];
    }
    
    return NO;
}

- (void)pkTextFieldDidBackSpaceWhileTextIsEmpty:(PKTextField *)textField
{
    if (![self isBackspaceEnabled])
        return;
    
    if ([textField isEqual:_cardCVCField]) {
        [self.cardExpiryField becomeFirstResponder];
	}
    else if ([textField isEqual:_cardExpiryField]) {
        [self stateCardNumber];
	}
    else if ([textField isEqual:_cardZipField]) {
        [self stateCardCVC];
    }
}

- (BOOL)cardNumberFieldShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [_cardNumberField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PKTextField textByRemovingUselessSpacesFromString:resultString];
    PKCardNumber *cardNumber = [PKCardNumber cardNumberWithString:resultString];
    if ([self.delegate respondsToSelector:@selector(paymentView:didChangeCardNumber:)])
        [self.delegate paymentView:self didChangeCardNumber:cardNumber];
    
    if (![cardNumber isPartiallyValid]) {
        return NO;
	}
    
    if (replacementString.length > 0) {
        _cardNumberField.text = [cardNumber formattedStringWithTrail];
    }
	else {
        _cardNumberField.text = [cardNumber formattedString];
    }
    
    [self setPlaceholderToCardType];
    
    if ([cardNumber isValid]) {
        [self textFieldIsValid:_cardNumberField];
        [self stateMeta];
    } else if ([cardNumber isValidLength] && ![cardNumber isValidLuhn]) {
        [self textFieldIsInvalid:_cardNumberField withErrors:YES];
    } else if (![cardNumber isValidLength]) {
        [self textFieldIsInvalid:_cardNumberField withErrors:NO];
    }
    
    return NO;
}

- (BOOL)cardExpiryShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [_cardExpiryField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PKTextField textByRemovingUselessSpacesFromString:resultString];
    PKCardExpiry *cardExpiry = [PKCardExpiry cardExpiryWithString:resultString];
    
    if (![cardExpiry isPartiallyValid]) {
		return NO;
	}
    
    // Only support shorthand year
    if ([cardExpiry formattedString].length > 5) return NO;
    
    if (replacementString.length > 0) {
        _cardExpiryField.text = [cardExpiry formattedStringWithTrail];
    } else {
        _cardExpiryField.text = [cardExpiry formattedString];
    }
    
    if ([cardExpiry isValid]) {
        [self textFieldIsValid:_cardExpiryField];
        [self stateCardCVC];
    } else if ([cardExpiry isValidLength] && ![cardExpiry isValidDate]) {
        [self textFieldIsInvalid:_cardExpiryField withErrors:YES];
    } else if (![cardExpiry isValidLength]) {
        [self textFieldIsInvalid:_cardExpiryField withErrors:NO];
    }
    
    return NO;
}

- (BOOL)cardCVCShouldChangeCharactersInRange: (NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [_cardCVCField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PKTextField textByRemovingUselessSpacesFromString:resultString];
    PKCardCVC *cardCVC = [PKCardCVC cardCVCWithString:resultString];
    PKCardType cardType = [[PKCardNumber cardNumberWithString:_cardNumberField.text] cardType];
    
    // Restrict length
    if (![cardCVC isPartiallyValidWithType:cardType]) {
		return NO;
	}
    
    // Strip non-digits
    _cardCVCField.text = [cardCVC string];
    
    if ([cardCVC isValidWithType:cardType]) {
        [self textFieldIsValid:_cardCVCField];
        [self stateCardZip];
    } else {
        [self textFieldIsInvalid:_cardCVCField withErrors:NO];
    }
    
    return NO;
}

- (BOOL)cardZipShouldChangeCharactersInRange: (NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [_cardZipField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PKTextField textByRemovingUselessSpacesFromString:resultString];
    PKAddressZip *zip = [PKAddressZip addressZipWithString:resultString countryCode:_countryCode];
    
    // Restrict length
    if (![zip isPartiallyValid]) {
        return NO;
    }
    
    // Strip non-digits
    _cardZipField.text = [zip string];
    
    if ([zip isValid]) {
        [self textFieldIsValid:_cardZipField];
    } else {
        [self textFieldIsInvalid:_cardZipField withErrors:NO];
    }
    
    return NO;
}


// Validations

- (void)checkValid
{
    if ([self isValid]) {
        isValidState = YES;
		
        if ([self.delegate respondsToSelector:@selector(paymentView:withCard:isValid:)]) {
            [self.delegate paymentView:self withCard:self.card isValid:YES];
        }
    } else if (![self isValid] && isValidState) {
        isValidState = NO;
        
        if ([self.delegate respondsToSelector:@selector(paymentView:withCard:isValid:)]) {
            [self.delegate paymentView:self withCard:self.card isValid:NO];
        }
    }
}

- (void)textFieldIsValid:(UITextField *)textField {
    textField.textColor = _defaultTextAttributes[NSForegroundColorAttributeName];
    [self checkValid];
}

- (void)textFieldIsInvalid:(UITextField *)textField withErrors:(BOOL)errors {
    if (errors) {
        textField.textColor = kPKRedColor;
    } else {
        textField.textColor = _defaultTextAttributes[NSForegroundColorAttributeName];;
    }
	
    [self checkValid];
}

- (void)onTapCountryFlag:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(paymentViewDidTapCountryFlag:)])
        [self.delegate paymentViewDidTapCountryFlag:self];
}

#pragma mark -
#pragma mark UIResponder
- (UIResponder *)firstResponderField;
{
    NSArray *responders = @[self.cardNumberField, self.cardExpiryField, self.cardCVCField, self.cardZipField];
    for (UIResponder *responder in responders) {
        if (responder.isFirstResponder) {
            return responder;
        }
    }
    
    return nil;
}

- (PKTextField *)firstInvalidField;
{
    if (![[PKCardNumber cardNumberWithString:self.cardNumberField.text] isValid]) {
        return self.cardNumberField;
	}
    else if (![[PKCardExpiry cardExpiryWithString:self.cardExpiryField.text] isValid]) {
        return self.cardExpiryField;
	}
    else if (![[PKCardCVC cardCVCWithString:self.cardCVCField.text] isValid]) {
        return self.cardCVCField;
	}
    else if (![[PKAddressZip addressZipWithString:self.cardZipField.text countryCode:_countryCode] isValid])
        return self.cardZipField;
    
    return nil;
}

- (PKTextField *)nextFirstResponder;
{
    if (self.firstInvalidField) {
        return self.firstInvalidField;
	}
    
    return self.cardZipField;
}

- (BOOL)isFirstResponder;
{
    return self.firstResponderField.isFirstResponder;
}

- (BOOL)canBecomeFirstResponder;
{
    return self.nextFirstResponder.canBecomeFirstResponder;
}

- (BOOL)becomeFirstResponder;
{
    return [self.nextFirstResponder becomeFirstResponder];
}

- (BOOL)canResignFirstResponder;
{
    return self.firstResponderField.canResignFirstResponder;
}

- (BOOL)resignFirstResponder;
{
    return [self.firstResponderField resignFirstResponder];
}

@end
