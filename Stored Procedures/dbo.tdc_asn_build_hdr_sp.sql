SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_asn_build_hdr_sp] (
	@ASN_num	int
	) AS
/*******************************************************************************
 *
 * 980624 REA
 *
 * This proc prints carton information from TDC and Platinum data
 * to the EDI ASN 856 file structure for LUNT.
 *
 *	EDI - Electronic Data Interchange
 *	ASN - Advanced Shipping Notification
 *
 * INPUT
 *	#order_list_out		List of order/extension numbers
 *	#sm_containers_list	List of all containers for all the listed orders
 *	#items_list		List of items included in the ASN
 *
 * OUTPUT
 *	tdc_ASN_text	Carton line item information stored in this table for each carton
 *			held by the input container.  Used by calling program to print ASN information
 *			Carton information printed to the ASN file for each carton
 *			contained by the parent carton for the specified order/extension.
 *	#err_list_out	Error messages
 **********
 * HDR
 **********
 *
 * Order information - header information about a particular
 * order included in the shipment.
 *
 * Warning:  Potential loss of data...
 *	@HDRBillToName1	char(35) <--  varchar(40)
 *	@HDRBillToAddr1	char(35) <--  varchar(40)
 *	@HDRBillToAddr2	char(35) <--  varchar(40)
 *	@HDRBillToCity	char(19) <--  varchar(40)
 *
 * Each 'HDR' segment will be followed immediately by its own
 * set of 'CAR' segments for the specified order/extension.
 */

/*
 * Tables for INTERNAL use
 */
CREATE TABLE #ord_containers_list (
	parent_serial_no int,	-- containers in the ASN-order tree
	child_serial_no int	-- pointers to corresponding items
	)
CREATE TABLE #text_date_time (
	date_text	char(6),
	time_text	char(6)
	)

DECLARE	@err_stop int
SELECT	@err_stop = 1

--set nocount on

DECLARE	@HDRTag			char(3),
	@OrderNum		int,
	@OrderExt		int,
	@HDROrderNo		char(22),
	@OrderDate		datetime,
	@ExpectedShipDate	datetime,
	@CancelDate		datetime,
	@HDROrderDate		char(6),
	@HDRExpectedShipDate	char(6),
	@HDRCancelDate		char(6),
	@HDRUser2UltimateRec	char(17),
	@HDRReceiverName1	char(35),
	@HDRReceiverName2	char(35),
	@HDRReceiverAddr1	char(35),
	@HDRReceiverAddr2	char(35),
	@HDRReceiverCity	char(19),
	@HDRReceiverStateProv	char(2),
	@HDRReceiverCountry	char(2),
	@HDRReceiverPostalCode	char(11),
	@HDRLocalBillToID	char(50),
	@HDRExternalBillToID	char(50),
	@HDRBillToName1		char(35),
	@HDRBillToName2		char(35),
	@HDRBillToAddr1		char(35),
	@HDRBillToAddr2		char(35),
	@HDRBillToCity		char(19),
	@HDRBillToStateProv	char(2),
	@HDRBillToCountry	char(2),
	@HDRBillToPostalCode	char(11),
	@HDRDepartmentNo	char(15),
	@HDRApplicationID	char(10),
	@HDRPromoDealCode	char(30),
	@HDRVendorCode		char(30),
	@HDRCustomerPONo	char(25),
	@HDRHCartons		char(6),
	@HDRHDetailLines	char(6),
	@HDRInvoiceNo		char(30),
	@HDRBuffer		char(205),	-- Wojtek said he would put 205 characters here
	@tmp			int

DECLARE	@return_code	int
SELECT	@return_code = 0


/*
 * Initialize constant values
 */
SELECT	@HDRTag			= 'HDR',
	@HDRUser2UltimateRec	= '',
	@HDRReceiverName1	= '',
	@HDRReceiverName2	= '',
	@HDRReceiverAddr1	= '',
	@HDRReceiverAddr2	= '',
	@HDRReceiverCity	= '',
	@HDRReceiverStateProv	= '',
	@HDRReceiverCountry	= '',
	@HDRReceiverPostalCode	= '',
	@HDRExternalBillToID	= '',
	@HDRBillToName2		= '',
	@HDRBillToCountry	= '', -- Weird this isn't stored in bol
	@HDRDepartmentNo	= '',
	@HDRApplicationID	= '',
	@HDRPromoDealCode	= '',
	@HDRVendorCode		= '',
	@HDRInvoiceNo		= ''

DECLARE cursorHDR INSENSITIVE CURSOR FOR SELECT
	order_no, order_ext
	FROM #order_list_out
	ORDER BY order_no, order_ext
	FOR READ ONLY
/*
 * Start HDR segment processing
 */
OPEN cursorHDR
startOfCursorHDR:
	/*
	 * Initialize the segment's varying character values...
	 * NOTE:  These should always be init'ed so that we
	 * don't end up with any NULLs or wrongful repeats
	 */
	SELECT	@HDROrderNo		= '',
		@HDROrderDate		= '',
		@HDRExpectedShipDate	= '',
		@HDRCancelDate		= '',
		@HDRLocalBillToID	= '',
		@HDRBillToName1		= '',
		@HDRBillToAddr1		= '',
		@HDRBillToAddr2		= '',
		@HDRBillToCity		= '',
		@HDRBillToStateProv	= '',
		@HDRBillToPostalCode	= '',
		@HDRCustomerPONo	= '',
		@HDRHCartons		= '',
		@HDRHDetailLines	= '',
		@HDRBuffer		= ''

	FETCH NEXT FROM cursorHDR INTO
		@OrderNum,
		@OrderExt
	IF (@@fetch_status = 0) BEGIN /* next HDR row fetched */
		SELECT	@HDROrderNo		= convert(char(11),@OrderNum)+'x'+convert(char(10),@OrderExt)
		SELECT	@OrderDate		= date_entered,
			@ExpectedShipDate	= sch_ship_date,
			@CancelDate		= cancel_date,
			@HDRLocalBillToID	= bill_to_key,
			@HDRCustomerPONo	= cust_po,
			@HDRBuffer		= f_note  -- Wojtek said he would put 205 characters here
			FROM orders
			WHERE	order_no = @OrderNum AND
				ext	 = @OrderExt
		EXEC tdc_calc_text_date_time @OrderDate
		SELECT	@HDROrderDate = date_text
			FROM #text_date_time
		EXEC tdc_calc_text_date_time @ExpectedShipDate
		SELECT	@HDRExpectedShipDate = date_text
			FROM #text_date_time
		EXEC tdc_calc_text_date_time @CancelDate
		SELECT	@HDRCancelDate = date_text
			FROM #text_date_time
		SELECT	@HDRBillToName1		= convert(char(35), bill_to_name),
			@HDRBillToAddr1		= convert(char(35), bill_to_add_1),
			@HDRBillToAddr2		= convert(char(35), bill_to_add_2),
			@HDRBillToCity		= convert(char(19), bill_to_city),
			@HDRBillToStateProv	= bill_to_state,
			@HDRBillToPostalCode	= bill_to_zip
			FROM bol
			WHERE	bl_src_no  = @OrderNum AND
				bl_src_ext = @OrderExt
/*
 * Need to create a temp table of the serial number(s) for the lowest
 * level containers in tdc_dist_group for a given order for this ASN.
 *
 * This will also be passed along to tdc_lunt_asn_build_carton
 */
		TRUNCATE TABLE #ord_containers_list
		INSERT INTO #ord_containers_list
			SELECT	c.parent_serial_no, c.child_serial_no
				FROM #sm_containers_list c, tdc_dist_item_pick p
				WHERE	c.child_serial_no = p.child_serial_no AND
					p.order_no	  = @OrderNum AND
					p.order_ext	  = @OrderExt
		SELECT	@tmp	= COUNT(DISTINCT parent_serial_no)
			FROM #ord_containers_list
		SELECT	@HDRHCartons		= convert(char(6), @tmp)
		SELECT	@tmp	= COUNT(child_serial_no)
			FROM #ord_containers_list
		SELECT	@HDRHDetailLines	= convert(char(6), @tmp)


select	@HDRTag			= ISNULL(@HDRTag, ' '),
	@HDROrderNo		= ISNULL(@HDROrderNo, ' '),
	@HDROrderDate		= ISNULL(@HDROrderDate, ' '),
	@HDRExpectedShipDate	= ISNULL(@HDRExpectedShipDate, ' '),
	@HDRCancelDate		= ISNULL(@HDRCancelDate, ' '),
	@HDRUser2UltimateRec	= ISNULL(@HDRUser2UltimateRec, ' '),
	@HDRReceiverName1	= ISNULL(@HDRReceiverName1, ' '),
	@HDRReceiverName2	= ISNULL(@HDRReceiverName2, ' '),
	@HDRReceiverAddr1	= ISNULL(@HDRReceiverAddr1, ' '),
	@HDRReceiverAddr2	= ISNULL(@HDRReceiverAddr2, ' '),
	@HDRReceiverCity	= ISNULL(@HDRReceiverCity, ' '),
	@HDRReceiverStateProv	= ISNULL(@HDRReceiverStateProv, ' '),
	@HDRReceiverCountry	= ISNULL(@HDRReceiverCountry, ' '),
	@HDRReceiverPostalCode	= ISNULL(@HDRReceiverPostalCode, ' '),
	@HDRLocalBillToID	= ISNULL(@HDRLocalBillToID, ' '),
	@HDRExternalBillToID	= ISNULL(@HDRExternalBillToID, ' '),
	@HDRBillToName1		= ISNULL(@HDRBillToName1, ' '),
	@HDRBillToName2		= ISNULL(@HDRBillToName2, ' '),
	@HDRBillToAddr1		= ISNULL(@HDRBillToAddr1, ' '),
	@HDRBillToAddr2		= ISNULL(@HDRBillToAddr2, ' '),
	@HDRBillToCity		= ISNULL(@HDRBillToCity, ' '),
	@HDRBillToStateProv	= ISNULL(@HDRBillToStateProv, ' '),
	@HDRBillToCountry	= ISNULL(@HDRBillToCountry, ' '),
	@HDRBillToPostalCode	= ISNULL(@HDRBillToPostalCode, ' '),
	@HDRDepartmentNo	= ISNULL(@HDRDepartmentNo, ' '),
	@HDRApplicationID	= ISNULL(@HDRApplicationID, ' '),
	@HDRPromoDealCode	= ISNULL(@HDRPromoDealCode, ' '),
	@HDRVendorCode		= ISNULL(@HDRVendorCode, ' '),
	@HDRCustomerPONo	= ISNULL(@HDRCustomerPONo, ' '),
	@HDRHCartons		= ISNULL(@HDRHCartons, ' '),
	@HDRHDetailLines	= ISNULL(@HDRHDetailLines, ' '),
	@HDRInvoiceNo		= ISNULL(@HDRInvoiceNo, ' '),
	@HDRBuffer		= ISNULL(@HDRBuffer, ' ')

/*
 * Note: We are putting a kludge in here to work around the automatic conversion
 * of concatenated strings to varchar() even though the insert is into a text field
 */
DECLARE @txt_ptr varbinary(16)
/*
 * We are starting with a fresh ASN...TRUNCATE to make certain the table's fresh
 */
INSERT INTO tdc_asn_text 
	SELECT	@ASN_num,
		@HDRTag

SELECT	@txt_ptr = TEXTPTR(segment_text) 
	FROM tdc_asn_text
	WHERE row_num = (SELECT MAX(row_num) FROM tdc_asn_text WHERE asn_num = @ASN_num)
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDROrderNo
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDROrderDate
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRExpectedShipDate
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRCancelDate
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRUser2UltimateRec
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRReceiverName1
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRReceiverName2
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRReceiverAddr1
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRReceiverAddr2
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRReceiverCity
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRReceiverStateProv
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRReceiverCountry
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRReceiverPostalCode
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRLocalBillToID
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRExternalBillToID
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRBillToName1
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRBillToName2
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRBillToAddr1
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRBillToAddr2
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRBillToCity
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRBillToStateProv
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRBillToCountry
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRBillToPostalCode
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRDepartmentNo
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRApplicationID
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRPromoDealCode
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRVendorCode
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRCustomerPONo
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRHCartons
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRHDetailLines
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRInvoiceNo
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@HDRBuffer

		EXEC @return_code = tdc_asn_build_carton_sp @ASN_num, @OrderNum, @OrderExt
		IF @return_code < 0
			IF @err_stop = 1 RETURN @return_code

		GOTO startOfCursorHDR /* FETCH NEXT HDR */
		END
	ELSE IF (@@fetch_status = -1) /* nothing fetched */
		GOTO endOfCursorHDR
	ELSE 	
		
		/* fetched row must have data that was changed...
		 * We won't do anything because we aren't writing
		 * to the temp table to cause this to happen.
		 */

		GOTO startOfCursorHDR

	GOTO startOfCursorHDR /* FETCH NEXT */

endOfCursorHDR:

DEALLOCATE cursorHDR

/*
 * End HDR segment processing
 */

RETURN @return_code

GO
GRANT EXECUTE ON  [dbo].[tdc_asn_build_hdr_sp] TO [public]
GO
