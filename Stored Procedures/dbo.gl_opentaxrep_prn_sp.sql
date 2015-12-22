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
            CREATE PROCEDURE [dbo].[gl_opentaxrep_prn_sp] @report_date int, @report_cur smallint, 
@now int AS DECLARE @ret_val int BEGIN     BEGIN TRAN  EXEC gl_opentaxrep_ar_prn_sp @report_date, 
 @report_cur,  @ret_val OUTPUT  IF (@ret_val <> 0)  BEGIN  IF (@ret_val = 2) ROLLBACK TRAN 
 RETURN  END EXEC gl_opentaxrep_ap_prn_sp @report_date,  @report_cur,  @ret_val OUTPUT 
 IF (@ret_val <> 0)  BEGIN  IF (@ret_val = 2) ROLLBACK TRAN  RETURN  END COMMIT TRAN 
END 
GO
GRANT EXECUTE ON  [dbo].[gl_opentaxrep_prn_sp] TO [public]
GO
