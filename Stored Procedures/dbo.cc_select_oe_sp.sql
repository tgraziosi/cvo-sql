SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

-- v1.1 CB 17/09/2013 - Issue #927 - Buying Group Switching - RB Orders set and removed from BGs
-- v1.2 CB 01/10/2013 - Issue #927 - Buying Group Switching - Deal with non BG customers
-- v1.3 CB 06/11/2013 - Fix issue with non BG parents
-- v2.0 CB 10/06/2014 - ReWrite of BG data
-- tag - cvo - 12/29/2013 - performance - re-arrange joins on insert #orders statements

CREATE PROCEDURE [dbo].[cc_select_oe_sp] @customer_code	varchar(8)

AS


	DECLARE @relation_code varchar(10),
			@IsParent int, -- v1.1
			@Parent varchar(8), -- v1.3
			@IsBG int -- v1.3

	SELECT @relation_code = credit_check_rel_code
	FROM arco (NOLOCK)
	
-- v1.5 Start
 	CREATE TABLE #customers( customer_code varchar(8) )    
    
	-- WORKING TABLE
	IF OBJECT_ID('tempdb..#bg_data') IS NOT NULL
		DROP TABLE #bg_data

	CREATE TABLE #bg_data (
		doc_ctrl_num	varchar(16),
		order_ctrl_num	varchar(16),
		customer_code	varchar(10),
		doc_date_int	int,
		doc_date		varchar(10),
		parent			varchar(10))

	-- Call BG Data Proc
	--EXEC cvo_bg_get_document_data_sp '030774',2
	--select * From #bg_data

   EXEC cvo_bg_get_document_data_sp @customer_code,2
   
	CREATE INDEX #bg_data_ind22 ON #bg_data (customer_code, doc_ctrl_num)
	-- 12/29/14 - tag
	CREATE INDEX #bg_data_ind33 ON #bg_data (parent)


	INSERT #customers    
	SELECT DISTINCT customer_code FROM #bg_data    
    

	CREATE TABLE #orders
	(	invoice_no int	NULL,
		order_no int,			
		date_entered datetime	NULL,
		total_amt_order decimal(20,8),
		ext int,
		status	char(1),
		status_description varchar(50)	NULL,
		cust_po varchar(20)	NULL,
		curr_key varchar(10),
		ship_to_name varchar(40)	NULL,
		salesperson_name varchar(40)	NULL,
		total_discount decimal(20,8)	NULL,
		cust_code varchar(10),
		total_invoice decimal(20,8),
		total_tax decimal(20,8)	NULL,
		total_freight	 decimal(20,8)	NULL,
		net decimal(20,8) NULL)

	DECLARE @include_returns	smallint

	SELECT	@include_returns = include_credit_returns FROM cc_ord_status (NOLOCK)

	IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id('dbo.orders'))
	BEGIN
		IF @include_returns = 1
		BEGIN
			INSERT #orders( invoice_no,	order_no,date_entered,total_amt_order,ext,status,status_description ,cust_po,curr_key,ship_to_name,salesperson_name,total_discount,cust_code,total_invoice, total_tax,	total_freight )
			SELECT 	orders.invoice_no,
					orders.order_no,
					orders.date_entered,
					orders.total_amt_order,
					orders.ext,
					orders.status,
					'status_description' = 
					CASE UPPER( orders.status )
						WHEN 'A' THEN 'A - Hold for Quote'
						WHEN 'B' THEN 'B - Both a credit and price hold'
						WHEN 'C' THEN 'C - Credit Hold'
						WHEN 'E' THEN 'E - EDI'
						WHEN 'H' THEN 'H - Price Hold'
						WHEN 'M' THEN 'M - Blanket Order(parent)'
						WHEN 'N' THEN 'N - New'
						WHEN 'P' THEN 'P - Open/Picked'
						WHEN 'Q' THEN 'Q - Open/Printed'
						WHEN 'R' THEN 'R - Ready/Posting'
						WHEN 'S' THEN 'S - Shipped/Posted'
						WHEN 'T' THEN 'T - Shipped/Transferred'
						WHEN 'V' THEN 'V - Void'
						WHEN 'X' THEN 'X - Voided/Cancel Quote'
						ELSE ''
					END, 
					orders.cust_po,
					orders.curr_key,
					'ship_to_name' = ISNULL(arshipto.ship_to_name,' '),
					salesperson_name,
					orders.total_discount,
					orders.cust_code,
					orders.total_invoice,
					orders.total_tax,
					orders.freight
			FROM 	#bg_data bg 
		-- tag - 12/29/14 - move joins around for performance
			inner join orders (NOLOCK)
			--JOIN	#bg_data bg
			ON		bg.order_ctrl_num = CAST(orders.order_no AS varchar(10)) + '-' + CAST(orders.ext AS varchar(6)) 
			LEFT OUTER JOIN arsalesp (NOLOCK) ON (salesperson = arsalesp.salesperson_code)
			LEFT OUTER JOIN arshipto (NOLOCK) ON (ship_to = arshipto.ship_to_code AND cust_code = arshipto.customer_code)
			WHERE bg.parent = @customer_code 
			and UPPER( status ) IN ( SELECT UPPER( status_code ) FROM cc_ord_status (NOLOCK) WHERE use_flag = 1 )	
			ORDER BY orders.order_no
							
		END
		ELSE
		BEGIN
			INSERT #orders( invoice_no,	order_no,date_entered,total_amt_order,ext,status,status_description ,cust_po,curr_key,ship_to_name,salesperson_name,total_discount,cust_code,total_invoice, total_tax,	total_freight )
			SELECT 	orders.invoice_no,
					orders.order_no,
					orders.date_entered,
					orders.total_amt_order,
					orders.ext,
					orders.status,
					'status_description' = CASE UPPER( orders.status )
						WHEN 'A' THEN 'A - Hold for Quote'
						WHEN 'B' THEN 'B - Both a credit and price hold'
						WHEN 'C' THEN 'C - Credit Hold'
						WHEN 'E' THEN 'E - EDI'
						WHEN 'H' THEN 'H - Price Hold'
						WHEN 'M' THEN 'M - Blanket Order(parent)'
						WHEN 'N' THEN 'N - New'
						WHEN 'P' THEN 'P - Open/Picked'
						WHEN 'Q' THEN 'Q - Open/Printed'
						WHEN 'R' THEN 'R - Ready/Posting'
						WHEN 'S' THEN 'S - Shipped/Posted'
						WHEN 'T' THEN 'T - Shipped/Transferred'
						WHEN 'V' THEN 'V - Void'
						WHEN 'X' THEN 'X - Voided/Cancel Quote'
						ELSE ''
					END, 
					orders.cust_po,
					orders.curr_key,
					'ship_to_name' = ISNULL(arshipto.ship_to_name,' '),
					salesperson_name,
					orders.total_discount,
					orders.cust_code,
					orders.total_invoice,
					orders.total_tax,
					orders.freight
			FROM 	#bg_data bg
			-- tag - 12/29/14 - move joins around for performance
			inner join orders (NOLOCK)
			ON	bg.order_ctrl_num = 	CAST(orders.order_no AS varchar(10)) + '-' + CAST(orders.ext AS varchar(6)) 
			LEFT OUTER JOIN arsalesp (NOLOCK) ON (salesperson = arsalesp.salesperson_code)
			LEFT OUTER JOIN arshipto (NOLOCK) ON (ship_to = arshipto.ship_to_code AND cust_code = arshipto.customer_code)
			WHERE bg.parent = @customer_code
			and  orders.cust_code IN ( SELECT customer_code FROM #customers )
			AND	UPPER( orders.status ) IN ( SELECT UPPER( status_code ) FROM cc_ord_status (NOLOCK) WHERE use_flag = 1 )	
			AND	UPPER(type) <> 'C'
			ORDER BY orders.order_no 
			
		END
	END

	UPDATE #orders
	SET status_description = ISNULL( hold_reason, 'A - Hold for Quote' )
	FROM #orders o, orders_all a
	WHERE o.status = 'A'
	AND o.order_no = a.order_no
	AND o.ext = a.ext

	UPDATE #orders
	SET	total_amt_order = a.gross_sales,
			total_discount = a.total_discount,
			total_invoice = a.total_invoice,
			total_freight = a.freight,
			total_tax = a.total_tax
	FROM #orders o, orders_all a
	WHERE o.status IN ( 'R', 'S', 'T' )
	AND o.order_no = a.order_no
	AND o.ext = a.ext

	AND UPPER( o.status ) IN ( SELECT UPPER( status_code ) FROM cc_ord_status WHERE use_flag = 1 ) 
	AND void = 'N' 

	UPDATE #orders
	SET	total_amt_order = a.total_amt_order,
			total_discount = a.tot_ord_disc,
			total_invoice = 0,
			total_freight = a.tot_ord_freight,
			total_tax = a.tot_ord_tax
	FROM #orders o, orders_all a
	WHERE o.status NOT IN ( 'R', 'S', 'T' )
	AND o.order_no = a.order_no
	AND o.ext = a.ext

	AND UPPER( o.status ) IN ( SELECT UPPER( status_code ) FROM cc_ord_status WHERE use_flag = 1 ) 
	AND void = 'N' 


	UPDATE #orders
	SET	total_amt_order = a.gross_sales * -1,
			total_discount = a.total_discount * -1,
			total_invoice = a.total_invoice * -1,
			total_freight = a.freight * -1,
			total_tax = a.total_tax * -1
	FROM #orders o, orders_all a
	WHERE o.status IN ( 'R', 'S', 'T' )
	AND o.order_no = a.order_no
	AND o.ext = a.ext

	AND UPPER( o.status ) IN ( SELECT UPPER( status_code ) FROM cc_ord_status WHERE use_flag = 1 ) 
	AND void = 'N' 
	AND type = 'C'

	UPDATE #orders
	SET	total_amt_order = a.total_amt_order * -1,
			total_discount = a.tot_ord_disc * -1,
			total_invoice = 0,
			total_freight = a.tot_ord_freight * -1,
			total_tax = a.tot_ord_tax * -1
	FROM #orders o, orders_all a
	WHERE o.status NOT IN ( 'R', 'S', 'T' )
	AND o.order_no = a.order_no
	AND o.ext = a.ext

	AND UPPER( o.status ) IN ( SELECT UPPER( status_code ) FROM cc_ord_status WHERE use_flag = 1 ) 
	AND void = 'N' 
	AND type = 'C'


	UPDATE #orders
	SET net = total_amt_order - total_discount + total_freight + total_tax


	

select invoice_no,	order_no,date_entered,total_amt_order,ext,status_description ,cust_po,curr_key,ship_to_name,salesperson_name,total_discount,cust_code,total_invoice, total_tax,	total_freight, net from #orders

DROP TABLE #bg_data

GO
GRANT EXECUTE ON  [dbo].[cc_select_oe_sp] TO [public]
GO
