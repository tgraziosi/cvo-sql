
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
  
  
CREATE PROCEDURE [dbo].[gledldp_grp_sp]  
   @process_mode smallint,  
   @batch_code   varchar(16),  
   @debug_level smallint = 0  
AS  
  
DECLARE @result      int,    
  @rnd      float,  
  @prc      float,  
  @error_level    int,  
  @error_code     int,  
  @nat_cur_code    varchar(8),  
  @old_nat_cur_code   varchar(8),  
  @ib_flag    int,  
  @acct_desc   varchar(40)  
   
select @acct_desc = ''  
  
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "gledldp_grp.cpp" + ", line " + STR( 84, 5 ) + " -- ENTRY: "  
  
  
  
  
  
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
   h.journal_ctrl_num,   
   d.sequence_id,   
   h.journal_description,   
   h.journal_type,   
   h.date_entered,   
   h.date_applied,   
   h.batch_code,   
   h.hold_flag,   
   h.home_cur_code,   
   h.intercompany_flag,   
   h.company_code,   
   h.source_batch_code,   
   h.type_flag,   
   h.user_id,   
   h.source_company_code,   
   d.account_code,   
   '',   
   d.rec_company_code,   
   d.nat_cur_code,   
   d.document_1,   
   LEFT(d.description,40), -- v1.0  
   d.reference_code,   
   d.balance,   
   d.nat_balance,   
   d.trx_type,   
   d.offset_flag,   
   d.seq_ref_id,   
   0,   
   @@spid,   
   h.oper_cur_code,   
   d.balance_oper,   
   glcomp_vw.db_name,  
   h.org_id,     
   d.org_id,  
   ISNULL(h.interbranch_flag,0)  
FROM gltrx_all h  
 INNER JOIN #Group_batch GRP ON h.batch_code = GRP.batch_ctrl_num AND GRP.batch_ctrl_num_group = @batch_code  
 INNER JOIN gltrxdet d ON h.journal_ctrl_num = d.journal_ctrl_num   
 INNER JOIN glcomp_vw ON d.rec_company_code = glcomp_vw.company_code  
  
  
  
  
  
  
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
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  INSERT INTO #hold   
  SELECT DISTINCT journal_ctrl_num, 2051, 0    
  FROM   #gltrxedt1  
  WHERE  company_code = rec_company_code   
  AND     controlling_org_id <> detail_org_id  
  AND  sequence_id != -1  
  AND     interbranch_flag != 1  
  
 END  
   
   
  
   
 SELECT @error_code = 2044  
 EXEC    glerrdef_sp @error_code, @error_level OUTPUT  
   
 IF (@process_mode = 0 AND @error_level > 1) OR  
    (@process_mode = 1 AND @error_level > 2)  
 BEGIN  
   
  INSERT INTO #hold   
  SELECT DISTINCT journal_ctrl_num, 2044, 0  
  FROM #gltrxedt1  
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
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
   INSERT INTO #hold   
   SELECT DISTINCT d.journal_ctrl_num, 2045, 0    
   FROM   #gltrxedt1 d  
    LEFT JOIN OrganizationOrganizationRel ood ON d.controlling_org_id = ood.controlling_org_id AND d.detail_org_id  = ood.detail_org_id  
   WHERE  d.controlling_org_id != d.detail_org_id  
   AND   d.company_code = d.rec_company_code -- Rev. 2.3  
   AND ood.controlling_org_id IS NULL   
  END  
 END   
   
  
   
 IF (SELECT COUNT(journal_ctrl_num) FROM #gltrxedt1 WHERE controlling_org_id !=  detail_org_id AND company_code = rec_company_code) > 0  
 BEGIN  
  SELECT @error_code = 2046  
  EXEC    glerrdef_sp @error_code, @error_level OUTPUT  
   
  IF (@process_mode = 0 AND @error_level > 1) OR  
     (@process_mode = 1 AND @error_level > 2)  
  BEGIN  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
   INSERT INTO #hold   
   SELECT DISTINCT d.journal_ctrl_num, 2046, 0    
   FROM   #gltrxedt1 d  
    INNER JOIN OrganizationOrganizationDef ood ON d.controlling_org_id = ood.controlling_org_id AND d.detail_org_id = ood.detail_org_id AND d.account_code LIKE ood.account_mask  
   WHERE  d.controlling_org_id != d.detail_org_id  
   AND d.interbranch_flag = 1      
   AND   d.company_code = d.rec_company_code  -- Rev. 2.3  
   AND   d.seq_ref_id > 0  
   AND ood.controlling_org_id IS NULL    
  END  
 END  
  
   
  
   
 SELECT @error_code = 2050  
 EXEC    glerrdef_sp @error_code, @error_level OUTPUT  
  
 IF (@process_mode = 0 AND @error_level > 1) OR  
    (@process_mode = 1 AND @error_level > 2)  
 BEGIN  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  INSERT INTO #hold   
  SELECT DISTINCT journal_ctrl_num, 2050, 0    
  FROM   #gltrxedt1 d  
   LEFT JOIN apcash CS ON d.account_code = CS.cash_acct_code  
   INNER JOIN glchart CH ON d.account_code = CH.account_code  
  WHERE temp_flag = 0  
  AND   d.company_code = d.rec_company_code   -- Rev. 2.3  
  AND     CH.organization_id <> d.detail_org_id   
  AND CS.cash_acct_code IS NULL  
    
 END  
  
  
   
  
   
 SELECT @error_code = 2047  
 EXEC    glerrdef_sp @error_code, @error_level OUTPUT  
  
 IF (@process_mode = 0 AND @error_level > 1) OR  
    (@process_mode = 1 AND @error_level > 2)  
 BEGIN  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  INSERT INTO #hold   
  SELECT DISTINCT d.journal_ctrl_num, 2047, 0    
  FROM   #gltrxedt1 d  
   LEFT JOIN Organization org ON d.controlling_org_id = org.organization_id AND org.active_flag = 1  
  WHERE  org.organization_id IS NULL  
  
 END  
    
   
   
  
   
 SELECT @error_code = 2048  
 EXEC    glerrdef_sp @error_code, @error_level OUTPUT  
  
 IF (@process_mode = 0 AND @error_level > 1) OR  
    (@process_mode = 1 AND @error_level > 2)  
 BEGIN  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  INSERT INTO #hold   
  SELECT DISTINCT d.journal_ctrl_num, 2048, 0    
  FROM   #gltrxedt1 d  
   LEFT JOIN Organization org ON d.detail_org_id = org.organization_id AND org.active_flag = 1  
  WHERE  d.company_code = d.rec_company_code -- Rev. 2.3  
  AND org.organization_id IS NULL    
 END  
  
END  
ELSE  
BEGIN  
   
  
   
 SELECT @error_code = 2049  
 EXEC    glerrdef_sp @error_code, @error_level OUTPUT  
  
 IF (@process_mode = 0 AND @error_level > 1) OR  
    (@process_mode = 1 AND @error_level > 2)  
 BEGIN  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  INSERT INTO #hold   
  SELECT DISTINCT d.journal_ctrl_num, 2049, 0    
  FROM   #gltrxedt1 d  
  WHERE  d.company_code = d.rec_company_code -- Rev. 2.3  
  AND d.controlling_org_id != d.detail_org_id   
  
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
 FROM   #gltrxedt1 ed  
  INNER JOIN glco co ON ed.company_code <> co.company_code  
 WHERE  sequence_id = -1  
END  
  
  
  
  
SELECT @error_code = 2034  
EXEC    glerrdef_sp @error_code, @error_level OUTPUT  
  
IF (@process_mode = 0 AND @error_level > 1) OR  
   (@process_mode = 1 AND @error_level > 2)  
BEGIN  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
 INSERT INTO #hold   
 SELECT DISTINCT journal_ctrl_num, 2034, 0   
 FROM   #gltrxedt1 ed  
  LEFT JOIN gljtype j ON ed.journal_type = j.journal_type  
 WHERE   ed.sequence_id = -1  
 AND j.journal_type IS NULL  
END  
  
  
  
  
--UPDATE #gltrxedt1 SET temp_flag = 0   
  
  
  
  
  
  
  
UPDATE sysgen  
SET    sysgen.temp_flag = 1  
FROM   #gltrxedt1 sysgen, (SELECT *   
       FROM   #gltrxedt1  
       WHERE  offset_flag = 0  
       AND    sequence_id > -1  
       AND    rec_company_code <> company_code) usergen  
WHERE  sysgen.offset_flag = 1  
AND    sysgen.rec_company_code = sysgen.company_code  
AND    usergen.offset_flag = 0  
AND    usergen.sequence_id > -1  
AND    usergen.rec_company_code <> usergen.company_code  
AND    (sysgen.seq_ref_id = usergen.sequence_id OR  
 (sysgen.seq_ref_id = 0 AND sysgen.nat_cur_code = usergen.nat_cur_code  
  AND abs(sysgen.nat_balance - usergen.nat_balance) < 0.01))  
  
--DROP TABLE #gltrxedt   
  
  
  
  
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
 --EXEC gledtutl_sp   
 --THIS IS THE CONTENT OF THE gledtutl_sp PROCEDURE  
 DECLARE @min_sequence_id int  
  
 SELECT @min_sequence_id = MIN(ic.sequence_id)  
 FROM #gltrxedt1 ed, glcocodt_vw ic  
 WHERE ed.offset_flag = 0  
 AND ed.sequence_id > -1  
 AND ed.rec_company_code <> ed.company_code  
 AND  ed.company_code = ic.org_code  
 AND  ed.rec_company_code = ic.rec_code  
 AND ed.account_code LIKE ic.account_mask  
  
 SELECT ed.journal_ctrl_num journal_ctrl_num,  
  ed.sequence_id trx_id,  
  ic.sequence_id mask_id  
 INTO #mask_id  
 FROM #gltrxedt1 ed, glcocodt_vw ic  
 WHERE ed.offset_flag = 0  
 AND ed.sequence_id > -1  
 AND ed.rec_company_code <> ed.company_code  
 AND ed.company_code = ic.org_code  
 AND ed.rec_company_code = ic.rec_code  
 AND ed.account_code LIKE ic.account_mask  
 AND ic.sequence_id = @min_sequence_id  
 GROUP BY ed.account_code, ed.journal_ctrl_num,   
   ed.sequence_id, ic.sequence_id  
  
 UPDATE #gltrxedt1  
 SET temp_flag = mask_id  
 FROM #mask_id m, #gltrxedt1 ed  
 WHERE m.journal_ctrl_num = ed.journal_ctrl_num  
 AND m.trx_id = ed.sequence_id  
  
 DROP TABLE #mask_id  
 ----------------------------------------------------  
  
  
  
  
  
  
  
 UPDATE sysgen  
 SET    sysgen.temp_flag = 2  
 FROM   #gltrxedt1 sysgen, glcocodt_vw ic, (SELECT *   
            FROM   #gltrxedt1  
            WHERE  offset_flag = 0  
            AND    sequence_id > -1  
            AND    rec_company_code <> company_code) usergen  
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
 FROM   #gltrxedt1  
  INNER JOIN glco ON rec_company_code = glco.company_code  
 WHERE  sequence_id > -1  
 AND    offset_flag = 1  
 AND    temp_flag = 1  
  
 --DROP TABLE #gltrxedt2   
END  
  
  
  
  
  
INSERT INTO #hold   
 SELECT DISTINCT journal_ctrl_num, 6500, 0   
 FROM   #gltrxedt1 g  
  INNER JOIN ibifc ib  
   ON ib.link1 = g.journal_ctrl_num  
   --AND ib.state_flag  IN (-4 , -5)  
  
  
  
  
  
IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "gledldp_grp.cpp" + ", line " + STR( 872, 5 ) + " -- EXIT: "  
  
RETURN  
GO

GRANT EXECUTE ON  [dbo].[gledldp_grp_sp] TO [public]
GO
