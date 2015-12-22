SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[glvedb_sp] @db_name varchar(128),
         @header_db varchar(128),
         @process_mode int,
         @flag smallint,
         @debug_level smallint = 0
AS

DECLARE @current_period_end_date        int,
  @home_currency                  varchar(8),
  @error_level                    int,
  @error_code                     int,
  @rnd                            float,
  @prc                            float,
  @current_period_start_date	int

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "glvedb.cpp" + ", line " + STR( 48, 5 ) + " -- ENTRY: "





IF (@flag = 1)
BEGIN
  SELECT @error_code = 2005
  EXEC    glerrdef_sp @error_code, @error_level OUTPUT

  IF (@process_mode = 0 AND @error_level > 1) OR
     (@process_mode = 1 AND @error_level > 2)
  BEGIN
    INSERT  INTO #ewerror 
    (       module_id,      err_code,       info1,
      info2,          infoint,        infofloat,
      flag1,          trx_ctrl_num,   sequence_id,
      source_ctrl_num,extra
    )
    SELECT  6000,     2005,  "",
      "",                     user_id,        0.0,
      1,                      journal_ctrl_num,sequence_id,
      "",                     0                               
    FROM    #gltrxedt1
    WHERE   db_name = @db_name
    AND     sequence_id > -1
  END

  RETURN 0
END 





SELECT  @current_period_end_date = period_end_date,
  @home_currency = home_currency
FROM    glco

SELECT @current_period_start_date = period_start_date
FROM glprd
WHERE period_end_date = @current_period_end_date

DECLARE @min_date INT
DECLARE @max_date INT
SELECT @min_date = MIN(period_start_date) FROM glprd
SELECT @max_date = MAX(period_end_date) FROM glprd

IF (@db_name != @header_db)
BEGIN
  



  SELECT  @error_code = 2003
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
    SELECT  6000,     2003,    "",
      "",                     user_id,                0.0,
      1,                      journal_ctrl_num,       sequence_id,
      "",                     0               
    FROM    #gltrxedt1 ed
		LEFT JOIN glcoco_vw CO ON ed.rec_company_code = CO.rec_code AND ed.company_code = CO.org_code
    WHERE   ed.db_name = @db_name
		AND CO.rec_code IS NULL
  END 

  


  SELECT @error_code = 2036
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
    SELECT  6000,     2036,     "",
      "",                     user_id,                0.0,
      1,                      journal_ctrl_num,       sequence_id,
      "",                     0       
    FROM    #gltrxedt1 ed
    WHERE   sequence_id > -1
    AND     offset_flag = 0
    AND     db_name = @db_name
	AND  NOT  EXISTS (
		  SELECT  1
		  FROM    #gltrxedt1 ed2
		  WHERE   ed2.offset_flag = 1
		  AND     ed2.rec_company_code = ed.company_code
		  AND     (ed2.seq_ref_id = ed.sequence_id
			OR (ed2.seq_ref_id = 0 
			AND ed.nat_cur_code = ed2.nat_cur_code
			AND abs(ed.nat_balance - ed2.nat_balance) < 0.01)))
  END 


  


  SELECT @error_code = 2037
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
    SELECT  6000,     2037,    "",
      "",                     user_id,                0.0,
      1,                      journal_ctrl_num,       sequence_id,
      "",                     0       
    FROM    #gltrxedt1 ed
    WHERE   sequence_id > -1
    AND     offset_flag = 0
    AND     db_name = @db_name
    AND  NOT   EXISTS (
      SELECT  1
      FROM    #gltrxedt1 ed2
      WHERE   ed2.offset_flag = 1
      AND     ed2.rec_company_code = ed.rec_company_code
      AND     (ed2.seq_ref_id = ed.sequence_id
        OR (ed2.seq_ref_id = 0 
        AND ed.nat_cur_code = ed2.nat_cur_code
        AND abs(ed.nat_balance + ed2.nat_balance) < 0.01)))
  END

  UPDATE #gltrxedt1 SET temp_flag = 0

  EXEC    gledtutl_sp 

  


	DECLARE @gltrxedt TABLE
	(
		journal_ctrl_num varchar(16), 
		sequence_id int, 
		company_code varchar(8) NULL, 
		rec_company_code varchar(8),
		nat_cur_code varchar(8), 
		nat_balance float, 
		offset_flag smallint
	)

  INSERT INTO @gltrxedt
  SELECT journal_ctrl_num, sequence_id, company_code, rec_company_code, nat_cur_code, nat_balance, offset_flag
  --INTO #gltrxedt
  FROM    #gltrxedt1
  WHERE   offset_flag = 0
  AND     sequence_id > -1
  AND     rec_company_code <> company_code

  UPDATE  #gltrxedt1
  SET     temp_flag = 1
  FROM    #gltrxedt1 sysgen, @gltrxedt usergen
  WHERE   sysgen.offset_flag = 1
  AND     sysgen.rec_company_code = usergen.rec_company_code
  AND     usergen.offset_flag = 0
  AND     usergen.sequence_id > -1
  AND     usergen.rec_company_code <> usergen.company_code
  AND     (sysgen.seq_ref_id = usergen.sequence_id
    OR (sysgen.seq_ref_id = 0
    AND sysgen.nat_cur_code = usergen.nat_cur_code
    AND abs(sysgen.nat_balance + usergen.nat_balance) < 0.01))

  --DROP    TABLE   #gltrxedt 

  


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
    SELECT  6000,     2038,     "",
      "",                     user_id,                0.0,
      1,                      journal_ctrl_num,       sequence_id,
      "",                     0
    FROM    #gltrxedt1 ed
    WHERE   offset_flag = 1
    AND     db_name = @db_name
    AND     temp_flag = 0   
  END 



  


  SELECT @error_code = 2018
  EXEC    glerrdef_sp @error_code, @error_level OUTPUT

  IF (@process_mode = 0 AND @error_level > 1) OR
     (@process_mode = 1 AND @error_level > 2)
  BEGIN
    CREATE TABLE #gltrxedt_ic
    (
      journal_ctrl_num  varchar(16),
      sequence_id     smallint,
      user_id       smallint,
      journal_type    varchar(8),
      company_code    varchar(8),
      rec_company_code  varchar(8),
      account_code    varchar(32),
      account_len     tinyint,
      mark_flag     tinyint,
      db_name varchar(128)
    )

	CREATE INDEX gltrxedt_glvedb_ic_ind_0 ON #gltrxedt_ic (journal_ctrl_num)

    CREATE TABLE #glcocodt
    (
      org_code      varchar(8),
      rec_code      varchar(8),
      sequence_id     smallint,
      account_mask    varchar(32),
      org_ic_acct     varchar(32), 
      rec_ic_acct     varchar(32), 
      account_mask_len  tinyint,
      account_mask_strip  varchar(32) NULL
    )


    INSERT  #glcocodt
    (
        org_code,
        rec_code,
        sequence_id,
        account_mask,
        org_ic_acct,
        rec_ic_acct,
        account_mask_len,
        account_mask_strip
    )
    SELECT
        org_code,
        rec_code,
        sequence_id,
        account_mask,
        org_ic_acct,
        rec_ic_acct,
        ISNULL(DATALENGTH(RTRIM(account_mask)), 0),
        RTRIM(STUFF(account_mask, charindex('_', account_mask), 32, ' '))
    FROM
        glcocodt_vw


    INSERT  #gltrxedt_ic
    (
        journal_ctrl_num,
        sequence_id,
        user_id,
        journal_type,
        company_code,
        rec_company_code,
        account_code,
        account_len,
        mark_flag,
        db_name
    )
    SELECT
        journal_ctrl_num,
        sequence_id,
        user_id,
        journal_type,
        company_code,
        rec_company_code,
        account_code,
        ISNULL(DATALENGTH(RTRIM(account_code)), 0),
        0,
        db_name
    FROM
        #gltrxedt1
    WHERE
        sequence_id > -1 AND
        rec_company_code <> company_code AND
        offset_flag = 0
        AND db_name = @db_name

    UPDATE  #gltrxedt_ic
    SET   mark_flag = 1

    FROM  #gltrxedt_ic edt, #glcocodt coco
    WHERE
        edt.company_code = coco.org_code AND
        edt.rec_company_code = coco.rec_code AND
        edt.mark_flag = 0 AND
          
        edt.account_code LIKE coco.account_mask
       AND edt.db_name = @db_name


    SELECT  edt.* INTO #gltrxedt_fail
    FROM  #gltrxedt_ic edt, #glcocodt coco
    WHERE
        edt.company_code = coco.org_code AND
        edt.rec_company_code = coco.rec_code AND
        edt.mark_flag = 0 AND
        
        edt.account_code NOT LIKE coco.account_mask
       AND edt.db_name = @db_name



    INSERT INTO #ewerror 
    (   module_id,      err_code,       info1,
      info2,          infoint,        infofloat,
      flag1,          trx_ctrl_num,   sequence_id,
      source_ctrl_num,extra
    )
    SELECT  6000,     2018,   "",
      "",                     user_id,                0.0,
      1,                      journal_ctrl_num,       sequence_id,
      "",                     0
    FROM    #gltrxedt_fail


    DROP TABLE #gltrxedt_ic
    DROP TABLE #gltrxedt_fail
    DROP TABLE #glcocodt
  END 

  


  SELECT @error_code = 2020
  EXEC    glerrdef_sp @error_code, @error_level OUTPUT

  IF (@process_mode = 0 AND @error_level > 1) OR
     (@process_mode = 1 AND @error_level > 2)
  BEGIN

	DECLARE @gltrxedt2 TABLE
	(
		journal_ctrl_num varchar(16), 
		sequence_id int, 
		company_code varchar(8) NULL, 
		account_code varchar(32),
		rec_company_code varchar(8),
		nat_cur_code varchar(8), 
		nat_balance float, 
		offset_flag smallint
	)

	INSERT INTO @gltrxedt2
    SELECT  journal_ctrl_num, sequence_id int, company_code, account_code, rec_company_code, nat_cur_code, nat_balance, offset_flag
	--INTO #gltrxedt2
    FROM    #gltrxedt1
    WHERE   offset_flag = 0
    AND     sequence_id > -1
    AND     rec_company_code <> company_code

    UPDATE  #gltrxedt1
    SET     temp_flag = 2
    FROM    #gltrxedt1 sysgen, @gltrxedt2 usergen, glcocodt_vw ic
    WHERE   sysgen.offset_flag = 1
    AND     sysgen.db_name = @db_name
    AND     usergen.offset_flag = 0
    AND     usergen.sequence_id > -1
    AND     usergen.rec_company_code = sysgen.rec_company_code
    AND     (sysgen.seq_ref_id = usergen.sequence_id
      OR (sysgen.seq_ref_id = 0
      AND sysgen.nat_cur_code = usergen.nat_cur_code
      AND abs(sysgen.nat_balance + usergen.nat_balance) < 0.01))
    AND     usergen.company_code = ic.org_code
    AND     usergen.rec_company_code = ic.rec_code
    AND     sysgen.account_code =  dbo.IBAcctMask_fn (ic.rec_ic_acct, sysgen.detail_org_id )
    AND     usergen.account_code LIKE ic.account_mask
    AND     sysgen.temp_flag = 1

    INSERT INTO #ewerror 
    (       module_id,      err_code,       info1,
      info2,          infoint,        infofloat,
      flag1,          trx_ctrl_num,   sequence_id,
      source_ctrl_num,extra
    )
    SELECT  6000,     2020,    "",
      "",                     user_id,                0.0,
      1,                      journal_ctrl_num,       sequence_id,
      "",                     0
    FROM    #gltrxedt1 ed
    WHERE   sequence_id > -1
    AND     offset_flag = 1
    AND     db_name = @db_name
    AND     temp_flag = 1   

    --DROP    TABLE #gltrxedt2
  END 
END 




SELECT @error_code = 2029
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN

  --UPDATE #gltrxedt1 SET temp_flag = 0

  SELECT @rnd = rounding_factor, @prc = curr_precision FROM glcurr_vw, glco
  WHERE   currency_code = @home_currency

  INSERT INTO #ewerror 
  (       module_id,      err_code,       info1,
    info2,          infoint,        infofloat,
    flag1,          trx_ctrl_num,   sequence_id,
    source_ctrl_num,extra
  )
  SELECT  6000,     2029,     "",
    "",                     0,                      0.0,
    1,                      journal_ctrl_num,       -1,
    "",                     0
  FROM    #gltrxedt1 ed
  WHERE   sequence_id > -1
  AND     db_name = @db_name
  GROUP BY journal_ctrl_num
  HAVING  round(abs(sum(balance)), @prc) >= @rnd
END 





SELECT @error_code = 2001
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN

  UPDATE #gltrxedt1 SET temp_flag = 0








  UPDATE  #gltrxedt1
  SET     temp_flag = 1,
      account_description = ch.account_description
  FROM    #gltrxedt1 ed
	INNER JOIN glchart ch ON ed.account_code = ch.account_code
  WHERE   db_name = @db_name

  INSERT INTO #ewerror 
  (       module_id,      err_code,       info1,
    info2,          infoint,        infofloat,
    flag1,          trx_ctrl_num,   sequence_id,
    source_ctrl_num,extra
  )
  SELECT  6000,     2001,      "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1
  WHERE   sequence_id > -1
  AND     db_name = @db_name
  AND     temp_flag = 0

END 





SELECT @error_code = 2016
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
  SELECT  6000,     2016,     "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1 ed, glchart ch
  WHERE   db_name = @db_name
  AND     ed.account_code = ch.account_code
  AND     temp_flag = 1
  AND     ((date_applied NOT BETWEEN active_date AND inactive_date
    AND (active_date > 0 AND inactive_date > 0))
    OR (date_applied < active_date AND inactive_date = 0))
END 





SELECT @error_code = 2017
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
  SELECT  6000,     2017,   "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1 ed
	INNER JOIN glchart ch ON ed.account_code = ch.account_code AND inactive_flag = 1
  WHERE   db_name = @db_name
    AND     temp_flag = 1
END 





SELECT @error_code = 2000
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN









  UPDATE  #gltrxedt1
  SET     temp_flag = 2
  FROM    #gltrxedt1 ed
  WHERE   db_name = @db_name
  AND     ed.date_applied BETWEEN @min_date AND @max_date


  INSERT INTO #ewerror 
  (       module_id,      err_code,       info1,
    info2,          infoint,        infofloat,
    flag1,          trx_ctrl_num,   sequence_id,
    source_ctrl_num,extra
  )
  SELECT  6000,     2000,       "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1 
  WHERE   sequence_id > -1
  AND     db_name = @db_name
  AND     temp_flag = 1
END 




SELECT @error_code = 2024
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
  SELECT  DISTINCT 6000,     2024,    "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       0,
    "",                     0
  FROM    #gltrxedt1 ed
  WHERE   db_name = @db_name
  AND     ed.date_applied < @current_period_start_date
  AND     temp_flag = 2
END


SELECT @error_code = 2027
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
  SELECT DISTINCT 6000,     2027,     "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       0,
    "",                     0
  FROM    #gltrxedt1 ed
  WHERE   db_name = @db_name
  AND     ed.date_applied > @current_period_end_date
  AND     temp_flag = 2
END


SELECT @error_code = 2025
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN












  UPDATE  #gltrxedt1
  SET     temp_flag = 3
  FROM    #gltrxedt1 ed, glbal bal
  WHERE   db_name = @db_name
  AND     ed.date_applied BETWEEN @min_date AND @max_date
  AND     bal.balance_date = @max_date
  AND     bal.account_code = ed.account_code
  AND     temp_flag = 2

  INSERT INTO #ewerror 
  (       module_id,      err_code,       info1,
    info2,          infoint,        infofloat,
    flag1,          trx_ctrl_num,   sequence_id,
    source_ctrl_num,extra
  )
  SELECT  6000,     2025,    "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1
  WHERE   sequence_id > -1
  AND     db_name = @db_name
  AND     temp_flag = 2
END


SELECT @error_code = 2009
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
  UPDATE  #gltrxedt1
  SET     temp_flag = 4
  FROM    #gltrxedt1 ed, glincsum i
  WHERE   db_name = @db_name
  AND     ed.account_code LIKE i.account_pattern
  AND     temp_flag > 0

  INSERT INTO #ewerror 
  (       module_id,      err_code,       info1,
    info2,          infoint,        infofloat,
    flag1,          trx_ctrl_num,   sequence_id,
    source_ctrl_num,extra
  )
  SELECT  6000,     2009,      "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1
  WHERE   sequence_id > -1
  AND     db_name = @db_name
  AND     temp_flag BETWEEN 1 AND 3
END


SELECT @error_code = 2009
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
  SELECT  6000,     2009,      "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       ed.sequence_id,
    "",                     0
  FROM    #gltrxedt1 ed
		INNER JOIN glincsum i ON ed.account_code LIKE i.account_pattern
		LEFT JOIN glchart CHRT ON i.is_acct_code = CHRT.account_code
  WHERE   temp_flag > 0
  AND     db_name = @db_name
  AND     CHRT.account_code IS NULL
END


SELECT  @error_code = 2011
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
  SELECT  6000,     2011,     "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       ed.sequence_id,
    "",                     0
  FROM    #gltrxedt1 ed
	INNER JOIN glincsum i ON ed.account_code LIKE i.account_pattern
	LEFT JOIN glchart CHRT ON i.re_acct_code = CHRT.account_code 
  WHERE   temp_flag > 0
  AND     db_name = @db_name
  AND CHRT.account_code  IS NULL
END


SELECT  @error_code = 2014
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN

  UPDATE #gltrxedt1 SET temp_flag = 0











  UPDATE  #gltrxedt1
  SET     temp_flag = 1
  FROM    #gltrxedt1 ed
	INNER JOIN glcocond_vw a ON ed.account_code LIKE a.account_mask
	INNER JOIN glcomp_vw b ON ed.company_code = b.company_code AND a.parent_comp_id = b.company_id
	INNER JOIN glcomp_vw c ON ed.rec_company_code = c.company_code AND a.sub_comp_id = c.company_id
  WHERE   ed.db_name = @db_name

  INSERT INTO #ewerror 
  (       module_id,      err_code,       info1,
    info2,          infoint,        infofloat,
    flag1,          trx_ctrl_num,   sequence_id,
    source_ctrl_num,extra
  )
  SELECT  6000,     2014,     "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       ed.sequence_id,
    "",                     0
  FROM    #gltrxedt1 ed, glincsum i
  WHERE   ed.sequence_id > -1
  AND     db_name = @db_name
  AND     temp_flag = 0
END


SELECT  @error_code = 2022
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
  SELECT  6000,     2022,       "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1 ed
	LEFT JOIN glcurr_vw CUR ON ed.nat_cur_code = CUR.currency_code
  WHERE   db_name = @db_name
  AND CUR.currency_code IS NULL
END


SELECT  @error_code = 2041
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
  SELECT  6000,     2041,     "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1 ed
	INNER JOIN glchart ch ON ed.account_code = ch.account_code AND ch.currency_code <> ""
  WHERE   db_name = @db_name
  AND     nat_cur_code <> ch.currency_code
END


SELECT  @error_code = 2023
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
  SELECT  6000,     2041,     "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1 ed
	LEFT JOIN glcurate_vw CUR ON ed.home_cur_code = CUR.to_currency AND ed.nat_cur_code = CUR.from_currency
  WHERE   db_name = @db_name
  AND     home_cur_code <> nat_cur_code
  AND CUR.from_currency IS NULL
END


SELECT  @error_code = 2042
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
  SELECT  6000,     2042,      "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1 ed
	INNER JOIN glrefact ra ON ed.account_code LIKE ra.account_mask AND ra.reference_flag = 3
  WHERE   db_name = @db_name
  AND     offset_flag = 0
  AND     sequence_id > -1
  AND     ed.reference_code = ''
END


UPDATE #gltrxedt1 SET temp_flag = 0

UPDATE  #gltrxedt1
SET     temp_flag = 1
FROM    #gltrxedt1, glrefact
WHERE   db_name = @db_name
AND     account_code LIKE account_mask
AND     reference_code <> ""
AND     offset_flag = 0
AND     sequence_id > -1


SELECT  @error_code = 2031
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
  SELECT  6000,     2031,     "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1 
  WHERE   db_name = @db_name
  AND     reference_code <> ""
  AND     offset_flag = 0
  AND     temp_flag = 0


  INSERT INTO #ewerror 
  (       module_id,      err_code,       info1,
    info2,          infoint,        infofloat,
    flag1,          trx_ctrl_num,   sequence_id,
    source_ctrl_num,extra
  )
  SELECT  6000,     2031,     "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1, glrefact ra 
  WHERE   db_name = @db_name
  AND     account_code LIKE account_mask
  AND     reference_flag = 1
  AND     temp_flag = 1
  AND     offset_flag = 0
END


SELECT  @error_code = 2028
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN








  UPDATE  #gltrxedt1
  SET     temp_flag = 2
  FROM    #gltrxedt1 ed
	INNER JOIN glref r ON ed.reference_code = r.reference_code
  WHERE   db_name = @db_name
  AND     temp_flag = 1

  INSERT INTO #ewerror 
  (       module_id,      err_code,       info1,
    info2,          infoint,        infofloat,
    flag1,          trx_ctrl_num,   sequence_id,
    source_ctrl_num,extra
  )
  SELECT  6000,     2028,       "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1
  WHERE   db_name = @db_name
  AND     offset_flag = 0
  AND     temp_flag = 1
END


SELECT  @error_code = 2033
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
  SELECT  6000,     2033,    "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1 ed
	INNER JOIN glref r ON ed.reference_code = r.reference_code
  WHERE   db_name = @db_name
  AND     status_flag = 1
  AND     offset_flag = 0
  AND     temp_flag >= 1
END


SELECT  @error_code = 2030
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN










  UPDATE  #gltrxedt1
  SET     temp_flag = 3
  FROM    #gltrxedt1 ed
	INNER JOIN glref r ON ed.reference_code = r.reference_code
	INNER JOIN glratyp t ON ed.account_code LIKE t.account_mask AND r.reference_type = t.reference_type
  WHERE   db_name = @db_name
  AND     temp_flag >= 1

  INSERT INTO #ewerror 
  (       module_id,      err_code,       info1,
    info2,          infoint,        infofloat,
    flag1,          trx_ctrl_num,   sequence_id,
    source_ctrl_num,extra
  )
  SELECT  6000,     2030,       "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1 ed
  WHERE   db_name = @db_name
  AND     offset_flag = 0
  AND     temp_flag BETWEEN 1 AND 2
END


SELECT  @error_code = 2040
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
  SELECT  6000,     2040,      "",
    "",                     user_id,                0.0,
    1,                      journal_ctrl_num,       sequence_id,
    "",                     0
  FROM    #gltrxedt1 
  WHERE   db_name = @db_name
  AND     reference_code <> ''
  AND     offset_flag = 1
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "glvedb.cpp" + ", line " + STR( 1397, 5 ) + " -- EXIT: "
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[glvedb_sp] TO [public]
GO
