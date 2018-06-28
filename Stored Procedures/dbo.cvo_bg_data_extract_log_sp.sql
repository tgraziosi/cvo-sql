SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
-- exec cvo_bg_data_extract_log_sp ' Where parent like ''%000655%'' AND xinv_date BETWEEN 736695 AND 736846'
-- exec cvo_bg_data_extract_log_sp ' Where parent BETWEEN ''000567'' AND ''000655'''
-- exec cvo_bg_data_extract_log_sp ' Where parent BETWEEN ''000567'' AND ''000655'' AND xinv_date BETWEEN 736695 AND 736842'
-- exec cvo_bg_data_extract_log_sp ' Where parent BETWEEN ''000567'' AND ''000655'' AND xinv_date=736695'
-- exec cvo_bg_data_extract_log_sp ' Where xinv_date=736695'
-- exec cvo_bg_data_extract_log_sp ' Where parent like ''%000655%'' AND parent_name like ''%the professional edge%'' AND xinv_date BETWEEN 736695 AND 736846'

CREATE PROC [dbo].[cvo_bg_data_extract_log_sp] @whereclause varchar(1024)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE @date_from		varchar(10),
			@date_to		varchar(10),
			@jul_from		int,
			@jul_to			int,
			@start_count	int,
			@end_count		int,
			@test_string	varchar(1024),
			@test_string2	varchar(1024),
			@bg_start		varchar(10),
			@bg_end			varchar(10)

	-- PROCESS WHERECLAUSE
	IF (CHARINDEX ('parent',@whereclause) <> 0)  
	BEGIN  
		SET	@start_count = CHARINDEX ('parent',@whereclause)  
		SET @test_string = SUBSTRING(@whereclause,@start_count,LEN(@whereclause) - @start_count)
		SET @test_string2 = SUBSTRING(@whereclause,@start_count,15)

		IF (CHARINDEX ('like',@test_string2) > 0)
		BEGIN
			SET @bg_start = SUBSTRING(@test_string, 15, 6)
			SET @bg_end = @bg_start
		END
		IF (CHARINDEX ('between',@test_string2) > 0)
		BEGIN
			SET @bg_start = SUBSTRING(@test_string, 17, 6)
			SET @bg_end = SUBSTRING(@test_string, 30, 6)
		END
	END
	ELSE
	BEGIN
		SELECT	@bg_start = MIN(customer_code)
		FROM	armaster_all (NOLOCK)
		WHERE	addr_sort1 = 'Buying Group'

		SELECT	@bg_end = MAX(customer_code)
		FROM	armaster_all (NOLOCK)
		WHERE	addr_sort1 = 'Buying Group'
	END

	IF (CHARINDEX ('xinv_date',@whereclause) <> 0)  
	BEGIN  
		SET	@start_count = CHARINDEX ('xinv_date',@whereclause)  
		SET @test_string = SUBSTRING(@whereclause,@start_count,LEN(@whereclause) - @start_count + 1)
		SET @test_string2 = SUBSTRING(@whereclause,@start_count,18)

		IF (CHARINDEX ('between',@test_string2) > 0)
		BEGIN
			SET @jul_from = SUBSTRING(@test_string,CHARINDEX('BETWEEN ',@test_string)+8,6)
			SET @jul_to = SUBSTRING(@test_string,CHARINDEX('AND ',@test_string)+4,6)
		END
		ELSE
		BEGIN
			SET @jul_from = SUBSTRING(@test_string,11,6)
			SET @jul_to = SUBSTRING(@test_string,11,6)
		END
	END
	ELSE
	BEGIN
		SET @date_from = CONVERT(varchar(10), DATEADD(m,-1, GETDATE()),101)  
		SET	@date_to = CONVERT(varchar(10), GETDATE(),101)  
		SET @jul_from = DATEDIFF(dd, '1/1/1753', @date_from) + 639906   
		SET @jul_to = DATEDIFF(dd, '1/1/1753', @date_to) + 639906 
	END

	-- WORKING TABLES
	CREATE TABLE #data_extract_raw (
		parent			varchar(10),
		parent_name		varchar(40),
		cust_code		varchar(10),
		customer_name	varchar(40),
		doc_ctrl_num	varchar(16),
		trm				int,
		type			varchar(20),
		inv_date		varchar(12),
		inv_tot			float,
		mer_tot			float,
		net_amt			float,
		freight			float,
		tax				float,
		mer_disc		float,
		inv_due			float,
		disc_perc		float,
		date_due_month	varchar(10),
		xinv_date		int,
		line_no			int,
		part_no			varchar(30) NULL,
		description		varchar(255) NULL,
		shipped			decimal(20,8) NULL,
		rec_type		int)

	CREATE TABLE #order_data_extract_raw (
		parent			varchar(10),
		parent_name		varchar(40),
		cust_code		varchar(10),
		customer_name	varchar(40),
		doc_ctrl_num	varchar(16),
		trm				int,
		type			varchar(20),
		inv_date		varchar(12),
		inv_tot			float,
		mer_tot			float,
		net_amt			float,
		freight			float,
		tax				float,
		mer_disc		float,
		inv_due			float,
		disc_perc		float,
		date_due_month	varchar(10),
		xinv_date		int,
		promo_id		varchar(20) NULL,
		promo_level		varchar(30) NULL,
		is_quoted		char(1) NULL DEFAULT('N'),
		quoted_price	float NULL,
		part_no			varchar(30) NULL,
		line_no			int NULL,
		description		varchar(255) NULL,
		shipped			decimal(20,8) NULL,
		category		varchar(40) NULL,
		style			varchar(40) NULL,
		res_type		varchar(40) NULL,
		net_only		char(1) NULL DEFAULT ('N'),
		is_list_price	char(1) NULL DEFAULT ('N'),
		order_date		datetime) -- v1.2

	-- PROCESSING
	INSERT	#order_data_extract_raw (parent, parent_name, cust_code, customer_name, doc_ctrl_num, trm, type, inv_date,
		inv_tot, mer_tot, net_amt, freight, tax, mer_disc, inv_due, disc_perc, date_due_month, xinv_date, promo_id, promo_level, part_no, 
		category, style, res_type, line_no, description, shipped, order_date) -- v1.2
	SELECT	cv.buying_group,
			bg.customer_name,
			h.cust_code,  
			b.customer_name,
			i.doc_ctrl_num,  
			t.days_due,
			'Invoice',
			CONVERT(VARCHAR(12),DATEADD(dd,(x.date_doc)-639906,'1/1/1753'),101),
			ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2),
			ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2),
			0,
			0,
			0,
			d.Shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2),
			d.Shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2),
			CASE WHEN (CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) = 0 THEN 0
				WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 
				ELSE p.disc_perc END) <> 0 THEN ROUND(1 - ((d.shipped*ROUND(curr_price-(curr_price*((CASE WHEN d.curr_price > c.list_price 
				THEN 0 ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) END)/100)),2)) /
				(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) ), 2)
				WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) = 0 THEN 
				(CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100 
				ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) END,
			RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,(x.date_due)-639906,'1/1/1753'),101),4) + '/'+  
			LEFT(CONVERT(VARCHAR(12),DATEADD(dd,(x.date_due)-639906,'1/1/1753'),101),2),  
			x.date_doc,
			cv.promo_id,
			cv.promo_level,
			d.part_no,
			iv.category,
			iva.field_2, -- v1.2 Switch
			iv.type_code, -- v1.2 Switch
			d.line_no,
			d.description,
			d.shipped,
			CAST(CONVERT(varchar(10),h.date_entered,120) as datetime) -- v1.2
	FROM	cvo_orders_all cv (NOLOCK)
	JOIN	orders_all h (NOLOCK) ON h.order_no = cv.order_no AND h.ext = cv.ext
	JOIN	orders_invoice i (NOLOCK) ON h.order_no =i.order_no AND h.ext = i.order_ext  
	JOIN	arterms t (NOLOCK) ON h.terms = t.terms_code  
	JOIN	artrx_all x (NOLOCK) ON i.doc_ctrl_num = x.doc_ctrl_num  
	LEFT JOIN arcust bg (NOLOCK) ON bg.customer_code = cv.buying_group
	JOIN	arcust B (NOLOCK)ON h.cust_code = b.customer_code  
	JOIN	ord_list d (NOLOCK) ON h.order_no = d.order_no AND h.ext = d.order_ext  
	JOIN	Cvo_ord_list c (NOLOCK) ON  d.order_no =c.order_no AND d.order_ext = c.order_ext AND d.line_no = c.line_no  
	JOIN	CVO_disc_percent p (NOLOCK) ON d.order_no = p.order_no AND d.order_ext = p.order_ext AND d.line_no = p.line_no
	JOIN	inv_master iv (NOLOCK) ON d.part_no = iv.part_no
	JOIN	inv_master_add iva (NOLOCK) on d.part_no = iva.part_no
	WHERE	cv.buying_group > ''
	AND		x.date_doc BETWEEN  @jul_from AND @jul_to 
	AND		cv.buying_group BETWEEN @bg_start AND @bg_end  
	AND		d.shipped > 0  
	AND		h.type = 'I'  
	AND		h.terms NOT LIKE 'INS%'   
	AND		x.void_flag <> 1

	--INSERT	#order_data_extract_raw (parent, parent_name, cust_code, customer_name, doc_ctrl_num, trm, type, inv_date,
	--	inv_tot, mer_tot, net_amt, freight, tax, mer_disc, inv_due, disc_perc, date_due_month, xinv_date, promo_id, promo_level, part_no, 
	--	category, style, res_type, line_no, description, shipped, order_date)
	UNION ALL
	SELECT	cv.buying_group,
			bgc.customer_name,
			o.cust_code,
			b.customer_name,
			h.doc_ctrl_num,
			z.installment_days,
			CASE WHEN o.type = 'I' THEN 'Invoice' ELSE 'Credit' END,
			CONVERT(varchar(12), DATEADD(dd, h.date_doc - 639906, '1/1/1753'),101),
			(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped) * (z.installment_prc/100),2)),
			(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped) * (z.installment_prc/100),2)),
			0,
			0,
			0,
			(d.Shipped * ROUND((d.curr_price - (d.curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100))) * (z.installment_prc/100),2)),
			(d.Shipped * ROUND((d.curr_price - (d.curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100))) * (z.installment_prc/100),2)),
			CASE WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 
				THEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100 ELSE (CASE WHEN d.curr_price > c.list_price 
				THEN 0 ELSE p.disc_perc END) END,
			CASE h.date_due WHEN 0 THEN
				SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),7,4) + '/' + SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),1,2)
				ELSE SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),7,4)	+ '/' + SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),1,2) END,
			h.date_doc,
			cv.promo_id,
			cv.promo_level,
			d.part_no,
			iv.category,
			iva.field_2,
			iv.type_code,
			d.line_no,
			d.description,
			d.shipped,
			CAST(CONVERT(varchar(10),o.date_entered,120) as datetime)
	FROM	artrx_all h (NOLOCK)
	JOIN	orders_invoice i (NOLOCK) 
	ON		i.doc_ctrl_num = LEFT(h.doc_ctrl_num, CHARINDEX('-',h.doc_ctrl_num)-1)
	JOIN	orders_all o (NOLOCK) 
	ON		o.order_no = i.order_no 
	AND		o.ext = i.order_ext
	JOIN	cvo_orders_all cv (NOLOCK)
	ON		o.order_no = cv.order_no 
	AND		o.ext = cv.ext
	JOIN	ord_list d (NOLOCK) 
	ON		o.order_no = d.order_no 
	AND		o.ext = d.order_ext
	LEFT JOIN arnarel r (NOLOCK) 
	ON		o.cust_code = r.child
	LEFT JOIN arcust m (NOLOCK) 
	ON		r.parent = m.customer_code
	JOIN	arcust b (NOLOCK) 
	ON		o.cust_code = b.customer_code
	JOIN	cvo_ord_list c (NOLOCK) 
	ON		d.order_no = c.order_no 
	AND		d.order_ext = c.order_ext 
	AND		d.line_no = c.line_no
	JOIN	cvo_disc_percent p (NOLOCK) 
	ON		d.order_no = p.order_no 
	AND		d.order_ext = p.order_ext 
	AND		d.line_no = p.line_no
	JOIN	cvo_artermsd_installment z (NOLOCK) 
	ON		h.terms_code = z.terms_code 
	AND		CONVERT(int,RIGHT(h.doc_ctrl_num,1)) = z.sequence_id
	JOIN	inv_master iv (NOLOCK) ON d.part_no = iv.part_no
	JOIN	inv_master_add iva (NOLOCK) on d.part_no = iva.part_no
	JOIN	arcust bgc (NOLOCK) ON cv.buying_group = bgc.customer_code
	WHERE	d.shipped > 0
	AND		h.date_doc BETWEEN  @jul_from AND @jul_to  
	AND		cv.buying_group BETWEEN @bg_start AND @bg_end 
	AND		o.type = 'I'
	AND		LEFT(h.terms_code,3) = 'INS' 
	AND		h.trx_type = 2031
	AND		LEFT(h.doc_ctrl_num,3) <> 'FIN' 
	AND		LEFT(h.doc_ctrl_num,2) <> 'CB' 
	AND		h.void_flag <> 1			
	AND		cv.buying_group > '' 
	CREATE NONCLUSTERED INDEX cvo_bg_data_extract_idx ON #order_data_extract_raw (cust_code, part_no,  res_type, style) INCLUDE (order_date)

	CREATE NONCLUSTERED INDEX cvo_bg_data_extract_idx2 ON #order_data_extract_raw (is_quoted) include (cust_code, part_no, res_type,  net_only, order_date)

	CREATE NONCLUSTERED INDEX cvo_bg_data_extract_promo_idx ON #order_data_extract_raw (promo_id, promo_level) 

	CREATE NONCLUSTERED INDEX cvo_bg_list ON #order_data_extract_raw (is_list_price, net_only)

	-- Update for contract pricing
	UPDATE	a
	SET		is_quoted = 'Y',
			quoted_price = b.rate,
			net_only = b.net_only			
	FROM	#order_data_extract_raw a
	JOIN	c_quote b (NOLOCK)
	ON		a.cust_code = b.customer_key		
	AND		a.part_no = b.item
	AND		b.start_date <= a.order_date
	AND		b.date_expires >= a.order_date
	AND		b.res_type = a.res_type 
	AND		b.style = a.style


	-- Customer and Item Pricing with style only
	UPDATE	a
	SET		is_quoted = 'Y',
			quoted_price = b.rate,
			net_only = b.net_only			
	FROM	#order_data_extract_raw a
	JOIN	c_quote b (NOLOCK)
	ON		a.cust_code = b.customer_key		
	AND		a.part_no = b.item
	AND		b.start_date <= a.order_date
	AND		b.date_expires >= a.order_date
	AND		b.res_type = a.res_type 
	WHERE	a.is_quoted = 'N'
	AND		ISNULL(b.style,'') = ''

	-- Customer and Item Pricing only
	UPDATE	a
	SET		is_quoted = 'Y',
			quoted_price = b.rate,
			net_only = b.net_only			
	FROM	#order_data_extract_raw a
	JOIN	c_quote b (NOLOCK)
	ON		a.cust_code = b.customer_key		
	AND		a.part_no = b.item
	AND		b.start_date <= a.order_date
	AND		b.date_expires >= a.order_date
	WHERE	a.is_quoted = 'N'
	AND		ISNULL(b.res_type,'') = ''
	AND		ISNULL(b.style,'') = ''

	-- Customer and Category Pricing with res_type and style
	UPDATE	a
	SET		is_quoted = 'Y',
			quoted_price = b.rate,
			net_only = b.net_only			
	FROM	#order_data_extract_raw a
	JOIN	c_quote b (NOLOCK)
	ON		a.cust_code = b.customer_key		
	AND		a.category = b.item
	AND		b.start_date <= a.order_date
	AND		b.date_expires >= a.order_date
	AND		a.res_type = b.res_type
	AND		a.style = b.style
	WHERE	a.is_quoted = 'N'

	-- Customer and Category Pricing with res_type only
	UPDATE	a
	SET		is_quoted = 'Y',
			quoted_price = b.rate,
			net_only = b.net_only			
	FROM	#order_data_extract_raw a
	JOIN	c_quote b (NOLOCK)
	ON		a.cust_code = b.customer_key		
	AND		a.category = b.item
	AND		b.start_date <= a.order_date
	AND		b.date_expires >= a.order_date
	AND		a.res_type = b.res_type
	WHERE	a.is_quoted = 'N'
	AND		ISNULL(b.style,'') = ''

	-- Customer and Category Pricing only
	UPDATE	a
	SET		is_quoted = 'Y',
			quoted_price = b.rate,
			net_only = b.net_only			
	FROM	#order_data_extract_raw a
	JOIN	c_quote b (NOLOCK)
	ON		a.cust_code = b.customer_key		
	AND		a.category = b.item
	AND		b.start_date <= a.order_date
	AND		b.date_expires >= a.order_date
	WHERE	a.is_quoted = 'N'
	AND		ISNULL(b.res_type,'') = ''
	AND		ISNULL(b.style,'') = ''

	UPDATE	a
	SET		is_list_price = CASE WHEN b.list = 0 THEN 'N' ELSE 'Y' END
	FROM	#order_data_extract_raw a
	JOIN	cvo_promo_discount_vw b
	ON		a.promo_id = b.promo_id
	AND		a.promo_level = b.promo_level

	UPDATE	#order_data_extract_raw
	SET		inv_tot = inv_due,
			mer_tot = inv_due,
			disc_perc = 0
	WHERE	(is_list_price = 'Y' OR net_only = 'Y')

	-- Order Lines  
	INSERT	#data_extract_raw (parent, parent_name, cust_code, customer_name, doc_ctrl_num, trm, type, inv_date,
		inv_tot, mer_tot, net_amt, freight, tax, mer_disc, inv_due, disc_perc, date_due_month, xinv_date, line_no, 
		part_no, description, shipped, rec_type)
	SELECT	parent, 
			parent_name, 
			cust_code, 
			customer_name, 
			doc_ctrl_num, 
			trm, 
			type, 
			inv_date,
			SUM(inv_tot), 
			SUM(mer_tot), 
			0, 
			0, 
			0, 
			SUM(mer_disc), 
			SUM(inv_due), 
			disc_perc, 
			date_due_month, 
			xinv_date,
			line_no,
			part_no,
			description,
			shipped,
			1
	FROM	#order_data_extract_raw
	GROUP BY parent, parent_name, cust_code, customer_name, doc_ctrl_num, trm, type, inv_date,
			disc_perc, date_due_month, xinv_date, line_no, part_no, description, shipped

	UNION ALL

	-- CR Order Lines  
	SELECT	cv.buying_group,
			bg.customer_name,
			h.cust_code,  
			b.customer_name,
			i.doc_ctrl_num,  
			t.days_due,
			'Credit',
			CONVERT(VARCHAR(12),DATEADD(dd,(x.date_doc)-639906,'1/1/1753'),101),
			SUM(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.cr_shipped),2)) * -1,
			SUM(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.cr_shipped),2)) * -1,
			0,
			0,
			0,
			SUM(d.cr_shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1,
			SUM(d.cr_shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1,
			CASE WHEN SUM(CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) = 0 THEN 0 
				WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) <> 0 THEN -- two levels of discount in play
				ROUND(1 - (SUM(d.cr_shipped*ROUND(curr_price-(curr_price*((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) END)/100)),2)) 
				/ SUM(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.cr_shipped),2)) ), 2)
				WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) = 0 THEN 
				(CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) /100 
				ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) END,
			RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_due)-639906,'1/1/1753'),101),4) + '/'+  
			LEFT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_due)-639906,'1/1/1753'),101),2),  
			x.date_doc,
			d.line_no,
			d.part_no,
			d.description,
			d.cr_shipped,
			1
	FROM	cvo_orders_all cv (NOLOCK)
	JOIN	orders_all h (NOLOCK) ON h.order_no = cv.order_no AND h.ext = cv.ext
	JOIN	orders_invoice i (NOLOCK) ON h.order_no =i.order_no AND h.ext = i.order_ext  
	JOIN	artrx_all x (NOLOCK) ON i.doc_ctrl_num = x.doc_ctrl_num AND x.trx_type = 2032  
	JOIN	arcust bg (NOLOCK) ON bg.customer_code = cv.buying_group  
	JOIN	arcust B (NOLOCK)ON h.cust_code = b.customer_code  
	JOIN	ord_list d (NOLOCK) ON h.order_no = d.order_no AND h.ext = d.order_ext  
	JOIN	Cvo_ord_list c (NOLOCK) ON  d.order_no =c.order_no AND d.order_ext = c.order_ext AND d.line_no = c.line_no  
	JOIN	CVO_disc_percent p (NOLOCK) ON d.order_no = p.order_no AND d.order_ext = p.order_ext AND d.line_no = p.line_no  
	JOIN	arterms t (NOLOCK) ON h.terms = t.terms_code  
	WHERE	cv.buying_group > ''
	AND		x.date_doc BETWEEN  @jul_from AND @jul_to 
	AND		cv.buying_group BETWEEN @bg_start AND @bg_end  
	AND		d.cr_shipped > 0  
	AND		h.type = 'C'  
	AND		h.terms NOT LIKE 'INS%'   
	AND		x.void_flag <> 1
	AND		d.part_no <> 'Credit Return Fee'
	GROUP BY cv.buying_group, bg.customer_name, h.cust_code, b.customer_name, i.doc_ctrl_num, t.days_due, x.date_due, h.type,
			x.date_doc, (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END), (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END),
			d.line_no, d.part_no, d.description, d.cr_shipped  

	UNION ALL

	-- CR order lines - debit promos 
	SELECT	cv.buying_group,
			bg.customer_name,
			h.cust_code,  
			b.customer_name,
			xx.doc_ctrl_num,  
			t.days_due,
			'Credit',
			CONVERT(VARCHAR(12),DATEADD(d,x.date_doc-639906,'1/1/1753'),101),
			SUM(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) * -1,
			SUM(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) * -1,
			0,
			0,
			0,
			CASE WHEN SUM(dd.credit_amount) <= SUM(d.shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1))
				THEN SUM(dd.credit_amount) * -1 ELSE
				SUM(d.shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1 END,
			CASE WHEN SUM(dd.credit_amount) <= SUM(d.shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) 
				THEN SUM(dd.credit_amount) * -1 ELSE
				SUM(d.shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1 END,
			CASE WHEN SUM(CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) = 0 THEN 0
				WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) <> 0 THEN -- two levels of discount in play
				ROUND(1 - (SUM(d.shipped*ROUND(curr_price-(curr_price*((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100)),2)) 
				/ SUM(ROUND(((CASE WHEN d.curr_price > c.list_price THEN d.curr_price ELSE c.list_price END) * d.shipped),2)) ), 2)
			WHEN (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) > 0 AND (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) = 0 THEN 
			(CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END)/100 
			ELSE (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) END,
			CASE MAX(x.date_due) WHEN 0 THEN
				RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_doc)-639906,'1/1/1753'),101),4) + '/'+    
				LEFT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_doc)-639906,'1/1/1753'),101),2) 
				ELSE RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_due)-639906,'1/1/1753'),101),4) + '/'+    
				LEFT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_due)-639906,'1/1/1753'),101),2) END,
			x.date_doc,
			d.line_no,
			d.part_no,
			d.description,
			d.shipped,
			3
	FROM	cvo_debit_promo_customer_det dd 
	INNER JOIN ord_list d (NOLOCK) ON d.order_no = dd.order_no AND d.order_ext = dd.ext AND d.line_no = dd.line_no
	INNER JOIN orders_all h (NOLOCK)  ON h.order_no = dd.order_no AND h.ext = dd.ext
	JOIN	cvo_orders_all cv (NOLOCK) ON h.order_no = cv.order_no AND h.ext = cv.ext
	JOIN	artrx_all xx (nolock) ON dd.trx_ctrl_num = xx.trx_ctrl_num
	JOIN	orders_invoice i (NOLOCK) ON h.order_no =i.order_no AND h.ext = i.order_ext  
	JOIN	artrx_all x (NOLOCK) ON i.trx_ctrl_num = x.trx_ctrl_num   
	JOIN	arcust bg (NOLOCK) ON bg.customer_code = cv.buying_group
	JOIN	arcust B (NOLOCK)ON h.cust_code = b.customer_code  
	JOIN	Cvo_ord_list c (NOLOCK) ON  d.order_no =c.order_no AND d.order_ext = c.order_ext AND d.line_no = c.line_no  
	JOIN	CVO_disc_percent p (NOLOCK) ON d.order_no = p.order_no AND d.order_ext = p.order_ext AND d.line_no = p.line_no  
	JOIN	arterms t (NOLOCK) ON h.terms = t.terms_code  
	WHERE	cv.buying_group > ''
	AND		x.date_doc BETWEEN  @jul_from AND @jul_to 
	AND		cv.buying_group BETWEEN @bg_start AND @bg_end  
	AND		d.shipped > 0  
	AND		h.terms NOT LIKE 'INS%'   
	AND		x.void_flag <> 1     
	GROUP BY cv.buying_group, bg.customer_name, h.cust_code, b.customer_name, xx.doc_ctrl_num, t.days_due, x.date_due, h.type,
		x.date_doc, (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END), (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END),
		d.line_no, d.part_no, d.description, d.shipped  
/*
	SELECT	'D',
			'',
			a.cust_code,
			a.doc_ctrl_num,
			'',
			'',
			'',
			'',
			'',
			'',
			'',
			'',
			'',
			'',
			'',
			'',
			a.mer_disc,
			0,
			0,
			a.mer_tot,
			LEFT(CONVERT(varchar(3),ISNULL(a.line_no,'')),3),
			LEFT(ISNULL(a.part_no,''),16),
			LEFT(ISNULL(a.description,''),16),
			'',
			'',			
			CASE WHEN o.type = 'C' THEN LEFT(CONVERT(varchar(20),ISNULL(CONVERT(int,a.shipped)*-1,'')),20) 
				ELSE LEFT(CONVERT(varchar(20),ISNULL(CONVERT(int,a.shipped),'')),20) END
	FROM	#data_extract_raw a
	JOIN	orders_invoice i (NOLOCK) 
	ON		i.doc_ctrl_num = a.doc_ctrl_num
	JOIN	orders_all o (NOLOCK) 
	ON		i.order_no = o.order_no 
	AND		i.order_ext = o.ext
	WHERE	CHARINDEX('-',a.doc_ctrl_num) = 0

	UNION ALL

	SELECT	'D',
			'',
			a.cust_code,
			a.doc_ctrl_num,
			'',
			'',
			'',
			'',
			'',
			'',
			'',
			'',
			'',
			'',
			'',
			'',
			a.mer_disc,
			0,
			0,
			a.mer_tot,
			LEFT(CONVERT(varchar(3),ISNULL(a.line_no,'')),3),
			LEFT(ISNULL(a.part_no,''),16),
			LEFT(ISNULL(a.description,''),16),
			'',
			'',			
			CASE WHEN o.type = 'C' THEN LEFT(CONVERT(varchar(20),ISNULL(CONVERT(int,a.shipped)*-1,'')),20) 
				ELSE LEFT(CONVERT(varchar(20),ISNULL(CONVERT(int,a.shipped),'')),20) END
	FROM	#data_extract_raw a
	JOIN	orders_invoice i (NOLOCK) 
	ON		i.doc_ctrl_num = LEFT(a.doc_ctrl_num, CHARINDEX('-',a.doc_ctrl_num)-1)
	JOIN	orders_all o (NOLOCK) 
	ON		i.order_no = o.order_no 
	AND		i.order_ext = o.ext
	WHERE	CHARINDEX('-',a.doc_ctrl_num) > 0
	ORDER BY a.doc_ctrl_num
*/


	INSERT	#data_extract_raw (parent, parent_name, cust_code, customer_name, doc_ctrl_num, trm, type, inv_date,
		inv_tot, mer_tot, net_amt, freight, tax, mer_disc, inv_due, disc_perc, date_due_month, xinv_date, rec_type)
	-- Order Header
	SELECT	cv.buying_group,
			bg.customer_name,
			h.cust_code,  
			b.customer_name,  
			i.doc_ctrl_num,  
			t.days_due,
			'Invoice',
			CONVERT(VARCHAR(12),DATEADD(d,x.date_doc-639906,'1/1/1753'),101),
			ROUND((h.total_tax  + h.freight),2),
			0,
			0,
			h.freight,
			h.total_tax,
			0,  
			ROUND((h.total_tax  + h.freight),2),  
			0,
			CASE WHEN x.date_due <> 0 THEN
				RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,x.date_due-639906,'1/1/1753'),101),4) + '/'+  
				LEFT(CONVERT(VARCHAR(12),DATEADD(dd,x.date_due-639906,'1/1/1753'),101),2)  
			ELSE CONVERT(VARCHAR(4),DATEPART(YEAR,GETDATE()))+'/'+CONVERT(VARCHAR(2), DATEPART(MONTH,GETDATE())) END,
			x.date_doc,
			1		
	FROM	dbo.cvo_orders_all cv (NOLOCK)
	JOIN	dbo.orders_all h (NOLOCK) ON h.order_no = cv.order_no AND h.ext = cv.ext
	JOIN	dbo.orders_invoice i (NOLOCK) ON h.order_no =i.order_no AND h.ext = i.order_ext  
	JOIN	dbo.artrx_all x (NOLOCK) ON i.trx_ctrl_num = x.trx_ctrl_num  
	LEFT JOIN arcust bg (NOLOCK) ON bg.customer_code = cv.buying_group
	JOIN	dbo.arcust B (NOLOCK)ON h.cust_code = b.customer_code  
	JOIN	dbo.arterms t (NOLOCK) ON  h.terms = t.terms_code  
	WHERE	(h.freight <> 0 OR h.total_tax <> 0)  
	AND		x.date_doc BETWEEN  @jul_from AND @jul_to   
	AND		cv.buying_group BETWEEN @bg_start AND @bg_end  
	AND		h.type = 'I'  
	AND		h.terms NOT LIKE 'INS%'   
	AND		x.void_flag <> 1
	AND		cv.buying_group > ''

	UNION ALL
  
	-- CR Order Header  - tax and freight portion
	SELECT	cv.buying_group,
			bg.customer_name,
			h.cust_code,  
			b.customer_name,
			i.doc_ctrl_num,  
			t.days_due,
			'Credit',
			CONVERT(VARCHAR(12),DATEADD(dd,(x.date_doc)-639906,'1/1/1753'),101),
			ROUND((h.total_tax  + h.freight)  ,2) * -1  AS inv_tot,  
			0,
			0,
			h.freight * -1,
			h.total_tax * -1,
			0,
			ROUND(h.total_tax  + h.freight ,2) * -1,
			0,
			RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,(x.date_due)-639906,'1/1/1753'),101),4) + '/' +  
			LEFT(CONVERT(VARCHAR(12),DATEADD(dd,(x.date_due)-639906,'1/1/1753'),101),2),  
			x.date_doc,
			1
	FROM	cvo_orders_all cv (NOLOCK)
	JOIN	orders_all h (NOLOCK) ON h.order_no = cv.order_no AND h.ext = cv.ext
	JOIN	orders_invoice i (NOLOCK) ON h.order_no =i.order_no AND h.ext = i.order_ext  
	JOIN	artrx_all x (NOLOCK) ON i.doc_ctrl_num = x.doc_ctrl_num AND x.trx_type = 2032  
	JOIN	arcust bg (NOLOCK) ON bg.customer_code = cv.buying_group
	JOIN	arcust B (NOLOCK)ON h.cust_code = b.customer_code  
	JOIN	arterms t (NOLOCK) ON h.terms = t.terms_code  
	WHERE	cv.buying_group > ''
	AND		x.date_doc BETWEEN  @jul_from AND @jul_to 
	AND		cv.buying_group BETWEEN @bg_start AND @bg_end    
	AND		(h.freight <> 0 OR h.total_tax <> 0)  
	AND		h.type = 'C'  
	AND		h.terms NOT LIKE 'INS%'   
	AND		x.void_flag <> 1
    
	UNION ALL

	SELECT	dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) parent, -- v2.5
			dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))) parent_name, -- v2.5
			o.cust_code,
			b.customer_name as customer_name,
			h.doc_ctrl_num,
			z.installment_days as trm,
			'Invoice' as type,
			convert(varchar(12), dateadd(dd, h.date_doc - 639906, '1/1/1753'),101) as inv_date,
			round((o.total_tax  + o.freight)* (z.installment_prc/100),2) as inv_tot,
			0 as mer_tot,
			0 as net_amt,
			round(o.freight*(z.installment_prc/100)  ,2)as freight,
			round(o.total_tax*(z.installment_prc/100)  ,2) as tax,
			0 as mer_disc,
			round((o.total_tax  + o.freight)* (z.installment_prc/100),2)  as inv_due,
			0 as disc_perc,
			CASE h.date_due WHEN 0 THEN
				SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),7,4)
				+'/'+ SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_doc - 639906,'1/1/1753'),101),1,2)
			ELSE	SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),7,4)
				+'/'+ SUBSTRING(CONVERT(varchar(10),dateadd(dd,h.date_due - 639906,'1/1/1753'),101),1,2)
			END as due_year_month,
			h.date_doc as xinv_date,
			1
	FROM	artrx_all h (NOLOCK)
	JOIN	orders_invoice i (NOLOCK) 
	ON		i.doc_ctrl_num = LEFT(h.doc_ctrl_num, CHARINDEX('-',h.doc_ctrl_num)-1)
	JOIN	orders_all o (NOLOCK) 
	ON		o.order_no = i.order_no 
	AND		o.ext = i.order_ext
	LEFT JOIN arnarel r (NOLOCK) 
	ON		o.cust_code = r.child
	LEFT JOIN arcust m (NOLOCK) 
	ON		r.parent = m.customer_code
	JOIN	arcust b (NOLOCK) 
	ON		o.cust_code = b.customer_code
	JOIN	cvo_artermsd_installment z (NOLOCK) 
	ON		h.terms_code = z.terms_code 
	AND		CONVERT(int,RIGHT(h.doc_ctrl_num,1)) = z.sequence_id
	WHERE	(o.freight <> 0 or o.total_tax <> 0)
	AND		h.date_doc BETWEEN  @jul_from AND @jul_to 
	AND		dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) BETWEEN @bg_start AND @bg_end  
	AND		o.type = 'I'
	AND		LEFT(h.terms_code,3) = 'INS' 
	AND		h.trx_type = 2031
	AND		LEFT(h.doc_ctrl_num,3) <> 'FIN' 
	AND		LEFT(h.doc_ctrl_num,2) <> 'CB'
	AND		h.void_flag <> 1
	AND		dbo.f_cvo_get_buying_group(o.cust_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) > '' 

	UNION ALL
  
	-- AR only records invoice  
	SELECT	dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)),
			dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))),
			h.customer_code,  
			b.customer_name,
			h.doc_ctrl_num,  
			t.days_due,
			'Invoice',
			CONVERT(VARCHAR(12),DATEADD(dd,h.date_doc - 639906,'1/1/1753'),101),
			CASE WHEN d.sequence_id = 1 THEN ROUND((d.unit_price * d.qty_shipped) + h.amt_tax  + h.amt_freight  ,2)
			ELSE ROUND((d.unit_price * d.qty_shipped),2) END,
			ROUND((d.unit_price * d.qty_shipped),2),
			0,
			CASE WHEN d.sequence_id  = 1 THEN h.amt_freight ELSE 0 END,
			CASE WHEN d.sequence_id  = 1 THEN h.amt_tax ELSE 0 END,
			(d.unit_price * d.qty_shipped)- d.discount_amt,
			CASE WHEN d.sequence_id = 1 THEN ROUND((d.unit_price * d.qty_shipped)- d.discount_amt + h.amt_tax  + h.amt_freight  ,2)  
			ELSE ROUND((d.unit_price * d.qty_shipped)-d.discount_amt,2) END,
			d.discount_prc/100,  
			SUBSTRING(CONVERT(VARCHAR(12),DATEADD(dd,h.date_due - 639906,'1/1/1753'),101),7,4) + '/'+  
			SUBSTRING(CONVERT(VARCHAR(12),DATEADD(dd,h.date_due - 639906,'1/1/1753'),101),1,2),  
			h.date_doc,
			1
	FROM	artrx_all h (NOLOCK)  
	JOIN	artrxcdt d (NOLOCK) ON h.trx_ctrl_num = d.trx_ctrl_num  
	JOIN	arcust B (NOLOCK)ON h.customer_code = b.customer_code  
	JOIN	arterms t (NOLOCK) ON h.terms_code = t.terms_code  
	WHERE	(h.order_ctrl_num = '' OR LEFT(h.doc_desc,3) NOT IN ('SO:', 'CM:'))  
	AND		h.date_doc BETWEEN  @jul_from AND @jul_to  
	AND		dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) BETWEEN @bg_start AND @bg_end   
	AND		h.trx_type IN (2031)  
	AND		h.doc_ctrl_num NOT LIKE 'FIN%'   
	AND		h.doc_ctrl_num NOT LIKE 'CB%'   
	AND		h.terms_code NOT LIKE 'INS%'   
	AND		h.void_flag <> 1
	AND		dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > ''
  
	UNION  ALL
  
	-- AR only records credit  
	SELECT  dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)),
			dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))),
			h.customer_code,  
			b.customer_name,
			h.doc_ctrl_num,  
			t.days_due,
			'Credit',
			CONVERT(VARCHAR(12),DATEADD(dd,h.date_doc - 639906,'1/1/1753'),101),
			CASE WHEN d.sequence_id = 1 THEN CASE WHEN h.recurring_flag = 2 THEN h.amt_tax*-1  
				WHEN h.recurring_flag = 3 THEN h.amt_freight*-1  
				WHEN h.recurring_flag = 4 THEN ROUND(h.amt_tax + h.amt_freight,2)*-1  
				ELSE ROUND((d.unit_price * d.qty_returned) + h.amt_tax  + h.amt_freight  ,2)*-1 END			            
				ELSE ROUND((d.unit_price * d.qty_returned),2)*-1  END,
			CASE WHEN h.recurring_flag < 2 THEN ROUND((d.unit_price * d.qty_returned),2)*-1   
				ELSE 0.0 END,
			0,
			CASE WHEN d.sequence_id  = 1 AND h.recurring_flag IN (1,3,4) THEN h.amt_freight *-1
				ELSE 0 END,
			CASE WHEN d.sequence_id  = 1 AND h.recurring_flag IN (1,2,4) THEN h.amt_tax*-1
				ELSE 0 END,
			CASE WHEN h.recurring_flag < 2 THEN ((d.unit_price * d.qty_returned)-d.discount_amt)*-1   
				ELSE 0.0 END,
			CASE WHEN d.sequence_id = 1 THEN CASE WHEN h.recurring_flag = 2 THEN h.amt_tax*-1  
				WHEN h.recurring_flag = 3 THEN h.amt_freight*-1  
				WHEN h.recurring_flag = 4 THEN ROUND(h.amt_tax + h.amt_freight,2)*-1  
				ELSE ROUND((d.unit_price * d.qty_returned)-d.discount_amt + h.amt_tax  + h.amt_freight  ,2)*-1 END  
				ELSE ROUND((d.unit_price * d.qty_returned)-d.discount_amt,2)*-1 END,
			d.discount_prc/100,  
			CASE h.date_due WHEN 0 THEN  
				SUBSTRING(CONVERT(VARCHAR(10),DATEADD(dd,h.date_doc - 639906,'1/1/1753'),101),7,4) +'/'+ 
				SUBSTRING(CONVERT(VARCHAR(10),DATEADD(dd,h.date_doc - 639906,'1/1/1753'),101),1,2)  
				ELSE SUBSTRING(CONVERT(VARCHAR(10),DATEADD(dd,h.date_due - 639906,'1/1/1753'),101),7,4) +'/'+ 
				SUBSTRING(CONVERT(VARCHAR(10),DATEADD(dd,h.date_due - 639906,'1/1/1753'),101),1,2) END,
			h.date_doc,
			1
	FROM	artrx_all h (NOLOCK)  
	JOIN	artrxcdt d (NOLOCK) ON h.trx_ctrl_num = d.trx_ctrl_num  
	JOIN	arcust B (NOLOCK)ON h.customer_code = b.customer_code  
	LEFT JOIN arterms t (NOLOCK) ON b.terms_code = t.terms_code
	WHERE	LEFT(h.doc_desc,3) NOT IN ('SO:', 'CM:')  
	AND		h.date_doc BETWEEN  @jul_from AND @jul_to  
	AND		dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(varchar(10),DATEADD(DAY,h.date_doc - 693596, '01/01/1900'),121)) BETWEEN @bg_start AND @bg_end    
	AND		h.trx_type IN (2032)  
	AND		h.doc_ctrl_num NOT LIKE 'FIN%'   
	AND		h.doc_ctrl_num NOT LIKE 'CB%'   
	AND		h.void_flag <> 1     --v2.0  
	AND		((recurring_flag < 2) OR (recurring_flag > 1 AND d.sequence_id = 1))  
	AND		dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > ''
	AND		NOT EXISTS (SELECT 1 FROM cvo_debit_promo_customer_det WHERE trx_ctrl_num = h.trx_ctrl_num)
  
	UNION ALL

	SELECT  cv.buying_group, 
			bg.customer_name,
			h.cust_code,  
			b.customer_name,
			i.doc_ctrl_num,  
			t.days_due,
			CASE WHEN h.type = 'I' THEN 'Invoice' ELSE 'Credit' END,
			CONVERT(VARCHAR(12),DATEADD(d,x.date_doc-639906,'1/1/1753'),101),
			SUM(d.cr_shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1,
			0.0,
			0.0,
			0.0,
			0.0,
			0.0,
			SUM(d.cr_shipped * ROUND(curr_price -(curr_price * ((CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END) / 100)),2,1)) * -1,
			0.0,
			CASE MAX(x.date_due) WHEN 0 THEN
				RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_doc)-639906,'1/1/1753'),101),4) + '/' + LEFT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_doc)-639906,'1/1/1753'),101),2) 
				ELSE RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_due)-639906,'1/1/1753'),101),4) + '/' + LEFT(CONVERT(VARCHAR(12),DATEADD(dd,MAX(x.date_due)-639906,'1/1/1753'),101),2) END,
			x.date_doc,
			2
	FROM	cvo_orders_all cv (NOLOCK)
	JOIN	orders_all h (NOLOCK)  
	ON		h.order_no = cv.order_no
	AND		h.ext = cv.ext 
	JOIN	orders_invoice i (NOLOCK) 
	ON		h.order_no = i.order_no 
	AND		h.ext = i.order_ext  
	JOIN	artrx x (NOLOCK) 
	ON		i.doc_ctrl_num = x.doc_ctrl_num 
	AND		x.trx_type = 2032  
	JOIN	ord_list d (NOLOCK) 
	ON		h.order_no = d.order_no 
	AND		h.ext = d.order_ext  
	JOIN	arcust bg (NOLOCK) 
	ON		bg.customer_code = cv.buying_group 
	JOIN	arcust B (NOLOCK)
	ON		h.cust_code = b.customer_code  
	JOIN	cvo_ord_list c (NOLOCK) 
	ON		d.order_no = c.order_no 
	AND		d.order_ext = c.order_ext 
	AND		d.line_no = c.line_no  
	JOIN	cvo_disc_percent p (NOLOCK) 
	ON		d.order_no = p.order_no 
	AND		d.order_ext = p.order_ext 
	AND		d.line_no = p.line_no  
	JOIN	arterms t (NOLOCK) 
	ON		h.terms = t.terms_code 
	WHERE	d.cr_shipped > 0  
	AND		h.type = 'C'  
	AND		h.terms NOT LIKE 'INS%'   
	AND		x.void_flag <> 1     
	AND		d.part_no = 'Credit Return Fee' 
	AND		x.date_doc BETWEEN  @jul_from AND @jul_to 
	AND		cv.buying_group BETWEEN @bg_start AND @bg_end  
	AND		cv.buying_group > '' 
	GROUP BY cv.buying_group, BG.customer_name, h.cust_code, b.customer_name, i.doc_ctrl_num, t.days_due, x.date_due, h.type,  -- v1.2
		x.date_doc, (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE d.discount END), (CASE WHEN d.curr_price > c.list_price THEN 0 ELSE p.disc_perc END) 

	UNION ALL
  
	-- CR debit promo tax line  
	SELECT 	cv.buying_group,
			bg.customer_name,
			b.customer_code,
			b.customer_name,
			x.doc_ctrl_num,  
			t.days_due,
			'Credit',
			CONVERT(VARCHAR(12),DATEADD(d,x.date_doc-639906,'1/1/1753'),101),
			ROUND((x.amt_tax)  ,2) * -1,
			0,
			0,
			0,
			x.amt_tax * -1,
			0,
			ROUND(x.amt_tax ,2) * -1,
			0, 
			CASE x.date_due WHEN 0 THEN
				RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,(x.date_doc)-639906,'1/1/1753'),101),4) + '/'+    
				LEFT(CONVERT(VARCHAR(12),DATEADD(dd,(x.date_doc)-639906,'1/1/1753'),101),2) 
				ELSE RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,(x.date_due)-639906,'1/1/1753'),101),4) + '/'+    
				LEFT(CONVERT(VARCHAR(12),DATEADD(dd,(x.date_due)-639906,'1/1/1753'),101),2) END,
			x.date_doc,
			3
	FROM	(SELECT DISTINCT dd.trx_ctrl_num, co.order_no, co.ext, buying_group 
			FROM  cvo_debit_promo_customer_det dd 
			INNER JOIN  cvo_orders_all co ON dd.order_no = co.order_no AND dd.ext = co.ext) cv 
	JOIN	artrx_all x (NOLOCK) ON cv.trx_ctrl_num = x.trx_ctrl_num
	JOIN	arcust B (NOLOCK) ON b.customer_code  = x.customer_code
	JOIN	arcust bg (NOLOCK) ON bg.customer_code = cv.buying_group
	JOIN	arterms t (NOLOCK) ON b.terms_code = t.terms_code  
	WHERE	(x.amt_tax <> 0) 
	AND		x.date_doc BETWEEN  @jul_from AND @jul_to 
	AND		cv.buying_group BETWEEN @bg_start AND @bg_end  
	AND		x.trx_type = 2032
	AND		x.terms_code NOT LIKE 'INS%'   
	AND		x.void_flag <> 1     
	AND		cv.buying_group > ''

	UNION ALL
  
	SELECT	dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)),
			dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))),
			h.customer_code,  
			b.customer_name,
			h.doc_ctrl_num,  
			0,
			CASE WHEN h.trx_type = 2061 THEN 'Finance Charge' WHEN h.trx_type = 2071 THEN 'Late Charge' ELSE '' END,
			CONVERT(VARCHAR(12),DATEADD(dd,h.date_doc - 639906,'1/1/1753'),101),
			h.amt_tot_chg,
			h.amt_tot_chg,
			0,
			0,
			0,
			0,
			h.amt_tot_chg,
			0, 
			CASE h.date_due WHEN 0 THEN
				RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_doc)-639906,'1/1/1753'),101),4) + '/'+    
				LEFT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_doc)-639906,'1/1/1753'),101),2) 
				ELSE RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_due)-639906,'1/1/1753'),101),4) + '/'+    
				LEFT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_due)-639906,'1/1/1753'),101),2) END,
			h.date_doc,
			1
	FROM	artrx_all h (NOLOCK)  
	JOIN	arcust B (NOLOCK)ON h.customer_code = b.customer_code  
	WHERE	h.trx_type IN (2061,2071)  
	AND		h.date_doc BETWEEN  @jul_from AND @jul_to 
	AND		dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) BETWEEN @bg_start AND @bg_end  
	AND		h.doc_ctrl_num NOT LIKE 'CB%'   
	AND		h.terms_code NOT LIKE 'INS%'   
	AND		h.void_flag <> 1  
	AND		dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > '' 

	UNION ALL

	SELECT  dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)),
			dbo.f_cvo_get_buying_group_name	(dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121))),
			h.customer_code,  
			b.customer_name,
			h.doc_ctrl_num,  
			0 AS trm,  
			CASE WHEN h.trx_type = 2061 THEN 'Finance Charge' WHEN h.trx_type = 2071 THEN 'Late Charge' ELSE '' END,
			CONVERT(VARCHAR(12),DATEADD(dd,h.date_doc - 639906,'1/1/1753'),101),
			h.amt_tot_chg,
			h.amt_tot_chg,
			0,
			0,
			0,
			0,
			h.amt_tot_chg,
			0, 
			CASE   h.date_due WHEN 0 THEN
				RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_doc)-639906,'1/1/1753'),101),4) + '/'+    
				LEFT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_doc)-639906,'1/1/1753'),101),2) 
				ELSE RIGHT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_due)-639906,'1/1/1753'),101),4) + '/'+    
				LEFT(CONVERT(VARCHAR(12),DATEADD(dd,(h.date_due)-639906,'1/1/1753'),101),2) END,
			h.date_doc,
			1
	FROM	artrx_all h (NOLOCK)  
	JOIN	arcust B (NOLOCK)ON h.customer_code = b.customer_code  
	WHERE	h.trx_ctrl_num LIKE 'CB%'   
	AND		h.date_doc BETWEEN  @jul_from AND @jul_to 
	AND		dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) BETWEEN @bg_start AND @bg_end  
	AND		h.terms_code NOT LIKE 'INS%'   
	AND		h.void_flag <> 1  
	AND		dbo.f_cvo_get_buying_group(h.customer_code, CONVERT(VARCHAR(10),DATEADD(DAY, h.date_doc - 693596, '01/01/1900'),121)) > ''     

	---- v1.1 Start
	--DELETE	#data_extract_raw
	--WHERE	disc_perc = 1
	---- v1.1 End


	-- v1.3 Start
	CREATE TABLE #results (
		parent			varchar(10),
		parent_name		varchar(40),
		cust_code		varchar(10),
		customer_name	varchar(40),
		doc_ctrl_num	varchar(16),
		type			varchar(20),
		inv_date		varchar(12),
		inv_tot			float,
		mer_tot			float,
		net_amt			float,
		freight			float,
		tax				float,
		trm				int,
		mer_disc		float,
		inv_due			float,
		disc_perc		float,
		date_due_month	varchar(10),
		xinv_date		int,
		rec_type		int)
		
	INSERT	#results
	SELECT	parent,
			parent_name,
			cust_code,
			customer_name,
			doc_ctrl_num,
			type,
			inv_date,
			SUM(inv_tot) inv_tot,
			SUM(mer_tot) mer_tot,                
			SUM(net_amt) net_amt,
			SUM(freight) freight,                
			SUM(tax) tax,          
			trm,
			sum(mer_disc) mer_disc,     
			SUM(inv_due) inv_due,
			disc_perc,
			date_due_month due_year_month,
			xinv_date,
			rec_type			
	FROM	#data_extract_raw
	WHERE disc_perc <> 1
	GROUP BY parent, parent_name, cust_code, customer_name, doc_ctrl_num, type, inv_date, trm,                  
			disc_perc, date_due_month, xinv_date, rec_type
	ORDER BY parent, cust_code, doc_ctrl_num

	
	CREATE TABLE #install_rounding (
		doc_ctrl_num	varchar(16),
		inv_gross		decimal(20,8),
		inv_freight		decimal(20,8),
		inv_tax			decimal(20,8),
		inv_net			decimal(20,8),
		inv_total		decimal(20,8), -- v1.5
		inv_diff		decimal(20,8), -- v1.5
		amt_gross		float,
		amt_freight		float,
		amt_tax			float,
		amt_net			float,
		disc_perc		float) -- v1.5

	INSERT	#install_rounding
	SELECT	doc_ctrl_num, SUM(inv_tot), SUM(freight), SUM(tax), SUM(inv_due), 0,0,0,0,0,0, disc_perc -- v1.5
	FROM	#results
	WHERE	CHARINDEX('-',doc_ctrl_num) > 0
	GROUP BY doc_ctrl_num, disc_perc -- v1.5

	CREATE INDEX #install_rounding_ind0 ON #install_rounding(doc_ctrl_num)

	 -- v1.5 Start
	SELECT	doc_ctrl_num, SUM(inv_net) total
	INTO	#temp_totals
	FROM	#install_rounding
	GROUP BY doc_ctrl_num

	UPDATE	a
	SET		inv_total = b.total
	FROM	#install_rounding a
	JOIN	#temp_totals b
	ON		a.doc_ctrl_num = b.doc_ctrl_num
	
	DROP TABLE  #temp_totals

	UPDATE	a
	SET		amt_gross = b.amt_gross,
			amt_freight = b.amt_freight,
			amt_tax = b.amt_tax,
			amt_net = b.amt_net,
			inv_diff = b.amt_net - inv_total
	FROM	#install_rounding a
	JOIN	artrx_all b (NOLOCK)
	ON		a.doc_ctrl_num = b.doc_ctrl_num

	DELETE	#install_rounding
	WHERE	inv_net = amt_net

	SELECT	doc_ctrl_num, COUNT(1) lines, MAX(inv_diff) diff, 0.00 split
	INTO	#temp_lines
	FROM	#install_rounding
	WHERE	inv_freight = 0 
	AND		inv_tax = 0
	GROUP BY doc_ctrl_num

	UPDATE	#temp_lines
	SET		split = diff / CAST(lines as decimal(20,8))

	UPDATE	a
	SET		inv_diff = b.split
	FROM	#install_rounding a
	JOIN	#temp_lines b
	ON		a.doc_ctrl_num = b.doc_ctrl_num

	DROP TABLE #temp_lines

	UPDATE	a
	SET		inv_tot = a.inv_tot + b.inv_diff,
			mer_tot = a.mer_tot + b.inv_diff,
			mer_disc = a.mer_disc + b.inv_diff,
			inv_due = a.inv_due + b.inv_diff
	FROM	#results a
	JOIN	#install_rounding b
	ON		a.doc_ctrl_num = b.doc_ctrl_num
	WHERE	a.freight = 0 
	AND		a.tax = 0
	-- v1.5 End
	
	-- v1.4 Start
	DELETE	#results
	WHERE	ABS(inv_due) < 0.01
	-- v1.4 End

	SELECT	parent,
			parent_name,
			cust_code,
			customer_name,
			doc_ctrl_num,
			type,
			inv_date,
			SUM(inv_tot) inv_tot,
			SUM(mer_tot) mer_tot,                
			SUM(net_amt) net_amt,
			SUM(freight) freight,                
			SUM(tax) tax,          
			trm,
			sum(mer_disc) mer_disc,     
			SUM(inv_due) inv_due,
			disc_perc,
			date_due_month due_year_month,
			xinv_date,
			rec_type			
	FROM	#results
	WHERE	disc_perc <> 1
	GROUP BY parent, parent_name, cust_code, customer_name, doc_ctrl_num, type, inv_date, trm,                  
			disc_perc, date_due_month, xinv_date, rec_type
	ORDER BY parent, cust_code, doc_ctrl_num

			
	-- CLEAN UP
	DROP TABLE #data_extract_raw
	DROP TABLE #order_data_extract_raw
	DROP TABLE #install_rounding
END
GO
GRANT EXECUTE ON  [dbo].[cvo_bg_data_extract_log_sp] TO [public]
GO
