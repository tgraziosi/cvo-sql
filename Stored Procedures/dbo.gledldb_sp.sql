SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[gledldb_sp] 
		 @db_name varchar(128),
         @header_db varchar(128),
         @process_mode int,
         @flag smallint,
         @debug_level smallint = 0
			
AS

DECLARE 		
		@rnd						float,
		@prc						float,
		@error_level				int,
		@error_code					int,
		@current_period_end_date	int,
		@home_currency				varchar(8)
		
		


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "gledldb.cpp" + ", line " + STR( 60, 5 ) + " -- ENTRY: "





IF (@flag = 1)
BEGIN
  SELECT @error_code = 2005
  EXEC    glerrdef_sp @error_code, @error_level OUTPUT

  IF (@process_mode = 0 AND @error_level > 1) OR
     (@process_mode = 1 AND @error_level > 2)
  BEGIN
	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2005, 0
    FROM    #gltrxedt1
    WHERE   db_name = @db_name
    AND     sequence_id > -1
  END

  RETURN 0
END 







SELECT  @current_period_end_date = period_end_date,
		@home_currency = home_currency
FROM    glco


IF (@db_name != @header_db)
BEGIN
  



  SELECT  @error_code = 2003
  EXEC    glerrdef_sp @error_code, @error_level OUTPUT

  IF (@process_mode = 0 AND @error_level > 1) OR
     (@process_mode = 1 AND @error_level > 2)
  BEGIN
	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2003, 0    
	FROM    #gltrxedt1 ed
    WHERE   ed.db_name = @db_name
    AND NOT EXISTS (
      SELECT  *
      FROM    glcoco_vw
      WHERE   ed.rec_company_code = rec_code
      AND     ed.company_code = org_code)
  END 



  


  SELECT @error_code = 2036
  EXEC    glerrdef_sp @error_code, @error_level OUTPUT

  IF (@process_mode = 0 AND @error_level > 1) OR
     (@process_mode = 1 AND @error_level > 2)
  BEGIN
    UPDATE #gltrxedt1 SET temp_flag = 0

    UPDATE  #gltrxedt1
    SET     temp_flag = 1
    FROM    #gltrxedt1 ed1
    WHERE   offset_flag = 0
    AND     db_name = @db_name
    AND     sequence_id > -1
    AND     EXISTS (
      SELECT  *
      FROM    #gltrxedt1 ed2
      WHERE   ed2.offset_flag = 1
      AND     ed2.rec_company_code = ed1.company_code
      AND     (ed2.seq_ref_id = ed1.sequence_id
        OR (ed2.seq_ref_id = 0 
        AND ed1.nat_cur_code = ed2.nat_cur_code
        AND abs(ed1.nat_balance - ed2.nat_balance) < 0.01)))

	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2036, 0    
    FROM    #gltrxedt1 ed
    WHERE   sequence_id > -1
    AND     offset_flag = 0
    AND     db_name = @db_name
    AND     temp_flag = 0   

  END 



  


  SELECT @error_code = 2037
  EXEC    glerrdef_sp @error_code, @error_level OUTPUT

  IF (@process_mode = 0 AND @error_level > 1) OR
     (@process_mode = 1 AND @error_level > 2)
  BEGIN
    UPDATE #gltrxedt1 SET temp_flag = 0

    UPDATE  #gltrxedt1
    SET     temp_flag = 1
    FROM    #gltrxedt1 ed1
    WHERE   offset_flag = 0
    AND     db_name = @db_name
    AND     sequence_id > -1
    AND     EXISTS (
      SELECT  *
      FROM    #gltrxedt1 ed2
      WHERE   ed2.offset_flag = 1
      AND     ed2.rec_company_code = ed1.rec_company_code
      AND     (ed2.seq_ref_id = ed1.sequence_id
        OR (ed2.seq_ref_id = 0 
        AND ed1.nat_cur_code = ed2.nat_cur_code
        AND abs(ed1.nat_balance + ed2.nat_balance) < 0.01)))

	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2037, 0  
    FROM    #gltrxedt1 ed
    WHERE   sequence_id > -1
    AND     offset_flag = 0
    AND     db_name = @db_name
    AND     temp_flag = 0   
  END




  UPDATE #gltrxedt1 SET temp_flag = 0

  EXEC    gledtutl_sp 

  


  SELECT * INTO #gltrxedt3
  FROM    #gltrxedt1
  WHERE   offset_flag = 0
  AND     sequence_id > -1
  AND     rec_company_code <> company_code

  UPDATE  #gltrxedt1
  SET     temp_flag = 1
  FROM    #gltrxedt1 sysgen, #gltrxedt3 usergen
  WHERE   sysgen.offset_flag = 1
  AND     sysgen.rec_company_code = usergen.rec_company_code
  AND     usergen.offset_flag = 0
  AND     usergen.sequence_id > -1
  AND     usergen.rec_company_code <> usergen.company_code
  AND     (sysgen.seq_ref_id = usergen.sequence_id
    OR (sysgen.seq_ref_id = 0
    AND sysgen.nat_cur_code = usergen.nat_cur_code
    AND abs(sysgen.nat_balance + usergen.nat_balance) < 0.01))

  DROP    TABLE   #gltrxedt3 

  























  


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



	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2018, 0  
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
    SELECT  * INTO #gltrxedt22
    FROM    #gltrxedt1
    WHERE   offset_flag = 0
    AND     sequence_id > -1
    AND     rec_company_code <> company_code

    UPDATE  #gltrxedt1
    SET     temp_flag = 2
    FROM    #gltrxedt1 sysgen, #gltrxedt22 usergen, glcocodt_vw ic
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
    AND     sysgen.account_code = dbo.IBAcctMask_fn (ic.rec_ic_acct, sysgen.detail_org_id ) 
    AND     usergen.account_code LIKE ic.account_mask
    AND     sysgen.temp_flag = 1

	INSERT INTO #hold 
	SELECT DISTINCT journal_ctrl_num, 2020, 0  
    FROM    #gltrxedt1 ed
    WHERE   sequence_id > -1
    AND     offset_flag = 1
    AND     db_name = @db_name
    AND     temp_flag = 1   

    DROP    TABLE #gltrxedt22
  END 
END 








SELECT @error_code = 2029
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN

  UPDATE #gltrxedt1 SET temp_flag = 0  

  SELECT @rnd = rounding_factor, @prc = curr_precision FROM glcurr_vw, glco
  WHERE   currency_code = @home_currency

  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2029, 0  
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
  FROM    #gltrxedt1 ed, glchart ch
  WHERE   db_name = @db_name
  AND     ed.account_code = ch.account_code

  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2001, 0  
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

  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2016, 0  
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
  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2017, 0  
  FROM    #gltrxedt1 ed, glchart ch
  WHERE   db_name = @db_name
  AND     ed.account_code = ch.account_code
  AND     inactive_flag = 1
  AND     temp_flag = 1
END 







SELECT @error_code = 2000
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
  UPDATE  #gltrxedt1
  SET     temp_flag = 2
  FROM    #gltrxedt1 ed, glprd prd
  WHERE   db_name = @db_name
  AND     ed.date_applied BETWEEN prd.period_start_date
  AND	  prd.period_end_date

  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2000, 0  
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
  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2024, 0  
  FROM    #gltrxedt1 ed, glprd prd
  WHERE   db_name = @db_name
  AND     ed.date_applied < prd.period_start_date
  AND     prd.period_end_date = @current_period_end_date
  AND     temp_flag = 2
END



SELECT @error_code = 2027
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2027, 0  
  FROM    #gltrxedt1 ed, glprd prd
  WHERE   db_name = @db_name
  AND     ed.date_applied > prd.period_end_date
  AND     prd.period_end_date = @current_period_end_date
  AND     temp_flag = 2
END




SELECT @error_code = 2025
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
  UPDATE  #gltrxedt1
  SET     temp_flag = 3
  FROM    #gltrxedt1 ed, glprd prd, glbal bal
  WHERE   db_name = @db_name
  AND     ed.date_applied BETWEEN prd.period_start_date 
    AND prd.period_end_date
  AND     prd.period_end_date = bal.balance_date
  AND     bal.account_code = ed.account_code
  AND     temp_flag = 2

  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2025, 0  
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

  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2009, 0  
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
  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2009, 0  
  FROM    #gltrxedt1 ed, glincsum i
  WHERE   temp_flag > 0
  AND     db_name = @db_name
  AND     ed.account_code LIKE i.account_pattern
  AND     i.is_acct_code NOT IN (SELECT account_code FROM glchart)
END


SELECT  @error_code = 2011
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2011, 0  
  FROM    #gltrxedt1 ed, glincsum i
  WHERE   temp_flag > 0
  AND     db_name = @db_name
  AND     ed.account_code LIKE i.account_pattern
  AND     i.re_acct_code NOT IN 
    (SELECT account_code FROM glchart)
END







SELECT  @error_code = 2014
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
  UPDATE #gltrxedt1 SET temp_flag = 0
  
  UPDATE  #gltrxedt1
  SET     temp_flag = 1
  FROM    #gltrxedt1 ed, glcocond_vw a, glcomp_vw b, glcomp_vw c
  WHERE   ed.db_name = @db_name
  AND     ed.company_code = b.company_code
  AND     b.company_id = a.parent_comp_id
  AND     ed.rec_company_code = c.company_code
  AND     c.company_id = a.sub_comp_id
  AND     ed.account_code LIKE a.account_mask

  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2014, 0  
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
  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2022, 0  
  FROM    #gltrxedt1 ed
  WHERE   db_name = @db_name
  AND     ed.nat_cur_code NOT IN
    (SELECT currency_code FROM glcurr_vw)
END





SELECT  @error_code = 2041
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2041, 0  
  FROM    #gltrxedt1 ed, glchart ch
  WHERE   db_name = @db_name
  AND     ed.account_code = ch.account_code
  AND     ch.currency_code <> ""
  AND     nat_cur_code <> ch.currency_code
END





SELECT  @error_code = 2023
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2023, 0  
  FROM    #gltrxedt1 ed
  WHERE   db_name = @db_name
  AND     home_cur_code <> nat_cur_code
  AND     NOT EXISTS
    (SELECT * FROM glcurate_vw
    WHERE   ed.home_cur_code = to_currency
    AND     ed.nat_cur_code = from_currency)
END


SELECT  @error_code = 2042
EXEC    glerrdef_sp @error_code, @error_level OUTPUT

IF (@process_mode = 0 AND @error_level > 1) OR
   (@process_mode = 1 AND @error_level > 2)
BEGIN
  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2042, 0  
  FROM    #gltrxedt1 ed, glrefact ra
  WHERE   db_name = @db_name
  AND     ed.account_code LIKE ra.account_mask
  AND     ra.reference_flag = 3
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
  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2031, 0  
  FROM    #gltrxedt1 
  WHERE   db_name = @db_name
  AND     reference_code <> ""
  AND     offset_flag = 0
  AND     temp_flag = 0


  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2031, 0  
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
  FROM    #gltrxedt1 ed, glref r
  WHERE   db_name = @db_name
  AND     ed.reference_code = r.reference_code
  AND     temp_flag = 1

  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2028, 0  
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
  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2033, 0 
  FROM    #gltrxedt1 ed, glref r
  WHERE   db_name = @db_name
  AND     ed.reference_code = r.reference_code
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
  FROM    #gltrxedt1 ed, glref r, glratyp t
  WHERE   db_name = @db_name
  AND     ed.reference_code = r.reference_code
  AND     r.reference_type = t.reference_type
  AND     ed.account_code LIKE t.account_mask
  AND     temp_flag >= 1

  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2030, 0 
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
  INSERT INTO #hold 
  SELECT DISTINCT journal_ctrl_num, 2040, 0 
  FROM    #gltrxedt1 
  WHERE   db_name = @db_name
  AND     reference_code <> ''
  AND     offset_flag = 1
END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "gledldb.cpp" + ", line " + STR( 919, 5 ) + " -- EXIT: "


RETURN
GO
GRANT EXECUTE ON  [dbo].[gledldb_sp] TO [public]
GO
