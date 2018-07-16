SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0		Design for Print Credit Memos - Only print if flagged
-- v2.0		Removed code for checking print flag.  always allow printing from C&C
-- BJB_20111102	Altered for CVO specifications
-- v2.2	CT 02/08/12 - Added new fields
-- v2.3 CT 03/08/12 - Additional fixes
-- v2.4 CT 21/11/12 - Don't alter price for credit return fee on Buying Group credits
-- v2.5 CB 07/12/12 - Issue #1002 - Add line notes (Patient/Tray)
-- v2.6 CB 23/07/2013 - Issue #927 - Buying Group Switching
-- v2.7 CB 07/12/12 - Issue #925 - BG Print option
-- v2.8 CB 18/09/2013 - Issue #927 - Buying Group Switching - RB orders set to and from BGs
-- v2.9 CT 20/10/2014 - Issue #1367 - If net price > list price, set list = net and discount = 0
-- v3.0 CT 23/10/2014 - Issue #1504 - Fix calculation for credit returns with a discount percentage
-- v3.1 CB 13/12/2017 - Discount not displaying correctly
-- v3.2 CB 12/01/2018 - Add routine to correct pricing
-- v3.3 CB 13/07/2018 - Truncation issue
CREATE PROCEDURE [dbo].[cc_credit_memo_report_sp]  	@my_id varchar(255),
													@user_name	varchar(30) = '',
													@company_db	varchar(30) = ''
 	

AS

SET NOCOUNT ON
--	IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_login_sp' ) EXEC sm_login_sp @user_name, @company_db
	

DECLARE @qty_prev_ret int, @inv_doc_num varchar(16), @cm_date_applied int


CREATE TABLE 	#cc_archarge_work 
( 
		trx_ctrl_num 		varchar(16) NULL, 	
		doc_ctrl_num		varchar( 16 ) NULL,
		date_doc 			int NULL, 			
		date_applied 		int NULL, 			
		amt_net 			float NULL, 
		amt_discount 		float NULL, 		
		amt_freight 		float NULL, 	
		amt_tax 			float NULL, 
		amt_gross 			float NULL, 		
		amt_write_off_given	float NULL, 	
		amt_discount_taken	float NULL, 
		customer_addr1 		varchar(40) NULL, 	
		customer_addr2 		varchar(40) NULL, 	
		customer_addr3 		varchar(40) NULL, 
		customer_addr4 		varchar(40) NULL, 	
		customer_addr5 		varchar(40) NULL, 	
		customer_addr6 		varchar(40) NULL, 
		ship_to_code		varchar( 8 ) NULL,
		ship_to_addr1 		varchar(40) NULL, 	
		ship_to_addr2 		varchar(40) NULL, 	
		ship_to_addr3 		varchar(40) NULL, 
		ship_to_addr4 		varchar(40) NULL, 	
		ship_to_addr5 		varchar(40) NULL, 	
		ship_to_addr6 		varchar(40) NULL, 
		apply_to_num 		varchar(16) NULL, 	
		customer_code 		varchar(8) NULL, 	
		cust_po_num 		varchar(20) NULL, 
		order_ctrl_num 		varchar(16) NULL, 
		salesperson_code 	varchar(8) NULL,
		salesperson_name	varchar(40) NULL, 
		comment_code 		varchar(8) NULL, 
		comment_line 		varchar(40) NULL, 
		nat_cur_code		varchar(8) NULL,	
		symbol				varchar(8) NULL,
		nat_currency_mask 	varchar(100) NULL,
		curr_precision		smallint NULL, 
		line_desc			varchar(60) NULL,
		item_code			varchar(30) NULL,
		unit_code			varchar(8) NULL,
		qty_shipped			float NULL,
		qty_returned		float NULL,
		qty_prev_returned	float NULL,
		unit_price			float NULL,
		extended_price		float NULL,
		discount_amt		float NULL,
		sequence_id			int NULL,
		symbol_placement	smallint NULL,
		contact_name		varchar(40) NULL,
		style				varchar(40) NULL,
		invoice_no			int NULL,
		terms				varchar(10) NULL,
		routing				varchar(20) NULL,
		FOB					varchar(10) NULL,
		date_shipped		datetime NULL,
		who_entered			varchar(40) NULL,
		bg_name				varchar(40) NULL,						--v2.0				
		-- START v2.2
		terms_code				varchar(30) 	NULL,				
		carrier					varchar(40) NUll,					
		so_invoice_date			DATETIME NULL,						
		so_caller				VARCHAR(255) NULL,					
		so_bill_to				VARCHAR(255) NULL,					
		so_promo_name			VARCHAR(30) NULL,					
		list_amt				float 			NULL,				
		order_date				datetime NULL,						
		order_type				varchar(40) NULL,
		-- END v2.2	
		o_user_def_fld9			int NULL 	-- v2.3			
		

) 







	INSERT 	#cc_archarge_work (	trx_ctrl_num,
															doc_ctrl_num,
															line_desc,
															item_code, 
															unit_code, 
															qty_shipped, 
															qty_returned, 
															qty_prev_returned, 
															unit_price, 
															extended_price, 
															discount_amt,
															sequence_id
														)
	SELECT 	trx_ctrl_num,
					doc_ctrl_num,
					line_desc,
					item_code, 
					unit_code, 
					qty_shipped, 
					qty_returned, 
					0, 
					unit_price, 
					extended_price, 
					discount_amt,
					sequence_id
	FROM artrxcdt 
	WHERE doc_ctrl_num IN ( SELECT trx_num FROM cc_trx_table WHERE my_id = @my_id )

		

 UPDATE	#cc_archarge_work	
 SET 	#cc_archarge_work.date_doc 
					= artrx.date_doc, 				#cc_archarge_work.date_applied	
					= artrx.date_applied, 			#cc_archarge_work.amt_gross 
					= artrx.amt_gross, 				#cc_archarge_work.amt_net 
					= artrx.amt_net, 					#cc_archarge_work.amt_discount 
					= artrx.amt_discount, 			#cc_archarge_work.amt_freight 
					= artrx.amt_freight, 			#cc_archarge_work.amt_tax 
					= artrx.amt_tax, 					#cc_archarge_work.amt_write_off_given 
					= artrx.amt_write_off_given, 	#cc_archarge_work.amt_discount_taken 
					= artrx.amt_discount_taken,	#cc_archarge_work.apply_to_num 	
					= artrx.apply_to_num, 			#cc_archarge_work.customer_code	
					= artrx.customer_code,			#cc_archarge_work.ship_to_code 	
					= artrx.ship_to_code,			#cc_archarge_work.cust_po_num 	
					= artrx.cust_po_num, 			#cc_archarge_work.order_ctrl_num 
					= artrx.order_ctrl_num, 		#cc_archarge_work.salesperson_code 
					= artrx.salesperson_code, 		#cc_archarge_work.comment_code 
					= artrx.comment_code, 			#cc_archarge_work.nat_cur_code 
					= artrx.nat_cur_code 
 FROM #cc_archarge_work, artrx
		WHERE 	artrx.trx_ctrl_num = #cc_archarge_work.trx_ctrl_num 
	

	INSERT 	#cc_archarge_work (	trx_ctrl_num,
															doc_ctrl_num,
															date_doc,
															date_applied,
															amt_net,
															amt_discount,
															amt_freight,
															amt_tax,
															amt_gross,
															amt_write_off_given,
															amt_discount_taken,
															ship_to_code,
															apply_to_num,
															customer_code,
															cust_po_num,
															order_ctrl_num,
															salesperson_code,
															comment_code,
															nat_cur_code
													 )
	SELECT	trx_ctrl_num,
					doc_ctrl_num,
					date_doc,
					date_applied,
					amt_net,
					amt_discount,
					amt_freight,
					amt_tax,
					amt_gross,
					amt_write_off_given,
					amt_discount_taken,
					ship_to_code,
					apply_to_num,
					customer_code,
					cust_po_num,
					order_ctrl_num,
					salesperson_code,
					comment_code,
					nat_cur_code
	FROM	artrx
	WHERE doc_ctrl_num IN ( SELECT trx_num FROM cc_trx_table WHERE my_id = @my_id )
	AND trx_type = 2032
	AND doc_ctrl_num NOT IN (SELECT doc_ctrl_num FROM #cc_archarge_work	)


	UPDATE	#cc_archarge_work	
	SET 	#cc_archarge_work.customer_addr1 
				= armaster.addr1, #cc_archarge_work.customer_addr2 
				= armaster.addr2, #cc_archarge_work.customer_addr3 
				= armaster.addr3, #cc_archarge_work.customer_addr4 
				= armaster.addr4, #cc_archarge_work.customer_addr5 
				= armaster.addr5, #cc_archarge_work.customer_addr6 
				= armaster.addr6,
				#cc_archarge_work.contact_name = armaster.contact_name
 	FROM 	#cc_archarge_work, armaster
	WHERE 	armaster.customer_code = #cc_archarge_work.customer_code
	AND 	address_type = 0


	UPDATE	#cc_archarge_work	
	SET 	#cc_archarge_work.ship_to_addr1 
			= armaster.addr1, #cc_archarge_work.ship_to_addr2 
			= armaster.addr2, #cc_archarge_work.ship_to_addr3 
			= armaster.addr3, #cc_archarge_work.ship_to_addr4 
			= armaster.addr4, #cc_archarge_work.ship_to_addr5 
			= armaster.addr5, #cc_archarge_work.ship_to_addr6 
			= armaster.addr6,
			#cc_archarge_work.contact_name = armaster.contact_name 
	FROM 	#cc_archarge_work, armaster
	WHERE 	armaster.customer_code = #cc_archarge_work.customer_code
	--AND 	address_type <> 0 
	AND 	armaster.ship_to_code = #cc_archarge_work.ship_to_code


	UPDATE	#cc_archarge_work
	SET	#cc_archarge_work.salesperson_name = arsalesp.salesperson_name
	FROM	#cc_archarge_work,arsalesp
	WHERE	#cc_archarge_work.salesperson_code = arsalesp.salesperson_code	
				
	UPDATE	#cc_archarge_work
	SET	#cc_archarge_work.comment_line = arcommnt.comment_line
	FROM	#cc_archarge_work,arcommnt
	WHERE	#cc_archarge_work.comment_code = arcommnt.comment_code
					
	
	UPDATE 	#cc_archarge_work
	SET 	#cc_archarge_work.symbol 
			= glcurr_vw.symbol,			#cc_archarge_work.curr_precision 
			= glcurr_vw.curr_precision,#cc_archarge_work.symbol_placement 
			= glcurr_vw.position,		#cc_archarge_work.nat_currency_mask 
			= glcurr_vw.currency_mask
	FROM 	#cc_archarge_work, glcurr_vw
	where 	#cc_archarge_work.nat_cur_code = glcurr_vw.currency_code

	

UPDATE #cc_archarge_work
SET	amt_gross = ROUND(isnull(amt_gross,0),curr_precision),
	amt_discount = ROUND(isnull(amt_discount,0),curr_precision),
	amt_freight = ROUND(isnull(amt_freight,0),curr_precision),
	amt_tax	 = ROUND(isnull(amt_tax,0),curr_precision),
	amt_net	 = ROUND(isnull(amt_net,0),curr_precision),
	amt_write_off_given = ROUND(isnull(amt_write_off_given,0),curr_precision),
	amt_discount_taken	 = ROUND(isnull(amt_discount_taken,0),curr_precision),
	extended_price = ROUND(isnull(extended_price,0),curr_precision),
	discount_amt = ROUND(isnull(discount_amt,0),curr_precision)


	update #cc_archarge_work
	set style = field_2
	from inv_master_add (nolock) 
	where part_no = item_code 
	

	-- START v2.2
	--update #cc_archarge_work
	update 
		a
	set 
		invoice_no = orders.invoice_no,
		terms = orders.terms,
		routing = orders.routing,
		FOB = orders.FOB,
		date_shipped = orders.date_shipped,
		who_entered = orders.who_entered,
		carrier = isnull(v.ship_via_name,orders.routing),
		order_type = case 
			when user_category = 'ST' then 'Stock Order'
			when user_category = 'RX' then 'RX Order'
			else 'Stock Order'
		end,
		order_date = orders.date_entered,
		so_invoice_date	= orders.date_shipped, --orders.invoice_date,	-- v2.3
		so_caller = orders.user_def_fld2,
		--so_bill_to = orders.user_def_fld4,	-- v2.3
		so_promo_name = p.promo_name,
		-- START v2.9
		--list_amt = cv1.list_price, 
		list_amt = CASE WHEN l.curr_price > cv1.list_price THEN l.curr_price ELSE cv1.list_price END, 
		-- START v3.0 - wrong name used in V2.9
		--discount_amt =	CASE WHEN l.curr_price > cv1.list_price THEN 0 
		amt_discount =	CASE WHEN l.curr_price > cv1.list_price THEN 0 
		-- END v3.0
						ELSE CASE orders.type WHEN 'I' THEN (cv1.list_price - l.curr_price) + cv1.amt_disc  
						ELSE CASE l.discount WHEN 0 THEN (cv1.list_price - l.curr_price)
						-- START v3.0  
						ELSE CASE WHEN cv1.list_price = l.curr_price THEN ROUND(cv1.list_price * l.discount/100,2) 
						ELSE (cv1.list_price - l.curr_price) + ROUND(l.curr_price * l.discount/100,2) END 
						--ELSE (cv1.list_price - l.curr_price) + cv1.amt_disc  
						-- END v3.0
		END END END,
		/*
		amt_discount = CASE orders.type WHEN 'I' THEN (cv1.list_price - l.curr_price) + cv1.amt_disc  
			   ELSE CASE l.discount WHEN 0 THEN (cv1.list_price - l.curr_price)   
			   ELSE (cv1.list_price - l.curr_price) + cv1.amt_disc  
			END END,
		*/
		-- END v2.9                  
		terms_code = orders.terms,
		comment_line = LEFT(l.note,40) -- v2.5 -- v3.3
	from #cc_archarge_work a 
	INNER JOIN orders (nolock) ON orders.order_no = left(a.order_ctrl_num, charindex('-',a.order_ctrl_num)-1)
						and orders.ext = right(a.order_ctrl_num,len (a.order_ctrl_num) - charindex('-',a.order_ctrl_num))	
	LEFT JOIN dbo.arshipv v (nolock) on v.ship_via_code = orders.routing 
	INNER JOIN dbo.cvo_orders_all c (NOLOCK) ON orders.order_no = c.order_no AND orders.ext = c.ext
	LEFT JOIN dbo.cvo_promotions p (nolock) ON c.promo_id = p.promo_id AND c.promo_level = p.promo_level
	INNER JOIN dbo.cvo_ord_list cv1 (NOLOCK) ON c.order_no = cv1.order_no AND orders.ext = cv1.order_ext AND a.sequence_id = cv1.line_no
	INNER JOIN dbo.ord_list l (NOLOCK) ON cv1.order_no = l.order_no AND cv1.order_ext = l.order_ext AND cv1.line_no = l.line_no
	where 
		--order_no = left(order_ctrl_num,  charindex('-',order_ctrl_num) - 1)
		--and ext = right(order_ctrl_num, len(order_ctrl_num) - charindex('-',order_ctrl_num) ) and
		charindex('-',order_ctrl_num) > 0 
	-- END v2.2
	

	-- START v2.3 
	UPDATE 
		#cc_archarge_work
	SET 
		o_user_def_fld9 = 0

	-- Add Buying Group Name    
	UPDATE 
		a 
	SET 
		so_bill_to = IsNull(ac.customer_name,' '),
		o_user_def_fld9 = CASE ac.addr_sort1 WHEN 'Buying Group' THEN 1 ELSE o_user_def_fld9 END
	FROM 
		#cc_archarge_work a
	INNER JOIN 
		CVO_orders_all c (nolock) 
	ON 
		c.order_no = LEFT(a.order_ctrl_num, CHARINDEX('-',a.order_ctrl_num)-1)
		AND c.ext = RIGHT(a.order_ctrl_num,len (a.order_ctrl_num) - CHARINDEX('-',a.order_ctrl_num))   
	INNER JOIN 
			arcust ac (nolock) 
	ON  
		c.buying_group = ac.customer_code
    WHERE 
		CHARINDEX('-',a.order_ctrl_num) > 0
	AND ISNULL(ac.alt_location_code,'0') = '1' -- v2.7

	-- If this is a buying group then no discount
	UPDATE
		#cc_archarge_work
	SET
		amt_discount = 0,
		unit_price = list_amt,
		extended_price = list_amt * ISNULL(qty_returned,0)
	WHERE
		ISNULL(o_user_def_fld9,0) = 1
-- v3.1	AND item_code <> 'Credit Return Fee' -- v2.4
		AND item_code = 'Credit Return Fee' -- v3.1
	-- END v2.3 

	update #cc_archarge_work
	set bg_name = a.customer_name
	from cvo_orders_all o (nolock), arcust a (nolock)
	where order_no = left(order_ctrl_num, charindex('-',order_ctrl_num)-1)
	and ext = right(order_ctrl_num,len (order_ctrl_num) - charindex('-',order_ctrl_num))
	and charindex('-',order_ctrl_num) > 0
	and o.buying_group = a.customer_code



	-- START v2.2
	--Get Terms description
	UPDATE
		a
	SET
		terms_code = t.terms_desc
	FROM
		#cc_archarge_work a
	INNER JOIN
		dbo.arterms t (nolock) 
	on 
		t.terms_code = a.terms_code
	-- END v2.2

-- v1.0	CVO : Delete any transactions where the Customer is not printing credit memos
-- v2.0 delete #cc_archarge_work 
-- v2.0 where customer_code in (select customer_code from cvo_armaster_all (nolock) where cvo_print_cm = 0 and address_type = 0)
--

	-- v2.6 Start
	UPDATE	a
	SET		so_bill_to = dbo.f_cvo_get_buying_group_name(dbo.f_cvo_get_buying_group(a.customer_code, CONVERT(varchar(10),DATEADD(DAY, a.date_doc - 693596, '01/01/1900'),121)))
	FROM	#cc_archarge_work a
	-- v2.6 End

	-- v2.8 Start
	UPDATE	a
	SET		so_bill_to = dbo.f_cvo_get_buying_group_name(b.buying_group)
	FROM	#cc_archarge_work a
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_ctrl_num = (CAST(b.order_no AS varchar(20)) + '-' + CAST(b.ext AS varchar(20)))
	WHERE	b.buying_group <> a.so_bill_to
	-- v2.8 End

	-- v3.2 Start
	DECLARE @c_gross_price		decimal(20,8),
			@c_discount_amount	decimal(20,8),
			@c_net_price		decimal(20,8), 
			@c_ext_net_price	decimal(20,8),
			@c_order_no			int,
			@c_order_ext		int,
			@c_line_no			int,
			@c_cust_code		varchar(10),
			@c_qty				decimal(20,8),
			@row_id				int,
			@parent				varchar(10),
			@IsBG				int,
			@trx_ctrl_num		varchar(16)

	CREATE TABLE #inv_pricing (
		row_id		int IDENTITY(1,1),
		order_no	int,
		order_ext	int,
		line_no		int,
		cust_code	varchar(10),
		qty			decimal(20,8),
		trx_ctrl_num varchar(16))

	INSERT	#inv_pricing (order_no,	order_ext, line_no, cust_code, qty, trx_ctrl_num)
	SELECT	LEFT(order_ctrl_num, CHARINDEX('-',order_ctrl_num)-1),
			RIGHT(order_ctrl_num,LEN (order_ctrl_num) - CHARINDEX('-',order_ctrl_num)),
			sequence_id,
			customer_code,
			qty_returned,
			trx_ctrl_num
	FROM	#cc_archarge_work
	WHERE	charindex('-',order_ctrl_num) > 0

	SET @row_id = 0

	WHILE (1 = 1)
	BEGIN
		SELECT	TOP 1 @row_id = row_id,
				@c_order_no = order_no,
				@c_order_ext = order_ext,
				@c_line_no = line_no,			
				@c_cust_code = cust_code,
				@c_qty = qty,
				@trx_ctrl_num = trx_ctrl_num
		FROM	#inv_pricing
		WHERE	row_id > @row_id
		ORDER BY row_id ASC

		IF (@@ROWCOUNT = 0)
			BREAK

		SET @c_gross_price = 0
		SET @c_discount_amount = 0
		SET @c_net_price = 0
		SET @c_ext_net_price = 0

		EXEC dbo.cvo_get_invoice_line_prices_sp	@c_order_no, @c_order_ext, @c_line_no, @c_cust_code, @c_qty, @c_gross_price OUTPUT, @c_discount_amount OUTPUT,
						@c_net_price OUTPUT, @c_ext_net_price OUTPUT

		SELECT	@parent = ISNULL(buying_group,'') 
		FROM	CVO_orders_all (NOLOCK) 
		WHERE	order_no = @c_order_no 
		AND		ext = @c_order_ext

		IF (@parent <> '')
		BEGIN
			SET @c_cust_code = @parent
		END

		SELECT	@isBG = ISNULL(alt_location_code,0) 
		FROM	arcust (NOLOCK)
		WHERE	customer_code = @c_cust_code

		IF (@isBG = 1)
		BEGIN
			IF EXISTS (SELECT 1 FROM ord_list (NOLOCK) WHERE order_no = @c_order_no AND order_ext = @c_order_ext AND line_no = @c_line_no AND discount = 100)
			BEGIN
				SET @c_discount_amount = @c_gross_price
				SET @c_net_price = 0
				SET @c_ext_net_price = 0
			END
		END

		UPDATE	#cc_archarge_work
		SET		list_amt = @c_gross_price,
				discount_amt = @c_discount_amount,
				amt_discount = @c_discount_amount,
				unit_price = @c_net_price,
				extended_price = @c_ext_net_price
		WHERE	trx_ctrl_num = @trx_ctrl_num
		AND		sequence_id = @c_line_no

	END

	DROP TABLE #inv_pricing
	-- v3.2 End


SELECT trx_ctrl_num,
	doc_ctrl_num,
	customer_code,
	customer_addr1,
	customer_addr2,
	customer_addr3,
	customer_addr4,
	customer_addr5,
	customer_addr6,
	ship_to_addr1,
	ship_to_addr2,
	ship_to_addr3,
	ship_to_addr4,
	ship_to_addr5,
	ship_to_addr6,
	cust_po_num,
	order_ctrl_num,	
	nat_cur_code,
	DateDoc =
	CASE date_doc
		WHEN 0 THEN 0
	ELSE
		convert(smalldatetime, dateadd(dd, date_doc - 639906, '1/1/1753'))
	END, 
	DateApplied = 
	CASE date_applied
		WHEN 0 THEN 0
	ELSE
		convert(smalldatetime, dateadd(dd, date_applied - 639906, '1/1/1753'))
	END, 	
	salesperson_name,
	apply_to_num,
	comment_code,
	comment_line,
	AmtGross = amt_gross,
	AmtDiscount = amt_discount,
	AmtFreight = amt_freight,
	AmtTax = amt_tax,
	AmtNet = amt_net,
	AmtWO = amt_write_off_given,
	AmtDiscTaken = amt_discount_taken,
	item_code,
	unit_code,
	qty_shipped,
	qty_returned,
	line_desc,
	DESC1 = substring(line_desc, 1, 30), 
	DESC2 = substring(line_desc, 31, 30), 
	ExtendedPrice = extended_price,
	DiscountAmount = discount_amt,
	UnitPrice = unit_price,
	sequence_id,
	company_name,
	addr1,
	addr2,
	addr3,
	addr4,
	addr5,
	addr6,
	symbol,
	symbol_placement,
	contact_name, 
	style,
	invoice_no,
	terms,
	routing,
	FOB,
	date_shipped,
	who_entered,
	bg_name,
	-- START v2.2
	terms_code,	
	carrier,	
	so_invoice_date,
	so_caller,		
	so_bill_to,		
	so_promo_name,	
	list_amt,		
	order_type,		
	order_date,
	-- END v2.2
	o_user_def_fld9	-- v2.3
FROM #cc_archarge_work, arco -- glco -- v2.2


DELETE cc_trx_table WHERE my_id = @my_id

GO
GRANT EXECUTE ON  [dbo].[cc_credit_memo_report_sp] TO [public]
GO
