SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

    
    CREATE PROC
[dbo].[imedmerr_sp] (@WhereClause VARCHAR(1000))
    AS
    EXEC imapint01_Errors_sp '', '', '', -1, 4092
GO
GRANT EXECUTE ON  [dbo].[imedmerr_sp] TO [public]
GO
