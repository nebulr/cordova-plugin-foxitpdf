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
 * @file	FSPressureSenseInk.h
 * @brief	This file contains definitions of object-c APIs for Foxit PDF SDK.
 */
#import "FSCommon.h"

@class FSPSI;
@class FSPSInk;

NS_ASSUME_NONNULL_BEGIN
/**
 * @brief	Class to represents a callback object for refreshing a region for PSI.
 *
 * @details	All the pure virtual functions in this class are used as callback functions and should be implemented by user.
 *			An implemented ::FSPSICallback object can be set to a PSI object by function {@link FSPSI::setCallback:}.
 */
@interface FSPSICallback : NSObject
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
/** @brief Default initialization. */
-(id)init;
/**
 * @brief	A callback function used to refresh a specified region for PSI.
 *
 * @param[in]	PSIHandle	Pointer to a ::FSPSI object.
 * @param[in]	flushRect	Rectangle of the refresh region.
 *
 * @return  None.
 */
-(void)refresh:(FSPSI*)PSIHandle Rect:(FSRectF*)flushRect;

/**
 * @brief   FSPSICallback release by it's handler ,don't need release it by itself
 *
 * @return  None.
 */
-(void)dealloc;
@end

/**
 * @brief	Class to access PSI operation.
 *
 * @details	PSI, "pressure sensitive ink", is used for handwriting signature especially, and usually works together with a handwriting board or for a touchscreen.
 *			PSI contains private coordinates, and a canvas is created in its coordinates. Canvas limits operating area and generates appearance of PSI.<br>
 *			PSI is independent of PDF, can be even used directly in the device screen. If user wants to save a PSI object to PDF file, please call function {@link FSPSI::convertToPDFAnnot:rect:rotate:}.
 *			This function will convert PSI data to a PSInk annotation (as a Foxit custom annotation type) and insert the PSInk annotation to the specified position in a PDF page.
 *
 * @see	FSPSInk
 */
@interface FSPSI : NSObject
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
 * @brief	Create a PSI object, based on a bitmap.
 *
 * @param[in]	bitmap		A bitmap used for rendering. It should be created with {@link FSDIBFormat::e_dibArgb} format.
 *							User should ensure this bitmap to keep valid until current PSI object is released.
 * @param[in]	simulate	Turn on/off simulation of PSI:<br>
 *							<b>YES</b> means to turn on simulation, and <b>NO</b> means to turn off simulation.<br>
 *							It can simulate handwriting weights by writing speed when simulation is on.
 *
 * @return	A new PSI object.
 *
 * @exception	e_errParam			Value of input parameter is invalid.
 * @exception	e_errOutOfMemory	Out-of-memory error occurs.
 */
-(id)initWithBitmap: (FSBitmap*)bitmap simulate: (BOOL)simulate;

/**
 * @brief	Create a PSI object, with specified width and height for the canvas.
 *
 * @param[in]	width		Width of PSI canvas in device coordinate system. This shall be greater than 0.
 * @param[in]	height		Height of PSI canvas in device coordinate system. This shall be greater than 0.
 * @param[in]	simulate	Turn on/off simulation of PSI:<br>
 *							<b>YES</b> means to turn on simulation, and <b>NO</b> means to turn off simulation.<br>
 *							It can simulate handwriting weights by writing speed when simulation is on.
 *
 * @return	A new PSI object.
 */
-(id)initWithWidth: (int)width height: (int)height simulate: (BOOL)simulate;

/**
 * @brief	Set the callback object for refreshing.
 *
 * @param[in]	callback		A callback object {@link ::FSPSICallback} which is implemented by user.
 *								User should not release it any more.
 *
 * @return None.
 */

-(void)setCallback: (FSPSICallback*)callback;

/**
 * @brief	Set ink color.
 *
 * @details	This should be set before adding first point to PSI object.
 *			If not set, the default value (value 0xFF000000) will be used.
 *
 * @param[in]	color	Ink color. Format: 0xAARRGGBB. If not set, default value will be used. Default value: 0xFF000000.
 *						Alpha value is ignored and will always be treated as 0xFF internally.
 *
 * @return None.
 */
-(void)setColor: (unsigned int)color;

/**
 * @brief	Set ink diameter.
 *
 * @details	This should be set before adding first point to PSI object.
 *			If not set, the default value (value 10) will be used.
 *
 * @param[in]	diameter	Ink diameter. This shall be bigger than 1.
 *							If not set, default value will be used. Default value: 10.
 *
 * @return None.
 *
 * @exception	e_errParam		Value of any input parameter is invalid.
 */
-(void)setDiameter: (int)diameter;

/**
 * @brief	Set ink opacity.
 *
 * @details	This should be set before adding first point to PSI object.
 *			If not set, the default value (value 1.0) will be used.
 *
 * @param[in]	opacity		Ink opacity. Valid range: from 0.0 to 1.0.
 *							If not set, default value will be used. Default value: 1.0.
 *
 * @return None.
 *
 * @exception	e_errParam		Value of any input parameter is invalid.
 */
-(void)setOpacity: (float)opacity;

/**
 * @brief	Add a point.
 *
 * @param[in]	point		A point in canvas coordinate system.
 * @param[in]	ptType	Point type. <br>
 *							Please refer to {@link FSPathPointType::e_pointTypeMoveTo FSPathPointType::e_pointTypeXXX} values and it would be one of them.
 * @param[in]	pressure	Pressure value for this point. Valid value: between 0 and 1.
 *
 * @return None.
 *
 * @exception	e_errParam		Value of input parameter is invalid.
 */
-(void)addPoint: (FSPointF*)point ptType: (FSPathPointType)ptType pressure: (float)pressure;

/**
 * @brief	Get contents rectangle.
 *
 * @return	Contents rectangle, in device coordinate system.
 *			If curernt PSI object does not contain a valid path or there is any error, a ::FSRectF object with all 0 values would be returned.
 */
-(FSRectF*)getContentsRect;

/**
 * @brief	Get the canvas bitmap.
 *
 * @return	Canvas bitmap.
 */
-(FSBitmap*)getBitmap;

/**
 * @brief	Convert a PSI object to a PSInk annotation and insert the annotation to a PDF page.
 *
 * @details	Actually, this function is to convert the path data of current PSI to a PSInk annotation, ignoring the canvas bitmap.<br>
 *			Before calling this function, user should ensure that current PSI object has contained a valid path (whose last point's type is {@link FSPathPointType::e_pointTypeLineToCloseFigure}.
 *			Otherwise, the conversion will be failed.<br>
 *
 * @param[in]	pdfPage		A PDF page object, to which the PSI is expected to inserted.
 * @param[in]	rect	A rectangle to specify the position in the PDF page, where the new PSInk annotation will be inserted.
 *							It should be valid in PDF coordinate system.
 * @param[in]	rotate		Rotation value. Currently, it can only be {@link FSRotation::e_rotation0}.
 *
 * @return	A new PSInk annotation.
 *			If there is any error, this function will return <b>nil</b>.
 *
 * @note	User do not need to call function {@link FSPSInk::resetAppearanceStream} to reset the appearance of PSInk annotation after this conversion.
 *
 * @exception	e_errParam		Value of input parameter is invalid.
 
 */
-(FSPSInk*)convertToPDFAnnot: (FSPDFPage*)pdfPage rect: (FSRectF*)rect rotate: (FSRotation)rotate;

/** @brief Free the object. */
-(void)dealloc;

@end

NS_ASSUME_NONNULL_END

