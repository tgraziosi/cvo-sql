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
            CREATE PROCEDURE [dbo].[gl_open_taxrep_pst_sp] @posted_by smallint, @ret_val smallint OUTPUT 
AS BEGIN DECLARE @today int  IF (@posted_by IS NULL)  BEGIN  SET @ret_val = 2  RETURN @ret_val 
 END SET @ret_val = 0  EXEC appdate_sp @today OUTPUT  BEGIN TRAN  INSERT gl_taxrep_open_hdr_hst 
(
 report_date,  start_date,  end_date,  date_generated,  date_posted,  generated_by, 
 posted_by,  report_cur 
)
SELECT  report_date,  start_date,  end_date,  date_generated,  @today,  generated_by, 
 @posted_by,  report_cur FROM  gl_taxrep_open_hdr IF (@@error <> 0 )  BEGIN  ROLLBACK TRAN 
 SET @ret_val = 1  RETURN @ret_val  END DELETE  gl_taxrep_open_hdr  INSERT gl_taxrep_open_dtl_hst 
(
 trx_ctrl_num,  doc_ctrl_num,  report_date,  start_date,  tax_box_code,  tax_type_code, 
 trx_type 
)
SELECT  trx_ctrl_num,  doc_ctrl_num,  report_date,  start_date,  tax_box_code,  tax_type_code, 
 trx_type FROM  gl_taxrep_open_dtl IF (@@error <> 0 )  BEGIN  ROLLBACK TRAN  SET @ret_val = 1 
 RETURN @ret_val  END DELETE  gl_taxrep_open_dtl COMMIT TRAN RETURN @ret_val END 
GO
GRANT EXECUTE ON  [dbo].[gl_open_taxrep_pst_sp] TO [public]
GO
