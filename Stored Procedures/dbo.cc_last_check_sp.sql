SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_last_check_sp]	@customer_code	varchar(8),
																	@all_org_flag			smallint = 0,	 
																	@from_org varchar(30) = '',
																	@to_org varchar(30) = ''

AS

	SET NOCOUNT ON

	DECLARE @trx_ctrl_num varchar(16)
	DECLARE @date_entered int


	IF ( SELECT ib_flag FROM glco ) = 0
		SELECT @all_org_flag = 1


	IF @all_org_flag = 1
		SELECT @date_entered = MAX( date_entered ) 
		FROM artrx
		WHERE customer_code = @customer_code
		AND trx_type = 2111
		AND void_flag = 0
		AND payment_type <> 3	
	ELSE
		SELECT @date_entered = MAX( date_entered ) 
		FROM artrx
		WHERE customer_code = @customer_code
		AND trx_type = 2111
		AND void_flag = 0
		AND payment_type <> 3	
		AND	org_id BETWEEN @from_org AND @to_org

	SET ROWCOUNT 1

	IF @all_org_flag = 1
		SELECT @trx_ctrl_num = trx_ctrl_num
		FROM artrx
		WHERE customer_code = @customer_code
		AND trx_type = 2111
		AND void_flag = 0
		AND payment_type <> 3	
		AND	date_entered = @date_entered
		ORDER BY trx_ctrl_num DESC
	ELSE
		SELECT @trx_ctrl_num = trx_ctrl_num
		FROM artrx
		WHERE customer_code = @customer_code
		AND trx_type = 2111
		AND void_flag = 0
		AND payment_type <> 3	
		AND	date_entered = @date_entered
		AND	org_id BETWEEN @from_org AND @to_org
		ORDER BY trx_ctrl_num DESC
	
SET ROWCOUNT 0





	CREATE TABLE #check_data
	(	customer_code	varchar(8),
		doc_ctrl_num	varchar(16),
		amt_net		float NULL,
		date_entered	int NULL,
		apply_to_num	varchar(16) NULL,
		amt_applied	float NULL,
		inv_date_entered	int NULL,
		nat_cur_code	varchar(8),
		date_applied int NULL,
		org_id	varchar(30) NULL )

	IF ( SELECT COUNT(*) FROM artrxpdt WHERE trx_ctrl_num = @trx_ctrl_num ) > 0
		INSERT	#check_data
		SELECT	h.customer_code, 
						h.doc_ctrl_num, 
						amt_net,
						h.date_entered, 
						d.apply_to_num,	
						d.amt_applied, 
						NULL,
						nat_cur_code, 
						h.date_applied,
						h.org_id
		FROM artrx h, artrxpdt d
		WHERE h.trx_ctrl_num = @trx_ctrl_num 	
		AND h.trx_ctrl_num = d.trx_ctrl_num
		AND h.customer_code = @customer_code
		AND	h.org_id = d.org_id
	ELSE
		INSERT	#check_data
		SELECT	h.customer_code, 
						h.doc_ctrl_num, 
						amt_net,
						h.date_entered, 
						'',
						0.0, 
						NULL,
						nat_cur_code, 
						h.date_applied,
						h.org_id
		FROM artrx h
		WHERE h.trx_ctrl_num = @trx_ctrl_num 	
		AND h.customer_code = @customer_code
	

	UPDATE #check_data 
	SET inv_date_entered = d.date_entered
	FROM #check_data c, artrx d
	WHERE d.doc_ctrl_num = c.apply_to_num

	SELECT 	customer_code, 
					doc_ctrl_num, 
					STR(amt_net,30,6), 
					CONVERT(varchar(15),DATEADD(dd, date_entered - 639906, '01/01/1753'),107), 
					CASE
					WHEN apply_to_num IS NOT NULL
					THEN apply_to_num
					ELSE 'ON ACCOUNT'
					END,
					STR(amt_applied,30,6), 
					CONVERT(varchar(15),DATEADD(dd, inv_date_entered - 639906, '01/01/1753'),107),
					nat_cur_code, 
					CONVERT(varchar(15),DATEADD(dd, date_applied - 639906, '01/01/1753'),107),
					ISNULL(org_id, '')
	FROM #check_data

DROP TABLE #check_data

	SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[cc_last_check_sp] TO [public]
GO
