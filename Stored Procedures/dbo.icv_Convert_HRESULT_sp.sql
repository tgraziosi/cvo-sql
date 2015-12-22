SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

  
    CREATE PROCEDURE 
[dbo].[icv_Convert_HRESULT_sp]
        @hresult int,
        @textresult char(10) OUTPUT
    AS
    -- Converts an HRESULT (error) returned from sp_OAx procedures.
    --
    DECLARE @output varchar(255)
    DECLARE @hrhex char(10)
    DECLARE @hr int
    DECLARE @source varchar(255)
    DECLARE @description varchar(255)
    EXEC icv_Hexadecimal_sp @hresult, 
                            @textresult OUT

GO
GRANT EXECUTE ON  [dbo].[icv_Convert_HRESULT_sp] TO [public]
GO
