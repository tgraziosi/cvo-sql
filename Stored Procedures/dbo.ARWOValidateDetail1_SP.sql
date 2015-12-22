SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[ARWOValidateDetail1_SP]	@error_level smallint, 
						@debug_level smallint = 0
AS

DECLARE	
	@result	smallint,
	@e_level	smallint,
	@e_level_1	smallint,
	@e_level_2	smallint,
	@e_level_3	smallint,
	@e_level_4	smallint,
        @ib_flag	integer        

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwovd1.cpp" + ", line " + STR( 42, 5 ) + " -- ENTRY: "

	























	
	


	IF (SELECT e_level FROM aredterr WHERE e_code = 20701) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwovd1.cpp" + ", line " + STR( 74, 5 ) + " -- MSG: " + "Validate customer code exists"

		UPDATE	#arvalpdt
		SET	temp_flag = 0
		
		UPDATE	#arvalpdt
		SET	temp_flag = 1
		FROM	arcust
		WHERE	#arvalpdt.customer_code = arcust.customer_code
		

		INSERT #ewerror
		SELECT	2000,
			20701,
			customer_code,
			"",
			0,
			0.0,
			0,
			trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalpdt 
		WHERE	temp_flag = 0
	END

        

        SELECT 	@ib_flag = 0
        SELECT 	@ib_flag = ib_flag
        FROM 	glco

        IF (@ib_flag > 0)
        BEGIN
	        

































        
        	


        	IF ( SELECT e_level FROM aredterr WHERE e_code = 20711 ) >= @error_level
        	BEGIN
        
              	        IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwovd1.cpp" + ", line " + STR( 150, 5 ) + " -- MSG: " + "Validate if organization exists and is active in Detail"        
        
        		UPDATE 	#arvalpdt
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
        		SELECT 2000,        20711,      b.org_id,
        			"",         "",         0.0,
        			1,         b.trx_ctrl_num, b.sequence_id,
        			b.trx_ctrl_num, 0
        		FROM 	#arvalpyt a, #arvalpdt b
        		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
        		        AND 	b.temp_flag2 = 0
	        END
        END


	








	SELECT	@e_level_1 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20702
	SELECT	@e_level_2 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20703
	SELECT	@e_level_3 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20707
	SELECT	@e_level_4 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20706

	IF (@e_level_1 + @e_level_2 + @e_level_3 + @e_level_4 ) > 0 
	BEGIN
		CREATE TABLE #invoices
		(
			doc_ctrl_num	varchar(16),
			trx_type	smallint,
			flag		smallint,
			posting_code	varchar(8) NULL,
			amount_due	float NULL,
			currency_code	varchar(8) NULL	
		)

		INSERT	#invoices (doc_ctrl_num, trx_type, flag) 
		SELECT	DISTINCT	apply_to_num, apply_trx_type, 0
		FROM	#arvalpdt

		UPDATE	#invoices
		SET	posting_code = trx.posting_code,
			amount_due = trx.amt_tot_chg - trx.amt_paid_to_date,
			currency_code = trx.nat_cur_code,
			flag = 1
		FROM	artrx trx
		WHERE	#invoices.doc_ctrl_num = trx.doc_ctrl_num
		AND	#invoices.trx_type = trx.trx_type
		AND	trx.void_flag = 0
	END
	
	


	IF @e_level_1 = 1
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwovd1.cpp" + ", line " + STR( 225, 5 ) + " -- MSG: " + "Validate the invoice being written off exists in the posted table"

		INSERT #ewerror
		SELECT	2000,
			20702,
			inv.doc_ctrl_num,
			"",
			0,
			0.0,
			0,
			pdt.trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalpdt pdt, #invoices inv
		WHERE	pdt.apply_to_num = inv.doc_ctrl_num
		AND	pdt.apply_trx_type = inv.trx_type
		AND	inv.flag = 0
	END

	


	IF @e_level_2 = 1
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwovd1.cpp" + ", line " + STR( 250, 5 ) + " -- MSG: " + "Validate the posting code of the invoice being written off exists"

		UPDATE	#arvalpdt
		SET	temp_flag = 0
		
		UPDATE	#arvalpdt
		SET	temp_flag = 1
		FROM	#invoices inv
		WHERE	#arvalpdt.apply_to_num = inv.doc_ctrl_num
		AND	#arvalpdt.apply_trx_type = inv.trx_type
		AND	inv.flag = 0

		UPDATE	#arvalpdt
		SET	temp_flag = 1
		FROM	#invoices inv, araccts ac
		WHERE	#arvalpdt.apply_to_num = inv.doc_ctrl_num
		AND	#arvalpdt.apply_trx_type = inv.trx_type
		AND	inv.posting_code = ac.posting_code
		AND	inv.flag = 1

		INSERT #ewerror
		SELECT	2000,
			20703,
			inv.posting_code,
			"",
			0,
			0.0,
			0,
			pdt.trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalpdt pdt, #invoices inv
		WHERE	pdt.apply_to_num = inv.doc_ctrl_num
		AND	pdt.apply_trx_type = inv.trx_type
		AND	pdt.temp_flag = 0
	END

	


	IF @e_level_3 = 1
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwovd1.cpp" + ", line " + STR( 293, 5 ) + " -- MSG: " + "Validate the currency code of the invoice being written off exists"

		UPDATE	#arvalpdt
		SET	temp_flag = 0
		
		UPDATE	#arvalpdt
		SET	temp_flag = 1
		FROM	#invoices inv
		WHERE	#arvalpdt.apply_to_num = inv.doc_ctrl_num
		AND	#arvalpdt.apply_trx_type = inv.trx_type
		AND	inv.flag = 0

		UPDATE	#arvalpdt
		SET	temp_flag = 1
		FROM	#invoices inv, glcurr_vw gl
		WHERE	#arvalpdt.apply_to_num = inv.doc_ctrl_num
		AND	#arvalpdt.apply_trx_type = inv.trx_type
		AND	inv.currency_code = gl.currency_code
		AND	inv.flag = 1

		INSERT #ewerror
		SELECT	2000,
			20707,
			inv.currency_code,
			"",
			0,
			0.0,
			0,
			pdt.trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalpdt pdt, #invoices inv
		WHERE	pdt.apply_to_num = inv.doc_ctrl_num
		AND	pdt.apply_trx_type = inv.trx_type
		AND	pdt.temp_flag = 0
	END

	


	IF @e_level_4 = 1
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwovd1.cpp" + ", line " + STR( 336, 5 ) + " -- MSG: " + "Validate the invoice has a positive amount due to write off"

		UPDATE	#arvalpdt
		SET	temp_flag = 0
		
		UPDATE	#arvalpdt
		SET	temp_flag = 1
		FROM	#invoices inv
		WHERE	#arvalpdt.apply_to_num = inv.doc_ctrl_num
		AND	#arvalpdt.apply_trx_type = inv.trx_type
		AND	inv.flag = 0

		UPDATE	#arvalpdt
		SET	temp_flag = 1
		FROM	#invoices inv, glcurr_vw gl
		WHERE	#arvalpdt.apply_to_num = inv.doc_ctrl_num
		AND	#arvalpdt.apply_trx_type = inv.trx_type
		AND	inv.currency_code = gl.currency_code
		AND	(SIGN(inv.amount_due) * ROUND(ABS(inv.amount_due) + 0.0000001, gl.curr_precision)) >= gl.rounding_factor
		AND	inv.flag = 1



		INSERT #ewerror
		SELECT	2000,
			20706,
			inv.doc_ctrl_num,
			"",
			0,
			0.0,
			0,
			pdt.trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalpdt pdt, #invoices inv
		WHERE	pdt.apply_to_num = inv.doc_ctrl_num
		AND	pdt.apply_trx_type = inv.trx_type
		AND	pdt.temp_flag = 0
		
		AND	inv.doc_ctrl_num not in (select a.apply_to_num 
					from 	arinppdt a, arwrofac b 
					where 	a.writeoff_code = b.writeoff_code 
					and 	b.writeoff_negative_amount = 1)
					
	
	


	END

	IF (@e_level_1 + @e_level_2 + @e_level_3 + @e_level_4 ) > 0 
	BEGIN
		DROP TABLE #invoices
	END


	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwovd1.cpp" + ", line " + STR( 394, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARWOValidateDetail1_SP] TO [public]
GO
