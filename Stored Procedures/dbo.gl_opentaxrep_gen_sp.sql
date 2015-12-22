SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*
              Confidential Information
   Limited Distribution of Authorized Persons Only
   Created 1996 and Protected as Unpublished Work
         Under the U.S. Copyright Act of 1976
Copyright (c) 1996 Platinum Software Corporation, 1996
                 All Rights Reserved 
 */
            CREATE PROCEDURE [dbo].[gl_opentaxrep_gen_sp] @report_date int, @report_cur smallint, 
@now int, @user_name varchar(30) AS DECLARE @min_date int, @max_date int, @start_date int, 
@end_date int, @ret_val int, @user_id smallint BEGIN BEGIN TRAN DELETE  gl_taxrep_open_dtl 
DELETE  gl_taxrep_open_hdr  SELECT  @user_id = user_id FROM  glusers_vw WHERE  user_name = LTRIM(RTRIM(@user_name )) 
 EXEC gl_opentaxrep_ar_gen_sp @report_date, @report_cur, @ret_val OUTPUT IF (@ret_val <> 0) 
 BEGIN  IF (@ret_val = 2) ROLLBACK TRAN  RETURN  END EXEC gl_opentaxrep_ap_gen_sp @report_date, @report_cur, @ret_val OUTPUT 
IF (@ret_val <> 0)  BEGIN  IF (@ret_val = 2) ROLLBACK TRAN  RETURN  END SELECT  @min_date = MIN(date_applied), 
 @max_date = MAX(date_applied) FROM  #gl_opentaxrep SELECT  @start_date = MAX( period_start_date ), 
 @end_date = MIN( period_end_date ) FROM  gl_gltaxprd WHERE  @min_date BETWEEN period_start_date AND 
 period_end_date  OR  @max_date BETWEEN period_start_date AND  period_end_date IF ((@start_date IS NULL) OR (@end_date IS NULL)) 
BEGIN  ROLLBACK TRAN  return 0 END IF ((EXISTS (SELECT * FROM #gl_opentaxrep))  AND (NOT EXISTS (SELECT * FROM gl_taxrep_open_hdr_hst WHERE start_date = @start_date))) 
INSERT INTO gl_taxrep_open_hdr 
(
 report_date,  start_date,  end_date,  date_generated,  generated_by,  report_cur 
)
VALUES 
(
 @report_date,  @start_date,  @end_date,  @now,  @user_id,  @report_cur 
)
INSERT gl_taxrep_open_dtl 
(
 trx_ctrl_num,  doc_ctrl_num,  report_date,  start_date,  tax_box_code,  tax_type_code, 
 trx_type 
)
SELECT  trx_ctrl_num,  doc_ctrl_num,  @report_date,  @start_date,  tax_box_code, 
 tax_type_code,  trx_type FROM  #gl_opentaxrep COMMIT TRAN END 
GO
GRANT EXECUTE ON  [dbo].[gl_opentaxrep_gen_sp] TO [public]
GO
