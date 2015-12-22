SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

    
    CREATE PROC
[dbo].[imeinverr_sp] (@WhereClause VARCHAR(1000))
    AS
    EXEC imarint01_Errors_sp '', '', '', -1, 2031
GO
GRANT EXECUTE ON  [dbo].[imeinverr_sp] TO [public]
GO
