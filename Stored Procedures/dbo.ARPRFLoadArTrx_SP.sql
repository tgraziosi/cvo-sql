SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 19/07/2013 - Issue #927 - Buying Group Switching   
-- v1.1 CB 16/09/2013 - Issue #927 - Buying Group Switching - Check for RB orders set for the parent 
-- v1.2 CB 01/10/2013 - Issue #927 - Buying Group Switching - When running for child exclude records affiliated with bg  
-- v1.3 CB 09/12/2013 - Issue when customer is added and removed from buying group
-- v2.0 CB 10/06/2014 - ReWrite of BG data
CREATE PROC [dbo].[ARPRFLoadArTrx_SP]	@cust_code varchar( 8 ), 
								@trx_type smallint,  
								@nat_flag int, 
								@rel_code varchar( 8 )  
AS  
  
BEGIN  
  
	DELETE #artrx  
  
	if @nat_flag = 0  
		select @rel_code = ''  
     
	CREATE TABLE #prfcust  
	(  
	 cust_code varchar( 8 )  
	)  
  
  
	EXEC ARPRFNationalCusts_SP @cust_code, @rel_code  

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
	EXEC cvo_bg_get_document_data_sp @cust_code
   
	CREATE INDEX #bg_data_ind22 ON #bg_data (customer_code, doc_ctrl_num)

  
	IF (@trx_type = 2151)  
	BEGIN
		INSERT INTO #artrx  
		(  
			ctrl,  
			type,  
			trx_ctrl_num,  
			doc_ctrl_num,  
			date_applied,  
			date_entered,  
			trx_type,  
			balance,  
			customer_code,  
			nat_cur_code  
		)  
		SELECT	a1.trx_ctrl_num,  
				a1.trx_type,  
				a2.trx_ctrl_num,  
				a1.apply_to_num,  
				a1.date_applied,  
				a2.date_entered,  
				a2.trx_type,  
				a1.inv_amt_wr_off,  
				a1.customer_code,  
				a2.nat_cur_code  
		FROM	artrxpdt a1 (NOLOCK)
		JOIN	artrx a2 (NOLOCK)
		ON		a2.doc_ctrl_num = a1.apply_to_num  
		JOIN	#bg_data bg
		ON		a2.customer_code = bg.customer_code
		AND		a2.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	a2.trx_type IN ( 2031, 2021 )   
		AND		a1.void_flag = 0   
		AND		a1.trx_type IN ( 2111, 2151 )   
		AND		a1.amt_wr_off > 0.0   
	END
  
	IF (@trx_type = 2032)  
	BEGIN

		INSERT INTO #artrx  
		(  
			ctrl,  
			type,  
			trx_ctrl_num,  
			doc_ctrl_num,  
			date_applied,  
			date_entered,  
			trx_type,  
			balance,  
			customer_code,  
			nat_cur_code  
		)  
		SELECT	a.trx_ctrl_num,  
				a.trx_type,  
				a.trx_ctrl_num,  
				a.doc_ctrl_num,  
				a.date_applied,  
				a.date_entered,   
				a.trx_type,  
				( a.amt_net*(-1)*(SIGN(ABS(a.recurring_flag-1))-1)   
					+ a.amt_tax*(-1)*(SIGN(ABS(a.recurring_flag-2))-1)   
					+ a.amt_freight*(-1)*(SIGN(ABS(a.recurring_flag-3))-1)   
					+(a.amt_tax + a.amt_freight)*(-1)*(SIGN(ABS(a.recurring_flag-4))-1) ),   
				a.customer_code,   
				a.nat_cur_code  
		FROM	artrx a (NOLOCK)
		JOIN	#bg_data bg
		ON		a.customer_code = bg.customer_code
		AND		a.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	a.trx_type = 2032  
		AND		a.non_ar_flag = 0   

	END
  
	IF (@trx_type = 2031) 
	BEGIN 
		INSERT INTO #artrx  
		(  
			ctrl,  
			type,  
			trx_ctrl_num,  
			doc_ctrl_num,  
			date_applied,  
			date_entered,  
			trx_type,  
			balance,  
			customer_code,  
			nat_cur_code  
		)  
		SELECT	a.trx_ctrl_num,  
				a.trx_type,  
				a.trx_ctrl_num,  
				a.doc_ctrl_num,  
				a.date_due,  
				a.date_entered,  
				a.trx_type,  
				(a.amt_tot_chg - a.amt_paid_to_date),  
				a.customer_code,  
				a.nat_cur_code  
		FROM	artrx a (NOLOCK)
		JOIN	#bg_data bg
		ON		a.customer_code = bg.customer_code
		AND		a.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	a.trx_type IN (2031, 2021)  
		AND		a.doc_ctrl_num = a.apply_to_num  

	END


	IF ( @trx_type = 2121 )  
	BEGIN  
		INSERT INTO #artrx  
		(  
			doc_ctrl_num, customer_code  
		)  
		SELECT	DISTINCT 
				age.doc_ctrl_num, 
				age.payer_cust_code  
		FROM	artrxage age (NOLOCK)
		JOIN	artrx trx (NOLOCK)
		ON		age.doc_ctrl_num = trx.doc_ctrl_num  
		AND		age.payer_cust_code = trx.customer_code 
		JOIN	#bg_data bg
		ON		trx.customer_code = bg.customer_code
		AND		trx.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	trx.trx_type = @trx_type  

		UPDATE	#artrx  
		SET		ctrl = #artrx.doc_ctrl_num,  
				type = trx.trx_type,  
				trx_ctrl_num = trx.trx_ctrl_num,  
				date_applied = trx.date_doc,  
				date_entered = trx.date_entered,  
				trx_type = trx.trx_type,  
				balance = amt_net,  
				nat_cur_code = trx.nat_cur_code  
		FROM	artrx trx  
		WHERE	#artrx.doc_ctrl_num = trx.doc_ctrl_num  
		AND		#artrx.customer_code = trx.customer_code  
	END  
  
	IF ( @trx_type = 2111 )  
	BEGIN  
		CREATE TABLE #prfpyt  
		(  
			doc_ctrl_num varchar( 16 ),  
			customer_code varchar( 8 )  
		)  

		INSERT INTO #prfpyt  
		(  
			doc_ctrl_num, customer_code  
		)  
		SELECT	DISTINCT trx.doc_ctrl_num, 
				trx.customer_code  
		FROM	artrx trx (NOLOCK)
		JOIN	#bg_data bg
		ON		trx.customer_code = bg.customer_code
		AND		trx.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	trx.trx_type = @trx_type  
		AND		trx.source_trx_ctrl_num IS NULL

		INSERT INTO #artrx  
		(  
			doc_ctrl_num, customer_code  
		)  
		SELECT	DISTINCT doc_ctrl_num, 
				customer_code  
		FROM	#prfpyt  
  
		DROP TABLE #prfpyt  
  
		UPDATE	#artrx  
		SET		ctrl = #artrx.doc_ctrl_num,  
				type = trx.trx_type,  
				trx_ctrl_num = trx.trx_ctrl_num,  
				date_applied = trx.date_applied,  
				date_entered = trx.date_entered,  
				trx_type = trx.trx_type,  
				balance = amt_net,  
				nat_cur_code = trx.nat_cur_code  
		FROM	artrx trx  
		WHERE	#artrx.doc_ctrl_num = trx.doc_ctrl_num  
		AND		#artrx.customer_code = trx.customer_code  
		AND		payment_type in (1, 3)  
		AND		trx.trx_type != 2112  
	END  
  
	IF (@trx_type = 2061 or @trx_type = 2071)  
	BEGIN  

		INSERT INTO #artrx  
		(  
			ctrl,  
			type,  
			trx_ctrl_num,  
			doc_ctrl_num,  
			date_applied,  
			date_entered,  
			trx_type,  
			balance,  
			customer_code,  
			nat_cur_code  
		)  
		SELECT	a2.trx_ctrl_num,  
				a2.trx_type,  
				a3.trx_ctrl_num,  
				a2.apply_to_num,  
				a2.date_applied,  
				a2.date_entered,  
				a3.trx_type,  
				a2.amt_tot_chg,  
				a2.customer_code,  
				a2.nat_cur_code  
		FROM	artrx a2 (NOLOCK)
		JOIN	artrx a3 (NOLOCK) 
		ON		a2.apply_to_num = a3.doc_ctrl_num  
		AND		a2.apply_trx_type = a3.trx_type 
		JOIN	#bg_data bg
		ON		a2.customer_code = bg.customer_code
		AND		a2.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	a2.customer_code = @cust_code  
		AND		a2.trx_type = @trx_type  
	END  
  
	SET rowcount 10000  
  
	WHILE ( 1 = 1)  
	BEGIN  
		UPDATE #artrx  
		SET amt_mask = currency_mask  
		FROM glcurr_vw  
		WHERE #artrx.nat_cur_code = currency_code  
		AND amt_mask IS NULL  
  
		IF @@rowcount < 10000  
			BREAK  
	END  
   
	SET rowcount 0  
  
	DROP TABLE #prfcust 
	DROP TABLE #bg_data
END    

GO
GRANT EXECUTE ON  [dbo].[ARPRFLoadArTrx_SP] TO [public]
GO
