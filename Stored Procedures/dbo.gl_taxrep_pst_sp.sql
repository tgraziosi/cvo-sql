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
            CREATE PROCEDURE [dbo].[gl_taxrep_pst_sp] @posted_by smallint, @ret_val smallint OUTPUT 
AS BEGIN DECLARE @today int  IF (@posted_by IS NULL)  BEGIN  SET @ret_val = 2  RETURN @ret_val 
 END SET @ret_val = 0  EXEC appdate_sp @today OUTPUT  BEGIN TRAN  INSERT gl_taxrep_hdr_hst 
(
 start_date,  end_date,  date_generated,  generated_by,  report_cur,  date_posted, 
 posted_by 
)
SELECT  start_date,  end_date,  date_generated,  generated_by,  report_cur,  @today, 
 @posted_by FROM  gl_taxrep_hdr IF (@@error <> 0 )  BEGIN  ROLLBACK TRAN  SET @ret_val = 1 
 RETURN @ret_val  END DELETE  gl_taxrep_hdr  INSERT gl_taxrep_dtl_hst 
(
 trx_ctrl_num,  doc_ctrl_num,  start_date,  tax_box_code,  tax_type_code,  trx_type 
)
SELECT  td.trx_ctrl_num,  td.doc_ctrl_num,  td.start_date,  td.tax_box_code,  td.tax_type_code, 
 td.trx_type FROM  gl_taxrep_dtl td JOIN gl_taxrep_hdr_hst thh  ON td.start_date = thh.start_date 
IF (@@error <> 0 )  BEGIN  ROLLBACK TRAN  SET @ret_val = 1  RETURN @ret_val  END 
DELETE  gl_taxrep_dtl COMMIT TRAN RETURN @ret_val END 
GO
GRANT EXECUTE ON  [dbo].[gl_taxrep_pst_sp] TO [public]
GO
