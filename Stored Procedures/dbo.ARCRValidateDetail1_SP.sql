SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[ARCRValidateDetail1_SP]	@error_level 	smallint, 
					@called_from	smallint,
					@debug_level 	smallint = 0
AS

DECLARE	
	@result	smallint,
	@e_level	smallint,
	@e_level_1	smallint,
	@e_level_2	smallint,
	@ib_flag	int


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrvd1.cpp" + ", line " + STR( 40, 5 ) + " -- ENTRY: "

	























	



	
	SELECT 	@ib_flag = 0
	SELECT 	@ib_flag = ib_flag
	FROM 	glco

if(@ib_flag > 0)
BEGIN
	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20434 ) >= @error_level
	BEGIN

		/*UPDATE 	#arvalpdt
	        SET 	temp_flag2 = 0

		UPDATE 	#arvalpdt
		SET 	temp_flag2 = 1
		FROM 	#arvalpdt a, Organization o
		WHERE 	a.org_id = o.organization_id
		AND 	o.active_flag = 1

		INSERT INTO #ewerror
		(       module_id,      err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,extra
		)
		SELECT 2000, 20434, b.org_id,
			b.org_id, "", 0.0,
			1, b.trx_ctrl_num, b.sequence_id,
			b.trx_ctrl_num, 0
		FROM 	#arvalpyt a, #arvalpdt b
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND	b.sequence_id > -1
		AND 	b.temp_flag2 = 0*/

		INSERT INTO #ewerror
		(       module_id,      err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,extra
		)
		SELECT 2000, 20434, b.org_id,
			b.org_id, "", 0.0,
			1, b.trx_ctrl_num, b.sequence_id,
			b.trx_ctrl_num, 0
		FROM 	#arvalpyt a, #arvalpdt b
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND	b.sequence_id > -1
		AND     NOT EXISTS ( select 1 from  Organization o  where b.org_id = o.organization_id AND o.active_flag = 1 )



		
	END

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20434 ) >= @error_level
	BEGIN

		/*UPDATE 	#arvalnonardet
	        SET 	temp_flag2 = 0

		UPDATE 	#arvalnonardet
		SET 	temp_flag2 = 1
		FROM 	#arvalnonardet a, Organization o
		WHERE 	a.org_id = o.organization_id
		AND 	o.active_flag = 1

		INSERT INTO #ewerror
		(       module_id,      err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,extra
		)
		SELECT 2000, 20434, b.org_id,
			b.org_id, "", 0.0,
			1, b.trx_ctrl_num, b.sequence_id,
			b.trx_ctrl_num, 0
		FROM 	#arvalpyt a, #arvalnonardet b
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND	b.sequence_id > -1
		AND 	b.temp_flag2 = 0*/
	
		
		INSERT INTO #ewerror
		(       module_id,      err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,extra
		)
		SELECT 2000, 20434, b.org_id,
			b.org_id, "", 0.0,
			1, b.trx_ctrl_num, b.sequence_id,
			b.trx_ctrl_num, 0
		FROM 	#arvalpyt a, #arvalnonardet b
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND	b.sequence_id > -1
		AND     NOT EXISTS ( select 1 from  Organization o  where b.org_id = o.organization_id AND o.active_flag = 1 ) 
	END

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20433 ) >= @error_level
	BEGIN
		UPDATE 	#arvalnonardet
	        SET 	temp_flag2 = 0

		UPDATE 	#arvalnonardet
		SET 	temp_flag2 = 1
		FROM 	#arvalpyt a, #arvalnonardet b, OrganizationOrganizationDef ood
		WHERE 	b.trx_ctrl_num = a.trx_ctrl_num
		AND	a.org_id = ood.controlling_org_id
		AND 	b.org_id = ood.detail_org_id
		AND 	b.gl_acct_code LIKE ood.account_mask			

		INSERT INTO #ewerror
		(   module_id,      	err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 2000, 20433, b.gl_acct_code,
			b.org_id, user_id, 0.0,
			1, b.trx_ctrl_num, b.sequence_id,
			b.trx_ctrl_num, 0
		FROM 	#arvalnonardet b, #arvalpyt a
		WHERE 	b.trx_ctrl_num = a.trx_ctrl_num
		AND	b.sequence_id > -1
		AND 	a.interbranch_flag = 1
		AND 	b.temp_flag2 = 0
		AND 	a.org_id <> b.org_id
	END

	



	IF (SELECT e_level FROM aredterr WHERE e_code = 20435) >= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmvli.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate account code for organization \arcmvli"

		


		/*UPDATE 	#arvalnonardet
	        SET 	temp_flag = 0

		



		UPDATE 	#arvalnonardet
	        SET 	temp_flag = 1
		FROM 	#arvalnonardet a
		WHERE   dbo.IBOrgbyAcct_fn(a.gl_acct_code)  = a.org_id 
		
		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20435, 		a.gl_acct_code,
			a.org_id, 		0, 			0.0,
			1, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#arvalnonardet a
		WHERE 	a.temp_flag = 0*/

				
		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20435, 		a.gl_acct_code,
			a.org_id, 		0, 			0.0,
			1, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#arvalnonardet a
		WHERE 	 dbo.IBOrgbyAcct_fn(a.gl_acct_code)  != a.org_id 

	END	-- AAP
END



ELSE
BEGIN
	


	IF (SELECT e_level FROM aredterr WHERE e_code = 20436) >= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmvli.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate all organizations are the same \arcmvli"
		


		/*UPDATE 	#arvalnonardet
	        SET 	temp_flag = 0

		



		UPDATE 	#arvalnonardet
	        SET 	temp_flag = 1
		FROM 	#arvalnonardet a, #arvalpyt b
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND 	a.org_id = b.org_id

		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20436, 		b.org_id +'-'+ a.org_id,
			a.org_id, 		0, 			0.0,
			1, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#arvalnonardet a, #arvalpyt b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.temp_flag = 0*/

		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20436, 		b.org_id +'-'+ a.org_id,
			a.org_id, 		0, 			0.0,
			1, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#arvalnonardet a, #arvalpyt b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.org_id != b.org_id

		
	END	

	


	IF (SELECT e_level FROM aredterr WHERE e_code = 20436) >= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrvd1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate all organizations are the same \arcrvd1"
		


		/*UPDATE 	#arvalpdt
	        SET 	temp_flag = 0

		



		UPDATE 	#arvalpdt
	        SET 	temp_flag = 1
		FROM 	#arvalpdt a, #arvalpyt b
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND 	a.org_id = b.org_id

		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20436, 		b.org_id +'-'+ a.org_id,
			a.org_id, 		0, 			0.0,
			1, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#arvalpdt a, #arvalpyt b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.temp_flag = 0*/
		
		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20436, 		b.org_id +'-'+ a.org_id,
			a.org_id, 		0, 			0.0,
			1, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#arvalpdt a, #arvalpyt b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.org_id != b.org_id
	END	
END	--AAP
	


	IF (SELECT e_level FROM aredterr WHERE e_code = 20403) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrvd1.cpp" + ", line " + STR( 319, 5 ) + " -- MSG: " + "Validate the payment distribution"

		SELECT trx_ctrl_num, trx_type, ISNULL(SUM(amt_applied), 0.0) amt_applied
		INTO	#applied_pyt
		FROM	#arvalpdt
		GROUP BY trx_ctrl_num, trx_type
		

		IF ( EXISTS(SELECT 1 from arco with (nolock) where chargeback_flag = 1 ))
		
			/* Begin mod: CB0001 - Add total chargebacks to balance the receipt */
		
			/* Add total_chargebacks to balance the receipt */
			INSERT #ewerror
			SELECT	2000,
				20403,
				"",
				"",
				0,
				val.amt_payment,
				1,
				val.trx_ctrl_num,
				0,
				"",
				0
			FROM	#arvalpyt val, #applied_pyt pyt, glcurr_vw gl, arcbtot cb
			WHERE	val.non_ar_flag = 0
			AND	val.nat_cur_code = gl.currency_code
			AND	val.trx_ctrl_num = pyt.trx_ctrl_num
			AND	val.trx_type = pyt.trx_type
			AND	cb.trx_ctrl_num = pyt.trx_ctrl_num
			AND	ABS(
			(SIGN((pyt.amt_applied + val.amt_on_acct - isnull(cb.total_chargebacks,0) - val.amt_payment)) * ROUND(ABS((pyt.amt_applied + val.amt_on_acct - isnull(cb.total_chargebacks,0) - val.amt_payment)) + 0.0000001, gl.curr_precision))) > gl.rounding_factor

			/* End mod: CB0001 */
		ELSE
			/* Begin mod: CB0001 - Original code 		*/
			INSERT #ewerror
			SELECT	2000,
				20403,
				"",
				"",
				0,
				val.amt_payment,
				1,
				val.trx_ctrl_num,
				0,
				"",
				0
			FROM	#arvalpyt val, #applied_pyt pyt, glcurr_vw gl
			WHERE	val.non_ar_flag = 0
			AND	val.nat_cur_code = gl.currency_code
			AND	val.trx_ctrl_num = pyt.trx_ctrl_num
			AND	val.trx_type = pyt.trx_type
			AND	ABS(
				(SIGN((pyt.amt_applied + val.amt_on_acct - val.amt_payment)) * ROUND(ABS((pyt.amt_applied + val.amt_on_acct - val.amt_payment)) + 0.0000001, gl.curr_precision))) > gl.rounding_factor
			/* End mod: CB0001 */
		

		DROP TABLE #applied_pyt		
	END
	
	





	IF ( @called_from = 2021 OR @called_from = 2031 )
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrvd1.cpp" + ", line " + STR( 357, 5 ) + " -- MSG: " + "Source transaction! Skip remaining validations!"
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrvd1.cpp" + ", line " + STR( 358, 5 ) + " -- EXIT: "
		RETURN 0
	END

	


	IF (SELECT e_level FROM aredterr WHERE e_code = 20414) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrvd1.cpp" + ", line " + STR( 367, 5 ) + " -- MSG: " + "Validate document being paid exists"
	
		/*UPDATE	#arvalpdt
		SET	temp_flag = 0
		
		UPDATE	#arvalpdt
		SET	temp_flag = 1
		WHERE	apply_to_num = 'BAL-FORWARD'
			
      		UPDATE	#arvalpdt
      		SET	temp_flag = 1
      		FROM	artrx trx
      		WHERE	#arvalpdt.apply_to_num = trx.doc_ctrl_num
      		AND	#arvalpdt.apply_trx_type = trx.trx_type
		AND	temp_flag = 0
			
      		INSERT #ewerror
      		SELECT	2000,
      			20414,
      			apply_to_num,
      			"",
      			0,
      			0.0,
      			0,
      			trx_ctrl_num,
      			0,
      			"",
      			0
      		FROM	#arvalpdt 
      		WHERE	temp_flag = 0*/
		INSERT #ewerror
      		SELECT	2000,
      			20414,
      			apply_to_num,
      			"",
      			0,
      			0.0,
      			0,
      			trx_ctrl_num,
      			0,
      			"",
      			0
      		FROM	#arvalpdt #arvalpdt
		WHERE   #arvalpdt.apply_to_num != 'BAL-FORWARD'
		AND  NOT EXISTS ( select 1 from  artrx trx where #arvalpdt.apply_to_num = trx.doc_ctrl_num 
		AND	#arvalpdt.apply_trx_type = trx.trx_type )

	END

	SELECT	@e_level_1 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20415
	SELECT	@e_level_2 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20416

	IF (@e_level_1 + @e_level_2) > 0 
	BEGIN
		CREATE TABLE #payments
			(	apply_to_num	varchar(16),
				apply_trx_type smallint,
				amount		float,
				wr_off_flag	smallint
			)
	
		INSERT	#payments
		SELECT apply_to_num, 
			apply_trx_type, 
			SUM(inv_amt_applied + inv_amt_disc_taken + inv_amt_max_wr_off),
			SUM(wr_off_flag)
		FROM	#arvalpdt
		GROUP BY apply_to_num, apply_trx_type
		
		UPDATE	#payments
		SET	amount = trx.amt_tot_chg - trx.amt_paid_to_date - #payments.amount
		FROM	artrx trx
		WHERE	#payments.apply_to_num = trx.doc_ctrl_num
		AND	#payments.apply_trx_type = trx.trx_type
	END

	


	IF @e_level_1 = 1
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrvd1.cpp" + ", line " + STR( 431, 5 ) + " -- MSG: " + "Validate that the invoice paid is not overpaid and written off "

		INSERT #ewerror
		SELECT	2000,
			20415,
			pdt.apply_to_num,
			"",
			0,
			0.0,
			0,
			pdt.trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalpdt pdt, #payments pyt, glcurr_vw gl
		WHERE	pdt.apply_to_num = pyt.apply_to_num
		AND	pdt.apply_trx_type = pyt.apply_trx_type
		AND	pdt.inv_cur_code = gl.currency_code
		AND	(((SIGN(pyt.amount) * ROUND(ABS(pyt.amount) + 0.0000001, gl.curr_precision))) < (0.0) - 0.0000001) 
		AND	((ABS((SIGN(pyt.amount) * ROUND(ABS(pyt.amount) + 0.0000001, gl.curr_precision)))) > (gl.rounding_factor) + 0.0000001)
		AND	pyt.wr_off_flag > 0


	END

	


	IF @e_level_2 = 1
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrvd1.cpp" + ", line " + STR( 461, 5 ) + " -- MSG: " + "Validate that the invoice paid is not overpaid "

		INSERT #ewerror
		SELECT	2000,
			20416,
			pdt.apply_to_num,
			"",
			0,
			0.0,
			0,
			pdt.trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalpdt pdt, #payments pyt, glcurr_vw gl
		WHERE	pdt.apply_to_num = pyt.apply_to_num
		AND	pdt.apply_trx_type = pyt.apply_trx_type
		AND	pdt.inv_cur_code = gl.currency_code
		AND	(((SIGN(pyt.amount) * ROUND(ABS(pyt.amount) + 0.0000001, gl.curr_precision))) < (0.0) - 0.0000001) 
		AND	((ABS((SIGN(pyt.amount) * ROUND(ABS(pyt.amount) + 0.0000001, gl.curr_precision)))) > (gl.rounding_factor) + 0.0000001)


	END

	IF (@e_level_1 + @e_level_2) > 0 
	BEGIN
		DROP TABLE #payments
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcrvd1.cpp" + ", line " + STR( 490, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCRValidateDetail1_SP] TO [public]
GO
