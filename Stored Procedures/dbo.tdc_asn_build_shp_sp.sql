SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_asn_build_shp_sp] AS
/*******************************************************************************
 *
 * 980622 REA
 *
 * This proc maps TDC and Platinum data to EDI ASN 856 file structure for LUNT.
 *
 * EDI - Electronic Data Interchange
 * ASN - Advanced Shipping Notification
 *
 * The serial number of the ASN will correspond to all the cartons to be
 * included in the generation of the ASN.
 *
 * INPUT
 *
 *	#int_list_in	ASN ID (found in tdc_dist_group).  Used to traverse 
 *			the ASN tree to find cartons.  These cartons will
 *			let us know which orders are involved as
 *			we generate the ASN.  Note: There should only be one
 *			shipment ID passed into this proc
 *			GROSS Weight (entered by user).
 *
 * OUTPUT
 *
 *	tdc_ASN_text	Detail line item information stored in this table for each item
 *			held by the input container.  Used by calling program to print ASN information
 *	#err_list_out	Error messages
 */

set nocount on

/*
 * Tables for INTERNAL use
 */
CREATE TABLE #all_containers_list (
	parent_serial_no int	-- all containers that have the correct status
	)
CREATE TABLE #sm_containers_list (
	parent_serial_no int,	-- smallest container serial numbers in the tree list of
	child_serial_no int	-- containers that have the correct status
	)
CREATE TABLE #items_list (
	child_serial_no int	-- items for the containers
	)
CREATE TABLE #all_orderitems_list (
	serial_no int		-- all items for all orders (includes external to ASN tree)
	)
CREATE TABLE #order_list_out (
	order_no int,	-- Order Number
	order_ext int	-- Order Extension
	)
CREATE TABLE #tmp_order_list (
	order_no int,	-- Order Number
	order_ext int	-- Order Extension
	)
CREATE TABLE #text_date_time (
	date_text	char(6),
	time_text	char(6)
	)

DECLARE @err_multiple_shipto int
SELECT	@err_multiple_shipto = -1020
DECLARE @err_no_shipto int
SELECT	@err_no_shipto = -1021
DECLARE @err_order_not_ready int
SELECT	@err_order_not_ready = -1022
DECLARE @err_no_shipto_date int
SELECT	@err_no_shipto_date = -1023


DECLARE @return_code int
SELECT	@return_code = 0

DECLARE @err_stop int	-- used as a flag to determine whether to halt on an error or 
SELECT	@err_stop = 1	-- allow it to go through (helps for testing purposes)


/*
 * Shipment information - global information about the shipment
 */
DECLARE	@SHPTag			char(3),
	@SHPTransactionSetID	char(3),
	@SHPLocalCustNo		char(50),
	@SHPExternalCustNo	char(50),
	@SHPShipmentID		char(30),
	@SHPCartonCount		char(6),
	@SHPGrossWeight		char(15),
	@SHPUOM			char(2),
	@ShipmentDateTime	datetime,
	@SHPShipmentDate	char(6),
	@SHPShipmentTime	char(6),
	@SHPCarrierID		char(15),
	@SHPCarrierNotes	char(80),
	@SHPCarrierName1	char(35),
	@SHPCarrierName2	char(35),
	@SHPCarrierAddr1	char(35),
	@SHPCarrierAddr2	char(35),
	@SHPCarrierCity		char(19),
	@SHPCarrierStateProv	char(2),
	@SHPCarrierCountry	char(2),
	@SHPCarrierPostalCode	char(11),
	@SHPCarrierFax		char(20),
	@SHPCarrierPhone	char(20),
	@SHPLocalShipToID	char(50),
	@SHPExternalShipToID	char(50),
	@SHPShipToName1		char(35),
	@SHPShipToName2		char(35),
	@SHPShipToAddr1		char(35),
	@SHPShipToAddr2		char(35),
	@SHPShipToCity		char(19),
	@SHPShipToStateProv	char(2),
	@SHPShipToCountry	char(2),
	@SHPShipToPostalCode	char(11),
	@SHPShipAuthorization	char(30),
	@SHPBuffer		char(30)

DECLARE	@ASN_num		int,
	@numShipLocations	int


/**********
 * SHP
 **********
 *
 * Shipment information - global information about the shipment
 *
 * Warning:  Potential loss of data...
 *	@SHPCarrierID varchar(15)    <-- o.routing varchar(20)
 *	@SHPCarrierName1 varchar(35) <-- o.description varchar(40)
 *	@SHPShipToName1 varchar(35)  <-- st.name varchar(40)
 *	@SHPShipToAddr1 varchar(35)  <-- st.address1 varchar(40)
 *	@SHPShipToAddr2 varchar(35)  <-- st.address2 varchar(40)
 *	(nothing)		     <-- st.address3 varchar(40)
 *	@SHPShipToCity varchar(19)   <-- st.city varchar(40)
 *	@SHPShipToCountry varchar(2) <-- st.country varchar(40)
 *
 *
 * Initialize the segment's character values...
 * NOTE:  These should always be init'ed so that we
 * don't end up with any NULLs
 */
SELECT	@SHPTag			= 'SHP',
	@SHPTransactionSetID	= '856',
	@SHPLocalCustNo		= '',
	@SHPExternalCustNo	= '',
	@SHPShipmentID		= '',
	@SHPCartonCount		= '',
	@SHPUOM			= 'LB',
	@ShipmentDateTime	= '',
	@SHPShipmentDate	= '',
	@SHPShipmentTime	= '',
	@SHPCarrierID		= '',
	@SHPCarrierNotes	= '',
	@SHPCarrierName1	= '',
	@SHPCarrierName2	= '',
	@SHPCarrierAddr1	= '',
	@SHPCarrierAddr2	= '',
	@SHPCarrierCity		= '',
	@SHPCarrierStateProv	= '',
	@SHPCarrierCountry	= '',
	@SHPCarrierPostalCode	= '',
	@SHPCarrierFax		= '',
	@SHPCarrierPhone	= '',
	@SHPLocalShipToID	= '',
	@SHPExternalShipToID	= '',
	@SHPShipToName1		= '',
	@SHPShipToName2		= '',
	@SHPShipToAddr1		= '',
	@SHPShipToAddr2		= '',
	@SHPShipToCity		= '',
	@SHPShipToStateProv	= '',
	@SHPShipToCountry	= '',
	@SHPShipToPostalCode	= '',
	@SHPShipAuthorization	= '',
	@SHPBuffer		= ''

SELECT	@ASN_num	= serial_no,
	@SHPGrossWeight = convert(char(15), gross_wt)
	FROM #int_list_in

DELETE FROM tdc_asn_text WHERE asn_num = @asn_num
 

/*
 * Note: There should only be one shipment ID passed into this proc
 */
SELECT	@SHPShipmentID	= convert(char(30), @asn_num)

/*
 * #int_list_in has the ASN shipment ID...use it to obtain:
 *	#all_containers_list	all containers for this ASN parent,
 *	#sm_containers_list	all containers that hold an item for this ASN parent,
 * and	#items_list		all the items within the tree structure
 */
TRUNCATE TABLE #all_containers_list
TRUNCATE TABLE #sm_containers_list
TRUNCATE TABLE #items_list
EXEC @return_code = tdc_asn_get_cart_items_sp
IF @return_code < 0
	IF @err_stop = 1 RETURN @return_code

/*
 * This allows us to determine our carton count.
 * (in fact, we could even calc the gross weight if we had weight/carton available)
 */
DECLARE @tmpInt int
SELECT @tmpInt		= COUNT(*) FROM #sm_containers_list

/* 
 * The following is incorrect.  We want to simply count the number
 * of cartons on the ASN.  CAC.  Dec. 3, 1998.
 *    SELECT @SHPCartonCount	= convert(char(6), @tmpInt)
 */
SELECT @SHPCartonCount = convert(char(6), count(*))
  FROM tdc_dist_group
 WHERE parent_serial_no = @asn_num


/*
 * Use these items to get all the order/extension numbers included in this ASN
 */
TRUNCATE TABLE #int_list_in
INSERT INTO #int_list_in
	SELECT child_serial_no, convert(char(15), 0) from #items_list
EXEC @return_code = tdc_dist_get_item_orders
IF @return_code < 0
	IF @err_stop = 1 RETURN @return_code


/*
 * All the orders touched by this ASN are now in #order_list_out
 * Get all items for all orders (go outside of the ASN tree)
 */
TRUNCATE TABLE #all_orderitems_list
INSERT INTO #all_orderitems_list
	SELECT DISTINCT p.child_serial_no
		FROM tdc_dist_item_pick p, #order_list_out o
		WHERE	p.order_no  = o.order_no AND
			p.order_ext = o.order_ext
/*
 * All items from all orders touched by this ASN are now in
 * #all_order_items_list. 
 *
 * 1) Check to see if any item has quantity > 0 (items picked but not
 * packed yet).
 */
TRUNCATE TABLE #tmp_order_list
INSERT INTO #tmp_order_list
	SELECT DISTINCT p.order_no, p.order_ext
		FROM tdc_dist_item_pick p, #items_list i
		WHERE	p.child_serial_no = i.child_serial_no AND
			p.quantity > 0
/*
 * 2) Check to see if any item (of any order)
 * is not status 'V' in some other container that is not in this ASN.
 * This will stop an ASN even for ready containers/ready orders.
 * We do not want to allow Container A with Orders A1 and A2 to 
 * generate an ASN for A1 (ready order) but not A2 (waiting order)
 * Once the container is shipped, it would be very difficult to 
 * generate an ASN for items in Container A, Order A2
 *
 * Note: with multiple containers, it would be nice to indicate which
 *	container(s) will hold up the show
 */
INSERT INTO #tmp_order_list
	SELECT DISTINCT p.order_no, p.order_ext
		FROM tdc_dist_item_pick p, tdc_dist_group g, #items_list i
		WHERE	p.child_serial_no = i.child_serial_no AND
			g.child_serial_no = i.child_serial_no AND
			g.status <> 'X'
IF EXISTS (SELECT * from #tmp_order_list) BEGIN
	SELECT	@return_code = @err_order_not_ready
	INSERT INTO #err_list_out
		SELECT	@return_code, 'Can not create an ASN - order/ext '+
			convert(varchar(10),order_no)+'/'+
			convert(varchar(10),order_ext)+' is not ready'
			FROM #tmp_order_list
	IF @err_stop = 1 RETURN @return_code
	END

/*
 * All orders should be ready for ASN.  We still have them in #order_list_out
 * Check for possible problems with ship-to locations
 */
SELECT @numShipLocations = COUNT(DISTINCT o.ship_to)
	FROM orders o, #order_list_out l
	WHERE	o.order_no = l.order_no AND
		o.ext = l.order_ext

IF @numShipLocations > 1 BEGIN
	SELECT @return_code = @err_multiple_shipto
	INSERT INTO #err_list_out
		VALUES (@return_code, 'Can not create a single ASN for multiple ship-to locations')
	IF @err_stop = 1 RETURN @return_code
	END
ELSE IF (@numShipLocations < 1) BEGIN
	SELECT @return_code = @err_no_shipto
	INSERT INTO #err_list_out
		VALUES (@return_code, 'Can not create an ASN without a ship-to location')
	IF @err_stop = 1 RETURN @return_code
	END

/*
 * If we get this far, we should be ready to process the ASN
 */

DECLARE @ADMCarrierID		varchar(20),
	@ADMCarrierName1	varchar(40),
	@ADMShipTo		varchar(10),
	@ADMCustCode		varchar(10),
	@ADMf_note		varchar(255)

/*
 * WARNING:
 * This should work for LUNT, since we don't expect multiple orders with
 * multiple cust_code/ship_to otherwise, it could very well be a problem
 * to just grab the MAX values (MAX was chosen over MIN due to NULLs)
 *
 * Note:
 *	While  cust_code/ship_to could conceptually become an illegit key
 *	when we look for MAX values, it will not in this case because we
 *	have already determined that all o.ship_to values are the same
 */
SELECT 	@ShipmentDateTime	= MAX(o.date_shipped),
	@ADMCarrierID		= MAX(o.routing),
	@ADMCustCode		= MAX(o.cust_code),
	@ADMShipTo		= MAX(o.ship_to),
	@ADMf_note		= MAX(o.f_note),
	@SHPBuffer		= MAX(o.location)
	FROM orders o, #order_list_out l
	WHERE	o.order_no = l.order_no AND
		o.ext = l.order_ext

/*
 * Platinum ADM 6.02 Code.  CAC.  08-10-1999.
SELECT	@ADMCarrierName1	= description
	FROM routing
	WHERE kys = @ADMCarrierID
 *
 */

/*
 * Platinum ERA 7.x Code.  CAC. 08-10-1999.
 */
SELECT	@ADMCarrierName1	= ship_via_name
	FROM arshipv
	WHERE ship_via_code = @ADMCarrierID



SELECT	@SHPCarrierID		= convert(char(15), @ADMCarrierID),
	@SHPCarrierName1	= convert(char(35), @ADMCarrierName1),
	@SHPLocalCustNo		= convert(char(50), @ADMCustCode)

IF @ADMShipTo = ' ' 
	BEGIN
	/*
	 * Platinum 6.02 Code.  CAC.  08-10-1999.
	 *
	 *
	 * Wojtek says he needs SOMEthing for ship-to ID, even if it is blank in ADM.
	 * The best we can do is give the key into the table for the ship-to data.
	 *
	SELECT	@SHPLocalShipToID	= convert(char(50), customer_key),
		@SHPShipToName1		= convert(char(35), customer_name),
		@SHPShipToAddr1		= convert(char(35), address_1),
		@SHPShipToAddr2		= convert(char(35), address_2),
		@SHPShipToCity		= convert(char(19), city),
		@SHPShipToStateProv	= state,
		@SHPShipToCountry	= convert(char( 2), country),
		@SHPShipToPostalCode	= convert(char(11), zip_code)
	  FROM	arcust
	 WHERE	customer_key  = @ADMCustCode
	 */

	/* 
	 * Platinum ERA 7.0 Code.  CAC. 08-10-1999.
	 */
	SELECT	@SHPLocalShipToID	= convert(char(50), customer_code),
		@SHPShipToName1		= convert(char(35), address_name),
		@SHPShipToAddr1		= convert(char(35), addr1),
		@SHPShipToAddr2		= convert(char(35), addr2),
		@SHPShipToCity		= convert(char(19), city),
		@SHPShipToStateProv	= state,
		@SHPShipToCountry	= convert(char( 2), country),
		@SHPShipToPostalCode	= convert(char(11), postal_code)
	  FROM	armaster
	 WHERE	customer_code  = @ADMCustCode

	END
ELSE 
	BEGIN
	/*
	 * Platinum 6.02 Code.  CAC.  08-10-1999.
	 *
	SELECT	@SHPLocalShipToID	= convert(char(50), @ADMShipTo),
		@SHPShipToName1		= convert(char(35), name),
		@SHPShipToAddr1		= convert(char(35), address1),
		@SHPShipToAddr2		= convert(char(35), address2),
		@SHPShipToCity		= convert(char(19), city),
		@SHPShipToStateProv	= state,
		@SHPShipToCountry	= convert(char( 2), country),
		@SHPShipToPostalCode	= convert(char(11), zip)
	  FROM	ship_to
	 WHERE	cust_code  = @ADMCustCode 
	   AND	ship_to_no = @ADMShipTo
	 *
	 */

	/*
	 * Platinum ERA 7.0 Code.  CAC.  08-10-1999.
	 */
	SELECT	@SHPLocalShipToID	= convert(char(50), @ADMShipTo),
		@SHPShipToName1		= convert(char(35), address_name),
		@SHPShipToAddr1		= convert(char(35), addr1),
		@SHPShipToAddr2		= convert(char(35), addr2),
		@SHPShipToCity		= convert(char(19), city),
		@SHPShipToStateProv	= state,
		@SHPShipToCountry	= convert(char( 2), country),
		@SHPShipToPostalCode	= convert(char(11), postal_code)
	  FROM	armaster
	 WHERE	customer_code  = @ADMCustCode
	   AND  ship_to_code = @ADMShipTo

	END


/*
 * Note:
 *	If DateTime is NULL, then the char(6) conversion would also be NULL.
 *	This would cause a problem with segment formatting.  But we don't
 *	allow a NULL ship_to date anyway.
 */
IF @ShipmentDateTime = NULL BEGIN
	SELECT @return_code = @err_no_shipto_date
	INSERT INTO #err_list_out
		SELECT	@return_code, 'Order has no ship_to date!'
	IF @err_stop = 1 RETURN @return_code
	END
EXEC tdc_calc_text_date_time @ShipmentDateTime
SELECT	@SHPShipmentDate = date_text,
	@SHPShipmentTime = time_text
	FROM #text_date_time

/*
 * This is a last-minute addition to the requirement:  return external ship-to ID
 * stored in orders.f_note, column positions 206-230.
 *
 * The thing that's uncomfortable about this is that it is another field selected
 * as a 'MAX' out of potentially many.
 */

SELECT	@SHPExternalShipToID	= convert(char(50),SUBSTRING(@ADMf_note,206,25))
IF (@SHPExternalShipToID = NULL) SELECT @SHPExternalShipToID = 'N/A'

SELECT	@SHPTag			= ISNULL(@SHPTag, ' '),
	@SHPTransactionSetID	= ISNULL(@SHPTransactionSetID, ' '),
	@SHPLocalCustNo		= ISNULL(@SHPLocalCustNo, ' '),
	@SHPExternalCustNo	= ISNULL(@SHPExternalCustNo, ' '),
	@SHPShipmentID		= ISNULL(@SHPShipmentID, ' '),
	@SHPCartonCount		= ISNULL(@SHPCartonCount, ' '),
	@SHPGrossWeight		= ISNULL(@SHPGrossWeight, ' '),
	@SHPUOM			= ISNULL(@SHPUOM, ' '),
	@SHPShipmentDate	= ISNULL(@SHPShipmentDate, ' '),
	@SHPShipmentTime	= ISNULL(@SHPShipmentTime, ' '),
	@SHPCarrierID		= ISNULL(@SHPCarrierID, ' '),
	@SHPCarrierNotes	= ISNULL(@SHPCarrierNotes, ' '),
	@SHPCarrierName1	= ISNULL(@SHPCarrierName1, ' '),
	@SHPCarrierName2	= ISNULL(@SHPCarrierName2, ' '),
	@SHPCarrierAddr1	= ISNULL(@SHPCarrierAddr1, ' '),
	@SHPCarrierAddr2	= ISNULL(@SHPCarrierAddr2, ' '),
	@SHPCarrierCity		= ISNULL(@SHPCarrierCity, ' '),
	@SHPCarrierStateProv	= ISNULL(@SHPCarrierStateProv, ' '),
	@SHPCarrierCountry	= ISNULL(@SHPCarrierCountry, ' '),
	@SHPCarrierPostalCode	= ISNULL(@SHPCarrierPostalCode, ' '),
	@SHPCarrierFax		= ISNULL(@SHPCarrierFax, ' '),
	@SHPCarrierPhone	= ISNULL(@SHPCarrierPhone, ' '),
	@SHPLocalShipToID	= ISNULL(@SHPLocalShipToID, ' '),
	@SHPExternalShipToID	= ISNULL(@SHPExternalShipToID, ' '),
	@SHPShipToName1		= ISNULL(@SHPShipToName1, ' '),
	@SHPShipToName2		= ISNULL(@SHPShipToName2, ' '),
	@SHPShipToAddr1		= ISNULL(@SHPShipToAddr1, ' '),
	@SHPShipToAddr2		= ISNULL(@SHPShipToAddr2, ' '),
	@SHPShipToCity		= ISNULL(@SHPShipToCity, ' '),
	@SHPShipToStateProv	= ISNULL(@SHPShipToStateProv, ' '),
	@SHPShipToCountry	= ISNULL(@SHPShipToCountry, ' '),
	@SHPShipToPostalCode	= ISNULL(@SHPShipToPostalCode, ' '),
	@SHPShipAuthorization	= ISNULL(@SHPShipAuthorization, ' '),
	@SHPBuffer		= ISNULL(@SHPBuffer, ' ')


/*
 * Note: We are putting a kludge in here to work around the automatic conversion
 * of concatenated strings to varchar() even though the insert is into a text field
 */
DECLARE @txt_ptr varbinary(16)
/*
 * We are starting with a fresh ASN...
 */
INSERT INTO tdc_asn_text
	SELECT	@ASN_num,
		@SHPTag

SELECT	@txt_ptr = TEXTPTR(segment_text) 
	FROM tdc_asn_text
	WHERE row_num = (SELECT MAX(row_num) FROM tdc_asn_text WHERE asn_num = @ASN_num)
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPTransactionSetID
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPLocalCustNo
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPExternalCustNo
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPShipmentID
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPCartonCount
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPGrossWeight
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPUOM
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPShipmentDate
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPShipmentTime
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPCarrierID
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPCarrierNotes
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPCarrierName1
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPCarrierName2
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPCarrierAddr1
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPCarrierAddr2
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPCarrierCity
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPCarrierStateProv
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPCarrierCountry
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPCarrierPostalCode
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPCarrierFax
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPCarrierPhone
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPLocalShipToID
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPExternalShipToID
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPShipToName1
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPShipToName2
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPShipToAddr1
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPShipToAddr2
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPShipToCity
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPShipToStateProv
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPShipToCountry
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPShipToPostalCode
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPShipAuthorization
UPDATETEXT tdc_asn_text.segment_text @txt_ptr NULL 0 WITH LOG	@SHPBuffer

/*
 * NEED TO CALL HEADER PROC, with #order_list_out as the populator
 */
EXEC @return_code = tdc_asn_build_hdr_sp @ASN_num

RETURN @return_code

GO
GRANT EXECUTE ON  [dbo].[tdc_asn_build_shp_sp] TO [public]
GO
