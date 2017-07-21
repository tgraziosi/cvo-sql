SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 08/05/2013 - Performance    
-- v1.1 CB 24/07/2013 - Issue #927 - Buying Group Switching
-- v1.2 CB 16/09/2013 - Issue #927 - Buying Group Switching - RB Orders set and removed from BGs
-- v1.3 CB 01/10/2013 - Issue #927 - Buying Group Switching - Deal with non BG customers
-- v1.4 CB 05/11/2013 - Peformance
-- v1.5 CB 06/11/2013 - Fix issue with non BG parents
-- v1.6 CB 06/11/2013 - Peformance
-- v1.7 CB 21/11/2013 - Need to include RB orders when the customer has no relationship with a parent
-- v1.8 CB 09/12/2013 - Issue when customer is added and removed from buying group
-- v1.9 CB 31/12/2013 - Issue when running for single customer record - picking up bg associated record
-- v2.0 CB 13/01/2013 - Further fix to v1.8
-- v2.1 CB 21/01/2014 - Fix issue with transactions showing with zero balance (float field)
-- v2.2 CB 03/02/2014 - Fix issue with nulls in the balance column
-- v2.3 CB 27/02/2014 - Additional fix to v1.8
-- v2.4 CB 13/03/2014 - Fix issue with due date calc
-- v2.5 CB 24/03/2014 - Fix issue with child and BG
-- v2.6 CB 28/03/2014 - Fix to customer records
-- v2.7 CB 29/04/2013 - Fix issue with records showing on a customer after they have joined a buying group
-- v2.8 CB 29/04/2013 - Fix issue with records not showing on a customer after they have left and rejoined a buying group
-- v2.9 CB 30/04/2014 - Fix issue for RB orders
-- v3.0 CB 06/06/2014 - Fix issue for child account leaving and joining buying group and transactions showing under child
-- v4.0 CB 09/06/2014 - ReWrite of BG data
-- v4.1 CB 12/03/2015 - Issue #1469 - Deal with finance and late charges and chargebacks
-- v4.2 CB 25/06/2015 - Fix to v4.1
-- EXEC  [cc_open_inv_sp] '000111'       
CREATE PROCEDURE [dbo].[cc_open_inv_sp]     
  @customer_code  varchar(8) = NULL,    
  @sort_by  tinyint = 1,    
  @sort_type  tinyint = 1,    
  @date_type tinyint = 4,    
  @all_org_flag   smallint = 1,      
  @from_org varchar(30) = 'CVO',    
  @to_org varchar(30) = 'CVO',
  @from_aging int = 0    
    
AS    
BEGIN    
    -- DIRECTIVES
	SET NOCOUNT ON    
    
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
	EXEC cvo_bg_get_document_data_sp @customer_code
   
	CREATE INDEX #bg_data_ind222 ON #bg_data (customer_code, doc_ctrl_num)

	SELECT	a.* 
	INTO	#artrxage   
	FROM	artrxage a (NOLOCK) 
	JOIN	#bg_data b
	ON		a.customer_code = b.customer_code
	AND		a.doc_ctrl_num = b.doc_ctrl_num

	CREATE INDEX #artrxage_idx1 ON #artrxage(customer_code, apply_to_num)    
	CREATE INDEX #artrxage_idx2 ON #artrxage(customer_code, doc_ctrl_num, trx_type)    
	CREATE INDEX #artrxage_idx3 ON #artrxage(order_ctrl_num)    
	
	SELECT	a.* 
	INTO	#artrx   
	FROM	artrx a (NOLOCK)
	JOIN	#bg_data b
	ON		a.customer_code = b.customer_code
	AND		a.doc_ctrl_num = b.doc_ctrl_num

	CREATE INDEX #artrx_idx1 ON #artrx(customer_code, doc_ctrl_num, trx_type)    
	CREATE INDEX #artrx_idx2 ON #artrx(order_ctrl_num)        
	CREATE INDEX #artrx_idx3 ON #artrx(trx_ctrl_num)        
    
	CREATE TABLE #dates    
	( date_start int,    
	date_end int,    
	bucket varchar(25) )    
    
	SELECT @date_type = 4    
    
	DECLARE @date_asof  int,    
	 @e_age_bracket_1 smallint,    
	 @e_age_bracket_2 smallint,    
	 @e_age_bracket_3 smallint,    
	 @e_age_bracket_4 smallint,    
	 @e_age_bracket_5 smallint,       
	 @b_age_bracket_1 smallint,    
	 @b_age_bracket_2 smallint,    
	 @b_age_bracket_3 smallint,    
	 @b_age_bracket_4 smallint,    
	 @b_age_bracket_5 smallint,    
	 @b_age_bracket_6 smallint,       
	 @detail_count int,    
	 @last_doc varchar(16),    
	 @date_doc int,     
	 @date_due int,     
	 @terms_code varchar(8),    
	 @last_check varchar(16),    
	 @last_cust varchar(8),    
	 @balance float,    
	 @stat_seq int    
    
	SELECT  @date_asof = DATEDIFF(dd, '1/1/1753', CONVERT(datetime, getdate())) + 639906    
    
	SELECT  @e_age_bracket_1  = age_bracket1,    
			@e_age_bracket_2  = age_bracket2,    
			@e_age_bracket_3  = age_bracket3,    
			@e_age_bracket_4  = age_bracket4,    
			@e_age_bracket_5  = age_bracket5     
	FROM	arco (NOLOCK) -- v1.0   
    
	SELECT  @b_age_bracket_2  = @e_age_bracket_1 + 1,    
			@b_age_bracket_3  = @e_age_bracket_2 + 1,    
			@b_age_bracket_4  = @e_age_bracket_3 + 1,    
			@b_age_bracket_5  = @e_age_bracket_4 + 1,    
			@b_age_bracket_6  = @e_age_bracket_5 + 1     
    
    
	SELECT  @e_age_bracket_1  = 30,    
			@e_age_bracket_2  = 60,    
			@e_age_bracket_3  = 90,    
			@e_age_bracket_4  = 120,    
			@e_age_bracket_5  = 150    
    
    
	SELECT  @b_age_bracket_1  = 1,    
			@b_age_bracket_2  = 31,    
			@b_age_bracket_3  = 61,    
			@b_age_bracket_4  = 91,    
			@b_age_bracket_5  = 121,    
			@b_age_bracket_6  = 151    
    
	CREATE TABLE #invoices    
	(	customer_code    varchar(8),    
		doc_ctrl_num     varchar(16) NULL,    
		date_doc       int   NULL,    
		trx_type       int   NULL,    
		amt_net       float   NULL,    
		amt_paid_to_date  float   NULL,    
		balance       float   NULL,    
		on_acct_flag     smallint  NULL,    
		nat_cur_code    varchar(8)  NULL,    
		apply_to_num     varchar(16)  NULL,    
		sub_apply_num    varchar(16)  NULL,    
		trx_type_code    varchar(8)  NULL,    
		trx_ctrl_num    varchar(16)  NULL,    
		status_code     varchar(5)  NULL,    
		status_date     int   NULL,    
		cust_po_num     varchar(20)  NULL,    
		age_bucket     smallint NULL,    
		date_due      int  NULL,    
		date_aging     int  NULL,    
		date_applied    int  NULL,    
		order_ctrl_num   varchar(16) NULL,    
		artrx_doc_ctrl_num  varchar(16) NULL,    
		org_id       varchar(30) NULL)    
     

	INSERT #invoices (customer_code, doc_ctrl_num, balance)    
	SELECT  a.customer_code,    
			a.apply_to_num ,     
			SUM(a.amount)     
	FROM	#artrxage  a  
	GROUP BY a.customer_code,a.apply_to_num    
	HAVING ABS(SUM(a.amount)) > 0.001    

	-- v4.2 Start
	-- v4.1
	/*
	INSERT #invoices (customer_code, doc_ctrl_num, balance)    
	SELECT  a.customer_code,    
			a.doc_ctrl_num,     
			SUM(a.amount)     
	FROM	#artrxage  a 
	WHERE	(LEFT(a.doc_ctrl_num,3) = 'FIN' OR LEFT(a.doc_ctrl_num,4) = 'LATE')
	AND		a.paid_flag = 0	 
	GROUP BY a.customer_code,a.doc_ctrl_num    
	HAVING ABS(SUM(a.amount)) > 0.001    
	*/
	-- v4.1
	-- v4.2 End


	CREATE INDEX #invoices_idx1 ON #invoices(customer_code, doc_ctrl_num )    

	UPDATE  #invoices    
	SET		amt_net      = h.amt_net,    
			amt_paid_to_date  = h.amt_paid_to_date,    
			balance      = h.amt_net - h.amt_paid_to_date,    
			date_doc      = a.date_doc,    
			date_due      = a.date_due,    
			date_aging     = (1+ sign(sign(a.ref_id) - 1))*a.date_aging + abs(sign(sign(a.ref_id)-1))*a.date_doc,     
			date_applied    = a.date_applied,    
			trx_type      = a.trx_type,    
			nat_cur_code    = a.nat_cur_code,    
			apply_to_num    = a.apply_to_num,    
			sub_apply_num   = a.sub_apply_num,     
			trx_ctrl_num    = a.trx_ctrl_num,    
			cust_po_num    = a.cust_po_num,    
			on_acct_flag    = 0,    
			order_ctrl_num   = a.order_ctrl_num,    
			org_id       = a.org_id    
	FROM	#artrxage a, #invoices i, #artrx h    
	WHERE	a.doc_ctrl_num = i.doc_ctrl_num    
	AND		a.customer_code = i.customer_code    
	AND		a.doc_ctrl_num = h.doc_ctrl_num		
    
	DELETE #invoices where trx_type > 2031 AND trx_type NOT IN (2061,2071) -- v4.1		   
     
	DELETE #invoices where ABS(balance) < 0.01 -- v2.1    


        
	CREATE TABLE #open    
	(	customer_code varchar(8),    
		doc_ctrl_num  varchar(16) NULL,    
		amt_net    float   NULL)    
    
	INSERT #open    
	SELECT	a.customer_code,    
			a.apply_to_num,     
			SUM(a.amount)      
	FROM	#artrxage a    
	LEFT JOIN #invoices i -- v1.4
	ON		a.apply_to_num = i.doc_ctrl_num -- v1.4
	WHERE	i.doc_ctrl_num IS NULL
	GROUP BY a.customer_code, a.apply_to_num    
	HAVING ABS(SUM(a.amount)) > 0.000001     
    
	CREATE INDEX #open_idx1 ON #open( doc_ctrl_num)    
     
	INSERT #invoices     
	(	customer_code,    
		doc_ctrl_num,     
		amt_net,     
		amt_paid_to_date, 
		balance, -- v2.2   
		date_doc,    
		date_due,    
		date_aging,    
		date_applied,    
		trx_type,    
		nat_cur_code,    
		apply_to_num,    
		sub_apply_num,     
		trx_ctrl_num,    
		cust_po_num,    
		on_acct_flag,    
		order_ctrl_num,    
		artrx_doc_ctrl_num,    
		org_id )    
	SELECT a.customer_code,    
		a.doc_ctrl_num,     
		h.amt_net,     
		h.amt_paid_to_date, 
		o.amt_net, -- v2.2   
		h.date_doc,    
		a.date_due,    
		(1+ sign(sign(a.ref_id) - 1))*a.date_aging + abs(sign(sign(a.ref_id)-1))*a.date_doc,     
		h.date_applied,    
		h.trx_type,    
		h.nat_cur_code,    
		a.apply_to_num,    
		a.sub_apply_num,     
		h.trx_ctrl_num,    
		h.cust_po_num,    
		0,    
		h.order_ctrl_num,    
		a.doc_ctrl_num,    
		a.org_id    
	FROM  #artrxage a, #open o, #artrx h
	WHERE  h.paid_flag = 0    
	AND h.trx_type in (2021,2031)    
	AND  a.doc_ctrl_num = o.doc_ctrl_num    
	AND  a.trx_ctrl_num = h.trx_ctrl_num    
  
	-- tag - 12/5/2012    
	-- update invoice hold status using cte instead of in document loop    
	;with cte as     
	(select max(sequence_num) seq, doc_ctrl_num, customer_code, status_code, date    
	from cc_inv_status_hist (NOLOCK) -- v1.0    
	where clear_date is null    
	group by doc_ctrl_num, customer_code, status_code, date)    
	UPDATE  i SET   i.status_code = cte.status_code,    
		i.status_date = cte.date    
		FROM   #invoices i, cte    
		WHERE  i.doc_ctrl_num = cte.doc_ctrl_num    
		AND   i.customer_code = cte.customer_code    
  
	-- update amount paid to date    
    UPDATE  #invoices    
	SET   amt_paid_to_date = (amt_net-balance) * -1    
	WHERE trx_type in (2021,2031)    
            
	SELECT	customer_code,    
			doc_ctrl_num,     
			'true_amount' = SUM(true_amount)    
	INTO	#cm     
	FROM	#artrxage     
	WHERE	paid_flag = 0    
	AND		trx_type in (2111,2161)    
	AND		ref_id < 1    
	GROUP BY customer_code,doc_ctrl_num    
	HAVING ABS(SUM(true_amount)) > 0.0001   

	INSERT #invoices ( customer_code,    
			doc_ctrl_num,    
			date_doc,    
			trx_type,    
			amt_net,    
			amt_paid_to_date,    
			on_acct_flag,    
			nat_cur_code,    
			apply_to_num,    
			sub_apply_num,    
			trx_ctrl_num,    
			date_due,    
			date_aging,    
			date_applied,    
			order_ctrl_num,    
			artrx_doc_ctrl_num,    
			org_id )    
	SELECT  a.customer_code,    
			a.doc_ctrl_num,    
			date_doc,    
			trx_type,    
			a.true_amount,    
			amt_paid,    
			1,     
			nat_cur_code,    
			apply_to_num,    
			sub_apply_num,     
			trx_ctrl_num,    
			a.date_due,    
			date_aging = (1+ sign(sign(a.ref_id) - 1))*a.date_aging + abs(sign(sign(a.ref_id)-1))*a.date_doc,     
			date_applied,    
			order_ctrl_num,    
			a.doc_ctrl_num,    
			a.org_id    
	FROM  #artrxage a, #cm c    
	WHERE  a.customer_code = c.customer_code    
	AND  trx_type in (2111,2161)     
	AND  (amount > 0.000001 or amount < -0.000001 )    
	AND  a.apply_to_num = a.doc_ctrl_num    
	AND  paid_flag = 0    
	AND  ref_id = 0    
	AND  a.doc_ctrl_num = c.doc_ctrl_num    
	AND  ISNULL(DATALENGTH(RTRIM(LTRIM(c.doc_ctrl_num))), 0 ) > 0    

	DROP TABLE #cm    

	DELETE #invoices WHERE trx_type IS NULL

	UPDATE  #invoices     
	SET		cust_po_num = h.cust_po_num    
	FROM	#invoices i, #artrx h    
	WHERE	i.doc_ctrl_num = h.doc_ctrl_num    
	AND		i.customer_code = h.customer_code    
 
	DELETE  #invoices    
	WHERE  doc_ctrl_num in (SELECT a.doc_ctrl_num     
	FROM  #artrxage a, #invoices i     
	WHERE  a.apply_trx_type = 2031     
	AND  a.trx_type = 2112    
	AND  a.customer_code = i.customer_code )    
	AND on_acct_flag = 1    
	AND trx_type NOT IN ( 2161, 2111)    
 
	DELETE #invoices     
	WHERE doc_ctrl_num in ( SELECT a.doc_ctrl_num     
	FROM #artrx a, #invoices i     
	WHERE a.void_flag = 1        
	AND a.customer_code = i.customer_code )    
	AND trx_type in (2111,2161)     
 
	UPDATE  #invoices    
	SET  #invoices.trx_type_code = artrxtyp.trx_type_code    
	FROM  #invoices, artrxtyp    
	WHERE  artrxtyp.trx_type = #invoices.trx_type    
	        
	-- Update on account balances    

	; with cte as      
	( select sum(amount) bal, a.doc_ctrl_num, a.customer_code    
	   from #artrxage a, #invoices i     
	   where a.doc_ctrl_num = i.artrx_doc_ctrl_num    
	   and a.customer_code = i.customer_code    
	   and ref_id < 1    
	   group by a.doc_ctrl_num, a.customer_code    
	  )    

	update i set i.balance = cte.bal    
	from #invoices i, cte    
	where i.doc_ctrl_num = cte.doc_ctrl_num and i.customer_code = cte.customer_code    
	and i.on_acct_flag = 1    
  
     
	--PJC 20120405    
	DECLARE @date int    
    
	SELECT @last_cust = MIN(customer_code) FROM #invoices    
	WHILE ( @last_cust IS NOT NULL )    
	BEGIN    
		SELECT @last_doc = MIN(doc_ctrl_num ) FROM #invoices WHERE trx_type IN (2112,2113,2121) AND customer_code = @last_cust    
    
		WHILE ( @last_doc IS NOT NULL )    
		BEGIN    
			SELECT @date = date_doc    
			FROM #invoices    
			WHERE doc_ctrl_num = @last_doc    
			AND trx_type = 2111    
			AND customer_code = @last_cust    
        
			UPDATE #invoices    
			SET date_doc = @date    
			WHERE doc_ctrl_num = @last_doc    
			AND customer_code = @last_cust    
			 
			SELECT @last_doc = MIN(doc_ctrl_num )     
			FROM #invoices    
			WHERE doc_ctrl_num = @last_doc     
			AND trx_type IN (2112,2113,2121)    
			AND customer_code = @last_cust    
		END    
		SELECT @last_cust = MIN(customer_code) FROM #invoices WHERE customer_code > @last_cust    
	END    
     
    
	SELECT @last_cust = MIN(customer_code) FROM #invoices    
	WHILE ( @last_cust IS NOT NULL )    
	BEGIN    
		SELECT @last_doc = MIN(doc_ctrl_num ) FROM #invoices WHERE on_acct_flag = 1 -- v2.4 AND date_due = 0 
																	AND customer_code = @last_cust    
		WHILE ( @last_doc IS NOT NULL )    
		BEGIN    
			SELECT @date_doc = MIN(date_doc)    
			FROM #invoices    
			WHERE doc_ctrl_num = @last_doc    
			AND customer_code = @last_cust    
     
		    SELECT @terms_code = terms_code FROM artrx (NOLOCK) WHERE doc_ctrl_num = @last_doc AND customer_code = @last_cust    
			/* PJC 042413 - get terms code from customer when terms code is blank */    
			IF ( @terms_code = '' OR @terms_code IS NULL )    
				SELECT @terms_code = terms_code from arcust (NOLOCK) where customer_code = @last_cust    
          
			IF ( SELECT ISNULL(DATALENGTH(LTRIM(RTRIM(@terms_code))), 0)) = 0     
				SELECT @terms_code = terms_code FROM arcust (NOLOCK) WHERE customer_code = @last_cust    
    
			EXEC CVO_CalcDueDate_sp @last_cust, @date_doc, @date_due OUTPUT, @terms_code    

			/* PJC 042413 - use doc date if due date is blank */    
			IF ( @date_due = 0 or @date_due IS NULL )    
				SELECT @date_due = @date_doc    
        
			UPDATE	#invoices     
			SET		date_due = @date_due,    
					date_aging = @date_due    
			WHERE	doc_ctrl_num = @last_doc    
			AND		trx_type <> 2031    
			AND		customer_code = @last_cust    
    
			SELECT @last_doc = MIN(doc_ctrl_num )    
			FROM #invoices     
-- v2.4		WHERE doc_ctrl_num = 'ON ACCT'    
			WHERE doc_ctrl_num > @last_doc --    
			-- v2.4 AND date_due = 0    
			AND customer_code = @last_cust    
			AND on_acct_flag = 1    
		END    
		SELECT @last_cust = MIN(customer_code) FROM #invoices WHERE customer_code > @last_cust    
	END    
    
	EXEC cvo_set_bucket_sp    
    
	--PJC 042513 - the stored procedure is messing up the dates    
	update #invoices set date_due = date_doc where date_due < 639906 and date_doc > 639906    
         
    UPDATE #invoices    
    SET age_bucket = 1    
    WHERE date_due BETWEEN ( SELECT date_start FROM #dates     
          WHERE bucket = 'current' )     
          AND ( SELECT date_end FROM #dates     
          WHERE bucket = 'current' )    
     
    UPDATE #invoices    
    SET age_bucket = 2    
    WHERE date_due BETWEEN ( SELECT date_start FROM #dates     
          WHERE bucket = '1-30' )     
          AND ( SELECT date_end FROM #dates     
          WHERE bucket = '1-30' )    
     
    UPDATE #invoices    
    SET age_bucket = 3    
    WHERE date_due BETWEEN ( SELECT date_start FROM #dates     
          WHERE bucket = '31-60' )     
          AND ( SELECT date_end FROM #dates     
          WHERE bucket = '31-60' )    
     
    UPDATE #invoices    
    SET age_bucket = 4    
    WHERE date_due BETWEEN ( SELECT date_start FROM #dates     
          WHERE bucket = '61-90' )     
          AND ( SELECT date_end FROM #dates     
          WHERE bucket = '61-90' )    
 
    UPDATE #invoices    
    SET age_bucket = 5    
    WHERE date_due BETWEEN ( SELECT date_start FROM #dates     
          WHERE bucket = '91-120' )     
          AND ( SELECT date_end FROM #dates     
          WHERE bucket = '91-120' )    
     
    UPDATE #invoices    
    SET age_bucket = 6    
    WHERE date_due < ( SELECT date_start FROM #dates WHERE bucket = '91-120' )    
     
    UPDATE #invoices    
    SET age_bucket = 0    
    WHERE date_due > ( SELECT date_end FROM #dates WHERE bucket = 'future' )    

    
    IF (@from_aging = 1)
	BEGIN

		insert #ab(customer_code, doc_ctrl_num, date_doc, trx_type, amt_net, amt_paid_to_date, balance,
				on_acct_flag, nat_cur_code, apply_to_num, trx_type_code, trx_ctrl_num, status_code,
				status_date, comment, age_bucket, date_due, order_ctrl_num, comment_count, [rowcount])     
		 SELECT  customer_code,    
				 doc_ctrl_num,    
				 'date_doc' = CASE WHEN date_doc > 639906 THEN CONVERT(varchar(12), DATEADD(dd, date_doc - 639906, '1/1/1753'),101)     
			--      ELSE 'Invalid Date' END,    
				   ELSE ' ' END,    
				 trx_type,     
				 'amt_net' = ISNULL(STR(amt_net,30,6), 0),    
				 'amt_paid_to_date' = ISNULL(STR(amt_paid_to_date,30,6), 0),    
				 'balance' = ISNULL(STR(balance,30,6), 0),    
				 'on_acct_flag' = CASE WHEN on_acct_flag = 1 THEN 'OA' ELSE '' END,    
				 nat_cur_code,    
				 apply_to_num,    
				 trx_type_code,    
				 trx_ctrl_num,    
				 'status_code' = ISNULL(status_code, '  '),    
				 'status_date' = CASE WHEN date_doc > 639906 THEN CONVERT(varchar(12), DATEADD(dd, status_date - 639906, '1/1/1753'),101) ELSE '  ' END,    
				 ISNULL(cust_po_num,'   '),    
				 age_bucket,    
				 'date_due' = CASE WHEN date_due > 639906 THEN CONVERT(varchar(12), DATEADD(dd, date_due - 639906, '1/1/1753'),101)     
			--      ELSE 'Invalid Date' END,    
				   ELSE ' ' END,    
				 order_ctrl_num,    
				 'comment_count' = ( SELECT COUNT(1)     
				  FROM comments     
				  WHERE key_1 IN (SELECT a.trx_ctrl_num     
						  FROM #artrx a, #invoices i    
						  WHERE a.doc_ctrl_num = i.doc_ctrl_num    
						  AND a.customer_code = i.customer_code)),    
				 'rowCount' = ( SELECT COUNT(*) FROM #invoices )    
				FROM  #invoices     
				ORDER BY date_doc, doc_ctrl_num, customer_code, ABS(trx_type - 2021) 
	END
	ELSE
    BEGIN   
		SELECT  customer_code,    
				 doc_ctrl_num,    
				 'date_doc' = CASE WHEN date_doc > 639906 THEN CONVERT(varchar(12), DATEADD(dd, date_doc - 639906, '1/1/1753'),101)     
			--      ELSE 'Invalid Date' END,    
				   ELSE ' ' END,    
				 trx_type,     
				 'amt_net' = amt_net, --ISNULL(STR(amt_net,30,6), 0),    
				 'amt_paid_to_date' = amt_paid_to_date, --ISNULL(STR(amt_paid_to_date,30,6), 0),    
				 'balance' = balance, --ISNULL(STR(balance,30,6), 0),    
				 'on_acct_flag' = CASE WHEN on_acct_flag = 1 THEN 'OA' ELSE '' END,    
				 nat_cur_code,    
				 apply_to_num,    
				 trx_type_code,    
				 trx_ctrl_num,    
				 'status_code' = ISNULL(status_code, '  '),    
				 'status_date' = CASE WHEN date_doc > 639906 THEN CONVERT(varchar(12), DATEADD(dd, status_date - 639906, '1/1/1753'),101) ELSE '  ' END,    
				 RIGHT(ISNULL(cust_po_num,'   '),10), -- 7/21 TAG    
				 age_bucket,    
				 'date_due' = CASE WHEN date_due > 639906 THEN CONVERT(varchar(12), DATEADD(dd, date_due - 639906, '1/1/1753'),101)     
			--      ELSE 'Invalid Date' END,    
				   ELSE ' ' END,    
				 order_ctrl_num,    
				 'comment_count' = ( SELECT COUNT(1)     
				  FROM comments     
				  WHERE key_1 IN (SELECT a.trx_ctrl_num     
						  FROM #artrx a, #invoices i    
						  WHERE a.doc_ctrl_num = i.doc_ctrl_num    
						  AND a.customer_code = i.customer_code)),    
				 'rowCount' = ( SELECT COUNT(*) FROM #invoices )
		FROM  #invoices
		ORDER BY date_doc, doc_ctrl_num, customer_code, ABS(trx_type - 2021)	
	END    
        
	SET NOCOUNT OFF    
    
	DROP TABLE #bg_data
END

GO
GRANT EXECUTE ON  [dbo].[cc_open_inv_sp] TO [public]
GO
