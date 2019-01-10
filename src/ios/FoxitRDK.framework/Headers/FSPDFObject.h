/* ----------------------------------------------------------------------------
 * This file was automatically generated by SWIG (http://www.swig.org).
 * Version 2.0.6
 *
 * This file is not intended to be easily readable and contains a number of
 * coding conventions designed to improve portability and efficiency. Do not make
 * changes to this file unless you know what you are doing--modify the SWIG
 * interface file instead.
 * ----------------------------------------------------------------------------- */

/**
 * @file	FSPDFObject.h
 * @brief	This file contains definitions of object-c APIs for Foxit PDF SDK.
 */

#import "FSCommon.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * @brief	Enumeration for PDF object type.
 *
 * @details	Values of this enumeration can be used alone.
 */
typedef NS_ENUM(NSUInteger, FSPDFObjectType) {
    /** @brief	Invalid PDF object type. */
    e_objInvalidType = 0,
    /** @brief	PDF object type for boolean. */
    e_objBoolean,
    /** @brief	PDF object type for number. */
    e_objNumber,
    /** @brief	PDF object type for string. */
    e_objString,
    /** @brief	PDF object type for name. */
    e_objName,
    /** @brief	PDF object type for array. */
    e_objArray,
    /** @brief	PDF object type for dictionary. */
    e_objDictionary,
    /** @brief	PDF object type for stream. */
    e_objStream,
    /** @brief	PDF object type for a null object. */
    e_objNull,
    /** @brief	PDF object type for a reference object. */
    e_objReference
};


/**
 * @brief	Class to access a PDF object.
 *
 * @details	PDF supports eight basic types of objects: <br>
 *			"Boolean value", "Integer and real number", "String", "Name",
 *			"Array", "Dictionary",  "Stream", "The null object".<br>
 *			If user wants to make a newly created PDF object to be an indirect object, please call function {@link FSPDFDoc::addIndirectObject:}.
 *			For more details about PDF objects, please refer to <PDF Reference 1.7> Section 3.2 Objects.<br>
 *			Class ::FSPDFObject is a base class for all kinds of PDF objects. It offers different functions to create different kind of PDF objects.
 *			For "Array", "Dictionary" and "Stream" PDF object, please refer to derived classes ::FSPDFArray, ::FSPDFDictionary and ::FSPDFStream.
 *
 * @see FSPDFArray
 * @see FSPDFDictionary
 * @see FSPDFStream
 */
@interface FSPDFObject : NSObject
{
    /** @brief SWIG proxy related property, it's deprecated to use it. */
    void *swigCPtr;
    /** @brief SWIG proxy related property, it's deprecated to use it. */
    BOOL swigCMemOwn;
}
/** @brief SWIG proxy related function, it's deprecated to use it. */
-(void*)getCptr;
/** @brief SWIG proxy related function, it's deprecated to use it. */
-(id)initWithCptr: (void*)cptr swigOwnCObject: (BOOL)ownCObject;
/**
 * @brief	Create a PDF object from a boolean value.
 *
 * @param[in]	boolean		A boolean value.
 *
 * @return	A new PDF object instance, whose object type is {@link FSPDFObjectType::e_objBoolean}.
 */
+(FSPDFObject*)createFromBoolean: (BOOL)boolean;
/**
 * @brief	Create a PDF object from a float number.
 *
 * @param[in]	f		A float value.
 *
 * @return	A new PDF object instance, whose object type is {@link FSPDFObjectType::e_objNumber}.
 */
+(FSPDFObject*)createFromFloat: (float)f;
/**
 * @brief	Create a PDF object from a integer number.
 *
 * @param[in]	integer		An integer value.
 *
 * @return	A new PDF object instance, whose object type is {@link FSPDFObjectType::e_objNumber}.
 */
+(FSPDFObject*)createFromInteger: (int)integer;
/**
 * @brief	Create a PDF object from string.
 *
 * @param[in]	string	A string value.
 *
 * @return	A new PDF object instance, whose object type is {@link FSPDFObjectType::e_objString}.
 */
+(FSPDFObject*)createFromString: (NSString *)string;
/**
 * @brief	Create a PDF object from a string which represents a name.
 *
 * @param[in]	name	A name string.
 *
 * @return	A new PDF object instance, whose object type is {@link FSPDFObjectType::e_objName}.
 */
+(FSPDFObject*)createFromName: (NSString *)name;
/**
 * @brief	Create a PDF object from date time.
 *
 * @details	PDF defines a standard date format, which closely follows that of the
 *			international standard ASN.1 (Abstract Syntax Notation One), defined in ISO/
 *			IEC 8824 (see the Bibliography). A date is an ASCII string of the form
 *			(D:YYYYMMDDHHmmSSOHH'mm')
 *
 * @param[in]	dateTime	A date time instance.
 *
 * @return	A new PDF object instance, whose object type is {@link FSPDFObjectType::e_objString}.
 */
+(FSPDFObject*)createFromDateTime: (FSDateTime*)dateTime;
/**
 * @brief	Create a reference for an indirect object.
 *
 * @details	The indirect object can be retrieved from following functions:
 *			<ul>
 *			<li>Returned by function {@link FSPDFDoc::getIndirectObject:}.</li>
 *			<li>Returned by function {@link FSPDFDoc::addIndirectObject:}, when try to add a direct PDF object to PDF document
 *				and make it to be an indirect object.</li>
 *			</ul>
 *
 * @param[in]	pDoc	A PDF document instance.
 * @param[in]	objnum	The indirect object number of the indirect PDF object. This should be above 0.
 *
 * @return	A new PDF object instance, whose object type is {@link FSPDFObjectType::e_objReference}.
 */
+(FSPDFObject*)createReference: (FSPDFDoc*)pDoc objnum: (unsigned int)objnum;
/**
 * @brief	Clone current PDF object and get the clone result.
 *
 * @return	A new PDF object instance as the clone result.
 */
-(FSPDFObject*)cloneObject;
/**
 * @brief	Get the type of current PDF object.
 *
 * @return	A value represents the object type. Please refer to {@link FSPDFObjectType::e_objBoolean FSPDFObjectType::e_objXXX} values and it would be one of these values.
 */
-(FSPDFObjectType)getType;
/**
 * @brief	Get the indirect object number of current PDF object.
 *
 * @return	The indirect object number:
 *			<ul>
 *			<li>0 for direct object.</li>
 *			<li>above 0 for indirect object.</li>
 *			<li>-1 means there is any error.</li>
 *			</ul>
 */
-(unsigned int)getObjNum;
/**
 * @brief	Get the integer value of current PDF object.
 *
 * @details	Only used when current object type is {@link FSPDFObjectType::e_objNumber}.
 *
 * @return	The integer value. -1 may also mean current PDF object type is not {@link FSPDFObjectType::e_objNumber}.
 */
-(int)getInteger;
/**
 * @brief	Get the float value of current PDF object.
 *
 * @details	Only used when current object type is {@link FSPDFObjectType::e_objNumber}.
 *
 * @return	The integer value. -1.0 may also mean current PDF object type is not {@link FSPDFObjectType::e_objNumber}.
 */
-(float)getFloat;
/**
 * @brief	Get the boolean value of current PDF object.
 *
 * @details	Only used when current object type is {@link FSPDFObjectType::e_objBoolean}.
 *
 * @return	The boolean value. <b>NO</b> may also mean current PDF object type is not {@link FSPDFObjectType::e_objBoolean}.
 */
-(BOOL)getBoolean;
/**
 * @brief	Get the matrix value of current PDF object.
 *
 * @details	Only used for a PDF array object when it has 6 number objects as elements.
 *
 * @return	A matrix instance.
 *			If there is any error, <b>nil</b> will be returned.
 */
-(FSMatrix*)getMatrix;
/**
 * @brief	Get the rectangle value of current PDF object.
 *
 * @details	Only used for a PDF array object when it has 4 number objects as elements.
 *
 * @return	A float rectangle instance.
 *			If there is any error, <b>nil</b> will be returned.
 */
-(FSRectF*)getRect;
/**
 * @brief	Get the direct object of current PDF object.
 *
 * @return	A PDF object that represents the direct PDF object.
 *			If there is any error, <b>nil</b> will be returned.
 */
-(FSPDFObject*)getDirectObject;
/**
 * @brief	Get the date time value of current PDF object.
 *
 * @details	Only used when current object type is {@link FSPDFObjectType::e_objString} and its content is PDF standard date format.
 *
 * @return	A date time instance.
 *			If there is any error, <b>nil</b> will be returned.
 */
-(FSDateTime*)getDateTime;
/**
 * @brief	Get the string value of current PDF object.
 *
 * @details	This function will get the string format for actual value of current PDF object.<br>
 *			If object type is {@link FSPDFObjectType::e_objBoolean}, "true" or "false" string value will be returned, depending on its actual value.<br>
 *			If object type is {@link FSPDFObjectType::e_objNumber}, the value will be represents as a string. For example, "1.5" string is for value 1.5.<br>
 *			If object type is {@link FSPDFObjectType::e_objString} or {@link FSPDFObjectType::e_objName}, the string value will be retrieved directly.<br>
 *			If value of current PDF object cannot be converted to a valid string, an empty string will be returned.
 *
 * @return	String value.
 *			An empty string may also mean there is not valid string value or there is any error.
 */
-(NSString *)getString;

/** @brief Free the object. */
-(void)dealloc;

@end


/**
 * @brief	Class to access a PDF stream object.
 *
 * @details	A PDF stream object consists of a direct dictionary object and stream data.<br>
 *			For more details, please refer to <PDF Reference 1.7> Section 3.2.7 Stream Objects.<br>
 *			Class ::FSPDFStream is derived from ::FSPDFObject
 *			and offers functions to create a new PDF stream object and access stream data.
 *
 * @see FSPDFObject
 */
@interface FSPDFStream : FSPDFObject
/** @brief SWIG proxy related function, it's deprecated to use it. */
-(void*)getCptr;
/** @brief SWIG proxy related function, it's deprecated to use it. */
-(id)initWithCptr: (void*)cptr swigOwnCObject: (BOOL)ownCObject;
/**
 * @brief	Create a new stream object based on a dictionary.
 *
 * @param[in]	dictionary	A PDF dictionary object.
 *							If this is <b>nil</b>, stream object will be created based on an empty dictionary.
 *
 * @return	A new PDF stream object.
 */
+(FSPDFStream*)create: (FSPDFDictionary*)dictionary;
/**
 * @brief	Get the dictionary object associated to current stream object.
 *
 * @return	The stream dictionary.
 */
-(FSPDFDictionary*)getDictionary;
/**
 * @brief	Get size of stream data, in bytes.
 *
 * @param[in]	rawData		A boolean value that indicates whether to get raw data or not:
 *							<b>YES</b> means to get raw data, and <b>NO</b> means to get decoded data (original data).
 *
 * @return	The data size, in bytes.
 */
-(unsigned int)getDataSize: (BOOL)rawData;
/**
 * @brief	Get stream data.
 *
 * @param[in]	rawData		A boolean value that indicates whether to get raw data or not:
 *							<b>YES</b> means to get raw data, and <b>NO</b> means to get decoded data (original data).
 * @param[in]	bufLen		Size of the data that user wants to retrieve from current PDF stream object, in bytes.
 *							If this is larger than the actual stream data size returned by function {@link FSPDFStream::getDataSize:} (with same parameter <i>rawData</i>),
 *							the whole stream data will be retrieved.
 *
 * @return	Stream data.
 */
-(NSData *)getData: (BOOL)rawData bufLen: (int)bufLen;
/**
 * @brief	Set stream data.
 *
 * @param[in]	buffer		New stream data.
 */
-(void)setData: (NSData *)buffer;

/** @brief Free the object. */
-(void)dealloc;

@end


/**
 * @brief	Class to access a PDF array object.
 *
 * @details	A PDF array object is a one-dimensional collection of objects arranged sequentially.
 *			Unlike arrays in many other computer languages, elements in a PDF array can be any combination of numbers, strings,
 *			dictionaries, or any other objects, including other arrays. <br>
 *			For more details, please refer to <PDF Reference 1.7> Section 3.2.5 Array Objects.<br>
 *			Class ::FSPDFArray is derived from ::FSPDFObject
 *			and offers functions to create a new PDF array object and access elements of a PDF array object.
 *
 * @see FSPDFObject
 */
@interface FSPDFArray : FSPDFObject
/** @brief SWIG proxy related function, it's deprecated to use it. */
-(void*)getCptr;
/** @brief SWIG proxy related function, it's deprecated to use it. */
-(id)initWithCptr: (void*)cptr swigOwnCObject: (BOOL)ownCObject;
/**
 * @brief	Create a new array object.
 *
 * @return	A new PDF array object.
 */
+(FSPDFArray*)create;
/**
 * @brief	Create a new array object for a matrix.
 *
 * @param[in]	matrix	A matrix object.
 *
 * @return	A new PDF array object.
 */
+(FSPDFArray*)createFromMatrix: (FSMatrix*)matrix;
/**
 * @brief	Create a new array object for a rectangle.
 *
 * @param[in]	rect	A float rectangle object.
 *
 * @return	A new PDF array object.
 */
+(FSPDFArray*)createFromRect: (FSRectF*)rect;
/**
 * @brief	Get the count of elements.
 *
 * @return	Count of elements. If there is any error, -1 will be returned.
 */
-(int)getElementCount;
/**
 * @brief	Get a specific element by index.
 *
 * @param[in]	index	Index of the element to be retrieved. Valid range: from 0 to (<i>count</i>-1).
 *						<i>count</i> is returned by function {@link FSPDFArray::getElementCount}.
 *
 * @return	A ::FSPDFObject object receives the element.
 *			If there is any error, <b>nil</b> will be returned.
 */
-(FSPDFObject*)getElement: (int)index;
/**
 * @brief	Add a PDF object to the end of current PDF array object.
 *
 * @param[in]	element		The PDF object to be added to array.
 */
-(void)addElement: (FSPDFObject*)element;
/**
 * @brief	Insert a PDF object to a specific position of current PDF array object.
 *
 * @param[in]	index		Index of the position where parameter <i>element</i> will be inserted to.
 *							Valid range: from 0 to (<i>count</i>-1). <i>count</i> is returned by function {@link FSPDFArray::getElementCount}.
 *							If this is below 0 or count of element in current PDF array is 0, parameter <i>element</i> is to be inserted to the first position.<br>
 *							If this is larger than count of element in current PDF array, parameter <i>element</i> is to be added to the last.
 * @param[in]	element		The PDF object to be inserted to current PDF array.
 */
-(void)insertAt: (int)index element: (FSPDFObject*)element;
/**
 * @brief	Set a new PDF object at specific position in current PDF array object.
 *
 * @param[in]	index		Index of the position where parameter <i>element</i> will be set to.
 *							Valid range: from 0 to (<i>count</i>-1). <i>count</i> is returned by function {@link FSPDFArray::getElementCount}.
 * @param[in]	element		The PDF object to be set to current PDF array.
 */
-(void)setAt: (int)index element: (FSPDFObject*)element;
/**
 * @brief	Remove an element in a specific position(by index) from current PDF array object.
 *
 * @param[in]	index	Index of the position where the element will be removed.
 *						Valid range: from 0 to (<i>count</i>-1). <i>count</i> is returned by function {@link FSPDFArray::getElementCount}.
 */
-(void)removeAt: (int)index;

/** @brief Free the object. */
-(void)dealloc;

@end


/**
 * @brief	Class to access a PDF dictionary object.
 *
 * @details	A PDF dictionary object is an associative table containing pairs of objects, known as entries of the dictionary.
 *			The first element of each entry is the key, and it must be a name PDF object.
 *			The second element is the value, and it can be any kind of PDF object, including another dictionary.
 *			In the same dictionary, no two entries should have the same key. <br>
 *			For more details, please refer to <PDF Reference 1.7> Section 3.2.6 Dictionary Objects.<br>
 *			Class ::FSPDFDictionary is derived from ::FSPDFObject
 *			and offers functions to create a new PDF dictionary object and access entries in a PDF dictionary object.
 *
 * @see FSPDFObject
 */
@interface FSPDFDictionary : FSPDFObject
/** @brief SWIG proxy related function, it's deprecated to use it. */
-(void*)getCptr;
/** @brief SWIG proxy related function, it's deprecated to use it. */
-(id)initWithCptr: (void*)cptr swigOwnCObject: (BOOL)ownCObject;
/**
 * @brief	Create a new dictionary object.
 *
 * @return	A new PDF dictionary instance, whose object type is {@link FSPDFObjectType::e_objDictionary}.
 */
+(FSPDFDictionary*)create;
/**
 * @brief	Check whether there is an entry with specific key in current dictionary or not.
 *
 * @param[in]	key		The key to be checked.
 *
 * @return	<b>YES</b> means the specific key exist in current dictionary, while <b>NO</b> means not.
 *			<b>NO</b> may also mean there is any error.
 */
-(BOOL)hasKey: (NSString *)key;
/**
 * @brief	Get the value element of an entry with specific key.
 *
 * @param[in]	key		The key of the entry.
 *
 * @return	A PDF object instance that represents the value element of the specific entry.
 *			If there is any error, <b>nil</b> will be returned.
 */
-(FSPDFObject*)getElement: (NSString *)key;
/**
 * @brief	Get the key of an entry specified by position.
 *
 * @param[in]	pos		A position instance that specifies the position of the entry.
 *
 * @return	The key of the specific entry.
 *			If there is any error, an empty string will be returned.
 */
-(NSString *)getKey: (void*)pos;
/**
 * @brief	Get the value element of an entry specified by position.
 *
 * @param[in]	pos		A position object that specifies the position of the entry.
 *
 * @return	A PDF object instance that receives the value element of the specific entry.
 *			If there is any error, <b>nil</b> will be returned.
 */
-(FSPDFObject*)getValue: (void*)pos;
/**
 * @brief	Move to the position of first or the next entry.
 *
 * @param[in]	pos		A position instance that indicates the position of current entry in the dictionary.
 *						If this is <b>nil</b>, the position of first entry in the dictionary will be returned.
 *
 * @return	A new position instance that represents the position of next entry in the dictionary.
 *			<b>nil</b> means current entry is the last in the dictionary, or there is any error.
 */
-(void*)moveNext: (void* _Nullable)pos;
/**
 * @brief	Set a PDF object as value element to an entry with specific key.
 *
 * @param[in]	key		The key of the entry, whose value element will be set.
 * @param[in]	object	A PDF object instance which will be set to the entry as value element.
 */
-(void)setAt: (NSString *)key object: (FSPDFObject*)object;
/**
 * @brief	Remove an entry with specific key.
 *
 * @param[in]	key		The key of the entry to be removed.
 */
-(void)removeAt: (NSString *)key;

/** @brief Free the object. */
-(void)dealloc;

@end

NS_ASSUME_NONNULL_END