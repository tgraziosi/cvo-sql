SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v2.1 CT 01/08/2012 - Added extra fields to output
-- v2.2 CT 03/08/12 - Additional fixes
-- v2.3 CB 10/09/12 - Issue #755 - Print frames first then cases
-- v2.4 CB 07/12/12 - Issue #1002 - Add line notes (Patient/Tray)
-- v2.5 CB 11/01/13 - Issue #866 - Add invoice notes
-- v2.6 CT 31/01/13 - Only take first 10 characters from line notes field 
-- v2.7 CB 23/07/2013 - Issue #927 - Buying Group Switching
-- v2.8 CB 07/12/12 - Issue #925 - BG Print option
-- v2.9 CB 17/09/2013 - Issue #927 - Buying Group Switching - RB Orders set to and from BGs
-- v3.0 CB 21/010/2013 - Issue #925 - BG Print option - if option not set then default to on
-- v3.1 CB 23/10/2013 - Issue #925 - BG print options - Always display buying group and correct discount, list price etc
-- v3.2 CB 04/11/2013 - Issue #925 - BG print options - Further Change
-- v3.3 CT 20/10/2014 - Issue #1367 - If net price > list price, set list = net and discount = 0
-- v3.4 CT 28/10/2014 - Issue #1367 - If net price > list price, set list = net and discount = 0 for BG printing non BG invoices
-- v3.5 CB 13/05/2015 - Issue #1446 - Add invoice notes from customer
-- v3.6 CB 15/07/2015 - Fix issue for free frames on BG invoices
-- v3.7 CB 08/09/2015 - As per Tine - They want to see the gross price (list price) as whatever it is (non-zero), and the net price to show as $0.
-- v3.8 CB 11/05/2016 - Fix for promo discount
-- v3.9 CB 28/12/2017 - Another fix for promo discount
-- v4.0 CB 08/01/2017 - #1656 - Customer Pricing Invoice
-- v4.1 CB 12/01/2018 - Add routine to correct pricing
-- v4.2 CB 09/08/2018 - For installment invoice just show totals


CREATE PROCEDURE [dbo].[cc_invoice_report_sp] @my_id	varchar(255),
																			@user_name	varchar(30) = '',
																			@company_db	varchar(30) = ''
 AS

SET NOCOUNT ON
--IF EXISTS (SELECT name FROM sysobjects WHERE name = 'sm_login_sp' ) EXEC sm_login_sp @user_name, @company_db

DECLARE @curr_precision smallint 

CREATE TABLE	#ccarhdr_work
(	trx_ctrl_num			varchar(16) NULL,
	doc_ctrl_num			varchar(16) NULL,
	location_code			varchar(10) NULL, -- v2.4 Increase to 10 as using this for patient/tray
	item_code				varchar(30) NULL,
	qty_shipped				float 			NULL,
	unit_code				varchar(8) 	NULL,
	unit_price				float 			NULL,
	line_desc				varchar(60) NULL,
	qty_ordered				float 			NULL,
	det_tax_code			varchar(8) 	NULL,
	extended_price			float 			NULL,
	gl_rev_acct				varchar(32) NULL,
	reference_code			varchar(32) NULL,
	weight					float 			NULL,
	discount_amt			float 			NULL,
	discount_prc			float 			NULL,
	sequence_id				int 				NULL,
	customer_code			varchar(8) 	NULL,
	customer_addr1			varchar(40) NULL,
	customer_addr2			varchar(40) NULL,
	customer_addr3			varchar(40) NULL,
	customer_addr4			varchar(40) NULL,
	customer_addr5			varchar(40) NULL,
	customer_addr6			varchar(40) NULL,
	ship_to_code			varchar(8) 	NULL,
	ship_to_addr1			varchar(40) NULL,
	ship_to_addr2			varchar(40) NULL,
	ship_to_addr3			varchar(40) NULL,
	ship_to_addr4			varchar(40) NULL,
	ship_to_addr5			varchar(40) NULL,
	ship_to_addr6			varchar(40) NULL,
	cust_po_num				varchar(20) NULL,
	order_ctrl_num			varchar(16) NULL,	
	nat_cur_code 			varchar(8) 	NULL,
	posting_code			varchar(8) 	NULL,
	tax_code				varchar(8)	NULL,
	fin_chg_code			varchar(8) 	NULL,
	date_doc				int 				NULL,
	date_applied			int 				NULL,
	--terms_code				varchar(8) 	NULL,
	terms_code				varchar(30) 	NULL,		-- v2.1
	date_due				int 				NULL,
	date_aging				int 				NULL,
	date_required			int 				NULL,
	date_shipped			int 				NULL,
	freight_code			varchar(8) 	NULL,
	dest_zone_code			varchar(8) 	NULL,
	fob_code				varchar(8) 	NULL,
	salesperson_code		varchar(8) 	NULL,
	territory_code			varchar(8) 	NULL,
	price_code				varchar(8) 	NULL,
	recurring_code			varchar(8) 	NULL,
	apply_to_num			varchar(16) NULL,
	comment_code			varchar(8) 	NULL,
	comment_line			varchar(40) NULL,
	doc_desc				varchar(40) NULL,
	amt_gross				float 			NULL,
	amt_discount			float 			NULL,
	amt_freight				float 			NULL,
	amt_tax					float 			NULL,
	amt_net					float 			NULL,
	amt_paid				float 			NULL,
	amt_due					float 			NULL,
	amt_paid_to_date		float 			NULL,
	artrx_amt_due			float 			NULL,
	symbol					varchar(8) 	NULL,
	curr_precision			smallint 		NULL,
	symbol_placement		smallint 		NULL,
	hdr_org_id				varchar(30) NULL,
	det_org_id				varchar(30) NULL,
	who_entered				varchar(40) NULL,
	style					varchar(40) NUll,
	order_type				varchar(40) NUll,
	--carrier					varchar(20) NUll,
	carrier					varchar(40) NUll,					-- v2.1
	order_date				datetime NULL,
	bg_name					varchar(40) NULL,					-- v2.0				
	so_invoice_date			DATETIME NULL,						-- v2.1
	so_caller				VARCHAR(255) NULL,					-- v2.1
	so_bill_to				VARCHAR(255) NULL,					-- v2.1
	so_promo_name			VARCHAR(30) NULL,					-- v2.1
	list_amt				float 			NULL,				-- v2.1
	o_user_def_fld9			int NULL, 							-- v2.2
	o_user_def_fld4			int NULL, 							-- v3.1
    invoice_note			varchar(255) -- v2.5
	

)



	INSERT	#ccarhdr_work (	trx_ctrl_num,
													doc_ctrl_num,
													location_code,
													item_code,
													qty_shipped,
													unit_code,
													unit_price,
													line_desc,
													qty_ordered,
													det_tax_code,
													extended_price, 
													gl_rev_acct,
													reference_code,
													weight,
													discount_amt,
													discount_prc,
													sequence_id,
													det_org_id
												)
	SELECT	trx_ctrl_num,
					doc_ctrl_num,
					location_code,
					item_code,					qty_shipped,
					unit_code,
					unit_price,
					line_desc,					qty_ordered,
					tax_code,
					extended_price,
					gl_rev_acct,
					reference_code,
					weight,
					discount_amt,
					discount_prc,
					sequence_id,
					org_id
	FROM artrxcdt 
	WHERE doc_ctrl_num IN ( SELECT trx_num FROM cc_trx_table WHERE my_id = @my_id )



	UPDATE 	#ccarhdr_work
	SET			customer_code			= h.customer_code,
					ship_to_code			= h.ship_to_code,
					cust_po_num				= h.cust_po_num,
					order_ctrl_num		= h.order_ctrl_num,
					nat_cur_code			= h.nat_cur_code,
					posting_code			= h.posting_code,
					tax_code					= h.tax_code,
					fin_chg_code			= h.fin_chg_code,
					date_doc					= h.date_doc,
					date_applied			= h.date_applied,
					terms_code				= h.terms_code,
					date_due					= h.date_due,
					date_aging				= h.date_aging,
					date_required			= h.date_required,
					date_shipped			= h.date_shipped,
					freight_code			= h.freight_code,
					dest_zone_code		= h.dest_zone_code,
					fob_code					= h.fob_code,
					salesperson_code	= h.salesperson_code,
					territory_code		= h.territory_code,
					price_code				= h.price_code,
					recurring_code		= h.recurring_code,
					apply_to_num			= h.apply_to_num,
					comment_code			= h.comment_code,
					doc_desc					= h.doc_desc,
					amt_gross					= h.amt_gross,
					amt_discount			= h.amt_discount,
					amt_freight				= h.amt_freight,
					amt_tax						= h.amt_tax,
					amt_net						= h.amt_net,
					amt_paid_to_date	= h.amt_paid_to_date,
					artrx_amt_due			=	h.amt_net - h.amt_paid_to_date,
					hdr_org_id				= h.org_id

	FROM #ccarhdr_work w, artrx h
	WHERE h.trx_ctrl_num = w.trx_ctrl_num 


 	INSERT #ccarhdr_work (	trx_ctrl_num,
													doc_ctrl_num,
													customer_code,
													ship_to_code,
													cust_po_num,
													order_ctrl_num,				
													nat_cur_code,
													posting_code,
													tax_code,
													fin_chg_code,
													date_doc,
													date_applied,
													terms_code,
													date_due,
													date_aging,
													date_required,
													date_shipped,
													freight_code,
													dest_zone_code,
													fob_code,
													salesperson_code,
													territory_code,
													price_code,
													recurring_code,
													apply_to_num,
													comment_code,
													doc_desc,
													amt_gross,
													amt_discount,
													amt_freight,
													amt_tax,
													amt_net,
													amt_paid_to_date,
													artrx_amt_due,
													hdr_org_id
												)
	SELECT	trx_ctrl_num,
					doc_ctrl_num,
					customer_code,
					ship_to_code,
					cust_po_num,
					order_ctrl_num,				
					nat_cur_code,
					posting_code,
					tax_code,
					fin_chg_code,
					date_doc,
					date_applied,
					terms_code,
					date_due,
					date_aging,
					date_required,
					date_shipped,
					freight_code,
					dest_zone_code,
					fob_code,
					salesperson_code,
					territory_code,
					price_code,
					recurring_code,
					apply_to_num,
					comment_code,
					doc_desc,
					amt_gross,
					amt_discount,
					amt_freight,
					amt_tax,
					amt_net,
					amt_paid_to_date,
					amt_net - amt_paid_to_date,
					org_id
	FROM	artrx
	WHERE doc_ctrl_num IN ( SELECT trx_num FROM cc_trx_table WHERE my_id = @my_id )
	AND	doc_ctrl_num NOT IN ( SELECT doc_ctrl_num FROM #ccarhdr_work )
 

	UPDATE	#ccarhdr_work
	SET			customer_addr1	= x.addr1,
					customer_addr2	= x.addr2,
					customer_addr3	= x.addr3,
					customer_addr4	= x.addr4,
					customer_addr5	= x.addr5,
					customer_addr6	= x.addr6,
					ship_to_addr1		= x.ship_addr1,
					ship_to_addr2		= x.ship_addr2,
					ship_to_addr3		= x.ship_addr3,
					ship_to_addr4		= x.ship_addr4,
					ship_to_addr5		= x.ship_addr5,
					ship_to_addr6		= x.ship_addr6





	FROM	#ccarhdr_work w, artrxxtr x
	WHERE	w.trx_ctrl_num	= x.trx_ctrl_num



	UPDATE 	#ccarhdr_work
	SET 		symbol						= g.symbol,
					curr_precision 		= g.curr_precision, 
					symbol_placement	= g.position
	FROM 		#ccarhdr_work w, glcurr_vw g
	WHERE w.nat_cur_code = g.currency_code

	UPDATE	#ccarhdr_work
	SET 		comment_line = c.comment_line
	FROM 		#ccarhdr_work w, arcommnt c
	WHERE 	w.comment_code = c.comment_code

	SELECT @curr_precision = (SELECT DISTINCT curr_precision FROM #ccarhdr_work)


	UPDATE	#ccarhdr_work
	SET			amt_gross 				= ISNULL(ROUND(amt_gross,@curr_precision),0),
					amt_discount 			= ISNULL(ROUND(amt_discount,@curr_precision),0),
					amt_freight 			= ISNULL(ROUND(amt_freight,@curr_precision),0),
					amt_tax	 					= ISNULL(ROUND(amt_tax,@curr_precision),0),
					amt_net	 					= ISNULL(ROUND(amt_net,@curr_precision),0),
					amt_paid 					= ISNULL(ROUND(amt_paid,@curr_precision),0),
					amt_due	 					= ISNULL(ROUND(amt_due,@curr_precision),0),
					amt_paid_to_date 	= ISNULL(ROUND(amt_paid_to_date,@curr_precision),0),
					artrx_amt_due 		= ISNULL(ROUND(artrx_amt_due,@curr_precision),0),
					extended_price 		= ISNULL(ROUND(extended_price,@curr_precision),0),
					discount_amt 			= ISNULL(ROUND(discount_amt,@curr_precision),0)

	UPDATE	#ccarhdr_work
	SET	amt_paid = 	amt_paid_to_date,
			amt_due = artrx_amt_due
/*	
	update #ccarhdr_work 
	set contact_name = armaster_all.contact_name
	from armaster_all (nolock) 
	where armaster_all.customer_code = #ccarhdr_work.customer_code
	and	armaster_all.ship_to_code = #ccarhdr_work.ship_to_code
*/
	-- START v2.1
	--update #ccarhdr_work
	update a
	set 
		--carrier = routing, 
		carrier = isnull(v.ship_via_name,orders.routing),
		order_type = case 
			when user_category = 'ST' then 'Stock Order'
			when user_category = 'RX' then 'RX Order'
			else 'Stock Order'
		end,
	order_date = date_entered,
	a.who_entered = orders.who_entered,
	--so_invoice_date	= orders.invoice_date,
	so_caller = orders.user_def_fld2,
	--so_bill_to = orders.user_def_fld4,	-- v2.2
	so_promo_name = p.promo_name,
	-- START v3.3
	--list_amt = cv1.list_price, 
	-- v3.8 Start
	list_amt = CASE WHEN l.curr_price < 0 THEN l.curr_price ELSE
				CASE WHEN l.curr_price > cv1.list_price THEN l.curr_price ELSE cv1.list_price END END, 
	discount_amt =	CASE WHEN l.curr_price < 0 THEN 0 ELSE CASE WHEN l.curr_price > cv1.list_price THEN 0 
					ELSE CASE orders.type WHEN 'I' THEN (cv1.list_price - l.curr_price) + cv1.amt_disc  
					ELSE CASE l.discount WHEN 0 THEN (cv1.list_price - l.curr_price)   
					ELSE (cv1.list_price - l.curr_price) + cv1.amt_disc  
	END END END END,
	-- v3.8 End
	/*
	discount_amt = CASE orders.type WHEN 'I' THEN (cv1.list_price - l.curr_price) + cv1.amt_disc  
	   ELSE CASE l.discount WHEN 0 THEN (cv1.list_price - l.curr_price)   
	   ELSE (cv1.list_price - l.curr_price) + cv1.amt_disc  
	END END,
	*/
	-- END v3.3
	-- START v2.6
	location_code = LEFT(l.note,10)
	-- location_code = l.note -- v2.4     
	-- END v2.6
	-- END v2.1
	from #ccarhdr_work a 
	INNER JOIN orders (nolock) ON orders.order_no = left(a.order_ctrl_num, charindex('-',a.order_ctrl_num)-1)
						and orders.ext = right(a.order_ctrl_num,len (a.order_ctrl_num) - charindex('-',a.order_ctrl_num))
	LEFT JOIN dbo.arshipv v (nolock) on v.ship_via_code = orders.routing 
	INNER JOIN dbo.cvo_orders_all c (NOLOCK) ON orders.order_no = c.order_no AND orders.ext = c.ext
	LEFT JOIN dbo.cvo_promotions p (nolock) ON c.promo_id = p.promo_id AND c.promo_level = p.promo_level
	INNER JOIN dbo.cvo_ord_list cv1 (NOLOCK) ON c.order_no = cv1.order_no AND orders.ext = cv1.order_ext AND a.sequence_id = cv1.line_no
	INNER JOIN dbo.ord_list l (NOLOCK) ON cv1.order_no = l.order_no AND cv1.order_ext = l.order_ext AND cv1.line_no = l.line_no
	where 
	--orders.order_no = left(order_ctrl_num, charindex('-',order_ctrl_num)-1)
	--and orders.ext = right(order_ctrl_num,len (order_ctrl_num) - charindex('-',order_ctrl_num)) and
	charindex('-',a.order_ctrl_num) > 0



	-- START v2.1
	--Get Terms description
	UPDATE
		a
	SET
		terms_code = t.terms_desc
	FROM
		#ccarhdr_work a
	INNER JOIN
		dbo.arterms t (nolock) 
	on 
		t.terms_code = a.terms_code
	-- END v2.1

	-- START v2.2 
	UPDATE 
		#ccarhdr_work
	SET 
		o_user_def_fld9 = 0

	-- Add Buying Group Name    
	UPDATE 
		a 
	SET 
		so_bill_to = IsNull(ac.customer_name,' '),
		o_user_def_fld9 = CASE ac.addr_sort1 WHEN 'Buying Group' THEN 1 ELSE o_user_def_fld9 END,
		o_user_def_fld4 = ISNULL(ac.alt_location_code,'1') -- v3.1
	FROM 
		#ccarhdr_work a
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
	-- v3.1 AND ISNULL(ac.alt_location_code,'1') = '1' -- v2.8 v3.0


	-- If this is a buying group then no discount
	UPDATE
		#ccarhdr_work
	SET
		discount_amt = 0,
		unit_price = list_amt,
		extended_price = list_amt * ISNULL(qty_shipped,0)
	WHERE
		ISNULL(o_user_def_fld9,1) = 1 -- v3.0
	AND	ISNULL(o_user_def_fld4,1) = 1

-- v3.1 Start
	update a
	set
	-- START v3.4 
	-- v3.8 Start
	list_amt = CASE WHEN l.curr_price < 0 THEN l.curr_price ELSE CASE WHEN l.curr_price > cv1.list_price THEN l.curr_price ELSE cv1.orig_list_price END END,
	--list_amt = cv1.orig_list_price, -- v3.2 CASE WHEN l.curr_price = l.temp_price THEN cv1.list_price ELSE l.temp_price END,
	discount_amt = CASE WHEN l.curr_price < 0 THEN 0 ELSE CASE WHEN l.curr_price > cv1.list_price THEN 0 ELSE (cv1.orig_list_price - l.curr_price) END END 
	--discount_amt = (cv1.orig_list_price - l.curr_price) -- v3.2 CASE WHEN l.curr_price = l.temp_price THEN (cv1.orig_list_price - l.curr_price) 
								-- v3.2 ELSE (cv1.orig_list_price - l.curr_price) END
	-- v3.8 End
	-- END v3.4
	from #ccarhdr_work a 
	INNER JOIN orders (nolock) ON orders.order_no = left(a.order_ctrl_num, charindex('-',a.order_ctrl_num)-1)
						and orders.ext = right(a.order_ctrl_num,len (a.order_ctrl_num) - charindex('-',a.order_ctrl_num))
	LEFT JOIN dbo.arshipv v (nolock) on v.ship_via_code = orders.routing 
	INNER JOIN dbo.cvo_orders_all c (NOLOCK) ON orders.order_no = c.order_no AND orders.ext = c.ext
	LEFT JOIN dbo.cvo_promotions p (nolock) ON c.promo_id = p.promo_id AND c.promo_level = p.promo_level
	INNER JOIN dbo.cvo_ord_list cv1 (NOLOCK) ON c.order_no = cv1.order_no AND orders.ext = cv1.order_ext AND a.sequence_id = cv1.line_no
	INNER JOIN dbo.ord_list l (NOLOCK) ON cv1.order_no = l.order_no AND cv1.order_ext = l.order_ext AND cv1.line_no = l.line_no
	where charindex('-',a.order_ctrl_num) > 0
	AND	ISNULL(a.o_user_def_fld9,1) = 1 -- v3.0
	AND	ISNULL(a.o_user_def_fld4,1) = 0


-- v3.1 End 

	-- Invoice date
	UPDATE 
		a  
	SET  
		so_invoice_date = c.inv_date  
	FROM 
		#ccarhdr_work a  
	INNER JOIN 
		cvo_order_invoice c (NOLOCK) 
	ON 
		c.order_no = LEFT(a.order_ctrl_num, CHARINDEX('-',a.order_ctrl_num)-1)
		AND c.order_ext = RIGHT(a.order_ctrl_num,len (a.order_ctrl_num) - CHARINDEX('-',a.order_ctrl_num))   
	WHERE 
		c.inv_date IS NOT NULL  
		AND CHARINDEX('-',a.order_ctrl_num) > 0 
	-- END v2.2 
	
	-- v2.5 Start
	UPDATE 
		a  
	SET  
		invoice_note = b.invoice_note
	FROM 
		#ccarhdr_work a  
	INNER JOIN 
		cvo_orders_all b (NOLOCK) 
	ON 
		b.order_no = LEFT(a.order_ctrl_num, CHARINDEX('-',a.order_ctrl_num)-1)
	AND b.ext = RIGHT(a.order_ctrl_num,len (a.order_ctrl_num) - CHARINDEX('-',a.order_ctrl_num))  
-- tag - 4/15/2013
	WHERE 
		b.invoice_note IS NOT NULL  
		AND CHARINDEX('-',a.order_ctrl_num) > 0   
-- tag - end 
	-- v2.5 End

	-- v3.5 Start
	UPDATE	a  
	SET		invoice_note = c.comment_line + CASE WHEN ISNULL(a.invoice_note,'') > '' THEN ' \ ' ELSE '' END + ISNULL(a.invoice_note,'')
	FROM	#ccarhdr_work a  
	JOIN	arcust b (NOLOCK)
	ON		a.customer_code = b.customer_code
	JOIN	arcommnt c (NOLOCK)
	ON		b.inv_comment_code = c.comment_code	
	-- v3.5 End

--	update #ccarhdr_work
--	set bg_name = a.customer_name
--	from cvo_orders_all o (nolock), arcust a (nolock)
--	where order_no = left(order_ctrl_num, charindex('-',order_ctrl_num)-1)
--	and ext = right(order_ctrl_num,len (order_ctrl_num) - charindex('-',order_ctrl_num))
--	and charindex('-',order_ctrl_num) > 0
--	and o.buying_group = a.customer_code
--
	update #ccarhdr_work
	set #ccarhdr_work.style = inv_master_add.field_2
	from inv_master_add (nolock)
	where inv_master_add.part_no = #ccarhdr_work.item_code


	-- v2.3 Start
	CREATE TABLE #part_type (
		part_type	varchar(20),
		printorder	int)

	INSERT	#part_type
	SELECT	'FRAME', 0
	INSERT	#part_type
	SELECT	'SUN', 0

	INSERT	#part_type
	SELECT	kys, 1
	FROM	part_type (NOLOCK)
	WHERE	kys NOT IN ('FRAME','SUN')
	-- v2.3 End	

	-- v2.7 Start
	UPDATE	a
	SET		so_bill_to = dbo.f_cvo_get_buying_group_name(dbo.f_cvo_get_buying_group(a.customer_code, CONVERT(varchar(10),DATEADD(DAY, a.date_doc - 693596, '01/01/1900'),121)))
	FROM	#ccarhdr_work a
	-- v2.7 End

	-- v2.9 Start
	UPDATE	a
	SET		so_bill_to = dbo.f_cvo_get_buying_group_name(b.buying_group)
	FROM	#ccarhdr_work a
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_ctrl_num = (CAST(b.order_no AS varchar(20)) + '-' + CAST(b.ext AS varchar(20)))
	WHERE	b.buying_group <> a.so_bill_to
	-- v2.9 End

	-- v4.2 Start
	IF NOT EXISTS ( SELECT 1 FROM cc_trx_table WHERE my_id = @my_id AND CHARINDEX('-',trx_num) > 0)
	BEGIN
		-- v3.6 Start
		UPDATE	a
		SET		unit_price = 0, 
				--list_amt = 0, -- v3.7
				discount_amt = list_amt, -- v3.7
				extended_price = 0
		FROM	#ccarhdr_work a
		JOIN	cvo_orders_all b (NOLOCK)
		ON		a.order_ctrl_num = (CAST(b.order_no AS varchar(20)) + '-' + CAST(b.ext AS varchar(20)))
		WHERE	ISNULL(b.buying_group,'') > ''
		AND		a.discount_prc = 100

		UPDATE	a
		SET		unit_price = 0
		FROM	#ccarhdr_work a
		JOIN	cvo_orders_all b (NOLOCK)
		ON		a.order_ctrl_num = (CAST(b.order_no AS varchar(20)) + '-' + CAST(b.ext AS varchar(20)))
		WHERE	ISNULL(b.buying_group,'') = ''
		AND		a.discount_prc = 100
		-- v3.6 End

		-- 3.9 Start
		UPDATE	#ccarhdr_work
		SET		extended_price = list_amt - discount_amt
		-- v3.9 End

		-- v4.0 Start
		UPDATE	a
		SET		list_amt = extended_price,
				discount_amt = 0
		FROM	#ccarhdr_work a
		JOIN	ord_list b (NOLOCK)
		ON		a.order_ctrl_num = CAST(b.order_no as varchar(10)) + '-' + CAST(b.order_ext as varchar(10))
		AND		SUBSTRING(doc_desc,CHARINDEX(' ',doc_desc)+1,10) = CAST(b.line_no as varchar(10))
		WHERE	LEFT(a.doc_desc,3) = 'SO:'
		AND		b.price_type IN ('Q','Y')

		-- v4.0 End

		-- v4.1 Start
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
				qty_shipped,
				trx_ctrl_num
		FROM	#ccarhdr_work
		WHERE	LEFT(doc_desc,3) = 'SO:'

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

			UPDATE	#ccarhdr_work
			SET		list_amt = @c_gross_price,
					discount_amt = @c_discount_amount,
					unit_price = @c_net_price,
					extended_price = @c_ext_net_price
			WHERE	trx_ctrl_num = @trx_ctrl_num
			AND		sequence_id = @c_line_no

		END

		DROP TABLE #inv_pricing
		-- v4.1 End

	END
	ELSE
	BEGIN
		UPDATE	#ccarhdr_work
		SET		qty_shipped = 1,
				list_amt = 0,
				discount_amt = 0,
				unit_price = 0
		WHERE	CHARINDEX('-',doc_ctrl_num) > 0   
	END
	-- v4.2 End

	SELECT	a.trx_ctrl_num,
			a.doc_ctrl_num,
			a.customer_code,
			a.customer_addr1,
			a.customer_addr2,
			a.customer_addr3,
			a.customer_addr4,
			a.customer_addr5,
			a.customer_addr6,
			a.ship_to_code,
			a.ship_to_addr1,
			a.ship_to_addr2,
			a.ship_to_addr3,
			a.ship_to_addr4,
			a.ship_to_addr5,
			a.ship_to_addr6,
			a.cust_po_num,
			a.order_ctrl_num,	
			a.nat_cur_code,
			a.posting_code,
			a.tax_code,
			a.fin_chg_code,
			DateDoc =	CASE a.date_doc	WHEN 0 THEN 0	
						ELSE	CONVERT(smalldatetime, DATEADD(dd, a.date_doc - 639906, '1/1/1753')) END, 
			DateApplied = CASE a.date_applied	WHEN 0 THEN 0
						  ELSE	CONVERT(smalldatetime, DATEADD(dd, a.date_applied - 639906, '1/1/1753')) END, 	
			a.terms_code,
			DateDue = CASE a.date_due	WHEN 0 THEN 0
					  ELSE	CONVERT(smalldatetime, DATEADD(dd, a.date_due - 639906, '1/1/1753')) END,	
			DateAging = CASE a.date_aging WHEN 0 THEN 0
						ELSE CONVERT(smalldatetime, DATEADD(dd, a.date_aging - 639906, '1/1/1753'))	END, 	
			DateRequired = CASE a.date_required	WHEN 0 THEN 0
						   ELSE	CONVERT(smalldatetime, DATEADD(dd, a.date_required - 639906, '1/1/1753')) END,	
			DateShipped = CASE a.date_shipped	WHEN 0 THEN 0
						  ELSE	CONVERT(smalldatetime, DATEADD(dd, a.date_shipped - 639906, '1/1/1753')) END, 	
			a.freight_code,
			a.dest_zone_code,
			a.fob_code,
			a.salesperson_code,
			a.territory_code,
			a.price_code,
			a.recurring_code,
			a.apply_to_num,
			a.comment_code,
			a.comment_line,
			a.doc_desc,
			a.amt_gross,
			a.amt_discount,
			a.amt_freight,
			a.amt_tax,
			a.amt_net,
			a.amt_paid,
			a.amt_due,
			a.amt_paid_to_date,
			a.artrx_amt_due,
			a.location_code,
			a.item_code,
			a.qty_shipped,
			a.unit_code,
			a.unit_price,
			a.line_desc,
			a.qty_ordered,
			a.det_tax_code,
			a.extended_price,
			a.gl_rev_acct,
			a.reference_code,
			a.weight	,
			a.discount_amt,
			a.discount_prc,
			a.sequence_id,
			r.company_name,
			r.addr1,
			r.addr2,
			r.addr3,
			r.addr4,
			r.addr5,
			r.addr6,
			a.symbol,
			a.symbol_placement,
			a.hdr_org_id,
			a.det_org_id,
			a.who_entered,	
			a.style,
			a.carrier, 
			a.order_type,
			a.order_date,
			a.bg_name,
			a.so_invoice_date,
			a.so_caller,
			a.so_bill_to,
			a.so_promo_name,
			a.list_amt,
			a.o_user_def_fld9,	-- v2.2
			a.invoice_note -- v2.5
	FROM 		#ccarhdr_work a
	CROSS JOIN	arco  r --glco	-- v2.1
	LEFT JOIN -- v2.3 Start
	inv_master b (NOLOCK)
	ON 
	a.item_code = b.part_no
	LEFT JOIN
	#part_type c
	ON
	b.type_code = c.part_type
	ORDER BY 
	a.doc_ctrl_num, ISNULL(c.printorder,3), a.item_code
	-- v2.3 End

-- v2.3	FROM 		#ccarhdr_work, arco --glco	-- v2.1

DELETE cc_trx_table WHERE my_id = @my_id
DROP TABLE	#ccarhdr_work
DROP TABLE #part_type -- v2.3

SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[cc_invoice_report_sp] TO [public]
GO
