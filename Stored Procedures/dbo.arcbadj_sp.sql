SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arcbadj_sp] @batch_ctrl_num varchar(16)

AS 

DECLARE	@cb_reason_code varchar(8), 
 	@cb_status_code varchar(2), 
	@new_cb_reason_code varchar(8), 
	@new_cb_status_code varchar(2),
 	@cb_responsibility_code varchar(8), 
	@new_cb_resp_code varchar(8), 
	@store_number varchar(16),
 	@new_store_number varchar(16),
	@min_trx varchar(16),
	@last_trx varchar(16),
	@apply_to_num varchar(16),
	@cust_code varchar(8),
	@result int,
	@open_amt float,
	@debug_level int,
	@cb_reason_desc varchar(40),
	@new_cb_reason_desc varchar(40)


BEGIN

SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcbadj.sp" + ", line " + STR( 1, 5 ) + " -- ENTRY: "

SELECT @min_trx = "", @last_trx=""

WHILE (1=1)
BEGIN
	SELECT	@min_trx = min(trx_ctrl_num) 
	FROM	#arinpchg_work
	WHERE 	trx_ctrl_num > @last_trx 
	AND	trx_type = 2051
	AND	apply_to_num LIKE 'CB%'
	AND	posted_flag <> 0

	IF @min_trx is null
		BREAK
	
	SELECT @last_trx = @min_trx

	/* Select fields from the adjustment */
	SELECT	@apply_to_num = apply_to_num,
		@cust_code = customer_code
	FROM	#arinpchg_work
	WHERE	trx_ctrl_num = @min_trx

	/* If comments on adjustment, delete any connected to the chargeback */
	IF EXISTS (SELECT * FROM comments WHERE key_1 = @min_trx)
		DELETE comments 
		FROM comments a, artrx b
		WHERE a.key_1 = b.trx_ctrl_num
		AND b.doc_ctrl_num = @apply_to_num

	UPDATE  comments
	SET key_1 = b.trx_ctrl_num
	FROM comments a, artrx b
	WHERE a.key_1 = @min_trx
	AND b.doc_ctrl_num = @apply_to_num

	/* Select the charge back details */
	SELECT	@cb_reason_code = cb_reason_code, 
		@new_cb_reason_code = new_cb_reason_code,
 		@cb_status_code = cb_status_code, 
		@new_cb_status_code = new_cb_status_code,
 		@cb_responsibility_code = cb_responsibility_code, 
		@new_cb_resp_code = new_cb_resp_code,
		@store_number = store_number,
		@new_store_number = new_store_number,
		@cb_reason_desc = cb_reason_desc,
		@new_cb_reason_desc = new_cb_reason_desc
	FROM	arcbinv
	WHERE	trx_ctrl_num = @min_trx

  	/* Update the charge back status code - The Emerald Group */
  	IF @new_cb_status_code <> @cb_status_code 
  	BEGIN
		UPDATE arcbinv SET cb_status_code = @new_cb_status_code
		FROM arcbinv a, artrx b
	 	WHERE b.doc_ctrl_num = @apply_to_num AND b.trx_type = 2031
		AND a.trx_ctrl_num = b.trx_ctrl_num
  	END

  	/* Update the charge back reason code - The Emerald Group */
  	IF @new_cb_reason_code <> @cb_reason_code 
  	BEGIN
		UPDATE arcbinv SET cb_reason_code = @new_cb_reason_code
		FROM arcbinv a, artrx b
	 	WHERE b.doc_ctrl_num = @apply_to_num AND b.trx_type = 2031
		AND a.trx_ctrl_num = b.trx_ctrl_num
  	END

  	IF @new_cb_reason_desc <> @cb_reason_desc 
  	BEGIN
		UPDATE arcbinv SET cb_reason_desc = @new_cb_reason_desc
		FROM arcbinv a, artrx b
	 	WHERE b.doc_ctrl_num = @apply_to_num AND b.trx_type = 2031
		AND a.trx_ctrl_num = b.trx_ctrl_num
  	END


  	/* Update the charge back responsibility code - The Emerald Group */
  	IF @new_cb_resp_code <> @cb_responsibility_code
  	BEGIN
		UPDATE arcbinv SET cb_responsibility_code = @new_cb_resp_code
		FROM arcbinv a, artrx b
	 	WHERE b.doc_ctrl_num = @apply_to_num AND b.trx_type = 2031
		AND a.trx_ctrl_num = b.trx_ctrl_num
  	END

  	/* Update the charge back store number - The Emerald Group */
  	IF @new_store_number <> @store_number
  	BEGIN
		UPDATE arcbinv SET store_number = @new_store_number
		FROM arcbinv a, artrx b
	 	WHERE b.doc_ctrl_num = @apply_to_num AND b.trx_type = 2031
		AND a.trx_ctrl_num = b.trx_ctrl_num
  	END

	/* Read the archgbk table and create chargebacks - The Emerald Group  */
  	EXEC @result = ARSplitcb_SP @min_trx, @apply_to_num, @cust_code, @debug_level

	/* If the chargebacks left an open amount of zero, set the paid flag on - The Emerald Group */ 
  	SELECT @open_amt=(amt_tot_chg - amt_paid_to_date) FROM artrx 
    	WHERE doc_ctrl_num = @apply_to_num AND trx_type = 2031 
	
  	IF @open_amt = 0
	BEGIN
		UPDATE artrx SET paid_flag = 1
		WHERE doc_ctrl_num = @apply_to_num AND trx_type = 2031 

		UPDATE artrxage SET paid_flag = 1
		WHERE doc_ctrl_num = @apply_to_num AND trx_type = 2031 
	END

	/* Delete the unposted charge back records - The Emerald Group */
  	DELETE archgbk WHERE trx_ctrl_num = @min_trx

END

END

GO
GRANT EXECUTE ON  [dbo].[arcbadj_sp] TO [public]
GO
