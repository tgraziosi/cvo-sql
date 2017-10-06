SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_release_st_consolidate_sp] @cust varchar(10), @ship_to varchar(10)='%', @who_entered varchar(20) = '%' -- v1.2 
AS  
BEGIN
  
	SET NOCOUNT ON

	CREATE TABLE #thold (
		consolidation_no	int, 
		order_no			int, 
		order_ext			int, 
		cust_code			varchar(10),  
        customer_name		varchar(40) NULL, 
		total_order_amt		decimal(20,8),  
        total_order_cost	decimal(20,8), 
		ship_to_no			varchar(10) NULL,  
        ship_to_name		varchar(40) NULL, 
		salesperson			varchar(10) NULL,
		carrier				varchar(10) NULL,
		sch_ship_date		datetime NULL,  
        who_entered			varchar(20) NULL, 
		date_entered		datetime NULL,  
        curr_factor			decimal(20,8), 
		printed				char(1),  
        status				char(1), 
		reason				varchar(10) null, 
		blanket				char(1),
        multiple			char(1),
		first_line			int)
  
	CREATE INDEX #t1 ON #thold (cust_code, ship_to_name, consolidation_no, order_no, order_ext)

	-- v1.3 Start
	INSERT	cvo_st_consolidate_release (consolidation_no, released, release_date, release_user)
	SELECT	a.consolidation_no, 0, NULL, NULL
	FROM	cvo_masterpack_consolidation_hdr a (NOLOCK)
	LEFT JOIN cvo_st_consolidate_release b (NOLOCK)
	ON		a.consolidation_no = b.consolidation_no
	WHERE	b.consolidation_no IS NULL
	AND		a.type = 'OE'
	AND		a.closed = 0
	AND		a.shipped = 0
	-- v1.3 End
  
	-- v1.2 Start
	IF (@who_entered = '%')
	BEGIN
		INSERT  #thold  
		SELECT  a.consolidation_no,
				b.order_no, 
				b.ext, 
				b.cust_code, 
				null, 0, 0,  
				b.ship_to, 
				b.ship_to_name, 
				b.salesperson,
				b.routing,
				b.sch_ship_date, 
				b.who_entered,   
				b.date_entered, 
				b.curr_factor, 
				'H', 
				b.status, 
				b.hold_reason, 
				b.blanket,  
				b.multiple_flag,
				0
		FROM    orders_entry_vw b (NOLOCK)
		JOIN	adm_cust c (NOLOCK)
		ON		b.cust_code = c.customer_code
		JOIN	cvo_masterpack_consolidation_det a (NOLOCK)
		ON		b.order_no = a.order_no
		AND		b.ext = a.order_ext
		JOIN	cvo_st_consolidate_release d (NOLOCK)
		ON		a.consolidation_no = d.consolidation_no  
		JOIN	cvo_masterpack_consolidation_hdr e (NOLOCK)
		ON		a.consolidation_no = e.consolidation_no
		WHERE   b.status IN ('N','A') 
		AND		b.cust_code like @cust 
		AND		(@ship_to = '%' or b.ship_to like @ship_to)  
		AND		b.type = 'I'
		AND		d.released = 0
		AND		e.shipped = 0
		AND		e.closed = 0
		AND		e.type = 'OE'
	END
	ELSE
	BEGIN
		INSERT  #thold  
		SELECT  a.consolidation_no,
				b.order_no, 
				b.ext, 
				b.cust_code, 
				null, 0, 0,  
				b.ship_to, 
				b.ship_to_name, 
				b.salesperson,
				b.routing,
				b.sch_ship_date, 
				b.who_entered,   
				b.date_entered, 
				b.curr_factor, 
				'H', 
				b.status, 
				b.hold_reason, 
				b.blanket,  
				b.multiple_flag,
				0
		FROM    orders_entry_vw b (NOLOCK)
		JOIN	adm_cust c (NOLOCK)
		ON		b.cust_code = c.customer_code
		JOIN	cvo_masterpack_consolidation_det a (NOLOCK)
		ON		b.order_no = a.order_no
		AND		b.ext = a.order_ext
		JOIN	cvo_st_consolidate_release d (NOLOCK)
		ON		a.consolidation_no = d.consolidation_no  
		JOIN	cvo_masterpack_consolidation_hdr e (NOLOCK)
		ON		a.consolidation_no = e.consolidation_no
		WHERE   b.status IN ('N','A') 
		AND		b.cust_code like @cust 
		AND		(@ship_to = '%' or b.ship_to like @ship_to)  
		AND		b.type = 'I'
		AND		d.released = 0
		AND		e.shipped = 0
		AND		e.closed = 0
		AND		e.type = 'OE'
		AND		e.consolidation_no IN (SELECT consolidation_no FROM cvo_stc_hold_user_vw WHERE who_entered like @who_entered)
	END
	-- v1.2 End	 

	-- v1.4 Start
	INSERT  #thold  
	SELECT  0,
			b.order_no, 
			b.ext, 
			b.cust_code, 
			null, 0, 0,  
			b.ship_to, 
			b.ship_to_name, 
			b.salesperson,
			b.routing,
			b.sch_ship_date, 
			b.who_entered,   
			b.date_entered, 
			b.curr_factor, 
			'H', 
			b.status, 
			b.hold_reason, 
			b.blanket,  
			b.multiple_flag,
			0
	FROM    orders_entry_vw b (NOLOCK)
	JOIN	adm_cust c (NOLOCK)
	ON		b.cust_code = c.customer_code
	JOIN	cvo_orders_all cvo (NOLOCK)
	ON		b.order_no = cvo.order_no
	AND		b.ext = cvo.ext
	LEFT JOIN cvo_masterpack_consolidation_det a (NOLOCK)
	ON		b.order_no = a.order_no
	AND		b.ext = a.order_ext
	WHERE   b.status IN ('N','A') 
	AND		b.cust_code like @cust 
	AND		(@ship_to = '%' or b.ship_to like @ship_to)  
	AND		b.type = 'I'
	AND		a.order_no IS NULL
	AND		a.order_ext IS NULL
	AND		ISNULL(cvo.st_consolidate,0) = 0
	AND		b.hold_reason = 'STC'
	-- v1.4 End

  
	UPDATE #thold set customer_name=adm_cust.customer_name  
	FROM   adm_cust (NOLOCK)  
	WHERE  adm_cust.customer_code = #thold.cust_code  
  
	UPDATE #thold   
	SET    total_order_amt=ISNULL( (SELECT SUM( ordered * price ) FROM ord_list (NOLOCK)  
			WHERE ord_list.order_no=#thold.order_no 
			AND ord_list.order_ext=#thold.order_ext), 0 )  
  
	UPDATE #thold   
	SET    total_order_cost=ISNULL( (SELECT SUM( ordered * ((std_cost+std_direct_dolrs+std_ovhd_dolrs+std_util_dolrs)* ord_list.conv_factor) )   
			FROM ord_list (NOLOCK)  
			WHERE ord_list.order_no=#thold.order_no 
			AND ord_list.order_ext=#thold.order_ext 
			AND (ord_list.part_type='M' OR ord_list.part_type='J') ), 0 )  
  
	UPDATE #thold   
	SET    total_order_cost=ISNULL( (SELECT SUM( ordered * ((i.std_cost+i.std_direct_dolrs+i.std_ovhd_dolrs+i.std_util_dolrs) * ord_list.conv_factor) )   
		FROM ord_list (NOLOCK), inv_list i (NOLOCK)
		WHERE ord_list.order_no=#thold.order_no 
		AND ord_list.order_ext=#thold.order_ext 
		AND ord_list.part_no=i.part_no AND ord_list.location=i.location 
		AND ord_list.part_type<>'M' AND ord_list.part_type<>'J'), 0 )  

	CREATE TABLE #minline (
		consolidation_no	int,
		order_no			int)

	INSERT	#minline
	SELECT	consolidation_no,
			MIN(order_no)
	FROM	#thold
	GROUP BY consolidation_no  

	UPDATE	a
	SET		first_line = 1
	FROM	#thold a
	JOIN	#minline b
	ON		a.consolidation_no = b.consolidation_no
	AND		a.order_no = b.order_no

	DROP TABLE #minline
 
	SELECT  consolidation_no, order_no, order_ext, cust_code,  
			customer_name, total_order_amt,  
			total_order_cost, ship_to_no,  
			ship_to_name, salesperson, carrier, sch_ship_date,
			who_entered, date_entered,  
			curr_factor, printed,  
			status, reason, blanket, multiple, first_line
	FROM	#thold  
	ORDER BY cust_code, ship_to_name, consolidation_no, order_no, order_ext  
  
END

GO
GRANT EXECUTE ON  [dbo].[cvo_release_st_consolidate_sp] TO [public]
GO
