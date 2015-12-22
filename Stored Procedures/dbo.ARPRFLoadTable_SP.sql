SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
  
CREATE PROCEDURE [dbo].[ARPRFLoadTable_SP]	@cust_code  varchar( 8 ),  
									@home_oper_flag int,  
									@nat_flag  int,  
									@rel_code  varchar( 8 )  
AS  
  
DECLARE	@tot_inv_amt  float,   
		@tot_cm_amt  float,   
		@tot_pyt_amt  float,   
		@tot_wr_off_amt float,   
		@tot_nsf_amt  float,   
		@tot_fin_chg_amt float,   
		@tot_late_chg_amt float,  
		@tot_disc_amt  float,  
		@last_amt  float,  
		@balance  float,  
		@last_doc  varchar( 16 ),  
		@last_cust  varchar( 8 ),  
		@last_cust_pyt varchar( 8 ),  
		@last_date  int,  
		@last_cur  varchar( 8 )  

-- v1.1 Start
DECLARE	@last_amt_sw	float,
		@last_doc_sw	varchar(16),
		@last_cust_sw	varchar(10),
		@last_date_sw	int,
		@last_cur_sw	varchar(8)
-- v1.1 End

BEGIN  
  
  
	INSERT INTO #arprfdt  
	(  
	customer_code,  customer_name,  addr1,  
	addr2,   addr3,   addr4,  
	addr5,   addr6,   status_type,  
	attention_name,  attention_phone, contact_name,  
	contact_phone,  tlx_twx,  phone_1,  
	phone_2,  terms_code,  contact_email  
	)  
	SELECT customer_code,  customer_name,  addr1,  
	addr2,   addr3,   addr4,  
	addr5,   addr6,   status_type,  
	attention_name,  attention_phone, contact_name,  
	contact_phone,  tlx_twx,  phone_1,  
	phone_2,  terms_code,  contact_email  
	FROM arcust  
	WHERE customer_code = @cust_code  
  
   
	CREATE TABLE #prfcust  
	(  
	cust_code varchar( 8 )  
	)  
  
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

	IF (@nat_flag = 1)  
	BEGIN  
  
		EXEC ARPRFNationalCusts_SP @cust_code, @rel_code 

		INSERT	#prfcust
		SELECT	a.customer_code
		FROM	#bg_data a
		LEFT JOIN #prfcust b
		ON		a.customer_code = b.cust_code
		WHERE	b.cust_code IS NULL

  
		SET ROWCOUNT 1  
  
		SELECT @last_cust = ' '  
		SET @last_cust_sw = NULL
  
  
		SELECT	@last_amt = act.amt_tot_chg,  
				@last_doc = act.doc_ctrl_num,  
				@last_cust = act.customer_code,  
				@last_date = act.date_doc,  
				@last_cur = act.nat_cur_code  
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' ) 
		AND		act.trx_type IN (2031,2021,2051)
		ORDER BY act.date_doc DESC, act.doc_ctrl_num DESC  
  

		IF ( ( LTRIM(@last_cust) IS NOT NULL AND LTRIM(@last_cust) != ' ' ) )  
		BEGIN  
			UPDATE	#arprfdt  
			SET		amt_last_inv = @last_amt,  
					last_inv_doc = @last_doc,  
					last_inv_cust = @last_cust,  
					date_last_inv = @last_date,
					last_inv_cur = @last_cur  
		END
			

		SELECT @last_cust = ' '  
		SET @last_cust_sw = NULL


		SELECT	@last_amt = act.amt_net,  
				@last_doc = act.doc_ctrl_num,  
				@last_cust = act.customer_code,  
				@last_date = act.date_doc,  
				@last_cur = act.nat_cur_code  
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' ) 
		AND		act.trx_type IN (2032)
		AND		act.void_flag = 0
		ORDER BY act.date_doc DESC, act.doc_ctrl_num DESC  
 

		IF ( ( LTRIM(@last_cust) IS NOT NULL AND LTRIM(@last_cust) != ' ' ) )  
		BEGIN  
			UPDATE	#arprfdt  
			SET		amt_last_cm = @last_amt,  
					last_cm_doc = @last_doc,  
					last_cm_cust = @last_cust,  
					date_last_cm = @last_date,  
					last_cm_cur = @last_cur 
		END
			  
		SELECT @last_cust = ' ' 
		SET @last_cust_sw = NULL 
    
		SELECT	@last_amt = act.amt_net,  
				@last_doc = act.doc_ctrl_num,  
				@last_cust_pyt = act.customer_code,  
				@last_date = act.date_doc,  
				@last_cur = act.nat_cur_code  
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' )
		AND		act.trx_type = 2111
		AND		act.void_flag = 0
		ORDER BY act.date_doc DESC, act.doc_ctrl_num DESC  
  
		SELECT @last_cust = artrxage.payer_cust_code  
		FROM artrxage, #arprfdt  
		WHERE doc_ctrl_num = @last_doc  
		AND trx_type = 2111  
		AND artrxage.customer_code = @last_cust_pyt  
  
		IF ( ( LTRIM(@last_cust) IS NOT NULL AND LTRIM(@last_cust) != ' ' )  )  
		BEGIN  
			UPDATE	#arprfdt  
			SET		amt_last_pyt = @last_amt,  
					last_pyt_doc = @last_doc,  
					last_pyt_cust = @last_cust,  
					date_last_pyt = @last_date,  
					last_pyt_cur = @last_cur  
  
			SELECT @last_cust = ' '
		END  
  
		SELECT	@last_amt = a1.inv_amt_wr_off,  
				@last_doc = a1.apply_to_num,  
				@last_cust = a1.customer_code,  
				@last_date = a2.date_doc,  
				@last_cur = a2.nat_cur_code  
		FROM	artrxpdt a1 (NOLOCK)
		JOIN	artrx a2 (NOLOCK)
		ON		a2.doc_ctrl_num = a1.apply_to_num  
		JOIN	#bg_data  bg
		ON		a2.customer_code = bg.customer_code
		AND		a2.doc_ctrl_num = bg.doc_ctrl_num  
		WHERE ( LTRIM(a1.apply_to_num) IS NOT NULL AND LTRIM(a1.apply_to_num) != ' ' )  
		AND		a2.trx_type IN ( 2031, 2021 )   
		AND		a1.void_flag = 0   
		AND		a1.trx_type IN ( 2111, 2151 )   
		AND		a1.amt_wr_off > 0.0   
		ORDER BY a2.date_doc DESC, a2.doc_ctrl_num DESC  
 

		IF ( ( LTRIM(@last_cust) IS NOT NULL AND LTRIM(@last_cust) != ' ' ))  
		BEGIN  
			UPDATE	#arprfdt  
			SET		amt_last_wr_off = @last_amt,  
					last_wr_off_doc = @last_doc,  
					last_wr_off_cust = @last_cust,  
					date_last_wr_off = @last_date,  
					last_wr_off_cur = @last_cur  
      
			SELECT @last_cust = ' '  
		END  
  
		SELECT	@last_cust = act.customer_code,  
				@last_date = act.date_doc,  
				@last_amt = act.amt_net,  
				@last_doc = act.doc_ctrl_num,  
				@last_cur = act.nat_cur_code  
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' )  
		AND		act.trx_type = 2121
		ORDER BY act.date_doc DESC, act.doc_ctrl_num DESC  
  
		IF ( ( LTRIM(@last_cust) IS NOT NULL AND LTRIM(@last_cust) != ' ' ) )  
		BEGIN  
			UPDATE	#arprfdt  
			SET		amt_last_nsf = @last_amt,  
					last_nsf_doc = @last_doc,  
					last_nsf_cust = @last_cust,  
					date_last_nsf = @last_date,  
					last_nsf_cur = @last_cur  
      
			SELECT @last_cust = ' '  
		END  
  
		SELECT	@last_cust = act.customer_code,  
				@last_date = act.date_doc,  
				@last_amt = act.amt_net,  
				@last_doc = act.doc_ctrl_num,  
				@last_cur = act.nat_cur_code  
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' )  
		AND		act.trx_type = 2061
		ORDER BY act.date_doc DESC, act.doc_ctrl_num DESC  
  
		IF ( ( LTRIM(@last_cust) IS NOT NULL AND LTRIM(@last_cust) != ' ' )  )  
		BEGIN  
			UPDATE	#arprfdt  
			SET		amt_last_fin_chg = @last_amt,  
					last_fin_chg_doc = @last_doc,  
					last_fin_chg_cust = @last_cust,  
					date_last_fin_chg = @last_date,  
					last_fin_chg_cur = @last_cur  
      
			SELECT @last_cust = ' '  
		END  

		SELECT	@last_cust = act.customer_code,  
				@last_date = act.date_doc,  
				@last_amt = act.amt_net,  
				@last_doc = act.doc_ctrl_num,  
				@last_cur = act.nat_cur_code  
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' )  
		AND		act.trx_type = 2071
		ORDER BY act.date_doc DESC, act.doc_ctrl_num DESC  
  
		IF ( ( LTRIM(@last_cust) IS NOT NULL AND LTRIM(@last_cust) != ' ' ) )  
		BEGIN  
			UPDATE	#arprfdt  
			SET		amt_last_late_chg = @last_amt,  
					last_late_chg_doc = @last_doc,  
					last_late_chg_cust = @last_cust,  
					date_last_late_chg = @last_date,  
					last_late_chg_cur = @last_cur  
		END  
  
		SET ROWCOUNT 0  
	END  
	ELSE  
	BEGIN  
		-- v1.3 Start

		INSERT INTO #prfcust  
		( cust_code )  
		VALUES ( @cust_code )  

		SET ROWCOUNT 1  
  
		SELECT @last_cust = ' '  
		SET @last_cust_sw = NULL
  
  
		SELECT	@last_amt = act.amt_tot_chg,  
				@last_doc = act.doc_ctrl_num,  
				@last_cust = act.customer_code,  
				@last_date = act.date_doc,  
				@last_cur = act.nat_cur_code  
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' ) 
		AND		act.trx_type IN (2031,2021,2051)
		ORDER BY act.date_doc DESC, act.doc_ctrl_num DESC  
  
		IF ( ( LTRIM(@last_cust) IS NOT NULL AND LTRIM(@last_cust) != ' ' ) )  
		BEGIN  
			UPDATE	#arprfdt  
			SET		amt_last_inv = @last_amt,  
					last_inv_doc = @last_doc,  
					last_inv_cust = @last_cust,  
					date_last_inv = @last_date,
					last_inv_cur = @last_cur  
		END
			
		SELECT @last_cust = ' '  
		SET @last_cust_sw = NULL


		SELECT	@last_amt = act.amt_net,  
				@last_doc = act.doc_ctrl_num,  
				@last_cust = act.customer_code,  
				@last_date = act.date_doc,  
				@last_cur = act.nat_cur_code  
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' ) 
		AND		act.trx_type IN (2032)
		AND		act.void_flag = 0
		ORDER BY act.date_doc DESC, act.doc_ctrl_num DESC  
 
		IF ( ( LTRIM(@last_cust) IS NOT NULL AND LTRIM(@last_cust) != ' ' ) )  
		BEGIN  
			UPDATE	#arprfdt  
			SET		amt_last_cm = @last_amt,  
					last_cm_doc = @last_doc,  
					last_cm_cust = @last_cust,  
					date_last_cm = @last_date,  
					last_cm_cur = @last_cur 
		END
			
  
		SELECT @last_cust = ' ' 
		SET @last_cust_sw = NULL 
    
		SELECT	@last_amt = act.amt_net,  
				@last_doc = act.doc_ctrl_num,  
				@last_cust_pyt = act.customer_code,  
				@last_date = act.date_doc,  
				@last_cur = act.nat_cur_code  
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' )
		AND		act.trx_type = 2111
		AND		act.void_flag = 0
		ORDER BY act.date_doc DESC, act.doc_ctrl_num DESC  
  
		SELECT @last_cust = artrxage.payer_cust_code  
		FROM artrxage, #arprfdt  
		WHERE doc_ctrl_num = @last_doc  
		AND trx_type = 2111  
		AND artrxage.customer_code = @last_cust_pyt  
  
		IF ( ( LTRIM(@last_cust) IS NOT NULL AND LTRIM(@last_cust) != ' ' )  )  
		BEGIN  
			UPDATE	#arprfdt  
			SET		amt_last_pyt = @last_amt,  
					last_pyt_doc = @last_doc,  
					last_pyt_cust = @last_cust,  
					date_last_pyt = @last_date,  
					last_pyt_cur = @last_cur  
  
			SELECT @last_cust = ' '  
		END  
  
		SELECT	@last_amt = a1.inv_amt_wr_off,  
				@last_doc = a1.apply_to_num,  
				@last_cust = a1.customer_code,  
				@last_date = a2.date_doc,  
				@last_cur = a2.nat_cur_code  
		FROM	artrxpdt a1 (NOLOCK)
		JOIN	artrx a2 (NOLOCK)
		ON		a2.doc_ctrl_num = a1.apply_to_num  
		JOIN	#bg_data  bg
		ON		a2.customer_code = bg.customer_code
		AND		a1.apply_to_num = bg.doc_ctrl_num
		WHERE ( LTRIM(a1.apply_to_num) IS NOT NULL AND LTRIM(a1.apply_to_num) != ' ' )  
		AND		a2.trx_type IN ( 2031, 2021 )   
		AND		a1.void_flag = 0   
		AND		a1.trx_type IN ( 2111, 2151 )   
		AND		a1.amt_wr_off > 0.0   
		ORDER BY a2.date_doc DESC, a2.doc_ctrl_num DESC  
  
		IF ( ( LTRIM(@last_cust) IS NOT NULL AND LTRIM(@last_cust) != ' ' ))  
		BEGIN  
			UPDATE	#arprfdt  
			SET		amt_last_wr_off = @last_amt,  
					last_wr_off_doc = @last_doc,  
					last_wr_off_cust = @last_cust,  
					date_last_wr_off = @last_date,  
					last_wr_off_cur = @last_cur  
      
			SELECT @last_cust = ' '  
		END  
  
		SELECT	@last_cust = act.customer_code,  
				@last_date = act.date_doc,  
				@last_amt = act.amt_net,  
				@last_doc = act.doc_ctrl_num,  
				@last_cur = act.nat_cur_code  
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' )  
		AND		act.trx_type = 2121
		ORDER BY act.date_doc DESC, act.doc_ctrl_num DESC  
  
		IF ( ( LTRIM(@last_cust) IS NOT NULL AND LTRIM(@last_cust) != ' ' ) )  
		BEGIN  
			UPDATE	#arprfdt  
			SET		amt_last_nsf = @last_amt,  
					last_nsf_doc = @last_doc,  
					last_nsf_cust = @last_cust,  
					date_last_nsf = @last_date,  
					last_nsf_cur = @last_cur  
      
			SELECT @last_cust = ' '  
		END  
  
		SELECT	@last_cust = act.customer_code,  
				@last_date = act.date_doc,  
				@last_amt = act.amt_net,  
				@last_doc = act.doc_ctrl_num,  
				@last_cur = act.nat_cur_code  
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' )  
		AND		act.trx_type = 2061
		ORDER BY act.date_doc DESC, act.doc_ctrl_num DESC  
  
		IF ( ( LTRIM(@last_cust) IS NOT NULL AND LTRIM(@last_cust) != ' ' )  )  
		BEGIN  
			UPDATE	#arprfdt  
			SET		amt_last_fin_chg = @last_amt,  
					last_fin_chg_doc = @last_doc,  
					last_fin_chg_cust = @last_cust,  
					date_last_fin_chg = @last_date,  
					last_fin_chg_cur = @last_cur  
      
			SELECT @last_cust = ' '  
		END  

		SELECT	@last_cust = act.customer_code,  
				@last_date = act.date_doc,  
				@last_amt = act.amt_net,  
				@last_doc = act.doc_ctrl_num,  
				@last_cur = act.nat_cur_code  
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' )  
		AND		act.trx_type = 2071
		ORDER BY act.date_doc DESC, act.doc_ctrl_num DESC  
  
		IF ( ( LTRIM(@last_cust) IS NOT NULL AND LTRIM(@last_cust) != ' ' ) )  
		BEGIN  
			UPDATE	#arprfdt  
			SET		amt_last_late_chg = @last_amt,  
					last_late_chg_doc = @last_doc,  
					last_late_chg_cust = @last_cust,  
					date_last_late_chg = @last_date,  
					last_late_chg_cur = @last_cur  
		END  
  
		SET ROWCOUNT 0  

	END  
  
	IF (@home_oper_flag = 0)  
	BEGIN  
  
  
		SET @tot_inv_amt = 0
		SELECT	@tot_inv_amt = SUM(act.amt_tot_chg - act.amt_paid_to_date)
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' ) 
		AND		act.trx_type IN (2031,2021,2051)


		IF (@tot_inv_amt IS NULL)
			SET @tot_inv_amt = 0.0


		SET @tot_cm_amt = 0
	
		SELECT	@tot_cm_amt = SUM(act.amt_net)
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num			
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' ) 
		AND		act.trx_type IN (2032)
		AND		act.void_flag = 0

		IF (@tot_cm_amt IS NULL)
			SET @tot_cm_amt = 0.0

		SET @tot_pyt_amt = 0.0

		SELECT	@tot_pyt_amt = SUM(act.amt_on_acct)
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num			
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' )
		AND		act.trx_type = 2111
		AND		act.void_flag = 0
		AND		act.source_trx_ctrl_num IS NULL

		IF (@tot_pyt_amt IS NULL)
			SET @tot_pyt_amt = 0.0

		SET @tot_wr_off_amt = 0.0  

		SELECT	@tot_wr_off_amt = SUM(a1.inv_amt_wr_off)
		FROM	artrxpdt a1 (NOLOCK)
		JOIN	artrx a2 (NOLOCK)
		ON		a2.doc_ctrl_num = a1.apply_to_num  
		JOIN	#bg_data  bg
		ON		a2.customer_code = bg.customer_code
		AND		a1.apply_to_num = bg.doc_ctrl_num 
		WHERE ( LTRIM(a1.apply_to_num) IS NOT NULL AND LTRIM(a1.apply_to_num) != ' ' )  
		AND		a2.trx_type IN ( 2031, 2021 )   
		AND		a1.void_flag = 0   
		AND		a1.trx_type IN ( 2111, 2151 )   
		AND		a1.amt_wr_off > 0.0   

		SET @tot_nsf_amt = 0.0

		SELECT	@tot_nsf_amt = SUM(act.amt_net)
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' )  
		AND		act.trx_type = 1021

		SET @tot_fin_chg_amt = 0.0

		SELECT	@tot_fin_chg_amt = SUM(act.amt_net)
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' )  
		AND		act.trx_type = 2061

		SET @tot_late_chg_amt = 0  

		SELECT	@tot_late_chg_amt = SUM(act.amt_net)
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' )  
		AND		act.trx_type = 2071

		SET @tot_disc_amt = 0  

		SELECT	@tot_disc_amt = SUM(act.amt_net)
		FROM	artrx act (NOLOCK)
		JOIN	#bg_data  bg
		ON		act.customer_code = bg.customer_code
		AND		act.doc_ctrl_num = bg.doc_ctrl_num			
		WHERE	( LTRIM(act.doc_ctrl_num) IS NOT NULL AND LTRIM(act.doc_ctrl_num) != ' ' )  
		AND		act.trx_type = 2131

		SELECT	@balance = (ISNULL(@tot_inv_amt,0.0) + ISNULL(@tot_fin_chg_amt,0.0) + ISNULL(@tot_late_chg_amt,0.0) + ISNULL(@tot_nsf_amt,0.0)) - 
					(ISNULL(@tot_cm_amt,0.0) + ISNULL(@tot_pyt_amt,0.0) + ISNULL(@tot_disc_amt,0.0))
--						(ISNULL(@tot_cm_amt,0.0) + ISNULL(@tot_pyt_amt,0.0) + ISNULL(@tot_wr_off_amt,0.0) + ISNULL(@tot_disc_amt,0.0))


	END  
	ELSE  
	BEGIN  
    
		SELECT @tot_inv_amt = SUM(amt_inv_oper),  
		@tot_cm_amt = SUM(amt_cm_oper),  
		@tot_pyt_amt = sum(amt_pyt_oper),  
		@tot_wr_off_amt = SUM(amt_wr_off_oper),  
		@tot_nsf_amt = sum(amt_nsf_oper),  
		@tot_fin_chg_amt = sum(amt_fin_chg_oper),  
		@tot_late_chg_amt = sum(amt_late_chg_oper),  
		@tot_disc_amt = SUM(amt_disc_t_oper)  
		FROM arsumcus cus, #prfcust prf  
		WHERE cus.customer_code = prf.cust_code  
    
		SELECT @balance = SUM( amt_balance_oper - amt_on_acct_oper )  
		FROM aractcus cus, #prfcust prf  
		WHERE cus.customer_code = prf.cust_code  
  
		SELECT @tot_pyt_amt = @tot_pyt_amt + SUM(amt_on_acct_oper)  
		FROM aractcus act, #prfcust prf  
		WHERE prf.cust_code = act.customer_code  
	END  
	-- v1.0 End   

	UPDATE #arprfdt  
	SET amt_last_inv_mask = currency_mask  
	FROM glcurr_vw  
	WHERE last_inv_cur = currency_code  
  
	UPDATE #arprfdt  
	SET amt_last_cm_mask = currency_mask  
	FROM glcurr_vw  
	WHERE last_cm_cur = currency_code  
  
	UPDATE #arprfdt  
	SET amt_last_pyt_mask = currency_mask  
	FROM glcurr_vw  
	WHERE last_pyt_cur = currency_code  
  
	UPDATE #arprfdt  
	SET amt_last_wr_off_mask = currency_mask  
	FROM glcurr_vw  
	WHERE last_wr_off_cur = currency_code  

	UPDATE #arprfdt  
	SET amt_last_nsf_mask = currency_mask  
	FROM glcurr_vw  
	WHERE last_nsf_cur = currency_code  

	UPDATE #arprfdt  
	SET amt_last_fin_chg_mask = currency_mask  
	FROM glcurr_vw  
	WHERE last_fin_chg_cur = currency_code  

	UPDATE #arprfdt  
	SET amt_last_late_chg_mask = currency_mask  
	FROM glcurr_vw  
	WHERE last_late_chg_cur = currency_code  
    
	CREATE TABLE #CustomerDunning(  
	customer_code  varchar(8),  
	max_dunning_level  int )  

	INSERT INTO #CustomerDunning  
	SELECT customer_code, MAX(dunning_level)  
	FROM ardncsdt  
	WHERE customer_code = @cust_code  
	GROUP BY customer_code  
  
	UPDATE #arprfdt  
	SET max_dunning_level = b.max_dunning_level  
	FROM #arprfdt a, #CustomerDunning b  
	WHERE a.customer_code = b.customer_code  
   
	DROP TABLE #CustomerDunning  
  
	UPDATE #arprfdt  
	SET tot_inv_amt = @tot_inv_amt,  
	tot_cm_amt = @tot_cm_amt,  
	tot_pyt_amt = @tot_pyt_amt,  
	tot_wr_off_amt = @tot_wr_off_amt,  
	tot_nsf_amt = @tot_nsf_amt,  
	tot_fin_chg_amt = @tot_fin_chg_amt,  
	tot_late_chg_amt = @tot_late_chg_amt,  
	tot_disc_amt = @tot_disc_amt,  
	balance = @balance  
  
	DROP TABLE #prfcust
	DROP TABLE #bg_data
  
END  

GO
GRANT EXECUTE ON  [dbo].[ARPRFLoadTable_SP] TO [public]
GO
