SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE        [dbo].[gledtval_sp]
			@process_mode                   smallint,
			@debug_level                    smallint = 0
			
AS

DECLARE @result                 int,
		@rnd                    float,
		@prc                    float,
		@error_level            int,
		@error_code             int,
		@nat_cur_code           varchar(8),
		@old_nat_cur_code       varchar(8),
		@rec_company_code       varchar(8),
		@old_rec_company_code   varchar(8),
		@ib_flag				int			






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
		










		INSERT INTO #ewerror 
		(       module_id,      err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,extra		)
		SELECT  6000,     2051,     d.detail_org_id,
			"",                     0,                      0.0,
			1,                      journal_ctrl_num,       sequence_id,				
			"",                     0             
		FROM   #gltrxedt1 d
		WHERE d.sequence_id != -1
		AND 	d.company_code = d.rec_company_code
		AND 	d.controlling_org_id <> d.detail_org_id
		AND   d.interbranch_flag NOT IN (1,2)	 			-- Rev 1.6 Proccess ibhdr table

	END
	

 
	SELECT @error_code = 2044
	EXEC    glerrdef_sp @error_code, @error_level OUTPUT
	
	IF (@process_mode = 0 AND @error_level > 1) OR
	   (@process_mode = 1 AND @error_level > 2)
	BEGIN
		INSERT INTO #ewerror 
		(       module_id,      err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,extra		)
		SELECT  6000,     2044,     rec_company_code,
			"",                     0,                      0.0,
			1,                      journal_ctrl_num,       sequence_id,				
			"",                     0                               
		FROM   #gltrxedt1
		WHERE  company_code <> rec_company_code
		AND    interbranch_flag = 1
		AND	sequence_id != -1
	END

	

 
	IF (SELECT COUNT(journal_ctrl_num) FROM #gltrxedt1 WHERE controlling_org_id !=  detail_org_id  AND company_code = rec_company_code) > 0
	BEGIN
		SELECT @error_code = 2045
		EXEC    glerrdef_sp @error_code, @error_level OUTPUT
	
		IF (@process_mode = 0 AND @error_level > 1) OR
		   (@process_mode = 1 AND @error_level > 2)
		BEGIN














			INSERT INTO #ewerror 
			(       module_id,      err_code,       info1,
				info2,          infoint,        infofloat,
				flag1,          trx_ctrl_num,   sequence_id,
				source_ctrl_num,extra		)
			SELECT  6000,     2045,     d.detail_org_id,
				"",                     0,                      0.0,
				1,                      d.journal_ctrl_num,       d.sequence_id,				
				"",                     0                
			FROM   #gltrxedt1 d
			LEFT JOIN OrganizationOrganizationRel ood ON d.controlling_org_id = ood.controlling_org_id AND d.detail_org_id 	= ood.detail_org_id
			WHERE 	d.controlling_org_id	!= d.detail_org_id
			AND  	d.company_code = d.rec_company_code -- Rev. 2.3
			AND ood.controlling_org_id IS NULL
			
			
	
		END
	END	
	

 
	IF (SELECT COUNT(journal_ctrl_num) FROM #gltrxedt1 WHERE controlling_org_id !=  detail_org_id ) > 0
	BEGIN
		SELECT @error_code = 2046
		EXEC    glerrdef_sp @error_code, @error_level OUTPUT
	
		IF (@process_mode = 0 AND @error_level > 1) OR
		   (@process_mode = 1 AND @error_level > 2)
		BEGIN

			INSERT INTO #ewerror 
			(       module_id,      err_code,       info1,
				info2,          infoint,        infofloat,
				flag1,          trx_ctrl_num,   sequence_id,
				source_ctrl_num,extra		)
			SELECT  6000,     2046,     d.detail_org_id,
				"",                     0,                      0.0,
				1,                      d.journal_ctrl_num,       sequence_id,				
				"",                     0             
			FROM   #gltrxedt1 d
				LEFT JOIN (SELECT  e.journal_ctrl_num
							FROM   #gltrxedt1 e
								INNER JOIN OrganizationOrganizationDef ood ON e.controlling_org_id	!= e.detail_org_id AND	e.controlling_org_id = ood.controlling_org_id AND 	e.detail_org_id = ood.detail_org_id AND	e.account_code 	LIKE ood.account_mask
							WHERE e.sequence_id != -1
								AND	e.interbranch_flag = 1			
								AND e.company_code = e.rec_company_code) TEMP ON d.journal_ctrl_num = TEMP.journal_ctrl_num 
			WHERE 	d.controlling_org_id != d.detail_org_id
			AND	d.sequence_id != -1
			AND	d.interbranch_flag = 1					
		 	AND d.company_code = d.rec_company_code -- Rev 1.3
			AND d.seq_ref_id > 0				
			AND TEMP.journal_ctrl_num IS NULL
	
		END
	END

	

 
	SELECT @error_code = 2050
	EXEC    glerrdef_sp @error_code, @error_level OUTPUT

	IF (@process_mode = 0 AND @error_level > 1) OR
	   (@process_mode = 1 AND @error_level > 2)
	BEGIN
		











		INSERT INTO #ewerror 
		(       module_id,      err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,extra		)
		SELECT  6000,     2050,     d.account_code,
			"",                     0,                      0.0,
			1,                      d.journal_ctrl_num,       d.sequence_id,				
			"",                     0             
		FROM   #gltrxedt1 d, glchart gl
		WHERE	 gl.account_code = d.account_code  
		AND		gl.organization_id != d.detail_org_id 
		AND		d.sequence_id != -1
		AND		d.account_code NOT IN (select cash_acct_code FROM apcash)	
		AND 	d.company_code = d.rec_company_code -- Rev 1.3

	END


	

 
	SELECT @error_code = 2047
	EXEC    glerrdef_sp @error_code, @error_level OUTPUT

	IF (@process_mode = 0 AND @error_level > 1) OR
	   (@process_mode = 1 AND @error_level > 2)
	BEGIN











				-- rev 1.7 

		INSERT INTO #ewerror 
		(       module_id,      err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra		)
		SELECT  6000,     2047,     d.controlling_org_id,
		"",                     0,                      0.0,
		1,                      journal_ctrl_num,       -1,				
		"",                     0             
		FROM   #gltrxedt1 d 
		LEFT OUTER JOIN Organization org ON ( d.controlling_org_id = org.organization_id AND org.active_flag = 1 )
		WHERE org.organization_id IS NULL AND 
			d.sequence_id = -1 
						
	
	END
  
	
	

 
	SELECT @error_code = 2048
	EXEC    glerrdef_sp @error_code, @error_level OUTPUT

	IF (@process_mode = 0 AND @error_level > 1) OR
	   (@process_mode = 1 AND @error_level > 2)
	BEGIN













	
		INSERT INTO #ewerror 
		(       module_id,      err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,extra		)
		SELECT  6000,     2048,     d.detail_org_id,
			"",                     0,                      0.0,
			1,                      journal_ctrl_num,       d.sequence_id,				
			"",                     0             
		FROM   #gltrxedt1 d 
		LEFT JOIN Organization org ON ( d.detail_org_id = org.organization_id AND org.active_flag = 1 )
		WHERE 	org.organization_id IS NULL AND 
				d.sequence_id != -1
		AND 	d.company_code = d.rec_company_code -- Rev 1.3
		
	END

END
ELSE
BEGIN
	

 
	SELECT @error_code = 2049
	EXEC    glerrdef_sp @error_code, @error_level OUTPUT

	IF (@process_mode = 0 AND @error_level > 1) OR
	   (@process_mode = 1 AND @error_level > 2)
	BEGIN

	









				
		INSERT INTO #ewerror 
		(       module_id,      err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,extra		)
		SELECT  6000,     2049,     d.detail_org_id,
			"",                     0,                      0.0,
			1,                      journal_ctrl_num,       sequence_id,				
			"",                     0             
		FROM   #gltrxedt1 d
		WHERE 	d.controlling_org_id != d.detail_org_id
		AND	d.sequence_id != -1
		AND 	d.company_code = d.rec_company_code -- Rev 1.3


	END

END		








 
SELECT @error_code = 2008
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

SELECT  @rnd = rounding_factor, @prc = curr_precision FROM glcurr_vw, glco
WHERE   currency_code = home_currency

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
	




	INSERT INTO #ewerror 
	(       module_id,      err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
	)
	SELECT  6000,     2008,     "",
		"",                     0,                      0.0,
		1,                      journal_ctrl_num,       -1,
		"",                     0                               
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
	



	INSERT INTO #ewerror 
	(       module_id,      err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
	)
	SELECT  6000,     2043,"",
		"",                     0,                      0.0,
		1,                      journal_ctrl_num,       -1,
		"",                     0                               
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

		



		INSERT INTO #ewerror 
		(module_id,     err_code,       info1,
		 info2,         infoint,        infofloat,
		 flag1,         trx_ctrl_num,   sequence_id,
		 source_ctrl_num,extra
		)
		SELECT  6000,     2026,      "Currency code:" + @nat_cur_code,
			"",                     0,                      0.0,
			1,                      journal_ctrl_num,       -1,
			"",                     0                               
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
	INSERT INTO #ewerror 
	(       module_id,      err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
	)
	SELECT  6000,     2039,      home_cur_code,
		"",                     user_id,                0.0,
		1,                      journal_ctrl_num,       sequence_id,
		"",                     0                               
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
	INSERT INTO #ewerror 
	(       module_id,      err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
	)
	SELECT  6000,     2006,           "",
		"",                     0,                      0.0,
		1,                      journal_ctrl_num,       sequence_id,
		"",                     0                               
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
	INSERT INTO #ewerror 
	(       module_id,      err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
	)
	SELECT  6000,     2007,            "",
		"",                     user_id,                0.0,
		1,                      journal_ctrl_num,       sequence_id,
		"",                     0                               
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
	INSERT INTO #ewerror 
	(       module_id,      err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
	)
	SELECT  6000,     2012,        "",
		"",                     user_id,                0.0,
		1,                      journal_ctrl_num,       sequence_id,
		"",                     0                               
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
	INSERT INTO #ewerror 
	(       module_id,      err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
	)
	SELECT  6000,     2004,         "",
		"",                     user_id,                0.0,
		1,                      journal_ctrl_num,       sequence_id,
		"",                     0                               
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
	INSERT INTO #ewerror 
	(       module_id,      err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
	)
	SELECT  6000,     2035,            "",
		"",                     user_id,                0.0,
		1,                      journal_ctrl_num,       sequence_id,
		"",                     0                               
	FROM   #gltrxedt1 ed, glco co
	WHERE  ed.company_code <> co.company_code
	AND    sequence_id = -1
END




SELECT @error_code = 2034
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN










	INSERT INTO #ewerror 
	(       module_id,      err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
	)
	SELECT  6000,     2034,           "",
		"",                     user_id,                0.0,
		1,                      journal_ctrl_num,       sequence_id,
		"",                     0                               
	FROM   #gltrxedt1 ed
		LEFT JOIN gljtype j ON ed.journal_type = j.journal_type
	WHERE   ed.sequence_id = -1
	AND j.journal_type IS NULL
	
END




UPDATE #gltrxedt1 SET temp_flag = 0 












UPDATE sysgen
SET    sysgen.temp_flag = 1
FROM   #gltrxedt1 sysgen, ( SELECT sequence_id, offset_flag, rec_company_code, company_code, nat_cur_code, nat_balance		
			    FROM #gltrxedt1 
			    WHERE  offset_flag = 0 AND sequence_id > -1 AND rec_company_code <> company_code ) usergen
WHERE  sysgen.offset_flag = 1
AND    sysgen.rec_company_code = sysgen.company_code
AND    usergen.offset_flag = 0
AND    usergen.sequence_id > -1
AND    usergen.rec_company_code <> usergen.company_code
AND    (sysgen.seq_ref_id = usergen.sequence_id OR
	(sysgen.seq_ref_id = 0 AND sysgen.nat_cur_code = usergen.nat_cur_code
	 AND abs(sysgen.nat_balance - usergen.nat_balance) < 0.01))






SELECT @error_code = 2038
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
	INSERT INTO #ewerror 
	(       module_id,      err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
	)
	SELECT  6000,     2038,             "",
		"",                     user_id,                0.0,
		1,                      journal_ctrl_num,       sequence_id,
		"",                     0                               
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
	
	









	

	UPDATE sysgen
	SET    sysgen.temp_flag = 2
	FROM   #gltrxedt1 sysgen, ( SELECT sequence_id, offset_flag, rec_company_code, company_code, account_code, nat_cur_code, nat_balance 	
				    FROM   #gltrxedt1
				    WHERE  offset_flag = 0 AND sequence_id > -1 AND rec_company_code <> company_code ) usergen, glcocodt_vw ic
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
	AND    sysgen.account_code = dbo.IBAcctMask_fn (ic.org_ic_acct, sysgen.detail_org_id )
	AND    usergen.account_code LIKE ic.account_mask
	AND    sysgen.temp_flag = 1

	INSERT INTO #ewerror 
	(       module_id,      err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
	)
	SELECT  6000,     2019,           "",
		"",                     user_id,                0.0,
		1,                      journal_ctrl_num,       sequence_id,
		"",                     0                               
	FROM   #gltrxedt1, glco 
	WHERE  sequence_id > -1
	AND    offset_flag = 1
	AND    rec_company_code = glco.company_code
	AND    temp_flag = 1

	
END



INSERT INTO #ewerror 
	(       module_id,      err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
	)
	SELECT  6000,     6500,           "",
		"",                     user_id,                0.0,
		1,                      journal_ctrl_num,       sequence_id,
		"",                     0                               
	FROM   #gltrxedt1 g
		INNER JOIN ibifc ib
			ON ib.link1 = g.journal_ctrl_num
			AND ib.state_flag  IN (0, -1, -4 , -5) AND g.sequence_id =-1


RETURN
GO
GRANT EXECUTE ON  [dbo].[gledtval_sp] TO [public]
GO
