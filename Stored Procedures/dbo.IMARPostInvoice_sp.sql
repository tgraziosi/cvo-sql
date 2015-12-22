SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

 
    CREATE PROC 
[dbo].[IMARPostInvoice_sp] @db_userid char(40), 
                   @db_password char(40), 
                   @invoice_flag smallint, 
                   @debug_level smallint, 
                   @perf_level smallint,
                   @pcn varchar(16) OUTPUT,
                   @userid INT = 0,
                   @IMARPostInvoice_sp_Application_Name VARCHAR(30) = 'Import Manager',
                   @IMARPostInvoice_sp_User_Name VARCHAR(30) = '',
                   @IMARPostInvoice_sp_TPS_int_value INT = NULL
    AS   
    IF @debug_level >= 3
        SELECT '(3): IMARPostInvoice_sp: Posting procedures have not been installed.'   
    RETURN    
GO
GRANT EXECUTE ON  [dbo].[IMARPostInvoice_sp] TO [public]
GO
