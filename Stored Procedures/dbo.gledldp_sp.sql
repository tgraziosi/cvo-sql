SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[gledldp_sp]
			@process_mode smallint,
			@batch_code   varchar(16),
			@debug_level smallint = 0
AS

DECLARE @result						int,		
		@rnd						float,
		@prc						float,
		@error_level				int,
		@error_code					int,
		@nat_cur_code				varchar(8),
		@old_nat_cur_code			varchar(8),
		@ib_flag				int
	
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "gledldP.cpp" + ", line " + STR( 81, 5 ) + " -- ENTRY: "





INSERT INTO #gltrxedt1 ( 
			journal_ctrl_num, 
			sequence_id, 
			journal_description, 
			journal_type,
			date_entered, 
			date_applied, 
			batch_code, 
			hold_flag, 
			home_cur_code, 
			intercompany_flag, 
			company_code, 
			source_batch_code, 
			type_flag, 
			user_id, 
			source_company_code, 
			account_code, 
			account_description, 
			rec_company_code, 
			nat_cur_code, 
			document_1, 
			description, 
			reference_code, 
			balance, 
			nat_balance, 
			trx_type, 
			offset_flag,
			seq_ref_id, 
			temp_flag, 
			spid, 
			oper_cur_code, 
			balance_oper, 
			db_name,
			controlling_org_id,		 
			detail_org_id,
			interbranch_flag
			) 				
SELECT 
			gltrx.journal_ctrl_num, 
			d.sequence_id, 
			gltrx.journal_description, 
			gltrx.journal_type, 
			gltrx.date_entered, 
			gltrx.date_applied, 
			gltrx.batch_code, 
			gltrx.hold_flag, 
			gltrx.home_cur_code, 
			gltrx.intercompany_flag, 
			gltrx.company_code, 
			gltrx.source_batch_code, 
			gltrx.type_flag, 
			gltrx.user_id, 
			gltrx.source_company_code, 
			d.account_code, 
			'', 
			d.rec_company_code, 
			d.nat_cur_code, 
			d.document_1, 
			d.description, 
			d.reference_code, 
			d.balance, 
			d.nat_balance, 
			d.trx_type, 
			d.offset_flag, 
			d.seq_ref_id, 
			0, 
			@@spid, 
			gltrx.oper_cur_code, 
			d.balance_oper, 
			glcomp_vw.db_name,
			gltrx.org_id,			
			d.org_id,
			ISNULL(gltrx.interbranch_flag,0)
FROM gltrx, gltrxdet d, glcomp_vw 
WHERE gltrx.journal_ctrl_num = d.journal_ctrl_num 
			AND d.rec_company_code = glcomp_vw.company_code
			AND gltrx.batch_code = @batch_code






SELECT @ib_flag = 0
SELECT @ib_flag = ib_flag
FROM glco


IF @ib_flag > 0
BEGIN
	

 
	SELECT @error_code = 2051
	EXEC    glerrdef_sp @error_code, @error_level OUTPUT
	
	IF (@process_mode = 0 AND @error_level > 1) OR
	   (@process_mode = 1 AND @error_level > 2)
	BEGIN
		
		UPDATE #gltrxedt1
		SET temp_flag = 0
			
		UPDATE #gltrxedt1
		SET temp_flag = 1
		FROM   #gltrxedt1 d
		WHERE 	d.controlling_org_id <> d.detail_org_id
		AND	d.sequence_id != -1
		AND     d.interbranch_flag = 1
				
		INSERT INTO #hold 
		SELECT DISTINCT journal_ctrl_num, 2051, 0 	
		FROM   #gltrxedt1
		WHERE 	temp_flag = 0
		AND  	company_code = rec_company_code 
		AND     controlling_org_id <> detail_org_id

	END
	
	

 
	SELECT @error_code = 2044
	EXEC    glerrdef_sp @error_code, @error_level OUTPUT
	
	IF (@process_mode = 0 AND @error_level > 1) OR
	   (@process_mode = 1 AND @error_level > 2)
	BEGIN
	
		INSERT INTO #hold 
		SELECT DISTINCT journal_ctrl_num, 2044, 0
		FROM	#gltrxedt1
		WHERE  company_code <> rec_company_code
		AND    interbranch_flag = 1

	END

	

 
	IF (SELECT COUNT(journal_ctrl_num) FROM #gltrxedt1 WHERE controlling_org_id !=  detail_org_id  AND company_code = rec_company_code) > 0
	BEGIN
		SELECT @error_code = 2045
		EXEC    glerrdef_sp @error_code, @error_level OUTPUT
	
		IF (@process_mode = 0 AND @error_level > 1) OR
		   (@process_mode = 1 AND @error_level > 2)
		BEGIN
			UPDATE #gltrxedt1
			SET temp_flag = 0
	
			UPDATE #gltrxedt1
			SET temp_flag = 1
			FROM   #gltrxedt1 d,  OrganizationOrganizationRel ood
			WHERE	d.controlling_org_id	!= d.detail_org_id
			AND	d.controlling_org_id	= ood.controlling_org_id 
			AND	d.detail_org_id 	= ood.detail_org_id
			AND  	d.company_code = d.rec_company_code  -- Rev. 2.3

			
			INSERT INTO #hold 
			SELECT DISTINCT journal_ctrl_num, 2045, 0 	
			FROM   #gltrxedt1 d
			WHERE 	temp_flag = 0
			AND	d.controlling_org_id	!= d.detail_org_id
			AND  	d.company_code = d.rec_company_code -- Rev. 2.3
	
		END
	END	
	

 
	IF (SELECT COUNT(journal_ctrl_num) FROM #gltrxedt1 WHERE controlling_org_id !=  detail_org_id AND company_code = rec_company_code) > 0
	BEGIN
		SELECT @error_code = 2046
		EXEC    glerrdef_sp @error_code, @error_level OUTPUT
	
		IF (@process_mode = 0 AND @error_level > 1) OR
		   (@process_mode = 1 AND @error_level > 2)
		BEGIN
			UPDATE #gltrxedt1
			SET temp_flag = 0
		
			UPDATE #gltrxedt1
			SET temp_flag = 1
			FROM   #gltrxedt1 d,   OrganizationOrganizationDef ood
			WHERE 	d.controlling_org_id	!= d.detail_org_id
			AND	d.controlling_org_id 	= ood.controlling_org_id			
			AND 	d.detail_org_id 	= ood.detail_org_id
			AND	d.account_code 	LIKE ood.account_mask
			AND	d.interbranch_flag = 1				
			AND  	d.company_code = d.rec_company_code  -- Rev. 2.3
	
			INSERT INTO #hold 
			SELECT DISTINCT journal_ctrl_num, 2046, 0 	
			FROM   #gltrxedt1 d
			WHERE 	temp_flag = 0
			AND	d.controlling_org_id	!= d.detail_org_id
			AND	d.interbranch_flag = 1				
			AND  	d.company_code = d.rec_company_code  -- Rev. 2.3
			AND  	d.seq_ref_id > 0				
	
		END
	END

	

 
	SELECT @error_code = 2050
	EXEC    glerrdef_sp @error_code, @error_level OUTPUT

	IF (@process_mode = 0 AND @error_level > 1) OR
	   (@process_mode = 1 AND @error_level > 2)
	BEGIN
		
		UPDATE #gltrxedt1
		SET temp_flag = 0
			
		UPDATE #gltrxedt1
		SET temp_flag = 1
		FROM   #gltrxedt1 d, glchart gl											
		WHERE	d.account_code NOT IN (select cash_acct_code FROM apcash)	
		AND     d.account_code = gl.account_code 
		AND     d.detail_org_id = gl.organization_id
		AND  	d.company_code = d.rec_company_code  -- Rev. 2.3

                
		INSERT INTO #hold 
		SELECT DISTINCT journal_ctrl_num, 2050, 0 	
		FROM   #gltrxedt1 d
		WHERE	temp_flag = 0
		AND	d.account_code NOT IN (select cash_acct_code FROM apcash)
		AND  	d.company_code = d.rec_company_code	  -- Rev. 2.3

	END


	

 
	SELECT @error_code = 2047
	EXEC    glerrdef_sp @error_code, @error_level OUTPUT

	IF (@process_mode = 0 AND @error_level > 1) OR
	   (@process_mode = 1 AND @error_level > 2)
	BEGIN

		UPDATE #gltrxedt1
		SET temp_flag = 0
			
		UPDATE #gltrxedt1
		SET temp_flag = 1
		FROM   #gltrxedt1 d,   Organization org
		WHERE 	d.controlling_org_id 	= org.organization_id
		AND	org.active_flag 	= 1

		INSERT INTO #hold 
		SELECT DISTINCT journal_ctrl_num, 2047, 0 	
		FROM   #gltrxedt1
		WHERE 	temp_flag = 0

	END
  
	
	

 
	SELECT @error_code = 2048
	EXEC    glerrdef_sp @error_code, @error_level OUTPUT

	IF (@process_mode = 0 AND @error_level > 1) OR
	   (@process_mode = 1 AND @error_level > 2)
	BEGIN

		UPDATE #gltrxedt1
		SET temp_flag = 0
			
		UPDATE #gltrxedt1
		SET temp_flag = 1
		FROM   #gltrxedt1 d,   Organization org
		WHERE 	d.detail_org_id	= org.organization_id
		AND	org.active_flag = 1
		AND  	company_code = rec_company_code -- Rev. 2.3
	
		INSERT INTO #hold 
		SELECT DISTINCT journal_ctrl_num, 2048, 0 	
		FROM   #gltrxedt1
		WHERE 	temp_flag = 0
		AND  	company_code = rec_company_code -- Rev. 2.3

		
	END

END
ELSE
BEGIN
	

 
	SELECT @error_code = 2049
	EXEC    glerrdef_sp @error_code, @error_level OUTPUT

	IF (@process_mode = 0 AND @error_level > 1) OR
	   (@process_mode = 1 AND @error_level > 2)
	BEGIN

		UPDATE #gltrxedt1
		SET temp_flag = 0
			
		UPDATE #gltrxedt1
		SET temp_flag = 1
		FROM   #gltrxedt1 d
		WHERE 	d.controlling_org_id = d.detail_org_id	
				
		INSERT INTO #hold 
		SELECT DISTINCT journal_ctrl_num, 2049, 0 	
		FROM   #gltrxedt1
		WHERE 	temp_flag = 0
		AND  	company_code = rec_company_code -- Rev. 2.3

	END

END		








 
SELECT @error_code = 2008
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

SELECT  @rnd = rounding_factor, @prc = curr_precision FROM glcurr_vw, glco
WHERE   currency_code = home_currency

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
	




	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2008, 0 
	FROM   #gltrxedt1
	WHERE  sequence_id > -1
	GROUP BY journal_ctrl_num
	HAVING round(abs(sum(balance)), @prc) >= @rnd
END





 
SELECT @error_code = 2043
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

SELECT  @rnd = rounding_factor, @prc = curr_precision FROM glcurr_vw, glco
WHERE   currency_code = oper_currency

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
	



	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2043, 0                            
	FROM   #gltrxedt1
	WHERE  sequence_id > -1
	GROUP BY journal_ctrl_num
	HAVING round(abs(sum(balance_oper)), @prc) >= @rnd
END






SELECT  @error_code = 2026
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
	SELECT @old_nat_cur_code = ""

	


	SET ROWCOUNT 1

	SELECT  @nat_cur_code = nat_cur_code
	FROM    #gltrxedt1
	WHERE   sequence_id > -1
	AND     nat_cur_code > @old_nat_cur_code
	ORDER BY nat_cur_code
	
	SET ROWCOUNT 0

	


	WHILE @nat_cur_code != @old_nat_cur_code
	BEGIN
		SELECT  @rnd = rounding_factor,
			@prc = curr_precision
		FROM    glcurr_vw
		WHERE   currency_code = @nat_cur_code

		



		INSERT INTO #hold 
		SELECT DISTINCT journal_ctrl_num, 2026, 0                            
		FROM   #gltrxedt1
		WHERE  sequence_id > -1
		AND    nat_cur_code = @nat_cur_code
		GROUP BY journal_ctrl_num
		HAVING round(abs(sum(nat_balance)), @prc) >= @rnd

		       
		SELECT @old_nat_cur_code = @nat_cur_code

		SET ROWCOUNT 1

		SELECT  @nat_cur_code = nat_cur_code
		FROM    #gltrxedt1
		WHERE   sequence_id > -1
		AND     nat_cur_code > @old_nat_cur_code
		ORDER BY nat_cur_code

		SET ROWCOUNT 0
	END
	
END




SELECT @error_code = 2039
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2039, 0                            
	FROM   #gltrxedt1 ed
	WHERE  sequence_id > -1
	AND    ed.home_cur_code NOT IN
	       (SELECT currency_code FROM glcurr_vw)
END




SELECT @error_code = 2006
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2006, 0 	
	FROM   #gltrxedt1 
	WHERE  sequence_id > -1
	GROUP BY journal_ctrl_num, sequence_id
	HAVING count(*) > 1
	
END





SELECT @error_code = 2007
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2007, 0 	
	FROM   #gltrxedt1 ed
	WHERE  sequence_id > 1
	AND    NOT EXISTS (
	       SELECT 1
	       FROM   #gltrxedt1 ed2
	       WHERE  ed2.journal_ctrl_num = ed.journal_ctrl_num
	       AND    ed2.sequence_id = ed.sequence_id - 1)
	
END




SELECT @error_code = 2012
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2012, 0 	
	FROM   #gltrxedt1 
	WHERE  sequence_id > -1
	AND    company_code <> rec_company_code
	AND    intercompany_flag = 0
END




SELECT @error_code = 2004
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2004, 0 	
	FROM   #gltrxedt1
	WHERE  sequence_id = -1 
	AND    company_code NOT IN (
	       SELECT company_code
	       FROM   glcomp_vw )
END




SELECT @error_code = 2035
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2035, 0 	
	FROM   #gltrxedt1 ed, glco co
	WHERE  ed.company_code <> co.company_code
	AND    sequence_id = -1
END




SELECT @error_code = 2034
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
	UPDATE #gltrxedt1 SET temp_flag = 0 

	UPDATE ed
	SET    temp_flag = 1
	FROM   #gltrxedt1 ed, gljtype j
	WHERE  ed.journal_type = j.journal_type
	AND    sequence_id = -1

	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2034, 0 
	FROM   #gltrxedt1
	WHERE   sequence_id = -1
	AND    temp_flag = 0
END




UPDATE #gltrxedt1 SET temp_flag = 0 

SELECT * INTO #gltrxedt 
FROM   #gltrxedt1
WHERE  offset_flag = 0
AND    sequence_id > -1
AND    rec_company_code <> company_code

UPDATE sysgen
SET    sysgen.temp_flag = 1
FROM   #gltrxedt1 sysgen, #gltrxedt usergen
WHERE  sysgen.offset_flag = 1
AND    sysgen.rec_company_code = sysgen.company_code
AND    usergen.offset_flag = 0
AND    usergen.sequence_id > -1
AND    usergen.rec_company_code <> usergen.company_code
AND    (sysgen.seq_ref_id = usergen.sequence_id OR
	(sysgen.seq_ref_id = 0 AND sysgen.nat_cur_code = usergen.nat_cur_code
	 AND abs(sysgen.nat_balance - usergen.nat_balance) < 0.01))

DROP TABLE #gltrxedt 




SELECT @error_code = 2038
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2038, 0
	FROM   #gltrxedt1 ed
	WHERE  company_code = rec_company_code
	AND    offset_flag = 1
	AND    temp_flag = 0
END
	



SELECT @error_code = 2019
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
	EXEC gledtutl_sp 
	
	SELECT * INTO #gltrxedt2
	FROM   #gltrxedt1
	WHERE  offset_flag = 0
	AND    sequence_id > -1
	AND    rec_company_code <> company_code

	UPDATE sysgen
	SET    sysgen.temp_flag = 2
	FROM   #gltrxedt1 sysgen, #gltrxedt2 usergen, glcocodt_vw ic
	WHERE  sysgen.offset_flag = 1
	AND    sysgen.rec_company_code = sysgen.company_code
	AND    usergen.offset_flag = 0
	AND    usergen.sequence_id > -1
	AND    usergen.rec_company_code <> usergen.company_code
	AND    (sysgen.seq_ref_id = usergen.sequence_id OR
		(sysgen.seq_ref_id = 0 
		 AND sysgen.nat_cur_code = usergen.nat_cur_code
		 AND abs(sysgen.nat_balance - usergen.nat_balance) < 0.01))
	AND    usergen.company_code = ic.org_code
	AND    usergen.rec_company_code = ic.rec_code
	AND    sysgen.account_code = ic.org_ic_acct
	AND    usergen.account_code LIKE ic.account_mask
	AND    sysgen.temp_flag = 1

	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2019, 0
	FROM   #gltrxedt1, glco 
	WHERE  sequence_id > -1
	AND    offset_flag = 1
	AND    rec_company_code = glco.company_code
	AND    temp_flag = 1

	DROP TABLE #gltrxedt2 
END





INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 6500, 0 
	FROM   #gltrxedt1 g
		INNER JOIN ibifc ib
			ON ib.link1 = g.journal_ctrl_num
			--AND ib.state_flag  IN (-4 , -5)





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "gledldP.cpp" + ", line " + STR( 766, 5 ) + " -- EXIT: "

RETURN
GO
GRANT EXECUTE ON  [dbo].[gledldp_sp] TO [public]
GO
