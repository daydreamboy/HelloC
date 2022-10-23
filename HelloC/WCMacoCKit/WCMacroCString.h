//
//  WCMacroCString.h
//  HelloC
//
//  Created by wesley_chen on 2022/10/23.
//

#ifndef WCMacroCString_h
#define WCMacroCString_h

// @see https://stackoverflow.com/questions/4102320/how-to-encrypt-strings-at-compile-time/4102533#4102533
// @see https://stackoverflow.com/questions/7270473/compile-time-string-encryption

#define WCEncryptedCString(literalCString_) WCXORCString30_(literalCString_)
#define WCDecryptedCString(encryptedCStringVar_) { WCXORCString_(encryptedCStringVar_) }

/**
 @param cStr, which maximum length is 30
 */
#define WCXORCString30_(cStr) { \
WCXORCString_(cStr "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0") \
}

#define WCXORCString_(cStr) \
WCXORChar2_((cStr)[0], 0), \
WCXORChar2_((cStr)[1], 1), \
WCXORChar2_((cStr)[2], 2), \
WCXORChar2_((cStr)[3], 3), \
WCXORChar2_((cStr)[4], 4), \
WCXORChar2_((cStr)[5], 5), \
WCXORChar2_((cStr)[6], 6), \
WCXORChar2_((cStr)[7], 7), \
WCXORChar2_((cStr)[8], 8), \
WCXORChar2_((cStr)[9], 9), \
WCXORChar2_((cStr)[10], 10), \
WCXORChar2_((cStr)[11], 11), \
WCXORChar2_((cStr)[12], 12), \
WCXORChar2_((cStr)[13], 13), \
WCXORChar2_((cStr)[14], 14), \
WCXORChar2_((cStr)[15], 15), \
WCXORChar2_((cStr)[16], 16), \
WCXORChar2_((cStr)[17], 17), \
WCXORChar2_((cStr)[18], 18), \
WCXORChar2_((cStr)[19], 19), \
WCXORChar2_((cStr)[20], 20), \
WCXORChar2_((cStr)[21], 21), \
WCXORChar2_((cStr)[22], 22), \
WCXORChar2_((cStr)[23], 23), \
WCXORChar2_((cStr)[24], 24), \
WCXORChar2_((cStr)[25], 25), \
WCXORChar2_((cStr)[26], 26), \
WCXORChar2_((cStr)[27], 27), \
WCXORChar2_((cStr)[28], 28), \
WCXORChar2_((cStr)[29], 29), \
'\0'

#define WCXORChar2_(ch, index) \
WCXORChar3_(ch, WCRandomSeed, index)

#define WCXORChar3_(ch, key, index) \
(char)(ch != '\0' ? ch ^ (key + index) : '\0')

// Use Compile-Time as seed
#define WCRandomSeed ( \
(__TIME__[7] - '0') * 1  + (__TIME__[6] - '0') * 10  + \
(__TIME__[4] - '0') * 60   + (__TIME__[3] - '0') * 600 + \
(__TIME__[1] - '0') * 3600 + (__TIME__[0] - '0') * 36000)

#endif /* WCMacroCString_h */
