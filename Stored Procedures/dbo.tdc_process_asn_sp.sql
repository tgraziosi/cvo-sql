SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_process_asn_sp]
	@asn_no		int,
	@gross_weight	varchar(15),
	@err_msg	varchar(255) OUTPUT
AS

--NO CURSOR
--SHP SEGMENT	
DECLARE
	@SHPTag			char(3), --Value = SHP
	@SHPTransactionSetID	char(3), --Value = 856
	@SHPLocalCustNo		char(50),
	@SHPExternalCustNo	char(50),
	@SHPShipmentID		char(30),
	@SHPCartonCount 	char(6),
	@SHPGrossWeight 	char(15),
	@SHPUOM			char(2),
	@ShipmentDateTime	datetime,--Used for getting the values for @SHPShipmentDate and @SHPShipmentTime
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
	@SHPShipToAddr3		char(35),
	@SHPShipToAddr4		char(35),
	@SHPShipToCity		char(19),
	@SHPShipToStateProv	char(2),
	@SHPShipToCountry	char(2),
	@SHPShipToPostalCode	char(11),
	@SHPShipAuthorization	char(30),
	@SHPBuffer		char(30)
--CURSOR
--HDR SEGMENT
DECLARE	@HDRTag			char(3),--Value = HDR
	@HDROrderNo		char(22),
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
	@HDRBuffer		char(205)
--CURSOR
--CAR SEGMENT
DECLARE	@CARtonTag		char(3),--Value = CAR
	@CARMH10FMT		char(26),
	@CARMH10Raw		char(20),
	@CARMHApplicationID	char(2),
	@CARMH10Type		char(1),
	@CARMH10ManufacturerID	char(7),
	@CARMHSerialNo		char(9),-- character representation of the serial number
	@CARMHChkDigit		char(1),
	@CARCDetails		char(6)
--CURSOR
--DET SEGMENT
DECLARE	@DETailTag		char(3),--Value = DET
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

	--NO CURSOR
	--SET SHP DEFAULT VALUES
	SELECT	@SHPTag			= 'SHP',	@SHPTransactionSetID	= '856',
		@SHPLocalCustNo		= '',		@SHPExternalCustNo	= '',
		@SHPShipmentID		= '',		@SHPCartonCount		= '',
		@SHPUOM			= 'LB',		@ShipmentDateTime	= '',
		@SHPShipmentDate	= '',		@SHPShipmentTime	= '',
		@SHPCarrierID		= '',		@SHPCarrierNotes	= '',
		@SHPCarrierName1	= '',		@SHPCarrierName2	= '',
		@SHPCarrierAddr1	= '',		@SHPCarrierAddr2	= '',
		@SHPCarrierCity		= '',		@SHPCarrierStateProv	= '',
		@SHPCarrierCountry	= '',		@SHPCarrierPostalCode	= '',
		@SHPCarrierFax		= '',		@SHPCarrierPhone	= '',
		@SHPLocalShipToID	= '',		@SHPExternalShipToID	= '',
		@SHPShipToName1		= '',		@SHPShipToName2		= '',
		@SHPShipToAddr3		= '',		@SHPShipToAddr4		= '',
		@SHPShipToCity		= '',		@SHPShipToStateProv	= '',
		@SHPShipToCountry	= '',		@SHPShipToPostalCode	= '',
		@SHPShipAuthorization	= '',		@SHPBuffer		= ''

	DECLARE
		@order_no		int,
		@order_ext		int,
		@carton_no		int,
		@order_date		datetime,
		@expected_ship_date	datetime,
		@cancel_date		datetime,
		@ADMShipTo		varchar(10),
		@ADMf_note		varchar(255),
		@mfg_code		char(7),
		@pkg_type		char(1),
		@mod10checkDigit	int,
		@return_code		int,
		@print_detail		int

	SELECT @print_detail = 1

	TRUNCATE TABLE #tdc_asn_text --CLEAR OUT OUR WORKING TEMP TABLE

	--THESE VALUES ARE USED IN THE PROCESSING OF A CARTON OR CARTONS
	SELECT	@mfg_code		= '0000000',
		@pkg_type		= '0'
	/*initializing manufacturing code*/
	SELECT	@mfg_code	= value_str
	  FROM  tdc_config (NOLOCK)
	 WHERE  [function]  = 'edi_asn_wo_code'   

	--GET ALL OF THE SHP INFORMATION
	SELECT DISTINCT TOP 1	
		@order_no = car.order_no, 
		@order_ext = car.order_ext 
	FROM tdc_carton_tx  car (NOLOCK) ,
	     tdc_dist_group dg (NOLOCK)
	WHERE car.carton_no 	  = dg.child_serial_no
	  AND dg.parent_serial_no = @asn_no

	SELECT @SHPCarrierID = ISNULL(MAX(carrier_code), '') 
	  FROM tdc_carton_tx (NOLOCK)
	WHERE carton_no IN (SELECT child_serial_no FROM tdc_dist_group (NOLOCK) WHERE parent_serial_no = @asn_no)

	SELECT 	@ShipmentDateTime	= date_shipped,
--		@SHPCarrierID		= ISNULL(routing,''),
		@SHPLocalCustNo		= ISNULL(cust_code,''),
		@ADMShipTo		= ISNULL(ship_to, ''),
		@ADMf_note		= ISNULL(f_note,''),
		@SHPBuffer		= ISNULL(location,'')
		FROM orders (NOLOCK)
		WHERE order_no 	= @order_no 
		  AND ext 	= @order_ext

	IF @ShipmentDateTime = NULL 
	BEGIN
		SELECT	@err_msg = 'Order has no ship_to date.'
		RETURN -1
	END

	EXEC tdc_calc_text_date_time @ShipmentDateTime
	SELECT	@SHPShipmentDate = date_text,
		@SHPShipmentTime = time_text
		FROM #text_date_time

	SELECT	@SHPCarrierName1 = ISNULL(ship_via_name, '')
		FROM arshipv (NOLOCK)
		WHERE ship_via_code = @SHPCarrierID

	SELECT 	@SHPShipmentID	= CONVERT(char(30), @asn_no)

	SELECT 	@SHPCartonCount = CONVERT(char(6), COUNT(*))
		FROM tdc_dist_group (NOLOCK)
		WHERE parent_serial_no = @asn_no

	SELECT 	@SHPGrossWeight = CONVERT(char(15), @gross_weight)

	SELECT	@SHPLocalShipToID	= CONVERT(char(50), @ADMShipTo),
		@SHPShipToName1		= CONVERT(char(35), address_name),
		@SHPShipToAddr3		= CONVERT(char(35), addr1),
		@SHPShipToAddr4		= CONVERT(char(35), addr2),
		@SHPShipToCity		= CONVERT(char(19), city),
		@SHPShipToStateProv	= state,
		@SHPShipToCountry	= CONVERT(char( 2), country),
		@SHPShipToPostalCode	= CONVERT(char(11), postal_code)
	  FROM	armaster (NOLOCK)
	 WHERE	customer_code  = @SHPLocalCustNo
	 AND  ship_to_code = @ADMShipTo

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
		@SHPShipToAddr3		= ISNULL(@SHPShipToAddr3, ' '),
		@SHPShipToAddr4		= ISNULL(@SHPShipToAddr4, ' '),
		@SHPShipToCity		= ISNULL(@SHPShipToCity, ' '),
		@SHPShipToStateProv	= ISNULL(@SHPShipToStateProv, ' '),
		@SHPShipToCountry	= ISNULL(@SHPShipToCountry, ' '),
		@SHPShipToPostalCode	= ISNULL(@SHPShipToPostalCode, ' '),
		@SHPShipAuthorization	= ISNULL(@SHPShipAuthorization, ' '),
		@SHPBuffer		= ISNULL(@SHPBuffer, ' ')

	--WRITE SHP INFORMATION TO tdc_asn_text TABLE
	INSERT INTO #tdc_asn_text (asn_num, segment_text)
	SELECT	@asn_no,
		@SHPTag +
		@SHPTransactionSetID  +
		@SHPLocalCustNo       +
		@SHPExternalCustNo    +
		@SHPShipmentID        +
		@SHPCartonCount       +
		@SHPGrossWeight       +
		@SHPUOM               +
		@SHPShipmentDate      +
		@SHPShipmentTime      +
		@SHPCarrierID         +
		@SHPCarrierNotes      +
		@SHPCarrierName1      +
		@SHPCarrierName2      +
		@SHPCarrierAddr1      +
		@SHPCarrierAddr2      +
		@SHPCarrierCity       +
		@SHPCarrierStateProv  +
		@SHPCarrierCountry    +
		@SHPCarrierPostalCode +
		@SHPCarrierFax        +
		@SHPCarrierPhone      +
		@SHPLocalShipToID     +
		@SHPExternalShipToID  +
		@SHPShipToName1       +
		@SHPShipToName2       +
		@SHPShipToAddr3       +
		@SHPShipToAddr4       +
		@SHPShipToCity        +
		@SHPShipToStateProv   +
		@SHPShipToCountry     +
		@SHPShipToPostalCode  +
		@SHPShipAuthorization +
		@SHPBuffer

	--CURSOR
	--HDR SEGMENT "Order Level"

	--SET HDR DEFAULT VALUES
	SELECT	@HDRTag			= 'HDR'

	DECLARE HDR_cursor CURSOR FAST_FORWARD READ_ONLY FOR
		SELECT DISTINCT car.order_no, car.order_ext 
		FROM tdc_carton_tx car,
		     tdc_dist_group dg
		WHERE car.carton_no = dg.child_serial_no
		  AND dg.parent_serial_no = @asn_no
		ORDER BY car.order_no
	OPEN HDR_cursor
	FETCH NEXT FROM HDR_cursor INTO @order_no, @order_ext
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--RESET HDR DEFAULT VALUES
		SELECT	@HDROrderNo 	       = '',	@HDROrderDate 	       = '',
			@HDRExpectedShipDate   = '',	@HDRCancelDate         = '',
			@HDRUser2UltimateRec   = '',	@HDRReceiverName1      = '',
			@HDRReceiverName2      = '',	@HDRReceiverAddr1      = '',
			@HDRReceiverAddr2      = '',	@HDRReceiverCity       = '',
			@HDRReceiverStateProv  = '',	@HDRReceiverCountry    = '',
			@HDRReceiverPostalCode = '',	@HDRLocalBillToID      = '',
			@HDRExternalBillToID   = '',	@HDRBillToName1        = '',
			@HDRBillToName2        = '',	@HDRBillToAddr1        = '',
			@HDRBillToAddr2        = '',	@HDRBillToCity         = '',
			@HDRBillToStateProv    = '',	@HDRBillToCountry      = '',
			@HDRBillToPostalCode   = '',	@HDRDepartmentNo       = '',
			@HDRApplicationID      = '',	@HDRPromoDealCode      = '',
			@HDRVendorCode         = '',	@HDRCustomerPONo       = '',
			@HDRHCartons           = '',	@HDRHDetailLines       = '',
			@HDRInvoiceNo          = '',	@HDRBuffer             = '' 

		SELECT	@HDROrderNo		= CONVERT(char(11),@order_no)+'x'+CONVERT(char(10),@order_ext)
		SELECT	@order_date		= date_entered,
			@expected_ship_date	= sch_ship_date,
			@cancel_date		= cancel_date,
			@HDRLocalBillToID	= bill_to_key,
			@HDRCustomerPONo	= cust_po,
			@HDRInvoiceNo		= invoice_no,
			@HDRUser2UltimateRec    = ship_to,
			@HDRBuffer		= f_note
			FROM orders (NOLOCK)
			WHERE order_no = @order_no 
			 AND  ext      = @order_ext

		EXEC tdc_calc_text_date_time @order_date
		SELECT	@HDROrderDate = date_text
			FROM #text_date_time

		EXEC tdc_calc_text_date_time @expected_ship_date
		SELECT	@HDRExpectedShipDate = date_text
			FROM #text_date_time

		EXEC tdc_calc_text_date_time @cancel_date
		SELECT	@HDRCancelDate = date_text
			FROM #text_date_time

		SELECT	@HDRBillToName1		= CONVERT(char(35), bill_to_name),
			@HDRBillToAddr1		= CONVERT(char(35), bill_to_add_1),
			@HDRBillToAddr2		= CONVERT(char(35), bill_to_add_2),
			@HDRBillToCity		= CONVERT(char(19), bill_to_city),
			@HDRBillToStateProv	= bill_to_state,
			@HDRBillToPostalCode	= bill_to_zip
			FROM bol (NOLOCK)
			WHERE	bl_src_no  = @order_no AND
				bl_src_ext = @order_ext

		--GET THE NUMBER OF CARTONS FOR THIS HEADER "ORDER"
		SELECT @HDRHCartons = CONVERT(char(6),COUNT(DISTINCT parent_serial_no))
		FROM tdc_dist_group (NOLOCK) 
		WHERE child_serial_no IN (SELECT child_serial_no 
					   FROM tdc_dist_item_pick 
					  WHERE order_no = @order_no AND order_ext = @order_ext)

		--GET THE NUMBER OF DETAILS IN ALL THE CARTONS ON THIS HEADER "ORDER"
		SELECT 	@HDRHDetailLines = CONVERT(char(6),COUNT(DISTINCT line_no)) 
			FROM tdc_dist_item_pick (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext

	SELECT	@HDROrderNo 	       = ISNULL(@HDROrderNo, ' '),
			@HDROrderDate 	       = ISNULL(@HDROrderDate, ' '),
			@HDRExpectedShipDate   = ISNULL(@HDRExpectedShipDate, ' '),
			@HDRCancelDate         = ISNULL(@HDRCancelDate, ' '),
			@HDRUser2UltimateRec   = ISNULL(@HDRUser2UltimateRec, ' '),	
			@HDRReceiverName1      = ISNULL(@HDRReceiverName1, ' '),
			@HDRReceiverName2      = ISNULL(@HDRReceiverName2, ' '),	
			@HDRReceiverAddr1      = ISNULL(@HDRReceiverAddr1, ' '),
			@HDRReceiverAddr2      = ISNULL(@HDRReceiverAddr2, ' '),	
			@HDRReceiverCity       = ISNULL(@HDRReceiverCity, ' '),
			@HDRReceiverStateProv  = ISNULL(@HDRReceiverStateProv, ' '),	
			@HDRReceiverCountry    = ISNULL(@HDRReceiverCountry, ' '),
			@HDRReceiverPostalCode = ISNULL(@HDRReceiverPostalCode, ' '),	
			@HDRLocalBillToID      = ISNULL(@HDRLocalBillToID, ' '),
			@HDRExternalBillToID   = ISNULL(@HDRExternalBillToID, ' '),	
			@HDRBillToName1        = ISNULL(@HDRBillToName1, ' '),
			@HDRBillToName2        = ISNULL(@HDRBillToName2, ' '),	
			@HDRBillToAddr1        = ISNULL(@HDRBillToAddr1, ' '),
			@HDRBillToAddr2        = ISNULL(@HDRBillToAddr2, ' '),	
			@HDRBillToCity         = ISNULL(@HDRBillToCity, ' '),
			@HDRBillToStateProv    = ISNULL(@HDRBillToStateProv, ' '),	
			@HDRBillToCountry      = ISNULL(@HDRBillToCountry, ' '),
			@HDRBillToPostalCode   = ISNULL(@HDRBillToPostalCode, ' '),	
			@HDRDepartmentNo       = ISNULL(@HDRDepartmentNo, ' '),
			@HDRApplicationID      = ISNULL(@HDRApplicationID, ' '),	
			@HDRPromoDealCode      = ISNULL(@HDRPromoDealCode, ' '),
			@HDRVendorCode         = ISNULL(@HDRVendorCode, ' '),	
			@HDRCustomerPONo       = ISNULL(@HDRCustomerPONo, ' '),
			@HDRHCartons           = ISNULL(@HDRHCartons, ' '),	
			@HDRHDetailLines       = ISNULL(@HDRHDetailLines, ' '),
			@HDRInvoiceNo          = ISNULL(@HDRInvoiceNo, ' '),	
			@HDRBuffer             = ISNULL(@HDRBuffer, ' ') 
			
		--INSERT HDR VALUES INTO tdc_asn_text TABLE
		INSERT INTO #tdc_asn_text (asn_num, segment_text)
			SELECT	@asn_no,
				@HDRTag + 
				@HDROrderNo +
				@HDROrderDate +
				@HDRExpectedShipDate   +
				@HDRCancelDate         +
				@HDRUser2UltimateRec   +
				@HDRReceiverName1      +
				@HDRReceiverName2      +
				@HDRReceiverAddr1      +
				@HDRReceiverAddr2      +
				@HDRReceiverCity       +
				@HDRReceiverStateProv  +
				@HDRReceiverCountry    +
				@HDRReceiverPostalCode +
				@HDRLocalBillToID      +
				@HDRExternalBillToID   +
				@HDRBillToName1        +
				@HDRBillToName2        +
				@HDRBillToAddr1        +
				@HDRBillToAddr2        +
				@HDRBillToCity         +
				@HDRBillToStateProv    +
				@HDRBillToCountry      +
				@HDRBillToPostalCode   +
				@HDRDepartmentNo       +
				@HDRApplicationID      +
				@HDRPromoDealCode      +
				@HDRVendorCode         +
				@HDRCustomerPONo       +
				@HDRHCartons           +
				@HDRHDetailLines       +
				@HDRInvoiceNo          +
				@HDRBuffer
		--GET CARTON INFORMATION
		--CURSOR
		--CAR SEGMENT "Carton Level"
		DECLARE CAR_cursor CURSOR FAST_FORWARD READ_ONLY FOR
			SELECT DISTINCT a.carton_no
			  FROM 	tdc_carton_tx a (NOLOCK),
				tdc_carton_detail_tx b (NOLOCK),
				tdc_dist_group c (NOLOCK)
			WHERE a.order_no = @order_no 
			  AND a.order_ext = @order_ext
			  AND a.order_no = b.order_no
			  AND a.order_ext = b.order_ext
			  AND a.carton_no = b.carton_no
			  AND c.parent_serial_no = @asn_no
			  AND a.carton_no = c.child_serial_no
		OPEN CAR_cursor
		FETCH NEXT FROM CAR_cursor INTO @carton_no
		WHILE @@FETCH_STATUS = 0
		BEGIN
			--SET CAR DEFAULT VALUES
			SELECT	@CARtonTag		= 'CAR',
				@CARMH10FMT		= '',
				@CARMHApplicationID	= '',
				@CARMH10Type		= '',
				@CARMH10ManufacturerID	= '',
				@CARMHChkDigit		= '',
				@CARMH10Raw		= '',
				@CARMHSerialNo		= '',
				@CARCDetails		= ''
  
			SELECT	@CARMHSerialNo	= RIGHT('00000000'+ convert(varchar(9), @carton_no), 9)
			SELECT	@CARMH10Raw	= @pkg_type + @mfg_code + @CARMHSerialNo
			EXEC	@mod10checkDigit = tdc_asn_calc_mod_10_chk_sp @CARMH10Raw
			SELECT	@CARMHChkDigit	= convert(char(1),@mod10checkDigit)
			SELECT	@CARMH10Raw	= '00' + @CARMH10Raw + @CARMHChkDigit

			SELECT @CARCDetails = CONVERT(char(6),COUNT(DISTINCT line_no))
			  FROM 	tdc_carton_tx a (NOLOCK),
				tdc_carton_detail_tx b (NOLOCK)
			WHERE a.order_no = @order_no 
			  AND a.order_ext = @order_ext
			  AND a.carton_no = @carton_no
			  AND a.carton_no = b.carton_no
			  AND a.order_no = b.order_no
			  AND a.order_ext = b.order_ext

			SELECT	@CARtonTag		= ISNULL(@CARtonTag, 			' '),
				@CARMH10Raw		= ISNULL(@CARMH10Raw, 			' '),
				@CARMHApplicationID	= ISNULL(@CARMHApplicationID, 		' '),
				@CARMH10Type		= ISNULL(@CARMH10Type, 			' '),
				@CARMH10ManufacturerID	= ISNULL(@CARMH10ManufacturerID, 	' '),
				@CARMHSerialNo		= ISNULL(@CARMHSerialNo, 		' '),
				@CARMHChkDigit		= ISNULL(@CARMHChkDigit, 		' '),
				@CARCDetails		= ISNULL(@CARCDetails, 			' ')
			--WRITE CARTON INFORMATION INTO tdc_asn_text TABLE
			INSERT INTO #tdc_asn_text
				SELECT	@asn_no,
					@CARtonTag		+
					@CARMH10FMT		+
					@CARMH10Raw		+
					@CARMHApplicationID	+
					@CARMH10Type		+
					@CARMH10ManufacturerID	+
					@CARMHSerialNo		+
					@CARMHChkDigit		+
					@CARCDetails

			--SET DET DEFAULT VALUES
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
			--GET CARTON DETAILS
			--CURSOR
			--DET SEGMENT "Carton Detail Level"
			DECLARE	DET_cursor CURSOR FAST_FORWARD READ_ONLY FOR
				SELECT 	CONVERT(char(6),b.line_no), CONVERT(char(50),b.part_no), CONVERT(char(60),b.[description]), 
					CONVERT(char(15),a.pack_qty), CONVERT(char(15),b.ordered-b.shipped), CONVERT(char(15),b.ordered)
				  FROM 	tdc_carton_detail_tx a (NOLOCK),
					ord_list b (NOLOCK)
				WHERE a.order_no = @order_no 
				  AND a.order_ext = @order_ext
				  AND a.carton_no = @carton_no
				  AND a.order_no = b.order_no
				  AND a.order_ext = b.order_ext
				  AND a.line_no = b.line_no
				ORDER BY b.line_no
			OPEN DET_cursor
			FETCH NEXT FROM DET_cursor INTO @DETLineNo, @DETLocalItemNo, @DETLocalItemDesc,
							@DETQtyInCarton, @DETBackOrderQty, @DETOrderQty
			WHILE @@FETCH_STATUS = 0
			BEGIN
				--THIS IS THE CUSTOMER CODE
				--@SHPLocalCustNo

				IF @print_detail = 1  --THIS WAS ORIGINALLY ADDED FOR PAJ SED 023 WHEN WE WERE SOMETIMES PRINTING DETAILS AND SOMETIMES NOT, THIS
				BEGIN		      --WAS LEFT IN HERE, BECAUSE SOMEONE ELSE MAY NEED THE CAPABILITY TO SKIP A DETAIL ITEM FROM BEING PRINTED
					-------------------------------------------------------------------------------------------------------------------------

					--* This is a configurable option for external item number (customer's number)
					--* to allow UPC code to be sent rather than cust_xref
					DECLARE @ext_ref_type varchar(40)
					SELECT @ext_ref_type = value_str
						FROM	tdc_config (NOLOCK)
						WHERE	[function] = 'asn_ext_item_no'
					IF (@ext_ref_type = 'UPC CODE') 
					BEGIN
						SELECT	@DETExternalItemNo	= convert(char(49),upc_code)
							FROM	inv_master (NOLOCK)
							WHERE	part_no = @DETLocalItemNo
					END
					ELSE 
					BEGIN /* use default cust_xref number */
						SELECT	@DETExternalItemNo	= convert(char(49),x.cust_part)
							FROM cust_xref x (NOLOCK), orders o (NOLOCK), tdc_dist_item_pick p (NOLOCK)
							WHERE	p.child_serial_no	= @carton_no AND
								o.order_no		= @order_no AND
								o.ext			= @order_ext AND
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

					--WRITE DETAIL INFORMATION TO tdc_asn_text TABLE
					INSERT INTO #tdc_asn_text (asn_num, segment_text)
						SELECT	@asn_no, 
							@DETailTag + 
							@DETLineNo + 
							@DETLocalItemNo + 
							@DETExternalItemNo +
							@DETLocalItemDesc + 
							@DETExternalItemDesc + 
							@DETAdditional +
							@DETQtyInCarton + 
							@DETUOM + 
							@DETUnitPrice + 
							@DETBackOrderQty +
							@DETOrderQty + 
							@DETUser1 + 
							@DETUser2 + 
							@DETUser3+ 
							@DETUser4 +
							@DETBuffer
				END
		 			--GET NEXT DETAIL RECORD FROM CURSOR
				FETCH NEXT FROM DET_cursor INTO @DETLineNo, @DETLocalItemNo, @DETLocalItemDesc,
								@DETQtyInCarton, @DETBackOrderQty, @DETOrderQty
			END
			CLOSE DET_cursor
			DEALLOCATE DET_cursor

			--GET NEXT CARTON RECORD FROM CURSOR
			FETCH NEXT FROM CAR_cursor INTO @carton_no
		END
		CLOSE CAR_cursor
		DEALLOCATE CAR_cursor
		--GET NEXT HEADER RECORD FROM CURSOR
		FETCH NEXT FROM HDR_cursor INTO @order_no, @order_ext
	END
	CLOSE HDR_cursor
	DEALLOCATE HDR_cursor
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_process_asn_sp] TO [public]
GO
