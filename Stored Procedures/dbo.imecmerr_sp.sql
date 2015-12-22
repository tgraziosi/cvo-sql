SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

    
    CREATE PROC
[dbo].[imecmerr_sp] (@WhereClause VARCHAR(1000))
    AS
    EXEC imarint01_Errors_sp '', '', '', -1, 2032
GO
GRANT EXECUTE ON  [dbo].[imecmerr_sp] TO [public]
GO
