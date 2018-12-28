SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC cc_pymt_hist_sp '035171',0, 0, 1, 'CVO', 'CVO', 1, 1
  
CREATE PROCEDURE [dbo].[cc_pymt_hist_sp] @customer_code  varchar(8) = NULL,  
                 @num_days int = 365,  
                 @num_trx int = 50,  
                 @all_org_flag   smallint = 0,    
                 @from_org varchar(30) = '',  
                 @to_org varchar(30) = '',  
                 @sort_by     tinyint = 2,  
                 @sort_type    tinyint = 2  
  
  
AS  
  
  -- v1.0 CB 06/06/2013 - Issue #1287 - Include voided checks in the detail and remove from the header  
  -- v1.1 CB 27/06/2013 - Issue #1328 - When checking for details use the #customers table to ensure that all customers for the buying group are included
  -- v1.2 CB 01/07/2013 - Issue #1328 - When running by child include payments from parent
  -- v1.3 CB 24/07/2013 - Issue #927 - Buying Group Switching
  -- v1.4 CB 17/09/2013 - Issue #927 - Buying Group Switching - RB Orders set to and from BGs
  -- v1.5 CB 01/10/2013 - Issue #927 - Buying Group Switching - Deal with non BG customers
  -- v1.6 CB 05/11/2013 - Peformance
  -- v1.7 CB 06/11/2013 - Fix issue with non BG parents
  -- v1.8 CB 05/11/2013 - Peformance
  -- v1.9 CB 09/12/2013 - Issue when customer is added and removed from buying group
  -- v2.0 CB 30/12/2013 - Issue with voided payments
  -- v3.0 CB 10/06/2014 - ReWrite of BG data
  -- v3.1 CB 16/01/2015 - Include transactions for customer or parent
  -- v3.2 CB 19/08/2015 - Stop the void records showing twice
  -- v3.3 CB 15/09/2015 - #1524 - Add order number to payment history
  -- v3.4 CB 10/12/2018 - Fix issue with data doubling up

 SET NOCOUNT ON  
  
 DECLARE @trx_ctrl_num varchar(16),  
     @doc_ctrl_num varchar(16),  
     @on_acct    float,  
     @amt_net   float ,  
     @row      int  
  
 DECLARE @detail_count int,  
     @order varchar(255),  
     @num_days_str varchar(15),  
     @detail int,  
     @cc_comments int,  
     @comments int,  
     @last_cust varchar(8)  
  
  
 DECLARE @relation_code varchar(10),
		 @IsParent int, -- v1.4  
		 @Parent varchar(8), -- v1.5
		 @IsBG int -- v1.7

 SELECT @relation_code = credit_check_rel_code  
 FROM arco (NOLOCK)  
  
  
 IF ( SELECT ib_flag FROM glco ) = 0  
  SELECT @all_org_flag = 1  
  
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
	EXEC cvo_bg_get_document_data_sp @customer_code
   
	CREATE INDEX #bg_data_ind22 ON #bg_data (customer_code, doc_ctrl_num)
    
	INSERT #customers    
	SELECT DISTINCT customer_code FROM #bg_data    
    
    CREATE INDEX #customers_ind1 ON #customers(customer_code) 

	SELECT	DISTINCT a.* -- v3.4
	INTO	#artrxage   
	FROM	artrxage a (NOLOCK) 
	JOIN	#bg_data b
	-- v3.1	ON		a.customer_code = b.customer_code
	ON		(a.customer_code = b.customer_code OR a.customer_code = b.parent) -- v3.1
	AND		a.doc_ctrl_num = b.doc_ctrl_num

	CREATE INDEX #artrxage_idx1 ON #artrxage(customer_code, apply_to_num)    
	CREATE INDEX #artrxage_idx2 ON #artrxage(customer_code, doc_ctrl_num, trx_type)   
	CREATE INDEX #artrxage_idx3 ON #artrxage(order_ctrl_num)  

	SELECT	DISTINCT a.* -- v3.4
	INTO	#artrx   
	FROM	artrx a (NOLOCK) 
	JOIN	#bg_data b
	-- v3.1	ON		a.customer_code = b.customer_code
	ON		(a.customer_code = b.customer_code OR a.customer_code = b.parent) -- v3.1
	AND		a.doc_ctrl_num = b.doc_ctrl_num	

	CREATE INDEX #artrx_idx1 ON #artrx(customer_code, doc_ctrl_num, trx_type)    
	CREATE INDEX #artrx_idx2 ON #artrx(order_ctrl_num)        
	CREATE INDEX #artrx_idx3 ON #artrx(trx_ctrl_num)        

  CREATE TABLE #payments  
 (  
  trx_ctrl_num    varchar(16) NULL,  
  doc_ctrl_num    varchar(16) NULL,  
  date_doc      int NULL,  
  trx_type      int NULL,  
  amt_net      float NULL,  
  amt_paid_to_date  float NULL,  
  balance      float NULL,  
  customer_code   varchar(12) NULL,  
  void_flag     smallint NULL,  
  trx_type_code   varchar(8) NULL,  
  payment_type    smallint NULL,  
  nat_cur_code   varchar(8) NULL,  
  date_sort     int,  
  date_applied   int NULL,  
  price_code    varchar(8) NULL,  
  amt_on_acct    float NULL,  
  sequence_id    int NULL,
  order_ctrl_num varchar(30) NULL, -- v3.3  
  org_id varchar(30) NULL )  
  
 CREATE table #results  
 (  customer_code varchar(8),  
   trx_ctrl_num   varchar(16) NULL  )  
  
 CREATE TABLE #pmt_final  
 ( trx_ctrl_num    varchar(16) NULL,  
  doc_ctrl_num    varchar(16) NULL,  
  date_doc      int NULL,  
  trx_type      int NULL,  
  amt_net      float NULL,  
  amt_paid_to_date  float NULL,  
  balance      float NULL,  
  customer_code   varchar(12) NULL,  
  void_flag     smallint NULL,  
  trx_type_code   varchar(8) NULL,  
  payment_type    smallint NULL,  
  nat_cur_code   varchar(8) NULL,  
  date_sort     int,  
  date_applied   int NULL,  
  price_code    varchar(8) NULL,  
  cc_comments_count int NULL,  
  comments_count  int NULL,  
  detail_count int NULL,  
  sort_date     int     NULL,  
  order_ctrl_num varchar(30) NULL, -- v3.3
  org_id varchar(30) NULL )  
  
  
 SELECT @num_days_str = CONVERT( varchar(15), @num_days )  
  
  
 IF ( @sort_by = 1 AND @sort_type = 1 )  
  SELECT @order = ' ORDER BY  h.date_doc,  h.doc_ctrl_num'  
 IF ( @sort_by = 1 AND @sort_type = 2 )  
  SELECT @order = 'ORDER BY  h.date_doc DESC,  h.doc_ctrl_num'  
 IF ( @sort_by = 2 AND @sort_type = 1 )  
  SELECT @order = ' ORDER BY  h.doc_ctrl_num, h.date_doc'  
 IF ( @sort_by = 2 AND @sort_type = 2 )  
  SELECT @order = ' ORDER BY  h.doc_ctrl_num DESC, h.date_doc'  
 IF ( @sort_by = 3 AND @sort_type = 1 )  
  SELECT @order = ' ORDER BY  h.customer_code, h.date_doc,  h.doc_ctrl_num'  
 IF ( @sort_by = 3 AND @sort_type = 2 )  
  SELECT @order = 'ORDER BY  h.customer_code DESC, h.date_doc,  h.doc_ctrl_num'  
  
IF @num_days > 0  
		INSERT #payments  
		SELECT  trx_ctrl_num,   
		  doc_ctrl_num,  
		  date_doc,  
		  trx_type,  
		  amt_net,  
		  null,  
		  amt_on_acct,  
		  customer_code,  
		  void_flag,  
		  NULL,  
		  payment_type,  
		  nat_cur_code,  
		  date_doc,  
		  date_applied,  
		  price_code,  
		  amt_on_acct,  
		  0,  
		  order_ctrl_num, -- v3.3
		  org_id  
	  FROM #artrx   
	  WHERE date_doc > DATEDIFF(dd,'01/01/1753',getdate()) + 639906 - @num_days  
	  AND trx_type = 2111  
	  AND payment_type = 1  
 ELSE  
	  INSERT #payments  
	  SELECT  trx_ctrl_num,   
		  doc_ctrl_num,  
		  date_doc,  
		  trx_type,  
		  amt_net,  
		  null,  
		  amt_on_acct,  
		  customer_code,  
		  void_flag,  
		  NULL,  
		  payment_type,  
		  nat_cur_code,  
		  date_doc,  
		  date_applied,  
		  price_code,  
		  amt_on_acct,  
		  0,  
		  order_ctrl_num, -- v3.3
		  org_id  
	  FROM #artrx   
	  WHERE trx_type = 2111  
	  AND payment_type = 1  

		  
IF @num_days > 0  
	  INSERT #payments  
	  SELECT  trx_ctrl_num,   
		  doc_ctrl_num,  
		  date_doc,  
		  trx_type,  
		  amt_net,  
		  null,  
		  amt_on_acct,  
		  customer_code,  
		  void_flag,  
		  NULL,  
		  payment_type,  
		  nat_cur_code,  
		  date_doc,  
		  date_applied,  
		  price_code,  
		  amt_on_acct,  
		  0,  
		  order_ctrl_num, -- v3.3
		  org_id  
	  FROM #artrx   
	  WHERE date_doc > DATEDIFF(dd,'01/01/1753',getdate()) + 639906 - @num_days  
	  AND trx_type = 2032  
	  AND payment_type = 0  
 ELSE  
	  INSERT #payments  
	  SELECT  trx_ctrl_num,   
		  doc_ctrl_num,  
		  date_doc,  
		  trx_type,  
		  amt_net,  
		  null,  
		  amt_on_acct,  
		  customer_code,  
		  void_flag,  
		  NULL,  
		  payment_type,  
		  nat_cur_code,  
		  date_doc,  
		  date_applied,  
		  price_code,  
		  amt_on_acct,  
		  0,  
		  order_ctrl_num, -- v3.3
		  org_id  
	  FROM #artrx   
	  WHERE trx_type = 2032  
	  AND payment_type = 0  
		  
		  
CREATE INDEX payments_idx_1 ON #payments( customer_code, doc_ctrl_num, payment_type )  
CREATE INDEX payments_idx_2 ON #payments( customer_code, doc_ctrl_num, trx_type )  
CREATE INDEX payments_idx_3 ON #payments( customer_code, doc_ctrl_num, trx_ctrl_num )  

  
 IF @all_org_flag = 0  
	DELETE #payments  WHERE org_id NOT BETWEEN @from_org AND @to_org  
		  
SET @last_cust = NULL
SET @doc_ctrl_num = NULL
  
SELECT @last_cust = MIN(customer_code) FROM #payments  
WHILE ( @last_cust IS NOT NULL )  
BEGIN  

	SELECT @doc_ctrl_num = MIN(doc_ctrl_num)   
	FROM #payments   
	WHERE payment_type <> 3  
	AND customer_code = @last_cust  
  
	WHILE (@doc_ctrl_num IS NOT NULL)  
	BEGIN  

		IF ( SELECT COUNT(*) FROM #payments WHERE doc_ctrl_num = @doc_ctrl_num  
							AND customer_code = @last_cust  
							AND payment_type = 2 ) > 0  
		BEGIN  
			SELECT  @on_acct = amt_on_acct,  
					@amt_net = amt_net  
			FROM	#payments  
			WHERE	doc_ctrl_num = @doc_ctrl_num  
			AND		customer_code = @last_cust  
			AND		payment_type = 1   
       
			UPDATE	#payments  
			SET		balance = @on_acct,  
					amt_net = @amt_net  
			WHERE	doc_ctrl_num = @doc_ctrl_num  
			AND		customer_code = @last_cust  
			AND		payment_type = 2   
      
			DELETE	#payments  
			WHERE	doc_ctrl_num = @doc_ctrl_num  
			AND		customer_code = @last_cust  
			AND		payment_type = 1  
		END  
     
		SELECT	@doc_ctrl_num = MIN(doc_ctrl_num)   
		FROM	#payments  
		WHERE	doc_ctrl_num > @doc_ctrl_num        
		AND		payment_type <> 3  
		AND		customer_code = @last_cust 	

	END   

	SELECT	@last_cust = MIN(customer_code)   
	FROM	#payments  
	WHERE	customer_code > @last_cust  
END  
  
SET @last_cust = NULL
SET @doc_ctrl_num = NULL

SELECT @last_cust = MIN(customer_code) FROM #payments  
WHILE ( @last_cust IS NOT NULL )  
BEGIN  

	SELECT @doc_ctrl_num = MIN(doc_ctrl_num)   
	FROM #payments   
	WHERE payment_type = 0  
	AND customer_code = @last_cust  
  
	WHILE (@doc_ctrl_num IS NOT NULL)  
	BEGIN  

		SELECT  @amt_net = SUM(amount)  
		FROM #artrxage  
		WHERE doc_ctrl_num = @doc_ctrl_num  
		AND customer_code = @last_cust  
		AND trx_type > 2031   
		AND ref_id < 1  
  
		UPDATE #payments  
		SET balance = @amt_net,  
		 amt_paid_to_date = ABS(amt_net) - ABS(@amt_net)  
		WHERE doc_ctrl_num = @doc_ctrl_num  
		AND customer_code = @last_cust  
      
		SELECT @doc_ctrl_num = MIN(doc_ctrl_num)   
		FROM #payments  
		WHERE doc_ctrl_num > @doc_ctrl_num  
		AND payment_type = 0  
		AND customer_code = @last_cust  
	END   
	SELECT @last_cust = MIN(customer_code)   
	FROM #payments  
	WHERE customer_code > @last_cust  
 END  


-- v3.2 Start	  
--	 INSERT #payments  
--	 SELECT p.trx_ctrl_num,   
--		 a.doc_ctrl_num,  
--		 a.date_doc,  
--		 a.trx_type,  
--		 a.amt_net * -1,  
--		 NULL,  
--		 a.amt_on_acct * -1,  
--		 a.customer_code,  
--		 a.void_flag,  
--		 NULL,  
--		 a.payment_type,  
--		 a.nat_cur_code,  
--		 p.date_doc,  
--		 p.date_applied,  
--		 a.price_code,  
--		 a.amt_on_acct,  
--		 0,  
--		 a.org_id  
--	 FROM #payments p, artrx a  (NOLOCK) 
--	 WHERE a.trx_type in (2112, 2113, 2121)  
--	 AND a.customer_code = p.customer_code  
--	 AND a.doc_ctrl_num = p.doc_ctrl_num   
-- v3.2 End	  
	  
 
	  
	  
	 UPDATE #payments   
	 SET date_sort = b.date_doc  
	 FROM #payments , #payments b  
	 WHERE #payments.trx_ctrl_num = b.trx_ctrl_num  
	 AND #payments.trx_type = 9999  
	 AND b.trx_type = 2111  
	 AND #payments.sequence_id = b.sequence_id  
	  
	  
	 UPDATE #payments  
	 SET #payments.trx_type_code = artrxtyp.trx_type_code  
	 FROM #payments,artrxtyp  
	 WHERE artrxtyp.trx_type = #payments.trx_type  
	  
	  
	 DELETE FROM #payments WHERE payment_type = 3  
	  
	 UPDATE #payments SET trx_type = 9999 WHERE trx_type is null  
	  
	  
	 SET ROWCOUNT @num_trx  
	 INSERT #results  
	--PJC 122112 SELECT customer_code, trx_ctrl_num FROM #payments WHERE trx_type = 2111 ORDER BY date_doc DESC   
	 SELECT customer_code, trx_ctrl_num FROM #payments GROUP BY customer_code, trx_ctrl_num  
	 SET ROWCOUNT 0  




	  
	 EXEC( ' INSERT #pmt_final  
		 ( trx_ctrl_num,  
		  doc_ctrl_num,  
		  date_doc,  
		  trx_type,  
		  amt_net,  
		  amt_paid_to_date,  
		  balance,  
		  customer_code,  
		  void_flag,  
		  trx_type_code,  
		  payment_type,  
		  nat_cur_code,  
		  date_sort,  
		  date_applied,  
		  price_code,  
		  sort_date, 
		  order_ctrl_num, 
		  org_id )  
		 SELECT  h.trx_ctrl_num,  
			 doc_ctrl_num,  
			 date_doc,  
			 trx_type,  
			 "amt_net" = STR(amt_net,30,6),   
			 "amt_paid_to_date" = STR(amt_paid_to_date,30,6),   
			 "balance" = STR(balance,30,6),   
			 h.customer_code,  
			 void_flag,  
			 trx_type_code,  
			 payment_type,  
			 nat_cur_code,  
			 date_sort,  
			 date_applied,  
			 price_code,  
			 date_doc,
			 order_ctrl_num,  
			 h.org_id   
		 FROM  #payments h, #results r  
		 WHERE  h.trx_ctrl_num = r.trx_ctrl_num   
		 AND h.customer_code = r.customer_code ' + @order )  -- v3.3

SET @last_cust = NULL
SET @doc_ctrl_num = NULL

SELECT @last_cust = MIN(customer_code) FROM #pmt_final  
WHILE ( @last_cust IS NOT NULL )  
BEGIN  
	SELECT @doc_ctrl_num = MIN(doc_ctrl_num)   
	FROM #pmt_final   
	WHERE customer_code = @last_cust  
    
	WHILE ( @doc_ctrl_num IS NOT NULL )  
    BEGIN  
  

		 SELECT @detail =  COUNT(apply_to_num)   
		 FROM #artrxage  a -- v1.4
		 WHERE doc_ctrl_num <> apply_to_num  -- v1.4
		 AND apply_trx_type < 2111  
		 AND doc_ctrl_num = @doc_ctrl_num  

	    SELECT @cc_comments = COUNT(*)   
	    FROM cc_comments  
	    WHERE doc_ctrl_num = @doc_ctrl_num  
	    AND customer_code = @last_cust  
    
	    SELECT @comments = COUNT(*)   
	    FROM comments  
	    WHERE key_1 IN ( SELECT trx_ctrl_num   
		FROM #pmt_final   
        WHERE doc_ctrl_num = @doc_ctrl_num  
        AND customer_code = @last_cust )  
    
		UPDATE #pmt_final  
		SET detail_count = @detail,  
			cc_comments_count = @cc_comments,  
			comments_count = @comments  
		WHERE doc_ctrl_num = @doc_ctrl_num  
		AND customer_code = @last_cust  
    
		SELECT @doc_ctrl_num = MIN(doc_ctrl_num)   
		FROM #pmt_final   
		WHERE doc_ctrl_num > @doc_ctrl_num  
		AND customer_code = @last_cust  
	END  
	SELECT @last_cust = MIN(customer_code)   
	FROM #pmt_final  
	WHERE customer_code > @last_cust  
END
  
  
UPDATE #pmt_final  
SET trx_type = 2111  
WHERE trx_type = 2032  

-- v2.0 Start
UPDATE	#pmt_final
SET		balance = 0
WHERE	void_flag = 1

UPDATE	#pmt_final
SET		balance = 0
WHERE	trx_type IN (2121, 2142, 2112, 2113)
-- v2.0 End

  
EXEC( 'SELECT DISTINCT trx_ctrl_num,  -- v3.1
     doc_ctrl_num,  
     date_doc,  
     trx_type,  
     amt_net,  
     amt_paid_to_date,  
     balance,  
     customer_code,  
     void_flag,  
     trx_type_code,  
     payment_type,  
     nat_cur_code,  
     date_sort,  
     date_applied,  
     price_code,  
     cc_comments_count,  
     comments_count,  
     org_id,  
     detail_count,  
     sort_date,  
	 order_ctrl_num
 FROM #pmt_final h WHERE trx_type <> 9999 ' + @order )  -- v1.0 Exclude 9999 - now in the details -- v3.3
  
DROP TABLE #payments  
DROP TABLE #results  
DROP TABLE #pmt_final  
DROP TABLE #bg_data  
  
SET NOCOUNT OFF  
GO
GRANT EXECUTE ON  [dbo].[cc_pymt_hist_sp] TO [public]
GO
