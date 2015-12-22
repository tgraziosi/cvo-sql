SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_asn_build_carton_sp] (
	@ASN_num	int,
	@ASN_order_no	int,
	@ASN_order_ext	int
	) AS
/*******************************************************************************
 *
 * 980624 REA
 *
 * This proc generates carton information from TDC and Platinum data
 * to the EDI ASN 856 file structure for LUNT.
 *
 *	EDI - Electronic Data Interchange
 *	ASN - Advanced Shipping Notification
 *
 * INPUT
 *	#int_list_in	List of cartons to be included in the ASN for the
 *			current order
 *	@ASN_num	ASN number
 *	@ASN_order_no	Order/extension numbers which contain the cartons
 *	@ASN_order_ext
 *
 * OUTPUT
 *	tdc_ASN_text	Carton line item information stored in this table for each carton
 *			held by the input container.  Used by calling program to print ASN information
 *	Carton information printed to the ASN file for each carton
 *	contained by the parent carton for the specified order/extension.
 *
 **********
 * CARton
 **********
 *
 * Carton information - header information about a particular
 * carton included in the current order.
 *
 *
 * Warning:  Potential loss of data...
 *	@CARBillToName1	char(35) <--  varchar(40)
 *
 *
 * DET segments are considered as line item detail.
 * There is no concern for a 'child container' detail for each
 * 'parent container'
 *
 * Each 'CAR' segment will be followed immediately by its own
 * set of 'DET' segments.
 */

DECLARE	@err_stop int
SELECT	@err_stop = 1

--set nocount on
/*
 * Table(s) for INTERNAL use
 */
CREATE TABLE #ord_container_items (
	serial_no int	-- items for the specified order/container
	)
/*
 * Package information - information about the package/carton
 *
 * Each 'CAR' segment will be followed immediately by its own
 * set of 'DET' segments for the specified order/extension.
 */
DECLARE	@CARtonTag		char(3),
	@CARMH10FMT		char(26),
	@CARMH10Raw		char(20),
	@CARMHApplicationID	char(2),
	@CARMH10Type		char(1),
	@CARMH10ManufacturerID	char(7),
	@MHSerialNum		int,	-- integer representation of the carton's serial number
	@CARMHSerialNo		char(9),-- character representation of the serial number
	@CARMHChkDigit		char(1),
	@CARCDetails		char(6)

DECLARE	@return_code	int
SELECT	@return_code = 0

DECLARE	@LUNTMfgCode		char(7),
	@LUNTPkgType		char(1),
	@mod10checkDigit	int,
	@numDetails		int

/*
 * Initialize constant values
 */
SELECT	@LUNTMfgCode		= '0000000',
	@LUNTPkgType		= '0',
	@CARtonTag		= 'CAR',
	@CARMH10FMT		= '',
	@CARMHApplicationID	= '',
	@CARMH10Type		= '',
	@CARMH10ManufacturerID	= '',
	@CARMHChkDigit		= ''

/*initializing manufacturing code*/
SELECT	@LUNTMfgCode	= value_str
  FROM  tdc_config
 WHERE  [function]  = 'edi_asn_wo_code'            



/*
 * Start CARton segment processing
 */
DECLARE cursorCAR INSENSITIVE CURSOR FOR SELECT
	DISTINCT parent_serial_no
	FROM	#ord_containers_list
	ORDER BY parent_serial_no
	FOR READ ONLY

OPEN cursorCAR
startOfCursorCAR:
	/*
	 * Initialize the segment's varying character values...
	 * NOTE:  These should always be init'ed so that we
	 * don't end up with any NULLs or wrongful repeats
	 */
	SELECT	@CARMH10Raw	= '',
		@CARMHSerialNo	= '',
		@CARCDetails	= ''

	FETCH NEXT FROM cursorCAR INTO
		@MHSerialNum
	IF (@@fetch_status = 0) BEGIN /* next CAR row fetched */
		SELECT	@CARMHSerialNo	 = RIGHT('00000000' + convert(varchar(9),@MHSerialNum), 9)
		SELECT	@CARMH10Raw	 = @LUNTPkgType + @LUNTMfgCode + @CARMHSerialNo
		EXEC	@mod10checkDigit = tdc_asn_calc_mod_10_chk_sp @CARMH10Raw

		SELECT	@CARMH10Raw	= LEFT('00' + @CARMH10Raw, 19) + CAST(@mod10checkDigit AS char(1))
		/*
		 * We need to figure out how many detail lines will follow.
		 * Create the list of detail serial numbers to be printed, and count that list
		 */
		TRUNCATE TABLE #ord_container_items
		INSERT INTO #ord_container_items
			SELECT	o.child_serial_no
				FROM	#ord_containers_list o, tdc_dist_item_pick p
				WHERE	o.parent_serial_no	= @MHSerialNum AND
					o.child_serial_no	= p.child_serial_no AND
					p.order_no  		= @ASN_order_no AND
					p.order_ext 		= @ASN_order_ext
		/*
		 * Now we can count the number of detail lines to be printed
		 */
		SELECT	@numDetails	= COUNT(*) FROM #ord_container_items
		SELECT	@CARCDetails	= convert(char(6),@numDetails)


		SELECT	@CARtonTag		= ISNULL(@CARtonTag, ' '),
			@CARMH10FMT		= ISNULL(@CARMH10FMT, ' '),
			@CARMH10Raw		= ISNULL(@CARMH10Raw, ' '),
			@CARMHApplicationID	= ISNULL(@CARMHApplicationID, ' '),
			@CARMH10Type		= ISNULL(@CARMH10Type, ' '),
			@CARMH10ManufacturerID	= ISNULL(@CARMH10ManufacturerID, ' '),
			@CARMHSerialNo		= ISNULL(@CARMHSerialNo, ' '),
			@CARMHChkDigit		= ISNULL(@CARMHChkDigit, ' '),
			@CARCDetails		= ISNULL(@CARCDetails, ' ')

/*!!!*/		INSERT INTO tdc_asn_text
			SELECT	@ASN_num,
				@CARtonTag		+
				@CARMH10FMT		+
				@CARMH10Raw		+
				@CARMHApplicationID	+
				@CARMH10Type		+
				@CARMH10ManufacturerID	+
				@CARMHSerialNo		+
				@CARMHChkDigit		+
				@CARCDetails

		/*
		 * #ord_container_items is populated with the list of detail items.
		 * it is passed along with the carton serial number to the BUILD DETAIL proc...
		 */
		EXEC @return_code =  tdc_asn_build_cart_det_sp @ASN_num, @ASN_order_no, @ASN_order_ext, @MHSerialNum
		IF @return_code < 0
			IF @err_stop = 1 RETURN @return_code

		GOTO startOfCursorCAR /* FETCH NEXT CAR */
		END
	ELSE IF (@@fetch_status = -1) /* nothing fetched */
		GOTO endOfCursorCAR
	ELSE 	
		
		/* fetched row must have data that was changed...
		 * We won't do anything because we aren't writing
		 * to the temp table to cause this to happen.
		 */
		
		GOTO startOfCursorCAR

endOfCursorCAR:

DEALLOCATE cursorCAR

/*
 * End CAR segment processing
 */


RETURN @return_code

GO
GRANT EXECUTE ON  [dbo].[tdc_asn_build_carton_sp] TO [public]
GO
