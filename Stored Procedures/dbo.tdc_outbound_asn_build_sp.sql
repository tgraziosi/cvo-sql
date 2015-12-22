SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_outbound_asn_build_sp] 
	@asn int

AS

DECLARE @cust_code		varchar(40),
	@ship_to_code		varchar(40),
	@status			int,
	@SCAC			varchar(50),
	@carrier_code		varchar(10),
	@carrier_type		varchar(10),
	@carrier_note		varchar(255),
	@ship_date		datetime,
	@num_of_orders		int,
	@num_of_cartons		int,
	@total_weight		decimal(20,8),
	@weight_uom		varchar(2),
	@carton_code		varchar(30),

	@special_instr		varchar(255),
	@freight_charge_term	varchar(10),
	@freight_bill_to_name	varchar(40),
	@freight_bill_to_adr	varchar(40),
	@freight_bill_to_street	varchar(40),
	@freight_bill_to_city	varchar(40),
	@freight_bill_to_state	varchar(40),
	@freight_bill_to_zip	varchar(10)


--------------------------------------------------------------------------------------------------------------------
-- Do validation
--------------------------------------------------------------------------------------------------------------------
	IF NOT EXISTS(
		SELECT *                    
		FROM tdc_dist_group (NOLOCK)              
		WHERE parent_serial_no = @asn   
		AND method = '01'                         
		AND type = 'E1'                           
		AND [function] = 'S' )  
	BEGIN
		RAISERROR ('Invalid ASN Number', 16, 1)
		RETURN -1
	END
	
	IF EXISTS(SELECT * FROM tdc_EDI_shipment_header(NOLOCK) WHERE asn = @asn)
	BEGIN
		RAISERROR ('ASN already processed', 16, 1)
		RETURN -1
	END

--------------------------------------------------------------------------------------------------------------------
-- Get list of cartons being shipped
--------------------------------------------------------------------------------------------------------------------
	TRUNCATE TABLE #outbound_cartons

	INSERT INTO #outbound_cartons (carton_no)
	SELECT child_serial_no                    
	  FROM tdc_dist_group (NOLOCK)              
	 WHERE parent_serial_no = @asn   
	   AND method = '01'                         
	   AND type = 'E1'                           
	   AND [function] = 'S' 
	   AND child_serial_no NOT IN (SELECT pack_no FROM tdc_master_pack_tbl (NOLOCK))
	UNION
	SELECT carton_no
	  FROM tdc_master_pack_ctn_tbl a(NOLOCK),       
	       tdc_dist_group b(NOLOCK)              
	 WHERE b.parent_serial_no = @asn   
	   AND b.method = '01'                         
	   AND b.type = 'E1'                           
	   AND b.[function] = 'S'  
	   AND a.pack_no = b.child_serial_no


--------------------------------------------------------------------------------------------------------------------
-- Get shipment header information
--------------------------------------------------------------------------------------------------------------------
	SELECT @status = -1

	SELECT TOP 1 @cust_code = cust_code, @ship_to_code = ship_to_no, @carrier_code = carrier_code, 
	@ship_date = date_shipped, @weight_uom = weight_uom, @SCAC = carrier_code
	FROM tdc_carton_tx (NOLOCK)
	WHERE carton_no IN( SELECT carton_no FROM #outbound_cartons )
	 
	SELECT @num_of_orders = COUNT(DISTINCT order_no)
	FROM tdc_carton_tx (NOLOCK) 
	WHERE carton_no IN( SELECT carton_no FROM #outbound_cartons )

	SELECT @num_of_cartons = COUNT(*) 
	FROM tdc_carton_tx (NOLOCK) 
	WHERE carton_no IN( SELECT carton_no FROM #outbound_cartons )
	
	SELECT @total_weight = SUM(weight)
	FROM tdc_carton_tx (NOLOCK) 
	WHERE carton_no IN( SELECT carton_no FROM #outbound_cartons ) 
	
	
	SELECT TOP 1 @carrier_note = special_instr, @special_instr = special_instr
	FROM orders a (NOLOCK),
	tdc_carton_tx b(NOLOCK)
	WHERE a.order_no = b.order_no
	AND a.ext = b.order_ext
	AND b.order_type = 'S' 
	AND b.carton_no IN( SELECT carton_no FROM #outbound_cartons ) 
				
	
	INSERT INTO  tdc_EDI_shipment_header (ASN, cust_code, ship_to_code, status, SCAC, carrier_code, carrier_type, carrier_note, 
						ship_date, num_of_orders, num_of_cartons, total_weight, weight_uom, authorization_code, 
						package_code, envelop_control_number, group_control_number, document_control_number, 
						envelop_date_time, seal_number, pro_number, special_instr, freight_charge_term, 
						freight_bill_to_name, freight_bill_to_adr, freight_bill_to_street, freight_bill_to_city, 
						freight_bill_to_state, freight_bill_to_zip)
	
	SELECT @asn, @cust_code, @ship_to_code, @status, @SCAC, @carrier_code, @carrier_type, @carrier_note, @ship_date, @num_of_orders, 
		@num_of_cartons, @total_weight, @weight_uom, NULL, NULL, NULL, NULL, 
		NULL, NULL, NULL, NULL, @special_instr, @freight_charge_term, 
		@freight_bill_to_name, @freight_bill_to_adr, @freight_bill_to_street, @freight_bill_to_city, @freight_bill_to_state, @freight_bill_to_zip
 
--------------------------------------------------------------------------------------------------------------------
-- Get shipment detail information
--------------------------------------------------------------------------------------------------------------------
	INSERT INTO tdc_EDI_shipment_detail (ASN, a.order_no, order_type, total_amt, amt_uom, order_date_created, ship_to_code, reference_no, 
					num_of_items, cust_po_no, cust_po_date, order_weight, weight_uom, department_no, vend_order_no, purchaser_code)
	 
	SELECT @asn, a.order_no, 'SO', total_amt_order, curr_key, date_entered, ship_to, NULL, 
		(select sum(ordered) FROM ord_list c(NOLOCK) 
			WHERE c.order_no = a.order_no
			  AND c.order_ext = a.ext), a.cust_po, a.date_entered AS DATETIME, 
		(isnull((select sum(ordered * weight_ea) FROM ord_list c(NOLOCK) 
			WHERE c.order_no = a.order_no
			  AND c.order_ext = a.ext), 0)), NULL, NULL, NULL, NULL
	FROM orders a (NOLOCK),
		tdc_carton_tx b(NOLOCK)
	WHERE a.order_no = b.order_no
	AND a.ext = b.order_ext
	AND b.order_type = 'S' 
	AND b.carton_no IN( SELECT carton_no FROM #outbound_cartons ) 
	GROUP BY a.order_no, a.ext, total_amt_order, curr_key, date_entered, ship_to, a.cust_po


 
--------------------------------------------------------------------------------------------------------------------
-- Get order line items information
--------------------------------------------------------------------------------------------------------------------

	INSERT INTO tdc_EDI_ord_list (ASN, order_no, line_no, part_no, ordered_qty, ordered_uom, packed_qty, packed_uom, shipped_qty, 
					shipped_uom, ship_to_code, UPC, vend_part_no, cust_part_no, volume)
	SELECT @asn, a.order_no, line_no, part_no, ordered, uom, 
		(SELECT ISNULL(SUM(pack_qty),0) FROM tdc_carton_detail_tx c (NOLOCK)
		--SCR #36629 05-31-06 ToddR ADDED ISNULL STATEMENT AROUND SUM(pack_qty)
		WHERE c.order_no = a.order_no
		AND c.order_ext = a.order_ext
		AND c.line_no = a.line_no), 
		(select uom from inv_master (NOLOCK) WHERE part_no = a.part_no),
		shipped, uom, ship_to, (select upc_code from inv_master (NOLOCK) WHERE part_no = a.part_no),
		NULL, NULL, NULL
		FROM ord_list a (NOLOCK),
			tdc_carton_tx b(NOLOCK)
		WHERE a.order_no = b.order_no
		AND a.order_ext = b.order_ext
		AND b.order_type = 'S' 
		AND b.carton_no IN( SELECT carton_no FROM #outbound_cartons )
		GROUP BY a.order_no, a.order_ext, line_no, part_no, ordered, uom, shipped, uom, ship_to
	 
--------------------------------------------------------------------------------------------------------------------
-- Get carton header information
--------------------------------------------------------------------------------------------------------------------
 	--SCR37438 Jim 2/12/07
	INSERT INTO tdc_EDI_carton_header (ASN, carton_no, package_type, weight, weight_uom, trailer_id, height, width, length, epc_tag, tracking_no)
	SELECT @asn, carton_no, ISNULL(carton_type, ''), weight, 'LBS', NULL, NULL, NULL, NULL, epc_tag, cs_tracking_no
	FROM tdc_carton_tx (NOLOCK) 
	WHERE carton_no IN( SELECT carton_no FROM #outbound_cartons )
 
--------------------------------------------------------------------------------------------------------------------
-- Get carton detail information
--------------------------------------------------------------------------------------------------------------------
	INSERT INTO tdc_EDI_carton_detail (ASN, carton_no, order_no, line_no, part_no, qty_packed, uom, weight)
	SELECT @asn, carton_no, order_no, line_no, a.part_no, pack_qty, uom, weight_ea * pack_qty
	 FROM tdc_carton_detail_tx a(nolock), 
	inv_master b (NOLOCK)
	WHERE a.part_no = b.part_no
	AND carton_no in( SELECT carton_no FROM #outbound_cartons )
	GROUP BY carton_no, order_no, line_no, a.part_no, pack_qty, uom, weight_ea, pack_qty
 
--------------------------------------------------------------------------------------------------------------------
-- Get carton detail information
--------------------------------------------------------------------------------------------------------------------
	INSERT INTO tdc_EDI_pallet (ASN, pallet_no, carton_no, EPC_TAG, num_of_cartons)

	SELECT @asn, a.pack_no, b.carton_no, epc_tag, (SELECT COUNT(*) FROM tdc_master_pack_ctn_tbl c(NOLOCK)
									WHERE c.pack_no = a.pack_no)
	 FROM tdc_master_pack_tbl a (NOLOCK),
		tdc_master_pack_ctn_tbl b(NOLOCK)
	WHERE a.pack_no = b.pack_no
	AND carton_no in( SELECT carton_no FROM #outbound_cartons ) 
	GROUP BY a.pack_no, b.carton_no, epc_tag
 


--------------------------------------------------------------------------------------------------------------------
-- Update status to ready
--------------------------------------------------------------------------------------------------------------------
UPDATE tdc_EDI_shipment_header SET status = 0 WHERE asn = @asn

RETURN 0


GO
GRANT EXECUTE ON  [dbo].[tdc_outbound_asn_build_sp] TO [public]
GO
