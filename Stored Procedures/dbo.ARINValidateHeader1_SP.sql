SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC [dbo].[ARINValidateHeader1_SP]	@error_level	smallint,
					@trx_type	smallint,
					@debug_level	smallint = 0,
                                        @rec_inv	smallint
AS

DECLARE	
	@result	smallint,
	@e_level_1	smallint,
	@e_level_2	smallint,
	@e_level_3	smallint

DECLARE @ib_flag		INTEGER			--AAP

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 64, 5 ) + ' -- ENTRY: '

	








	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20000 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 80, 5 ) + ' -- MSG: ' + 'Validate the user_id is valid'
		
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	ewusers_vw ew
		WHERE	#arvalchg.user_id = ew.user_id
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20000,
			'',
			'',
			user_id,
			0.0,
			5,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ''),
			0
		FROM	#arvalchg
	  	WHERE	temp_flag = 0 
		
	END


	IF @trx_type = 2031
	BEGIN
		


		IF ( ( SELECT e_level FROM aredterr WHERE e_code = 20001 ) >= @error_level )
                   AND @rec_inv = 0
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 119, 5 ) + ' -- MSG: ' + 'Validate that the transaction has been printed'
			
			


			INSERT	#ewerror
			SELECT 2000,
			  	20001,
				doc_ctrl_num,
				'',
				0,
				0.0,
				0,
				trx_ctrl_num,
				0,
				ISNULL(source_trx_ctrl_num, ''),
				0
			FROM 	#arvalchg
		  	WHERE 	printed_flag = 0 
		END

	END


	
	SELECT 	@ib_flag = 0
	SELECT 	@ib_flag = ib_flag
	FROM 	glco

	
	UPDATE  #arvalchg
	SET     interbranch_flag = 1
	FROM 	#arvalchg a, #arvalcdt b 
	WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
	AND   	a.org_id <> b.org_id


if(@ib_flag > 0)
BEGIN
	



	IF ( SELECT e_level FROM aredterr WHERE e_code = 20098 ) >= @error_level
	BEGIN
		UPDATE 	#arvalcdt
	        SET 	temp_flag2 = 0

		UPDATE 	#arvalcdt
	        SET 	temp_flag2 = 1
		FROM 	#arvalchg a, #arvalcdt b, OrganizationOrganizationRel ood
		WHERE 	a.org_id = ood.controlling_org_id			
		AND 	b.org_id = ood.detail_org_id
		AND     a.trx_ctrl_num = b.trx_ctrl_num

		INSERT INTO #ewerror
		(   	module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20098,			a.org_id +'-'+ b.org_id,
			b.org_id, 		user_id, 		0.0,
			1, 			a.trx_ctrl_num, 	0,
			b.trx_ctrl_num, 			0
		FROM 	#arvalchg a,  #arvalcdt b
		WHERE 	a.interbranch_flag = 1
		AND 	b.temp_flag2 = 0
		AND     a.trx_ctrl_num = b.trx_ctrl_num
		AND   	a.org_id <> b.org_id
	END

	



	IF ( SELECT e_level FROM aredterr WHERE e_code = 20100 ) >= @error_level
	BEGIN
		UPDATE 	#arvalchg
	        SET 	temp_flag2 = 0

		UPDATE 	#arvalchg
		SET 	temp_flag2 = 1
		FROM 	#arvalchg a, Organization o
		WHERE 	a.org_id = o.organization_id
		AND 	o.active_flag = 1

		INSERT INTO #ewerror
		(       module_id,      err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,extra
		)
		SELECT 2000, 20100, org_id,
			org_id, user_id, 0.0,
			1, trx_ctrl_num, 0, 					
			trx_ctrl_num, 0
		FROM 	#arvalchg
		WHERE 	temp_flag2 = 0
	END

	IF @trx_type = 2021
	BEGIN
	
		
		UPDATE  #arvalchg
		SET     interbranch_flag = 1
		FROM 	#arvalchg a, #arvalrev b 
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND   	a.org_id <> b.org_id
	
	
		


	
		IF ( SELECT e_level FROM aredterr WHERE e_code = 20098 ) >= @error_level
		BEGIN
			UPDATE 	#arvalrev
		        SET 	temp_flag = 0
	
			UPDATE 	#arvalrev
		        SET 	temp_flag = 1
			FROM 	#arvalchg a, #arvalrev b, OrganizationOrganizationRel ood
			WHERE 	a.org_id = ood.controlling_org_id			
			AND 	b.org_id = ood.detail_org_id
			AND     a.trx_ctrl_num = b.trx_ctrl_num
	
			INSERT INTO #ewerror
			(   	module_id,      	err_code,       	info1,
				info2,          	infoint,        	infofloat,
				flag1,          	trx_ctrl_num,   	sequence_id,
				source_ctrl_num,	extra
			)
			SELECT 	2000, 20098,			a.org_id +'-'+ b.org_id,
				b.org_id, 		user_id, 		0.0,
				0, 			a.trx_ctrl_num, 	0,
				b.trx_ctrl_num, 			0
			FROM 	#arvalchg a,  #arvalrev b
			WHERE 	a.interbranch_flag = 1
			AND 	b.temp_flag = 0
			AND     a.trx_ctrl_num = b.trx_ctrl_num
			AND   	a.org_id <> b.org_id
		END
	END

END 	--AAP

	





	IF ( SELECT e_level FROM aredterr WHERE e_code = 20002 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 275, 5 ) + ' -- MSG: ' + 'Validate that the Doc Num exists as an unposted invoice'
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20002,
			a.doc_ctrl_num,
			'',
			0,
			0.0,
			0,
			a.trx_ctrl_num,
			0,
			ISNULL(a.source_trx_ctrl_num, ''),
			0
		FROM   #arvalchg a, arinpchg b
	  	WHERE  a.doc_ctrl_num = b.doc_ctrl_num 
		AND	a.trx_ctrl_num != b.trx_ctrl_num
		AND	( LTRIM(a.doc_ctrl_num) IS NOT NULL AND LTRIM(a.doc_ctrl_num) != ' ' )

	END

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20003 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 304, 5 ) + ' -- MSG: ' + 'Validate that the Doc Num exists as a posted invoice'
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20003,
			a.doc_ctrl_num,
			'',
			0,
			0.0,
			0,
			a.trx_ctrl_num,
			0,
			ISNULL(a.source_trx_ctrl_num, ''),
			0
		FROM   #arvalchg a, artrx b
	  	WHERE  a.doc_ctrl_num = b.doc_ctrl_num
		AND	a.trx_type = b.trx_type
	END
	
	



	IF ( SELECT e_level FROM aredterr WHERE e_code = 20109 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 332, 5 ) + ' -- MSG: ' + 'Validate that the Currency is valid for tax connect'
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20109,
			a.doc_ctrl_num,
			'',
			0,
			0.0,
			0,
			a.trx_ctrl_num,
			0,
			ISNULL(a.source_trx_ctrl_num, ''),
			0
		FROM   #arvalchg a, artax t
	  	WHERE  a.tax_code = t.tax_code
		AND	t.tax_connect_flag = 1 AND NOT EXISTS(SELECT currency_code from gltc_currency 
													where gltc_currency.currency_code = a.nat_cur_code)
	END

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20004 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 360, 5 ) + ' -- MSG: ' + 'Validate that the master invoice exists artrx'
		
		





		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		



		UPDATE	#arvalchg
		SET	temp_flag = 1
		WHERE	( LTRIM(#arvalchg.apply_to_num) IS NULL OR LTRIM(#arvalchg.apply_to_num) = ' ' )
		
		


		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	#arvalchg, artrx
		WHERE	#arvalchg.apply_to_num = artrx.doc_ctrl_num
		AND	#arvalchg.apply_trx_type = artrx.trx_type
		AND	#arvalchg.temp_flag = 0

		


		INSERT	#ewerror
		SELECT 2000,
		  	20004,
			apply_to_num,
			'',
			0,
			0.0,
			0,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ''),
			0
		FROM   #arvalchg 
	  	WHERE  temp_flag = 0
	END

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20005 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 413, 5 ) + ' -- MSG: ' + 'Validate the transaction has a valid batch code'
		
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE #arvalchg
		SET	temp_flag = 1
		WHERE	( LTRIM(batch_code) IS NULL OR LTRIM(batch_code) = ' ' )
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	batchctl a
		WHERE	#arvalchg.batch_code = a.batch_ctrl_num
		AND	#arvalchg.temp_flag = 0
		
		
		INSERT	#ewerror
		SELECT 2000,
		  	20005,
			batch_code,
			'',
			0,
			0.0,
			0,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ''),
			0
		FROM #arvalchg
	  	WHERE temp_flag = 0 
		
	END


	SELECT	@e_level_1 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20006
	SELECT	@e_level_2 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20007	
	SELECT	@e_level_3 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20008

	IF (@e_level_1 + @e_level_2 + @e_level_3 ) > 0 
	BEGIN

		CREATE TABLE #cust_info
			( customer_code 	varchar(8),
			  nat_cur_code	varchar(8) NULL,
			  status_type		smallint NULL,
			  one_cur_cust	smallint NULL,
			  flag			smallint )
	
		INSERT INTO #cust_info (customer_code, flag)
		SELECT	distinct customer_code, 0
		FROM	#arvalchg 
			  	
		UPDATE	#cust_info
		SET	nat_cur_code = c.nat_cur_code,
			status_type = c.status_type,
			one_cur_cust = c.one_cur_cust,
			flag = 1
		FROM	arcust c
		WHERE	#cust_info.customer_code = c.customer_code
	
	END
		
	


	IF @e_level_1 = 1 
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 480, 5 ) + ' -- MSG: ' + 'Validate the customer_code exists in the customer table'
		
		INSERT	#ewerror
		SELECT 2000,
		  	20006,
			a.customer_code,
			'',
			0,
			0.0,
			0,
			a.trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ''),
			0
		FROM	#arvalchg a, #cust_info c
	  	WHERE 	a.customer_code = c.customer_code
		AND	c.flag = 0
	END

	


	IF @e_level_2 = 1 
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 504, 5 ) + ' -- MSG: ' + 'Validate the customer is active'
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20007,
			a.customer_code,
			'',
			0,
			0.0,
			0,
			a.trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ''),
			0
		FROM	#arvalchg a, #cust_info c
	  	WHERE	a.customer_code = c.customer_code
		AND	c.status_type >= 2
	END

	



	IF @e_level_3 = 1 
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 532, 5 ) + ' -- MSG: ' + 'Validate the invoice currency is valid for this cust code'
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20008,
			a.customer_code + '--' + a.nat_cur_code,
			'',
			0,
			0.0,
			0,
			a.trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ''),
			0
		FROM	#arvalchg a, #cust_info c
	  	WHERE	a.customer_code = c.customer_code
		AND	c.one_cur_cust = 1
		AND	a.nat_cur_code != c.nat_cur_code
	END

	
	IF (@e_level_1 + @e_level_2 + @e_level_3 ) > 0 
		DROP TABLE #cust_info
	
	
	SELECT	@e_level_1 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20009
	SELECT	@e_level_2 = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20010	

	IF (@e_level_1 + @e_level_2 ) > 0 
	BEGIN

		CREATE TABLE #ship_info
			( customer_code 	varchar(8),
			  ship_to_code	varchar(8) ,
			  nat_cur_code	varchar(8) NULL,
			  one_cur_cust	smallint NULL,
			  flag			smallint )
	
		INSERT INTO #ship_info (customer_code, ship_to_code,flag)
		SELECT	distinct customer_code, ship_to_code, 0
		FROM	#arvalchg 
		WHERE	( LTRIM(ship_to_code) IS NOT NULL AND LTRIM(ship_to_code) != ' ' )
			  	
		UPDATE	#ship_info
		SET	nat_cur_code = c.nat_cur_code,
			one_cur_cust = c.one_cur_cust,
			flag = 1
		FROM	armaster c
		WHERE	#ship_info.customer_code = c.customer_code
		AND	#ship_info.ship_to_code = c.ship_to_code
		AND	c.address_type = 1
	
	END
		
	


	IF @e_level_1 = 1
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 594, 5 ) + ' -- MSG: ' + 'Validate the ship_to_code exists for this customer '
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20009,
			a.ship_to_code,
			'',
			0,
			0.0,
			0,
			a.trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ''),
			0
		FROM 	#arvalchg a, #ship_info b
	  	WHERE 	a.customer_code = b.customer_code
	  	AND	a.ship_to_code = b.ship_to_code
	  	AND	flag = 0 
	END
	

	


	IF @e_level_2 = 1
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 623, 5 ) + ' -- MSG: ' + 'Validate the ship_to_code is valid for the currency of the invoice '
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20010,
			a.ship_to_code,
			'',
			0,
			0.0,
			0,
			a.trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ''),
			0
		FROM #arvalchg a, #ship_info b
	  	WHERE a.customer_code = b.customer_code 
		AND	a.ship_to_code = b.ship_to_code
		AND	b.one_cur_cust = 1
		AND	a.nat_cur_code != b.nat_cur_code
		
	END

	IF (@e_level_1 + @e_level_2 ) > 0 
		DROP TABLE #ship_info
	

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20011 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 657, 5 ) + ' -- MSG: ' + 'Validate the salesperson exists in salesperson table '
		
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	#arvalchg a, arsalesp b
		WHERE	a.salesperson_code = b.salesperson_code
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20011,
			salesperson_code,
			'',
			0,
			0.0,
			0,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ''),
			0
		FROM	#arvalchg
	  	WHERE	temp_flag = 0 
		AND	( LTRIM(salesperson_code) IS NOT NULL AND LTRIM(salesperson_code) != ' ' )
	END
	

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20012 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 693, 5 ) + ' -- MSG: ' + 'Validate the status for salesperson is active'
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20012,
			a.salesperson_code,
			'',
			0,
			0.0,
			0,
			a.trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ''),
			0
		FROM	#arvalchg a, arsalesp b
	  	WHERE	a.salesperson_code = b.salesperson_code
		AND	b.status_type >= 2
		
	END		

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20013 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 721, 5 ) + ' -- MSG: ' + 'Validate the territory code exists in the territory table '
		
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	#arvalchg a, arterr b
		WHERE	a.territory_code = b.territory_code
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20013,
			territory_code,
			'',
			0,
			0.0,
			0,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ''),
			0
		FROM	#arvalchg
	  	WHERE	temp_flag = 0 
		AND	( LTRIM(territory_code) IS NOT NULL AND LTRIM(territory_code) != ' ' )
	END

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20014 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 756, 5 ) + ' -- MSG: ' + 'Validate the price code exists in the price class table '
		
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	#arvalchg a, arprice b
		WHERE	a.price_code = b.price_code
		
		


		INSERT	#ewerror
		SELECT 2000,
		  	20014,
			price_code,
			'',
			0,
			0.0,
			0,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ''),
			0
		FROM	#arvalchg
	  	WHERE	temp_flag = 0 
		AND	( LTRIM(price_code) IS NOT NULL AND LTRIM(price_code) != ' ' )
	END
		
	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arinvh1.cpp' + ', line ' + STR( 787, 5 ) + ' -- EXIT: '
END
GO
GRANT EXECUTE ON  [dbo].[ARINValidateHeader1_SP] TO [public]
GO
