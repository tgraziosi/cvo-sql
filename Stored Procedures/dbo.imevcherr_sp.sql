SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

    
    CREATE PROC
[dbo].[imevcherr_sp] (@WhereClause VARCHAR(1000))
    AS
    EXEC imapint01_Errors_sp '', '', '', -1, 4091
GO
GRANT EXECUTE ON  [dbo].[imevcherr_sp] TO [public]
GO
