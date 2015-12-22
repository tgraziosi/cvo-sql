SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_pymt_search_sp]	@doc_num varchar(16) = NULL


AS

DECLARE @trx_ctrl_num varchar(16)


DECLARE @load_customer varchar(8)

CREATE table #payments
(
	trx_ctrl_num varchar(16) NULL,
	doc_ctrl_num varchar(16) NULL,
	date_doc int NULL,
	trx_type int NULL,
	amt_net float NULL,
	amt_paid_to_date float NULL,
	balance float NULL,
	customer_code varchar(12) NULL,
	void_flag smallint NULL,
	trx_type_code varchar(8) NULL,
	nat_cur_code varchar(8) NULL,
	payment_type 			smallint NULL,
	date_applied			int NULL,
	price_code				varchar(8) NULL,
	amt_on_acct				float NULL,
	sequence_id				int NULL,
	org_id	varchar(30) NULL)




INSERT #payments
	SELECT 	trx_ctrl_num, 
		doc_ctrl_num,
		date_doc,
		trx_type,
		amt_net,
		NULL,
		amt_on_acct,
		customer_code,
		void_flag,
		NULL,
		nat_cur_code,
		payment_type,
		date_applied,
		price_code,
		amt_on_acct,
		0,
		org_id
	FROM 	artrx 
	WHERE	(trx_ctrl_num = @doc_num
			OR doc_ctrl_num = @doc_num)
	AND 	payment_type = 1
	AND 	trx_type IN (2111,2113,2032)
		
SELECT 	@load_customer = MIN(customer_code) FROM #payments WHERE customer_code IS NOT NULL


SELECT @trx_ctrl_num = MIN(trx_ctrl_num) from #payments
WHILE (@trx_ctrl_num IS NOT NULL)
	BEGIN
		INSERT #payments
			SELECT 	d.trx_ctrl_num,
				d.apply_to_num, 
				date_doc, 
				NULL,
				inv_amt_applied,
				NULL, 
				amt_net, 
				d.customer_code,
				0,
				NULL,
				nat_cur_code,
				0,
				h.date_applied,
				h.price_code,
				h.amt_on_acct,
				d.sequence_id,
				d.org_id
			FROM 	artrxpdt d, artrx h
			WHERE 	d.trx_ctrl_num = @trx_ctrl_num 
 			AND 	d.apply_to_num = h.doc_ctrl_num
			AND d.void_flag = 0 
 
	SELECT @trx_ctrl_num = MIN(trx_ctrl_num) 
	FROM #payments
	WHERE trx_ctrl_num > @trx_ctrl_num
END	


UPDATE 	#payments
SET 	balance = 0
FROM 	#payments
WHERE 	void_flag = 1 

UPDATE 	#payments
SET 	#payments.trx_type_code = artrxtyp.trx_type_code
FROM 	#payments,artrxtyp
WHERE 	artrxtyp.trx_type = #payments.trx_type


	SELECT 	trx_ctrl_num,
					doc_ctrl_num,
					date_doc,
					trx_type,
					STR(amt_net,30,6), 
					STR(amt_paid_to_date,30,6), 
					STR(balance,30,6), 
					customer_code,
					void_flag,
					trx_type_code,
					@load_customer,
					nat_cur_code,
					date_applied,
					price_code,
				(	SELECT count(*) 
					FROM cc_comments 
					WHERE ( doc_ctrl_num = #payments.doc_ctrl_num)
					AND	customer_code = @load_customer ),
				( SELECT COUNT(*) 
					FROM comments 
					WHERE key_1 IN (SELECT trx_ctrl_num 
													FROM artrx 
													WHERE ( doc_ctrl_num = #payments.doc_ctrl_num)
													AND	customer_code = @load_customer)),
					org_id
	FROM #payments 
	ORDER BY trx_ctrl_num ,trx_type DESC


GO
GRANT EXECUTE ON  [dbo].[cc_pymt_search_sp] TO [public]
GO
