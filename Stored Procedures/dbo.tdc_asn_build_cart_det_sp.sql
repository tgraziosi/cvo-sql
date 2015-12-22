SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_asn_build_cart_det_sp] (
	@ASN_num	int,
	@ASN_order_no	int,
	@ASN_order_ext	int,
	@ASN_carton	int
	) AS
/*******************************************************************************
 *
 * 980623 REA
 *
 * This proc prints detail line item information from TDC and Platinum data
 * to the EDI ASN 856 file structure for LUNT.
 *
 *	EDI - Electronic Data Interchange
 *	ASN - Advanced Shipping Notification
 *
 * INPUT
 *	@ASN_num	Number of the ASN to separate multiple ASNs from ASN table
 *	@ASN_order_no	Order number
 *	@ASN_order_ext	Order extension
 *	@ASN_carton	Container serial number which contains detail items
 *			(needed to determine quantity of detail)
 *	#int_list_in	List of detail items to be printed
 *
 * OUTPUT
 *
 *	tdc_ASN_text	Detail line item information stored in this table for each item
 *			held by the input container.  Used by calling program to print ASN information
 */
/**********
 * DETail
 **********
 *
 * Print detail information - header information about an
 * item included in the current container.
 *
 *
 * Warning:  Potential loss of data...
 *	@DETLocalItemDesc char(60) <-- inv_master.description varchar(255)
 *
 *
 * DET segments are considered as line item detail.
 * There is no concern for a 'child container' detail for each
 * 'parent container'
 *
 * All 'DET' segments are for the immediately preceding 'CAR' segment.
 */

--set nocount on

DECLARE	@DETailTag		char(3),
	@DETLineNo		char(6),
	@DETLocalItemNo		char(50),
	@DETExternalItemNo	char(49),
	@DETLocalItemDesc	char(60),
	@DETExternalItemDesc	char(100),
	@DETAdditional		char(32),
	@DETQtyInCarton		char(15),
	@DETUOM			char(2),
	@DETUnitPrice		char(15),
	@DETBackOrderQty	char(15),
	@DETOrderQty		char(15),
	@DETUser1		char(30),
	@DETUser2		char(30),
	@DETUser3		char(15),
	@DETUser4		char(15),
	@DETBuffer		char(160)


DECLARE @err_unknown int
SELECT	@err_unknown = -999
DECLARE	@return_code int
SELECT	@return_code = 0

DECLARE @ItemSerialNum	int,
	@ADMpart_no	varchar(30)

/*
 * Initialize the segment's constant character values...
 * NOTE:  These should always be init'ed so that we don't end up with any NULLs
 */
SELECT	@DETailTag		= 'DET',
	@DETExternalItemDesc	= '',
	@DETAdditional		= '',
	@DETUOM			= 'EA',
	@DETUnitPrice		= '',
	@DETBackOrderQty	= '',
	@DETOrderQty		= '',
	@DETUser1		= '',
	@DETUser2		= '',
	@DETUser3		= '',
	@DETUser4		= '',
	@DETBuffer		= ''


DECLARE cursorDET INSENSITIVE CURSOR FOR SELECT
	o.serial_no
	FROM	#ord_container_items o, tdc_dist_item_pick p
	WHERE o.serial_no = p.child_serial_no
	ORDER BY p.line_no
	FOR READ ONLY
OPEN cursorDET
startOfCursorDET:
	/*
	 * Initialize the segment's varying character values...
	 * NOTE:  These should always be init'ed so that we
	 * don't end up with any NULLs or wrongful repeats
	 */
	SELECT	@DETLineNo		= '',
		@DETLocalItemNo		= '',
		@DETQtyInCarton		= '',
		@DETExternalItemNo	= '',
		@DETLocalItemDesc	= ''

	FETCH NEXT FROM cursorDET INTO
		@ItemSerialNum
	IF (@@fetch_status = 0) BEGIN /* next DETail row fetched */
		/*
		 * Process DETail segment
		 */
		SELECT	@DETLineNo		= convert(char(6),line_no),
			@ADMpart_no		= part_no, -- for type compatible comparison in inv_master
			@DETLocalItemNo		= convert(char(50),part_no)

			FROM tdc_dist_item_pick
			WHERE	child_serial_no = @ItemSerialNum

		SELECT	@DETQtyInCarton		= convert(char(15),quantity)

			FROM tdc_dist_group
			WHERE	parent_serial_no = @ASN_carton AND
				child_serial_no  = @ItemSerialNum

		SELECT	@DETLocalItemDesc	= convert(char(60),description)

			FROM inv_master
			WHERE	part_no = @ADMpart_no

		/*
		 * For LUNT, we made a configurable option for external item number (customer's number)
		 * to allow UPC code to be sent rather than cust_xref
		 */
		DECLARE @ext_ref_type varchar(40)
		SELECT @ext_ref_type = value_str
			FROM	tdc_config
			WHERE	[function] = 'asn_ext_item_no'

		IF (@ext_ref_type = 'UPC CODE') BEGIN
			SELECT	@DETExternalItemNo	= convert(char(49),upc_code)
				FROM	inv_master
				WHERE	part_no = @ADMpart_no
			END
		ELSE BEGIN /* use default cust_xref number */
			SELECT	@DETExternalItemNo	= convert(char(49),x.cust_part)
				FROM cust_xref x, orders o, tdc_dist_item_pick p
				WHERE	p.child_serial_no	= @ItemSerialNum AND
					o.order_no		= @ASN_order_no AND
					o.ext			= @ASN_order_ext AND
					x.part_no		= p.part_no AND
					x.customer_key		= o.cust_code
			END /* @ext_ref_type */


SELECT	@DETailTag		= ISNULL(@DETailTag, ' '),
	@DETLineNo		= ISNULL(@DETLineNo, ' '),
	@DETLocalItemNo		= ISNULL(@DETLocalItemNo, ' '),
	@DETExternalItemNo	= ISNULL(@DETExternalItemNo, ' '),
	@DETLocalItemDesc	= ISNULL(@DETLocalItemDesc, ' '),
	@DETExternalItemDesc	= ISNULL(@DETExternalItemDesc, ' '),
	@DETAdditional		= ISNULL(@DETAdditional, ' '),
	@DETQtyInCarton		= ISNULL(@DETQtyInCarton, ' '),
	@DETUOM			= ISNULL(@DETUOM, ' '),
	@DETUnitPrice		= ISNULL(@DETUnitPrice, ' '),
	@DETBackOrderQty	= ISNULL(@DETBackOrderQty, ' '),
	@DETOrderQty		= ISNULL(@DETOrderQty, ' '),
	@DETUser1		= ISNULL(@DETUser1, ' '),
	@DETUser2		= ISNULL(@DETUser2, ' '),
	@DETUser3		= ISNULL(@DETUser3, ' '),
	@DETUser4		= ISNULL(@DETUser4, ' '),
	@DETBuffer		= ISNULL(@DETBuffer, ' ')

/*
 * Note: We are putting a kludge in here to work around the automatic conversion
 * of concatenated strings to varchar() even though the insert is into a text field
 */
DECLARE @txt_ptr varbinary(16)

INSERT INTO tdc_asn_text 
	SELECT	@ASN_num, @DETailTag

SELECT	@txt_ptr = TEXTPTR(segment_text) 
	FROM tdc_asn_text
	WHERE row_num = (SELECT MAX(row_num) FROM tdc_asn_text WHERE asn_num = @ASN_num)
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETLineNo
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETLocalItemNo
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETExternalItemNo
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETLocalItemDesc
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETExternalItemDesc
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETAdditional
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETQtyInCarton
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETUOM
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETUnitPrice
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETBackOrderQty
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETOrderQty
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETUser1
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETUser2
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETUser3
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETUser4
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@DETBuffer


		GOTO startOfCursorDET /* FETCH NEXT DETail */
		END
	ELSE IF (@@fetch_status = -1) /* nothing fetched */
		GOTO endOfCursorDET
	ELSE 	
		/* fetched row must have data that was changed...
		 * We won't do anything because we aren't writing
		 * to the temp table to cause this to happen.
		 */
		GOTO startOfCursorDET

endOfCursorDET:
DEALLOCATE cursorDET

/*
 * End DET segment processing
 */
RETURN @return_code
GO
GRANT EXECUTE ON  [dbo].[tdc_asn_build_cart_det_sp] TO [public]
GO
