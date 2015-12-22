SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                























































	


























CREATE PROCEDURE [dbo].[apaprmk_sp]
	@trx_type smallint,	@trx_num char(32),	@system_date int
AS




DECLARE	@po_type 	smallint,	@voucher_type 	smallint,	
	@payment_type 	smallint,	@sequence_flag 	smallint,	
	@det_aprv_flag	smallint,	@add_appr_code 	varchar(16),
	@trx_amt 	float,		@appr_code 	varchar(16),	
	@apply_date 	int,		@acct_code 	varchar(32),	
	@branch_code 	varchar(16),	@vendor_code 	varchar(12),	
	@sqid 		int,		@last_sqid 	smallint,
	@line_amt 	float,		@approve 	smallint,	
	@date_doc 	int,		@proc_flag	smallint,
	@nat_cur_code varchar(8), @rate_type_home varchar(8),
	@rate_type_oper varchar(8), @rate_home float,
	@rate_oper float,	@approval_by_home smallint,
	@approve_amt float, @org_id varchar(16)


declare @oper_cur_code varchar(8), @home_cur_code varchar(8)
declare @op_rate decimal(20,8), @nat_rate decimal(20,8),
@curr_date int, @retval int, @divop int





SELECT	@voucher_type = 4091, @payment_type = 4111, @det_aprv_flag = 0, @po_type = 4090





IF ( @trx_type = @payment_type )
BEGIN
	


	SELECT	@proc_flag = aprv_check_flag,
		@approval_by_home = aprv_hm_flag
	FROM	apco

	SELECT	@trx_amt = amt_payment,
		@appr_code = approval_code,
		@vendor_code = vendor_code,
		@apply_date = date_applied,
		@date_doc = date_doc,
		@nat_cur_code = nat_cur_code,
		@rate_type_home = rate_type_home,
		@rate_type_oper = rate_type_oper,
		@rate_home = rate_home,
		@rate_oper = rate_oper,
		@org_id = org_id
	FROM	apinppyt
	WHERE	trx_type = @trx_type
	AND	trx_ctrl_num = @trx_num
END
ELSE IF ( @trx_type = @voucher_type )
BEGIN
	



	SELECT	@det_aprv_flag = aprv_voucher_det_flag,
		@proc_flag = aprv_voucher_flag,
		@approval_by_home = aprv_hm_flag
	FROM	apco

	SELECT	@trx_amt = amt_net,
		@appr_code = approval_code,
		@vendor_code = vendor_code,
		@branch_code = branch_code,
		@apply_date = date_applied,
		@date_doc = date_doc,
		@nat_cur_code = nat_cur_code,
		@rate_type_home = rate_type_home,
		@rate_type_oper = rate_type_oper,
		@rate_home = rate_home,
		@rate_oper = rate_oper,
		@org_id = org_id
	FROM	apinpchg
	WHERE	trx_type = @trx_type
	AND	trx_ctrl_num = @trx_num
END
ELSE IF ( @trx_type = @po_type)
		BEGIN


			SELECT	@proc_flag = aprv_po_flag,
				@approval_by_home = aprv_hm_flag
			FROM	apco (nolock)


			SELECT @rate_type_home = rate_type_home, 
				   @rate_type_oper = rate_type_oper,
				   @oper_cur_code = oper_currency,
				   @home_cur_code = home_currency
			FROM glco (NOLOCK)

			SELECT @branch_code = branch_code,
			 	   @nat_cur_code = curr_key
				 FROM apmaster_all apm (NOLOCK) 
						INNER JOIN purchase_all pall(NOLOCK) ON apm.vendor_code = pall.vendor_no
						AND po_no = @trx_num AND po_ext = 0


			SELECT	@trx_amt = total_amt_order,
					@appr_code = approval_code,
					@vendor_code = vendor_no,
					@apply_date = datediff(day,'01/01/1900',date_order_due) + 693596,    
					@date_doc = datediff(day,'01/01/1900',date_of_order) + 693596,
					@org_id = organization_id   				
			FROM purchase_all (NOLOCK)
			WHERE po_no = @trx_num and po_ext = 0

			exec @retval = adm_mccurate_sp  @date_doc, @nat_cur_code , @home_cur_code,
			@rate_type_home, @rate_home OUTPUT, 0, @divop OUTPUT
			
			exec @retval = adm_mccurate_sp  @date_doc, @nat_cur_code, @oper_cur_code,
			@rate_type_oper, @rate_oper OUTPUT, 0, @divop OUTPUT



			
		END
	ELSE
		RETURN

IF @approval_by_home = 1
   SELECT @approve_amt = @trx_amt * ( SIGN(1 + SIGN(@rate_home))*(@rate_home) + (SIGN(ABS(SIGN(ROUND(@rate_home,6))))/(@rate_home + SIGN(1 - ABS(SIGN(ROUND(@rate_home,6)))))) * SIGN(SIGN(@rate_home) - 1) )
ELSE 
   SELECT @approve_amt = @trx_amt * ( SIGN(1 + SIGN(@rate_oper))*(@rate_oper) + (SIGN(ABS(SIGN(ROUND(@rate_oper,6))))/(@rate_oper + SIGN(1 - ABS(SIGN(ROUND(@rate_oper,6)))))) * SIGN(SIGN(@rate_oper) - 1) )





IF ( @appr_code != SPACE(8) AND @proc_flag = 1 )
BEGIN
	INSERT	apaprtrx(
			user_id,			trx_ctrl_num,	trx_type,
			amount,				approved_flag,	disappr_flag,
			display_flag,		disable_flag,	date_approved,
			date_doc,			date_assigned,	appr_user_id,
			disappr_user_id,	approval_code,	sequence_flag,
			appr_seq_id,		appr_complete,	vendor_code,
			comment,			changed_flag,	origin_flag,
			nat_cur_code,		rate_type_home,	rate_type_oper,
			rate_home, 			rate_oper,		org_id)
	SELECT	user_id,			@trx_num,		@trx_type,
			@trx_amt,			0,				0,
			1,					0,				0,
			@date_doc,			@system_date,	0,
			0,					@appr_code,		0,
			sequence_id,		0,				@vendor_code,
			" ",				0,				1,
			@nat_cur_code,		@rate_type_home,@rate_type_oper,
			@rate_home,			@rate_oper,		@org_id 
	FROM	apaprdet
	WHERE	approval_code = @appr_code
 	AND	 ((@approve_amt) BETWEEN ((amt_min) - 0.0000001) AND ((amt_max) + 0.0000001)) 

	


	SELECT	@sequence_flag = 0
	SELECT	@sequence_flag = sequence_flag
	FROM	apapr
	WHERE	approval_code = @appr_code

	



	IF ( @sequence_flag = 1 )
	BEGIN
		


		UPDATE	apaprtrx
		SET	sequence_flag = 1
		WHERE	trx_ctrl_num = @trx_num
		AND	trx_type = @trx_type
		AND	approval_code = @appr_code

		


		UPDATE	apaprtrx
		SET	display_flag = 0
		WHERE	trx_ctrl_num = @trx_num
		AND	trx_type = @trx_type
		AND	approval_code = @appr_code
		AND	appr_seq_id >
			( SELECT	MIN( appr_seq_id )
			FROM	apaprtrx
			WHERE	trx_ctrl_num = @trx_num
			AND	trx_type = @trx_type
			AND	approval_code = @appr_code )
	END
END





SET	ROWCOUNT  1
SELECT	@add_appr_code = NULL







IF (( @trx_type = @payment_type ) OR ( @trx_type = @po_type ))
	SELECT	@add_appr_code = approval_code
	FROM	apaprdfh
	WHERE	vendor_code = @vendor_code
	AND	check_flag = 1
	AND	((amt_min) <= (@approve_amt) + 0.0000001) 
	ORDER BY sequence_id
ELSE IF ( @trx_type = @voucher_type )
	SELECT	@add_appr_code = approval_code
	FROM	apaprdfh
	WHERE	(( branch_code = @branch_code AND vendor_code = @vendor_code )
	OR	( branch_code = "" AND vendor_code = @vendor_code )
	OR	( branch_code = @branch_code AND vendor_code = "" ))
	AND	vouch_flag = 1
	AND	((amt_min) <= (@approve_amt) + 0.0000001)
	ORDER BY sequence_id

SET	ROWCOUNT  0





IF ( @add_appr_code IS NOT NULL AND @add_appr_code != @appr_code
   AND @proc_flag = 1 )
BEGIN
	INSERT	apaprtrx(
			user_id,			trx_ctrl_num,	trx_type,
			amount,				approved_flag,	disappr_flag,
			display_flag,		disable_flag,	date_approved,
			date_doc,			date_assigned,	appr_user_id,
			disappr_user_id,	approval_code,	sequence_flag,
			appr_seq_id,		appr_complete,	vendor_code,
			comment,			changed_flag,	origin_flag,
			nat_cur_code,		rate_type_home,	rate_type_oper,
			rate_home, 			rate_oper,		org_id )
	SELECT	user_id,			@trx_num,		@trx_type,	
			@trx_amt,			0,				0,
			1,          		0,				0,      	
			@date_doc,			@system_date,	0,
			0,					@add_appr_code,	0,	
			sequence_id,		0,				@vendor_code,	
			" ",				0,				2,
			@nat_cur_code,		@rate_type_home,@rate_type_oper,
			@rate_home,			@rate_oper,		@org_id
	FROM	apaprdet
	WHERE	approval_code = @add_appr_code
	AND	((@approve_amt) BETWEEN ((amt_min) - 0.0000001) AND ((amt_max) + 0.0000001))
	AND user_id NOT IN											
		( SELECT user_id FROM apaprtrx WHERE
		trx_ctrl_num = @trx_num )







	
	



	SELECT	@sequence_flag = sequence_flag
	FROM	apapr
	WHERE	approval_code = @add_appr_code

	IF ( @sequence_flag = 1 )
	BEGIN
		


		UPDATE	apaprtrx
		SET	sequence_flag = 1
		WHERE	trx_ctrl_num = @trx_num
		AND	trx_type = @trx_type
		AND	approval_code = @add_appr_code

		


		UPDATE	apaprtrx
		SET	display_flag = 0
		WHERE	trx_ctrl_num = @trx_num
		AND	trx_type = @trx_type
		AND	approval_code = @add_appr_code
		AND	appr_seq_id >
			( SELECT	MIN( appr_seq_id )
			FROM	apaprtrx
			WHERE	trx_ctrl_num = @trx_num
			AND	trx_type = @trx_type
			AND	approval_code = @add_appr_code )
	END
END

IF ( @trx_type = @voucher_type AND @det_aprv_flag = 1 )
BEGIN
	


	SELECT	@sqid = 1, @last_sqid = 0

	SELECT	@last_sqid = MAX( sequence_id )
	FROM	apinpcdt
	WHERE	trx_type = @trx_type
	AND	trx_ctrl_num = @trx_num

	WHILE ( @sqid <= @last_sqid )
	BEGIN
		SELECT	@acct_code = NULL

		SELECT	@acct_code = gl_exp_acct,
	   		@line_amt = ( ( qty_received * unit_price ) -
			amt_discount + amt_freight + amt_misc + amt_tax )
		FROM	apinpcdt
		WHERE	trx_type = @trx_type
	        AND	trx_ctrl_num = @trx_num
	        AND	sequence_id = @sqid

	   	



	   	SELECT	@sqid = @sqid + 1

	   	


	   	IF ( @acct_code IS NULL )
	   		CONTINUE

	   	SET	ROWCOUNT  1
	   	SELECT	@add_appr_code = NULL

	   	



	   	SELECT	@add_appr_code = approval_code
	   	FROM	apaprdfd
	   	WHERE	@acct_code LIKE substring(exp_acct_code,1,datalength(@acct_code))
	   	AND	((amt_min) <= (@line_amt) + 0.0000001)
	   	ORDER BY sequence_id

	   	SET	ROWCOUNT  0

	   	


	   	IF ( @add_appr_code IS NULL )
	   		CONTINUE

	   	


	   	UPDATE	apinpcdt
	   	SET	approval_code = @add_appr_code
	   	WHERE	trx_type = @trx_type
	   	AND	trx_ctrl_num = @trx_num
	   	AND	sequence_id = ( @sqid - 1 )

	   	



	   	IF 	( NOT EXISTS( SELECT approval_code FROM apaprtrx
	   		WHERE	trx_ctrl_num = @trx_num
		   	AND	trx_type = @trx_type
	   		AND	approval_code = @add_appr_code ) )
	   	BEGIN
		   INSERT apaprtrx(
					user_id,			trx_ctrl_num,	trx_type,
					amount,				approved_flag,	disappr_flag,
					display_flag,		disable_flag,	date_approved,
					date_doc,			date_assigned,	appr_user_id,
					disappr_user_id,	approval_code,	sequence_flag,
					appr_seq_id,		appr_complete,	vendor_code,
					comment,			changed_flag,	origin_flag,
					nat_cur_code,		rate_type_home,	rate_type_oper,
					rate_home, 			rate_oper,		org_id )
	      	   SELECT	
					user_id,			@trx_num,		@trx_type,	
					@trx_amt,			0, 				0,
					1,          		0,				0,      		
					@date_doc,			@system_date,	0,			
					0,					@add_appr_code,	0,			
					sequence_id,		0,				@vendor_code,		
					" ",				0,				3,
					@nat_cur_code,		@rate_type_home,@rate_type_oper,
					@rate_home,			@rate_oper,		@org_id
	      	   FROM   apaprdet
	      	   WHERE  approval_code = @add_appr_code
				AND	((@approve_amt) BETWEEN ((amt_min) - 0.0000001) AND ((amt_max) + 0.0000001))
		   	   AND    user_id NOT IN							
					( SELECT user_id FROM apaprtrx WHERE		
					trx_ctrl_num = @trx_num )					









	      	   



	      	   SELECT	@sequence_flag = sequence_flag
	      	   FROM		apapr
	      	   WHERE	approval_code = @add_appr_code

	      	   IF ( @sequence_flag > 0 )
		   BEGIN
			


			UPDATE	apaprtrx
			SET	sequence_flag = 1
			WHERE	trx_ctrl_num = @trx_num
			AND	trx_type = @trx_type
			AND	approval_code = @add_appr_code

			


		      	UPDATE	apaprtrx
			SET	display_flag = 0,
				sequence_flag = @sequence_flag
			WHERE	trx_ctrl_num = @trx_num
			AND	trx_type = @trx_type
			AND	approval_code = @add_appr_code
			AND	appr_seq_id >
				( SELECT MIN( appr_seq_id )
				FROM  apaprtrx
				WHERE trx_ctrl_num = @trx_num
				AND trx_type = @trx_type
				AND approval_code = @add_appr_code )
		   END
		END
	END
END






IF ( NOT EXISTS( SELECT trx_ctrl_num FROM apaprtrx
     WHERE	trx_ctrl_num = @trx_num
     AND	trx_type = @trx_type
     AND	approved_flag = 0 ) )
	SELECT	@approve = 0
ELSE
	SELECT	@approve = 1




IF ( @trx_type = @voucher_type )
	UPDATE	apinpchg
	SET	approval_flag = @approve
	WHERE	trx_ctrl_num = @trx_num
	AND	trx_type = @trx_type
ELSE IF ( @trx_type = @payment_type )
	UPDATE	apinppyt
	SET	approval_flag = @approve
	WHERE	trx_ctrl_num = @trx_num
	AND	trx_type = @trx_type




GO
GRANT EXECUTE ON  [dbo].[apaprmk_sp] TO [public]
GO
