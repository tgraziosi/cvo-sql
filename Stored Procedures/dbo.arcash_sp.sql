SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 18/07/2013 - Issue #927 - Buying Group Switching
-- v1.1 CB 13/09/2013 - Issue #927 - Buying Group Switching - Insert records where the order is set to RB and a buying group was set for a customer not affiliated
-- v1.2 CB 13/09/2013 - Issue #927 - Buying Group Switching - Remove records where the order is set to RB and a customer affiliated was set to no buying group
-- v1.3 CB 26/09/2013 - Issue #927 - Buying Group Switching - Remove records for customers where transaction link to buying groups
  
CREATE PROCEDURE  [dbo].[arcash_sp]	@i_trx_ctrl_num      varchar( 16 ),      
									@i_doc_ctrl_num  varchar( 16 ),      
									@amt_payment  float,      
									@auto_apply  smallint,      
									@auto_detail  smallint,      
									@desc   varchar( 40 ),      
									@restrict_by_cur smallint,      
									@pymt_cur_code  varchar( 8),      
									@home_cur_code  varchar( 8),      
									@oper_cur_code  varchar( 8),      
									@cr_date_applied int,      
									@cr_date_doc  int,      
									@rate_home  float,      
									@rate_oper  float,      
									@rate_type_home  varchar( 8),      
									@org_id   varchar(30) = ''         
AS               
      
	DECLARE	@sequence_id  int,      
			@inv_sequence_id int,      
			@customer_code  varchar( 8 ),      
			@apply_to_num  varchar( 16 ),      
			@apply_trx_type  smallint,      
			@doc_ctrl_num  varchar( 16 ),      
			@remain_bal  float,      
			@amount   float,      
			@amt_paid  float,      
			@amt_pyt_unposted float,      
			@amt_applied  float,      
			@min_date_due  int,      
			@cross_rate  float,      
			@gain_home  float,      
			@gain_oper  float,      
			@inv_amt_applied float,      
			@new_bal  float,      
			@result   int,      
			@after_entry_flag int,      
			@amt_payment_inv float,      
			@pymt_curr_precision smallint,      
			@date_aging  int,      
			@trx_type  int,      
			@year   int,      
			@month   int,      
			@day   int,      
			@payoff_inv_flag smallint,      
			@disc_payoff_inv_flag smallint,      
			@discount_flag  smallint,      
			@discount_amt  float,      
			@balance  float,      
			@inv_posted_disc float,      
			@inv_amt_applied_temp float,      
			@bal_fwd_flag  smallint,      
			@cur_row  numeric,      
			@age_apply_num  numeric,      
			@dis_doc  varchar(16),      
			@dis_trx_type  smallint,      
			@dis_terms_code  varchar(8),      
			@dis_doc_date  int,      
			@discount_flag_2 smallint,      
			@discount_prc  float,      
			@stmt_date   int,      
			@cus_code   varchar(16),
			@parent		varchar(10) -- v1.0      
        
BEGIN      
      
	SELECT @sequence_id = 1      
      
	SELECT	@pymt_curr_precision = curr_precision      
	FROM	glcurr_vw (NOLOCK)     
	WHERE	currency_code = @pymt_cur_code      
      
    SELECT	@amt_payment = @amt_payment + total_chargebacks      
	FROM	arcbtot (NOLOCK)
	WHERE	trx_ctrl_num = @i_trx_ctrl_num       
      
      
	DELETE #arvalbfd      
           
	EXEC appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @cr_date_doc   

	--MOD 001 CSG; PSALINAS 09/07/10       
	SELECT @cus_code = customer_code FROM #arvpay  ORDER BY customer_code DESC     
      
	SELECT	@stmt_date = stmt_date  
	FROM	cvo_cashrec_stmt_date (NOLOCK)      
	WHERE	trx_ctrl_num = @i_trx_ctrl_num AND customer_code = @cus_code       
	--MOD 001 END      

	-- v1.0 Start
	CREATE TABLE #bg_left(
		customer_code	varchar(10),
		end_date		int)

	CREATE TABLE #bg_start(
		customer_code	varchar(10),
		start_date		int)

	SET @parent = ''
	
--	SELECT	@parent = a.parent 
--	FROM	arnarel a (NOLOCK)
--	JOIN	arcust b
--	ON		a.parent = b.customer_code
--	WHERE	a.child = @cus_code
--	AND		b.addr_sort1 = 'Buying Group'


	IF EXISTS (SELECT 1 FROM cvo_buying_groups_hist (NOLOCK) WHERE parent = @cus_code)
	BEGIN

		SET @parent = @cus_code

		SELECT	@stmt_date = stmt_date  
		FROM	cvo_cashrec_stmt_date (NOLOCK)      
		WHERE	trx_ctrl_num = @i_trx_ctrl_num AND customer_code = @parent       

		INSERT	#bg_left
		SELECT	DISTINCT child, end_date_int
		FROM	cvo_buying_groups_hist (NOLOCK) 
		WHERE	parent = @parent
		AND		end_date_int <= @stmt_date

		INSERT	#arvpay
		SELECT	a.child, b.customer_name, b.bal_fwd_flag, 0
		FROM	dbo.f_cvo_get_buying_group_child_pay_list(@parent,@stmt_date) a
		JOIN	arcust b (NOLOCK) 
		ON		a.child = b.customer_code

		INSERT	#bg_start
		SELECT	DISTINCT child, start_date_int
		FROM	cvo_buying_groups_hist (NOLOCK) 
		WHERE	parent = @parent
		AND		start_date_int <= @stmt_date
		AND		start_date_int > 726468

	END	
	ELSE
	BEGIN
		SET @parent = ''

		INSERT	#bg_left
		SELECT	DISTINCT child, end_date_int
		FROM	cvo_buying_groups_hist (NOLOCK) 
		WHERE	child = @cus_code
		AND		end_date_int <= @stmt_date

		INSERT	#bg_start
		SELECT	DISTINCT child, start_date_int
		FROM	cvo_buying_groups_hist (NOLOCK) 
		WHERE	child = @cus_code
		AND		start_date_int <= @stmt_date
		AND		start_date_int > 726468

	END
	-- v1.0 End
      
	CREATE TABLE #unpaid_invoices (      
		customer_code  varchar( 8 ),      
		doc_ctrl_num  varchar( 16 ),      
		trx_type  smallint,      
		date_aging  int,      
		date_applied  int,      
		amt_tot_chg  float,      
		amt_paid_to_date float,      
		date_doc  int,      
		amt_net   float,      
		nat_cur_code  varchar( 8 ),      
		rate_type_home  varchar( 8 ),      
		rate_home  float,      
		rate_oper  float,      
		paid_flag  int,      
		terms_code  varchar( 8 ),      
		discount_flag  int NULL,      
		discount_prc  float NULL,      
		inv_amt_applied  float,      
		inv_amt_disc_taken float,      
		sequence_id  int identity,      
		cross_rate  float,      
		mc_date_applied  int,      
		curr_precision  int NULL,      
		amt_applied  float,      
		amt_disc_taken  float,      
		gain_home  float,      
		gain_oper  float,      
		inv_posted_disc  float,      
		inv_unposted_disc float,      
		org_id   varchar(30))      
      
	CREATE TABLE #unposted_payments(      
		customer_code  varchar( 8 ),      
		apply_to_num  varchar( 16 ),      
		apply_trx_type  smallint,      
		inv_amt_total  float,             
		inv_amt_disc_taken float)      
      
	IF ( @restrict_by_cur = 0 ) 
	BEGIN -- v1.1             
		INSERT #unpaid_invoices (      
			customer_code,  doc_ctrl_num,  trx_type,      
			date_aging,  amt_tot_chg,  amt_paid_to_date,      
			date_doc,  amt_net,               
			date_applied,  nat_cur_code,   rate_type_home,      
			rate_home,  rate_oper,  paid_flag,      
			inv_amt_applied, inv_amt_disc_taken,       
			cross_rate,         
			mc_date_applied,        
			amt_applied,  amt_disc_taken,      
			gain_home,  gain_oper,  inv_posted_disc,      
			inv_unposted_disc, terms_code,  org_id)      
		SELECT	artrx.customer_code, artrx.doc_ctrl_num, artrx.trx_type,      
				artrx.date_aging, artrx.amt_tot_chg, artrx.amt_paid_to_date,      
				artrx.date_doc,  artrx.amt_net,        
				artrx.date_applied, artrx.nat_cur_code, artrx.rate_type_home,      
				artrx.rate_home, artrx.rate_oper, artrx.paid_flag,      
				0.0,   0.0,         
				0.0,          
				SIGN(SIGN(@cr_date_applied-artrx.date_applied+0.5)+1)*@cr_date_applied      
				+SIGN(SIGN(artrx.date_applied-@cr_date_applied-0.5)+1)*artrx.date_applied,      
				0.0,   0.0,      
				0.0,   0.0,   ISNULL(artrx.amt_discount_taken, 0.0),      
				0.0,   terms_code,  artrx.org_id         
		FROM	artrx (NOLOCK), #arvpay  
		WHERE	artrx.customer_code = #arvpay.customer_code      
		AND		artrx.doc_ctrl_num = artrx.apply_to_num        
		AND		artrx.trx_type = artrx.apply_trx_type       
		AND		artrx.trx_type in (2021, 2031, 2071)      
		AND		artrx.paid_flag = 0       
		AND		artrx.void_flag = 0      
		AND		artrx.date_due <= @stmt_date        -- CVO 001
		--ORDER BY artrx.customer_code, artrx.apply_to_num   -- CVO 001  

		-- v1.1 Start
		IF (@parent > '')
		BEGIN
			INSERT #unpaid_invoices (      
				customer_code,  doc_ctrl_num,  trx_type,      
				date_aging,  amt_tot_chg,  amt_paid_to_date,      
				date_doc,  amt_net,               
				date_applied,  nat_cur_code,   rate_type_home,      
				rate_home,  rate_oper,  paid_flag,      
				inv_amt_applied, inv_amt_disc_taken,       
				cross_rate,         
				mc_date_applied,        
				amt_applied,  amt_disc_taken,      
				gain_home,  gain_oper,  inv_posted_disc,      
				inv_unposted_disc, terms_code,  org_id)      
			SELECT	artrx.customer_code, artrx.doc_ctrl_num, artrx.trx_type,      
					artrx.date_aging, artrx.amt_tot_chg, artrx.amt_paid_to_date,      
					artrx.date_doc,  artrx.amt_net,        
					artrx.date_applied, artrx.nat_cur_code, artrx.rate_type_home,      
					artrx.rate_home, artrx.rate_oper, artrx.paid_flag,      
					0.0,   0.0,         
					0.0,          
					SIGN(SIGN(@cr_date_applied-artrx.date_applied+0.5)+1)*@cr_date_applied      
					+SIGN(SIGN(artrx.date_applied-@cr_date_applied-0.5)+1)*artrx.date_applied,      
					0.0,   0.0,      
					0.0,   0.0,   ISNULL(artrx.amt_discount_taken, 0.0),      
					0.0,   terms_code,  artrx.org_id         
			FROM	artrx artrx (NOLOCK)
			JOIN	orders_all oa (NOLOCK)
			ON		artrx.customer_code = oa.cust_code
			AND		artrx.order_ctrl_num = (CAST(oa.order_no AS varchar(20)) + '-' + CAST(oa.ext AS varchar(20)))
			JOIN	cvo_orders_all cvo (NOLOCK)
			ON		oa.order_no = cvo.order_no
			AND		oa.ext = cvo.ext
			WHERE	artrx.doc_ctrl_num = artrx.apply_to_num        
			AND		artrx.trx_type = artrx.apply_trx_type       
			AND		artrx.trx_type in (2021, 2031, 2071)      
			AND		artrx.paid_flag = 0       
			AND		artrx.void_flag = 0      
			AND		artrx.date_due <= @stmt_date        -- CVO 001
			AND		cvo.buying_group = @parent
			AND		RIGHT(oa.user_category,2) = 'RB'
			AND		artrx.doc_ctrl_num NOT IN (SELECT doc_ctrl_num FROM #unpaid_invoices)
		END
	END
		-- v1.1 End
	ELSE      
	BEGIN -- v1.1 Start
		INSERT #unpaid_invoices (      
			customer_code,  doc_ctrl_num,   trx_type,      
			date_aging,  amt_tot_chg,   amt_paid_to_date,      
			date_doc,  amt_net,         
			date_applied,  nat_cur_code,   rate_type_home,      
			rate_home,  rate_oper,   paid_flag,      
			inv_amt_applied, inv_amt_disc_taken,        
			cross_rate,         
			mc_date_applied,      
			amt_applied,   amt_disc_taken,      
			gain_home,  gain_oper,   inv_posted_disc,      
			inv_unposted_disc, terms_code,   org_id)      
		SELECT	Distinct artrx.customer_code, artrx.doc_ctrl_num,  artrx.trx_type,      
				artrx.date_aging, artrx.amt_tot_chg,  artrx.amt_paid_to_date,      
				artrx.date_doc,  artrx.amt_net,        
				artrx.date_applied, artrx.nat_cur_code,  artrx.rate_type_home,      
				artrx.rate_home, artrx.rate_oper,  artrx.paid_flag,      
				0.0,   0.0,          
				0.0,          
				SIGN(SIGN(@cr_date_applied-artrx.date_applied+0.5)+1)*@cr_date_applied      
				+SIGN(SIGN(artrx.date_applied-@cr_date_applied-0.5)+1)*artrx.date_applied,      
				0.0,    0.0,      
				0.0,   0.0,    ISNULL(artrx.amt_discount_taken, 0.0),      
				0.0,   terms_code,   artrx.org_id         
		FROM	artrx (NOLOCK), #arvpay  
		WHERE	artrx.customer_code = #arvpay.customer_code      
		AND		artrx.doc_ctrl_num = artrx.apply_to_num        
		AND		artrx.trx_type = artrx.apply_trx_type       
		AND		artrx.trx_type in (2021, 2031, 2071)      
		AND		artrx.paid_flag = 0       
		AND		artrx.void_flag = 0      
		AND		artrx.nat_cur_code = @pymt_cur_code      
		AND		artrx.date_due <= @stmt_date        -- CVO 001  
		--ORDER BY artrx.customer_code, artrx.apply_to_num   -- CVO 001  


		-- v1.1 Start
		IF (@parent > '')
		BEGIN

			INSERT #unpaid_invoices (      
				customer_code,  doc_ctrl_num,   trx_type,      
				date_aging,  amt_tot_chg,   amt_paid_to_date,      
				date_doc,  amt_net,         
				date_applied,  nat_cur_code,   rate_type_home,      
				rate_home,  rate_oper,   paid_flag,      
				inv_amt_applied, inv_amt_disc_taken,        
				cross_rate,         
				mc_date_applied,      
				amt_applied,   amt_disc_taken,      
				gain_home,  gain_oper,   inv_posted_disc,      
				inv_unposted_disc, terms_code,   org_id)      
			SELECT	Distinct artrx.customer_code, artrx.doc_ctrl_num,  artrx.trx_type,      
					artrx.date_aging, artrx.amt_tot_chg,  artrx.amt_paid_to_date,      
					artrx.date_doc,  artrx.amt_net,        
					artrx.date_applied, artrx.nat_cur_code,  artrx.rate_type_home,      
					artrx.rate_home, artrx.rate_oper,  artrx.paid_flag,      
					0.0,   0.0,          
					0.0,          
					SIGN(SIGN(@cr_date_applied-artrx.date_applied+0.5)+1)*@cr_date_applied      
					+SIGN(SIGN(artrx.date_applied-@cr_date_applied-0.5)+1)*artrx.date_applied,      
					0.0,    0.0,      
					0.0,   0.0,    ISNULL(artrx.amt_discount_taken, 0.0),      
					0.0,   terms_code,   artrx.org_id         
			FROM	artrx artrx (NOLOCK)
			JOIN	orders_all oa (NOLOCK)
			ON		artrx.customer_code = oa.cust_code
			AND		artrx.order_ctrl_num = (CAST(oa.order_no AS varchar(20)) + '-' + CAST(oa.ext AS varchar(20)))
			JOIN	cvo_orders_all cvo (NOLOCK)
			ON		oa.order_no = cvo.order_no
			AND		oa.ext = cvo.ext
			WHERE	artrx.doc_ctrl_num = artrx.apply_to_num        
			AND		artrx.trx_type = artrx.apply_trx_type       
			AND		artrx.trx_type in (2021, 2031, 2071)      
			AND		artrx.paid_flag = 0       
			AND		artrx.void_flag = 0      
			AND		artrx.nat_cur_code = @pymt_cur_code      
			AND		artrx.date_due <= @stmt_date        -- CVO 001  
			AND		cvo.buying_group = @parent
			AND		RIGHT(oa.user_category,2) = 'RB'
			AND		artrx.doc_ctrl_num NOT IN (SELECT doc_ctrl_num FROM #unpaid_invoices)
		END
		--ORDER BY artrx.customer_code, artrx.apply_to_num   -- CVO 001      
 

	END 
		-- v1.1

 
	DECLARE discount_calc CURSOR FOR      
	SELECT doc_ctrl_num, trx_type, terms_code, date_doc FROM #unpaid_invoices      
      
	OPEN discount_calc      
      
	FETCH NEXT FROM discount_calc into @dis_doc, @dis_trx_type, @dis_terms_code, @dis_doc_date      
      
	WHILE @@FETCH_STATUS = 0      
	BEGIN      
      
		EXEC ARAPCalculateDiscount_sp @dis_terms_code, @cr_date_doc, @dis_doc_date, @discount_flag_2 OUTPUT, @discount_prc OUTPUT      
      
		UPDATE	#unpaid_invoices      
		SET		discount_flag = @discount_flag_2,       
				discount_prc = @discount_prc      
		WHERE	doc_ctrl_num = @dis_doc      
		AND		trx_type = @dis_trx_type      
        
		SELECT @dis_doc = ', @dis_trx_type = 0, @dis_terms_code = ', @dis_doc_date = 0      
        
		FETCH NEXT FROM discount_calc into @dis_doc, @dis_trx_type, @dis_terms_code, @dis_doc_date      
	END      
        
	CLOSE discount_calc     
	DEALLOCATE discount_calc      
           
	UPDATE	#unpaid_invoices      
	SET		curr_precision = gl.curr_precision      
	FROM	glcurr_vw gl (NOLOCK)     
	WHERE	#unpaid_invoices.nat_cur_code = gl.currency_code      
      
      
	CREATE INDEX unpaid_invoices on #unpaid_invoices (customer_code, doc_ctrl_num, trx_type)      
      
	INSERT #unposted_payments (      
		customer_code,   apply_to_num,      
		apply_trx_type,   inv_amt_total,      
		inv_amt_disc_taken)      
	SELECT	arinppdt.customer_code,  arinppdt.apply_to_num,      
			arinppdt.apply_trx_type, SUM(arinppdt.inv_amt_applied)       
			+ SUM(arinppdt.inv_amt_disc_taken)      
			+ SUM(arinppdt.inv_amt_max_wr_off),      
			SUM(arinppdt.inv_amt_disc_taken)      
	FROM	arinppdt (NOLOCK), #arvpay      
	WHERE	arinppdt.customer_code = #arvpay.customer_code       
	AND		arinppdt.trx_ctrl_num != @i_trx_ctrl_num       
	GROUP BY arinppdt.customer_code, arinppdt.apply_to_num, arinppdt.apply_trx_type      
            
	CREATE INDEX unposted_payments_ind_0 on #unposted_payments (customer_code, apply_to_num, apply_trx_type)      
       
	UPDATE	#unpaid_invoices      
	SET		inv_unposted_disc = pay.inv_amt_disc_taken      
	FROM	#unposted_payments pay      
	WHERE	pay.apply_to_num = #unpaid_invoices.doc_ctrl_num      
	AND		pay.apply_trx_type = #unpaid_invoices.trx_type      
      
	SELECT	@bal_fwd_flag = SIGN( COUNT( bal_fwd_flag ) )      
	FROM	#arvpay      
	WHERE	bal_fwd_flag = 1       
            
	IF @bal_fwd_flag = 1      
	BEGIN       
      
		CREATE TABLE #customer_totals (      
			customer_code  varchar( 8 ),      
			amt_tot_chg  float,      
			amt_paid_to_date float,      
			amt_net   float,      
			amt_pyt_unposted float,      
			amt_remain  float NULL,      
			amt_apply  float NULL,      
			date_applied  int )      
        
		INSERT #customer_totals (      
			customer_code,     amt_tot_chg,          
			amt_paid_to_date,    amt_net,      
			amt_pyt_unposted,    date_applied )      
		SELECT	DISTINCT #arvpay.customer_code,    SUM(#unpaid_invoices.amt_tot_chg),       
				SUM(#unpaid_invoices.amt_paid_to_date),  SUM(#unpaid_invoices.amt_net),      
				0.0,      MAX(#unpaid_invoices.date_applied)      
		FROM	#arvpay, #unpaid_invoices      
		WHERE	#arvpay.customer_code = #unpaid_invoices.customer_code      
		GROUP BY #arvpay.customer_code      
      
		UPDATE	#customer_totals      
		SET		amt_pyt_unposted = ISNULL((SELECT SUM(inv_amt_total)      
											  FROM #unposted_payments      
											  WHERE #unposted_payments.customer_code = #customer_totals.customer_code), 0.0 )      
            
		UPDATE #customer_totals      
		SET amt_remain = amt_tot_chg - amt_paid_to_date - amt_pyt_unposted      
        
		WHILE(1 = 1)      
		BEGIN      
			SET ROWCOUNT 1      
         
			SELECT	@customer_code = payees.customer_code,      
					@remain_bal = totals.amt_remain      
			FROM	#arvpay payees, #customer_totals totals      
			WHERE	payees.customer_code = totals.customer_code      
			AND		payees.seq_id = 0      
			AND		@auto_apply = 1      
			ORDER BY totals.date_applied      
   
			IF( @@rowcount = 0 )      
			BEGIN      
				SET ROWCOUNT 0      
				BREAK      
			END         
       
			SET ROWCOUNT 0      
      
			SELECT @payoff_inv_flag = SIGN(SIGN(@amt_payment-@remain_bal)+1)      
                  
			IF @payoff_inv_flag = 1      
			BEGIN      
				UPDATE	#customer_totals      
				SET		amt_apply = @remain_bal      
				WHERE	customer_code = @customer_code      
      
				SELECT	@amt_payment = @amt_payment - @remain_bal      
				WHERE	@payoff_inv_flag = 1      
			END      
			ELSE      
			BEGIN      
                UPDATE	#customer_totals      
				SET		amt_apply = @amt_payment      
				WHERE	@customer_code = customer_code      
      
				SELECT @amt_payment = 0.0      
			END      
      
			UPDATE	#arvpay      
			SET		seq_id = @sequence_id      
			WHERE	customer_code = @customer_code      
         
			SELECT @sequence_id = @sequence_id + 1            
		END      
      
      
        INSERT  #arinppdt4700 (       
			trx_ctrl_num,    doc_ctrl_num,       
			sequence_id,    trx_type,          
			apply_to_num,    apply_trx_type,        
			customer_code,   date_aging,        
			amt_applied,    amt_disc_taken,        
			wr_off_flag,    amt_max_wr_off,         
			void_flag,    line_desc,       
			sub_apply_num,   sub_apply_type,         
			amt_tot_chg,    amt_paid_to_date,        
			terms_code,    posting_code,        
			date_doc,     amt_inv,         
			gain_home,    gain_oper,         
			inv_amt_applied,   inv_amt_disc_taken,      
			inv_amt_max_wr_off,   inv_cur_code,      
			writeoff_code,       
			org_id)      
		SELECT	@i_trx_ctrl_num,   @i_doc_ctrl_num,      
				payees.seq_id,   2111,        
				'BAL-FORWARD',   0,           
				payees.customer_code,  0,      
				ISNULL(totals.amt_apply,0.0), 0.0,          
				0,     0.0,          
				0,     @desc,      
				'',     0,          
				ISNULL(totals.amt_tot_chg,0.0), ISNULL(totals.amt_paid_to_date,0.0),       
				'',     '',      
				0,     0.0,          
				0.0,     0.0,          
				ISNULL(totals.amt_apply, 0.0), 0.0,      
				0.0,     @pymt_cur_code,      
				arcust.writeoff_code,           
				@org_id               
		FROM	#customer_totals totals, #arvpay payees, arcust      
		WHERE	totals.customer_code = payees.customer_code      
		AND		arcust.customer_code = payees.customer_code        
		AND		(((ABS((totals.amt_apply)-(0.0)) > 0.0000001) AND @auto_apply = 1) OR @auto_detail = 1)      
              
        INSERT #arvalbfd (      
			customer_code,       
			source)      
		SELECT	payees.customer_code,       
				0      
		FROM	#arvpay payees, #customer_totals totals      
		WHERE	payees.customer_code = totals.customer_code      
		AND		(((ABS((totals.amt_apply)-(0.0)) > 0.0000001) AND @auto_apply = 1) OR @auto_detail = 1)      
      
		DROP TABLE #customer_totals      
	END       
	ELSE      
	BEGIN      
		CREATE TABLE #aging_info (      
			customer_code varchar( 8 ),      
			doc_ctrl_num varchar( 16 ),      
			trx_type smallint,      
			date_aging int,      
			date_due int,      
			apply_to_num varchar( 16 ),           
			apply_trx_type smallint,                          
			amount  float,      
			amt_paid float)      
      
		INSERT #aging_info (      
			customer_code,  doc_ctrl_num,      
			trx_type,  date_aging,      
			date_due,  apply_to_num,      
			apply_trx_type,  amount,      
			amt_paid)      
		SELECT	age.customer_code, age.doc_ctrl_num,        
				age.trx_type,  age.date_aging,      
				age.date_due,  age.apply_to_num,      
				age.apply_trx_type, (age.amount+      
				age.amt_fin_chg+      
				age.amt_late_chg),      
				age.amt_paid         
		FROM	artrxage age, #unpaid_invoices      
		WHERE	age.apply_to_num = #unpaid_invoices.doc_ctrl_num       
		AND		age.apply_trx_type = #unpaid_invoices.trx_type         
		AND		ref_id > 0      
		AND		age.trx_type <= 2031             
            
		INSERT #aging_info (      
			customer_code,  doc_ctrl_num,      
			trx_type,  date_aging,      
			date_due,  apply_to_num,      
			apply_trx_type,  amount,      
			amt_paid)      
		SELECT	inv.customer_code, inv.doc_ctrl_num,        
				inv.trx_type,  inv.date_aging,      
				inv.date_applied, inv.doc_ctrl_num,      
				inv.trx_type,  inv.amt_tot_chg,      
				inv.amt_paid_to_date         
		FROM	#unpaid_invoices inv, #arvpay, glcurr_vw gl (NOLOCK)     
		WHERE	inv.customer_code = #arvpay.customer_code       
		AND		inv.trx_type = 2071                   
		AND		gl.currency_code = inv.nat_cur_code      
      
		WHILE( 1 = 1 )      
		BEGIN      
         
			SET ROWCOUNT 1      
                  
            SELECT	@min_date_due = MIN(#aging_info.date_due)      
            FROM	#aging_info, #unposted_payments      
			WHERE	#aging_info.customer_code = #unposted_payments.customer_code      
			AND		#aging_info.apply_to_num   = #unposted_payments.apply_to_num       
			AND		#aging_info.apply_trx_type = #unposted_payments.apply_trx_type       
			AND		((#unposted_payments.inv_amt_total) > (0.0) + 0.0000001)      
			AND		((#aging_info.amount - #aging_info.amt_paid) > (0.0) + 0.0000001)      
         
			IF( @@rowcount = 0 )      
			BEGIN      
				SET ROWCOUNT 0      
				BREAK      
			END      
         
			SELECT	@customer_code = age.customer_code,      
					@apply_to_num = age.doc_ctrl_num,      
					@apply_trx_type = age.trx_type,      
					@remain_bal = age.amount - age.amt_paid,      
					@amount = age.amount,       
					@amt_paid = age.amt_paid,      
					@date_aging = age.date_aging,      
					@amt_pyt_unposted = pay.inv_amt_total      
			FROM	#aging_info age, #unposted_payments pay      
			WHERE	age.customer_code = pay.customer_code      
			AND		age.apply_to_num   = pay.apply_to_num       
			AND		age.apply_trx_type = pay.apply_trx_type       
			AND		((pay.inv_amt_total) > (0.0) + 0.0000001)      
			AND		((age.amount - age.amt_paid) > (0.0) + 0.0000001)      
			AND		age.date_due = @min_date_due      
                  
            IF( @@rowcount = 0 )      
			BEGIN      
				SET ROWCOUNT 0      
				BREAK      
			END      
      
			SELECT @payoff_inv_flag = SIGN(SIGN(@amt_pyt_unposted-@remain_bal)+1)      
      
			IF @payoff_inv_flag = 1      
			BEGIN      
				UPDATE	#aging_info      
				SET		amt_paid = amount        
				WHERE	customer_code = @customer_code      
				AND		doc_ctrl_num = @apply_to_num      
				AND		trx_type = @apply_trx_type      
				AND		date_aging = @date_aging      
          
				UPDATE	#unposted_payments      
				SET		inv_amt_total = inv_amt_total - @remain_bal       
				WHERE	customer_code = @customer_code      
				AND		apply_to_num = @apply_to_num      
				AND		apply_trx_type = @apply_trx_type      
      
				UPDATE	#unpaid_invoices      
				SET		amt_paid_to_date = amt_paid_to_date + @remain_bal      
				WHERE	customer_code = @customer_code      
				AND		doc_ctrl_num = @apply_to_num      
				AND		trx_type = @apply_trx_type      
      
			END       
			ELSE      
			BEGIN       
				UPDATE	#aging_info      
				SET		amt_paid = amt_paid + @amt_pyt_unposted      
				WHERE	customer_code = @customer_code      
				AND		doc_ctrl_num = @apply_to_num      
				AND		trx_type = @apply_trx_type      
				AND		date_aging = @date_aging      
      
				UPDATE	#unposted_payments      
				SET		inv_amt_total = 0.0      
				WHERE	customer_code = @customer_code      
				AND		apply_to_num = @apply_to_num      
				AND		apply_trx_type = @apply_trx_type      
          
				UPDATE	#unpaid_invoices      
				SET		amt_paid_to_date = amt_paid_to_date + @amt_pyt_unposted      
				WHERE	customer_code = @customer_code      
				AND		doc_ctrl_num = @apply_to_num      
				AND		trx_type = @apply_trx_type            
			END       
		END       
            
		DELETE	#unpaid_invoices      
		WHERE	((amt_tot_chg-amt_paid_to_date) <= (0.0) + 0.0000001)      
      
		IF ( @auto_apply = 1 )      
		BEGIN      
			CREATE TABLE #rates (      
				from_currency  varchar( 8 ),      
				to_currency   varchar( 8 ),      
				rate_type   varchar( 8 ),      
				date_applied   int,      
				rate    float)      
               
			INSERT #rates (      
				from_currency, to_currency,      
				rate_type,  date_applied,      
				rate)      
			SELECT	DISTINCT 
					nat_cur_code,  @home_cur_code,      
					rate_type_home, mc_date_applied,      
					0.0      
			FROM	#unpaid_invoices      
			UNION      
			SELECT DISTINCT      
					@pymt_cur_code, @home_cur_code,      
					@rate_type_home, mc_date_applied,      
					0.0      
			FROM	#unpaid_invoices      
        
			EXEC @result = CVO_Control..mcrates_sp   
            IF (@result != 0)      
				RETURN @result        
      
			UPDATE	#unpaid_invoices      
			SET		cross_rate = ( SIGN(1 + SIGN(inv.rate))*(inv.rate) + (SIGN(ABS(SIGN(ROUND(inv.rate,6))))/(inv.rate + SIGN(1 - ABS(SIGN(ROUND(inv.rate,6)))))) * SIGN(SIGN(inv.rate) - 1) )/( SIGN(1 + SIGN(pyt.rate))*(pyt.rate) + (SIGN(ABS(SIGN(ROUND(pyt.rate,6))))/
					(pyt.rate + SIGN(1 - ABS(SIGN(ROUND(pyt.rate,6)))))) * SIGN(SIGN(pyt.rate) - 1) )      
			FROM	#unpaid_invoices ui, #rates inv, #rates pyt      
			WHERE	ui.nat_cur_code = inv.from_currency      
			AND		ui.mc_date_applied = inv.date_applied      
			AND		pyt.from_currency = @pymt_cur_code      
			AND		pyt.date_applied = inv.date_applied      
			AND		(ABS((pyt.rate)-(0.0)) > 0.0000001)      
      
			DROP TABLE #rates      
          
			CREATE TABLE #aging_info_pay_app (      
				customer_code varchar( 8 ),      
				doc_ctrl_num varchar( 16 ),      
				trx_type smallint,      
				date_aging int,      
				date_due int,      
				apply_to_num varchar( 16 ),           
				apply_trx_type smallint,                          
				amount  float,      
				amt_paid float,      
				cross_rate_flag smallint,      
				seq_id  numeric identity)      
            
			INSERT INTO #aging_info_pay_app (      
				customer_code,  doc_ctrl_num,  trx_type,      
				date_aging,  date_due,  apply_to_num,      
				apply_trx_type,  amount,   amt_paid,      
				cross_rate_flag)      
			SELECT	age.customer_code, age.doc_ctrl_num, age.trx_type,      
					age.date_aging,  age.date_due,  age.apply_to_num,      
					age.apply_trx_type, age.amount,  age.amt_paid,      
					1      
			FROM	#aging_info age, #unpaid_invoices inv      
			WHERE	inv.customer_code = age.customer_code      
			AND		inv.doc_ctrl_num = age.apply_to_num      
			AND		inv.trx_type = age.apply_trx_type      
			AND		((amount - amt_paid) > (0.0) + 0.0000001)      
			AND		((cross_rate) > (0.0) + 0.0000001)      
			ORDER BY date_due      
      
			SELECT @age_apply_num = @@rowcount      
      
			SELECT @cur_row = 1      
      
			WHILE( @age_apply_num >= @cur_row AND ((@amt_payment) > (0.0) + 0.0000001) )      
			BEGIN      
          
				SELECT	@customer_code  = age.customer_code,      
						@doc_ctrl_num  = age.doc_ctrl_num,      
						@trx_type   = age.trx_type,      
						@apply_to_num  = age.apply_to_num,      
						@apply_trx_type = age.apply_trx_type,      
						@amount   = age.amount,      
						@amt_paid   = age.amt_paid,      
						@date_aging   = age.date_aging,      
						@remain_bal   = age.amount - age.amt_paid,      
						@cross_rate   = inv.cross_rate,      
						@amt_payment_inv  = ROUND(@amt_payment/inv.cross_rate,inv.curr_precision),      
						@discount_flag  = inv.discount_flag,      
						@discount_amt  = ROUND(inv.amt_tot_chg*discount_prc/100,inv.curr_precision) - inv.inv_posted_disc - inv.inv_unposted_disc,      
						@inv_sequence_id  = inv.sequence_id,      
						@inv_posted_disc = inv.inv_posted_disc      
				FROM	#unpaid_invoices inv, #aging_info_pay_app age      
				WHERE	age.seq_id = @cur_row      
				AND		inv.customer_code = age.customer_code      
				AND		inv.doc_ctrl_num = age.apply_to_num      
				AND		inv.trx_type = age.apply_trx_type      
                 
				SELECT @payoff_inv_flag = SIGN(SIGN(@amt_payment_inv-@remain_bal)+1)      
      
				IF @payoff_inv_flag = 1      
				BEGIN      
					UPDATE	#aging_info_pay_app      
					SET		amt_paid = amount         
					WHERE	seq_id = @cur_row      
                 
					SELECT	@amt_payment = @amt_payment - ROUND(@remain_bal*@cross_rate, @pymt_curr_precision)       
             
					UPDATE	#unpaid_invoices      
					SET		inv_amt_applied = inv_amt_applied + @remain_bal      
					WHERE	customer_code = @customer_code      
					AND		doc_ctrl_num = @apply_to_num      
					AND		trx_type = @apply_trx_type            
				END       
				ELSE      
				BEGIN       
      
					UPDATE	#aging_info_pay_app      
					SET		amt_paid = amt_paid + @amt_payment_inv      
					WHERE	seq_id = @cur_row      
     
					SELECT @amt_payment = 0.0      
      
					UPDATE	#unpaid_invoices      
					SET		inv_amt_applied = inv_amt_applied + @amt_payment_inv      
					WHERE	customer_code = @customer_code      
					AND		doc_ctrl_num = @apply_to_num      
					AND		trx_type = @apply_trx_type      

				END       
      
				IF ( @discount_flag = 1 )      
				BEGIN      
          
					IF (((@discount_amt) < (0.0) - 0.0000001))      
						SELECT @discount_amt = 0.0      
      
						SELECT	@payoff_inv_flag = SIGN(SIGN(amt_paid_to_date + inv_amt_applied + @discount_amt - amt_tot_chg)+1),      
								@disc_payoff_inv_flag = SIGN(SIGN(amt_paid_to_date + @discount_amt - amt_tot_chg)+1),      
								@balance = amt_tot_chg - amt_paid_to_date      
						FROM	#unpaid_invoices      
						WHERE	customer_code = @customer_code      
						AND		doc_ctrl_num = @apply_to_num      
						AND		trx_type = @apply_trx_type      
                 
					IF ( @disc_payoff_inv_flag = 1 )      
					BEGIN      
						UPDATE	#aging_info_pay_app      
						SET		amt_paid = amount      
						WHERE	seq_id = @cur_row       
						AND		apply_to_num = @apply_to_num      

						UPDATE	#unpaid_invoices      
						SET		inv_amt_applied = 0.0,      
								inv_amt_disc_taken = @balance      
						WHERE	customer_code = @customer_code      
						AND		doc_ctrl_num = @apply_to_num      
						AND		trx_type = @apply_trx_type      
      
						SELECT	@amt_payment = @amt_payment + ROUND(@balance*@cross_rate, @pymt_curr_precision)      
      
					END       
					ELSE IF ( @payoff_inv_flag = 1 )      
					BEGIN      
						UPDATE	#aging_info_pay_app      
						SET		amt_paid = amount      
						WHERE	seq_id = @cur_row       
						AND		apply_to_num = @apply_to_num      
                  
						SELECT	@inv_amt_applied_temp = inv_amt_applied      
						FROM	#unpaid_invoices      
						WHERE	customer_code = @customer_code      
						AND		doc_ctrl_num = @apply_to_num      
						AND		trx_type = @apply_trx_type      
             
						UPDATE	#unpaid_invoices      
						SET		inv_amt_applied = @balance - @discount_amt,      
								inv_amt_disc_taken = @discount_amt      
						WHERE	customer_code = @customer_code      
						AND		doc_ctrl_num = @apply_to_num      
						AND		trx_type = @apply_trx_type      
      
						SELECT	@amt_payment = @amt_payment + ROUND((@inv_amt_applied_temp - @balance + @discount_amt) * @cross_rate, @pymt_curr_precision)      
      
					END              
				END       
      
				SELECT @cur_row = @cur_row + 1      
			END       
       
			UPDATE	#unpaid_invoices      
			SET		amt_applied = ISNULL(ROUND(inv_amt_applied*cross_rate,@pymt_curr_precision), 0.0),      
					amt_disc_taken = ISNULL(ROUND(inv_amt_disc_taken*cross_rate,@pymt_curr_precision), 0.0)      
			FROM	glcurr_vw glh (NOLOCK)     
			WHERE	glh.currency_code = @home_cur_code      
                                     
			UPDATE	#unpaid_invoices      
					SET gain_home = ROUND(amt_applied*( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) ), glh.curr_precision)      
					-ROUND(inv_amt_applied*( SIGN(1 + SIGN(rate_home))*(rate_home) + (SIGN(ABS(SIGN(ROUND(rate_home,6))))/(rate_home + SIGN(1 - ABS(SIGN(ROUND(rate_home,6)))))) * SIGN(SIGN(rate_home) - 1) ), glh.curr_precision)      
			FROM	glcurr_vw glh  (NOLOCK)    
			WHERE	glh.currency_code = @home_cur_code      
               
			UPDATE	#unpaid_invoices      
			SET		gain_oper = ROUND(amt_applied*( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) ), glo.curr_precision)      
					-ROUND(inv_amt_applied*( SIGN(1 + SIGN(rate_oper))*(rate_oper) + (SIGN(ABS(SIGN(ROUND(rate_oper,6))))/(rate_oper + SIGN(1 - ABS(SIGN(ROUND(rate_oper,6)))))) * SIGN(SIGN(rate_oper) - 1) ), glo.curr_precision)      
			FROM	glcurr_vw glo (NOLOCK)     
			WHERE	glo.currency_code = @oper_cur_code      
      
			DROP TABLE #aging_info_pay_app            
		END       
      


		-- v1.2 Start
		IF (@parent > '')
		BEGIN

			DELETE	a
			FROM	#unpaid_invoices a
			JOIN	artrx b (NOLOCK)
			ON		a.doc_ctrl_num = b.doc_ctrl_num
			AND		a.customer_code = b.customer_code
			AND		a.trx_type = b.trx_type
			JOIN	orders_all c (NOLOCK)
			ON		b.customer_code = c.cust_code
			AND		b.order_ctrl_num = (CAST(c.order_no AS varchar(20)) + '-' + CAST(c.ext AS varchar(20)))
			JOIN	cvo_orders_all d (NOLOCK)
			ON		c.order_no = d.order_no
			AND		c.ext = d.ext
			WHERE	ISNULL(d.buying_group,'') = ''
			AND		RIGHT(c.user_category,2) = 'RB'					

		END		
		-- v1.2 End
		-- v1.3 Start
		ELSE
		BEGIN
			
			DELETE	a
			FROM	#unpaid_invoices a
			JOIN	artrx b (NOLOCK)
			ON		a.doc_ctrl_num = b.doc_ctrl_num
			AND		a.customer_code = b.customer_code
			AND		a.trx_type = b.trx_type
			JOIN	orders_all c (NOLOCK)
			ON		b.customer_code = c.cust_code
			AND		b.order_ctrl_num = (CAST(c.order_no AS varchar(20)) + '-' + CAST(c.ext AS varchar(20)))
			JOIN	cvo_orders_all d (NOLOCK)
			ON		c.order_no = d.order_no
			AND		c.ext = d.ext
			WHERE	ISNULL(d.buying_group,'') > ''	
			AND		RIGHT(c.user_category,2) = 'RB'									
		END
		-- v1.3 End



        INSERT  #arinppdt4700 (       
			trx_ctrl_num,    doc_ctrl_num,       
			sequence_id,    trx_type,         
			apply_to_num,    apply_trx_type,       
			customer_code,   date_aging,        
			amt_applied,    amt_disc_taken,       
			wr_off_flag,    amt_max_wr_off,        
			void_flag,    line_desc,       
			sub_apply_num,   sub_apply_type,        
			amt_tot_chg,    amt_paid_to_date,       
			terms_code,    posting_code,        
			date_doc,    amt_inv,        
			gain_home,    gain_oper,        
			inv_amt_applied,   inv_amt_disc_taken,      
			inv_amt_max_wr_off,   inv_cur_code,      
			writeoff_code,             
			org_id)      
		SELECT	@i_trx_ctrl_num,   @i_doc_ctrl_num,         
				convert(int, sequence_id),              2111,           
				doc_ctrl_num,    trx_type,         
				#unpaid_invoices.customer_code,   #unpaid_invoices.date_aging,       
				amt_applied,     0.0,            
				0,      0.0,            
				0,      '',            
				'',      0,            
				#unpaid_invoices.amt_tot_chg,  #unpaid_invoices.amt_paid_to_date,       
				'',      '',              
				#unpaid_invoices.date_doc,  #unpaid_invoices.amt_net,      
				gain_home,    gain_oper,      
				inv_amt_applied,   inv_amt_disc_taken,      
				0.0,     #unpaid_invoices.nat_cur_code,      
				arcust.writeoff_code,            
				org_id               
		FROM	#unpaid_invoices, arcust (NOLOCK)     
		WHERE	arcust.customer_code = #unpaid_invoices.customer_code       
              
		DROP TABLE #aging_info   


	END       
	



	-- v1.0 Start
	IF (@parent > '')
	BEGIN

		DELETE	a
		FROM	#arinppdt4700 a
		JOIN	#bg_left b
		ON		a.customer_code = b.customer_code
		JOIN	artrx c (NOLOCK)
		ON		a.customer_code = c.customer_code
		AND		a.apply_to_num = c.doc_ctrl_num
		WHERE	a.date_doc > b.end_date
		AND		c.apply_to_num NOT IN (SELECT b.doc_ctrl_num
									FROM	artrx b (NOLOCK)
									JOIN	orders_all c (NOLOCK)
									ON		b.order_ctrl_num = (CAST(c.order_no AS varchar(20)) + '-' + CAST(c.ext AS varchar(20)))
									JOIN	cvo_orders_all d (NOLOCK) 
									ON		c.order_no = d.order_no
									AND		c.ext = d.ext
									WHERE	RIGHT(c.user_category,2) = 'RB'
									AND		d.buying_group = @parent)




		DELETE	a
		FROM	#arinppdt4700 a
		JOIN	#bg_start b
		ON		a.customer_code = b.customer_code
		JOIN	artrx c (NOLOCK)
		ON		a.customer_code = c.customer_code
		AND		a.apply_to_num = c.doc_ctrl_num
		WHERE	a.date_doc < b.start_date
		AND		c.apply_to_num NOT IN (SELECT b.doc_ctrl_num
									FROM	artrx b (NOLOCK)
									JOIN	orders_all c (NOLOCK)
									ON		b.order_ctrl_num = (CAST(c.order_no AS varchar(20)) + '-' + CAST(c.ext AS varchar(20)))
									JOIN	cvo_orders_all d (NOLOCK) 
									ON		c.order_no = d.order_no
									AND		c.ext = d.ext
									WHERE	RIGHT(c.user_category,2) = 'RB'
									AND		d.buying_group = @parent)



	END
	ELSE
	BEGIN



		DELETE	a
		FROM	#arinppdt4700 a
		JOIN	#bg_left b
		ON		a.customer_code = b.customer_code
		JOIN	artrx c (NOLOCK)
		ON		a.customer_code = c.customer_code
		AND		a.apply_to_num = c.doc_ctrl_num
		WHERE	a.date_doc <= b.end_date
		AND		c.apply_to_num NOT IN (SELECT b.doc_ctrl_num
									FROM	artrx b (NOLOCK)
									JOIN	orders_all c (NOLOCK)
									ON		b.order_ctrl_num = (CAST(c.order_no AS varchar(20)) + '-' + CAST(c.ext AS varchar(20)))
									JOIN	cvo_orders_all d (NOLOCK) 
									ON		c.order_no = d.order_no
									AND		c.ext = d.ext
									WHERE	RIGHT(c.user_category,2) = 'RB'
									AND		d.buying_group = ''
									AND		b.customer_code = @cus_code)


		DELETE	a
		FROM	#arinppdt4700 a
		JOIN	#bg_start b
		ON		a.customer_code = b.customer_code
		JOIN	artrx c (NOLOCK)
		ON		a.customer_code = c.customer_code
		AND		a.apply_to_num = c.doc_ctrl_num
		WHERE	a.date_doc >= b.start_date
		AND		c.apply_to_num NOT IN (SELECT b.doc_ctrl_num
									FROM	artrx b (NOLOCK)
									JOIN	orders_all c (NOLOCK)
									ON		b.order_ctrl_num = (CAST(c.order_no AS varchar(20)) + '-' + CAST(c.ext AS varchar(20)))
									JOIN	cvo_orders_all d (NOLOCK) 
									ON		c.order_no = d.order_no
									AND		c.ext = d.ext
									WHERE	RIGHT(c.user_category,2) = 'RB'
									AND		d.buying_group = ''
									AND		b.customer_code = @cus_code)





	END

	DROP TABLE #bg_left
	DROP TABLE #bg_start
	-- v1.0 End
         
	DROP TABLE #unpaid_invoices      
	DROP TABLE #unposted_payments      
      
END       
  
GO
GRANT EXECUTE ON  [dbo].[arcash_sp] TO [public]
GO
