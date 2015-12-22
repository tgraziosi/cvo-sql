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
            CREATE PROCEDURE [dbo].[gl_taxrep_prn_sp] @start_date int, @end_date int, @now int 
AS DECLARE @ret_val int BEGIN IF (NOT EXISTS (SELECT * FROM gl_taxrep_hdr_hst WHERE start_date = @start_date)) 
 return BEGIN TRAN  EXEC gl_taxrep_ar_prn_sp @start_date, @ret_val OUTPUT  IF (@ret_val <> 0) 
 BEGIN  IF (@ret_val = 2) ROLLBACK TRAN  RETURN  END EXEC gl_taxrep_ap_prn_sp @start_date, @ret_val OUTPUT 
 IF (@ret_val <> 0)  BEGIN  IF (@ret_val = 2) ROLLBACK TRAN  RETURN  END COMMIT TRAN 
END 
GO
GRANT EXECUTE ON  [dbo].[gl_taxrep_prn_sp] TO [public]
GO
