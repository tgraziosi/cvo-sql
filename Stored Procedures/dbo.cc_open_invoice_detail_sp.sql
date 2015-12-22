SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cc_open_invoice_detail_sp] 
	@doc_ctrl_num	varchar(16) = NULL,
	@customer_code	varchar(8) = NULL
AS
SET NOCOUNT ON
CREATE table #details
	(apply_to_num varchar(16) NULL,
	doc_ctrl_num varchar(16) NULL,
	date_doc int NULL,
	trx_type int NULL,
	amt_net float NULL,
	price_code varchar(8) NULL,
	territory_code varchar(8) NULL,
	nat_cur_code	varchar(8) NULL,
	trx_type_code	varchar(8) NULL,
	amt_on_acct float NULL,
	status_code 		varchar(5) 	NULL,
	status_date 		int 		NULL,
	customer_code		varchar(10) ) -- v1.0



	CREATE TABLE #non_zero_records
	(
		doc_ctrl_num 		varchar(16)	NULL, 
		trx_type 		smallint	NULL, 
		customer_code 		varchar(8)	NULL, 
		total 			float		NULL
	)


		DECLARE @relation_code varchar(10),
				@IsParent int, -- v1.1
				@IsBG int -- v1.3
		
		SELECT @relation_code = credit_check_rel_code
		FROM arco (NOLOCK)

	CREATE TABLE #customers( customer_code varchar(8) )

	INSERT #customers
	SELECT @customer_code


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

	INSERT	#customers
	SELECT	DISTINCT customer_code FROM #bg_data

	INSERT #non_zero_records
	SELECT 	a.apply_to_num, 
			a.apply_trx_type, 
			a.customer_code, 
			SUM(a.amount) 
	FROM 	artrxage a (NOLOCK)
	JOIN	#bg_data b 
	ON		a.customer_code = b.customer_code 
	AND 	a.apply_to_num = @doc_ctrl_num
	GROUP BY a.customer_code, a.apply_to_num, a.apply_trx_type
	

	INSERT	#details
	SELECT 	a.apply_to_num, 
					a.doc_ctrl_num,
					a.date_doc,
					a.trx_type,
 
					amount,		 
					price_code,
					territory_code,
					nat_cur_code,
					t.trx_type_code,
					0,
					'',
					0,
					a.customer_code -- v1.0
	FROM 	artrxage a (NOLOCK), #non_zero_records c, artrxtyp t (NOLOCK)
	WHERE	a.apply_trx_type = c.trx_type
	AND		a.customer_code = c.customer_code 
	AND		a.doc_ctrl_num <> @doc_ctrl_num
	AND		a.apply_to_num = @doc_ctrl_num
	AND		a.trx_type = t.trx_type


	UPDATE 	#details
	SET 		trx_type = 2032 
	FROM 		#details
	WHERE 	trx_type = 2111 
	AND 		doc_ctrl_num IN (SELECT doc_ctrl_num FROM artrxcdt WHERE trx_type = 2032) 


	UPDATE	#details
	SET 		amt_on_acct = h.amt_on_acct 
	FROM 		#details d, artrx h 
	WHERE 	d.doc_ctrl_num = h.doc_ctrl_num
	AND 		h.trx_type = 2111

	UPDATE 	#details 
	SET 	status_code = h.status_code,
				status_date = h.date
	FROM 	#details, cc_inv_status_hist h
	WHERE 	#details.doc_ctrl_num = h.doc_ctrl_num
	AND 	sequence_num = (SELECT MAX(sequence_num) 
				FROM cc_inv_status_hist 
				WHERE doc_ctrl_num = #details.doc_ctrl_num
				AND clear_date IS NULL)

	SELECT	apply_to_num, 
					doc_ctrl_num,
					date_doc,
					trx_type,
					STR(amt_net,30,6), 
					price_code,
					territory_code,
					nat_cur_code,
					trx_type_code,
					(SELECT count(*) FROM cc_comments WHERE doc_ctrl_num = #details.doc_ctrl_num),
					(SELECT COUNT(*) FROM comments WHERE key_1 IN( SELECT doc_ctrl_num FROM artrx WHERE doc_ctrl_num = #details.doc_ctrl_num)),
					amt_on_acct,
					status_code,
					status_date
	FROM #details
	ORDER BY date_doc, doc_ctrl_num, trx_type_code

	DROP TABLE #details		
	DROP TABLE #bg_data
			
GO
GRANT EXECUTE ON  [dbo].[cc_open_invoice_detail_sp] TO [public]
GO
