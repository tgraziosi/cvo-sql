SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC 
[dbo].[IMAPPostVoucher_sp] @db_userid char(40), 
                   @db_password char(40), 
                   @invoice_flag smallint, 
                   @debug_level smallint, 
                   @perf_level smallint,
                   @pcn varchar(16) OUTPUT,
                   @userid INT = 0,
                   @IMAPPostVoucher_sp_Application_Name VARCHAR(30) = 'Import Manager',
                   @IMAPPostVoucher_sp_User_Name VARCHAR(30) = '',
                   @IMAPPostVoucher_sp_TPS_int_value INT = NULL
    AS    
    IF @debug_level >= 3
        SELECT '(3): IMAPPostVoucher_sp: Posting procedures have not been installed.'  
    RETURN    
GO
GRANT EXECUTE ON  [dbo].[IMAPPostVoucher_sp] TO [public]
GO
