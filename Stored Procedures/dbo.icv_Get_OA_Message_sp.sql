SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

       
    CREATE PROCEDURE 
[dbo].[icv_Get_OA_Message_sp]
        @SIGOM_Object int,
        @SIGOM_Message varchar(255) OUTPUT
    AS
    -- Returns the text message related to the last OA error message that was 
    -- registered for the specified object.
    -- to a character value (for display).
    --
    DECLARE @hr int
    DECLARE @source varchar(255)
    
    EXEC @hr = sp_OAGetErrorInfo @SIGOM_Object, 
                                 @source OUT, 
                                 @SIGOM_Message OUT
    RETURN @hr

GO
GRANT EXECUTE ON  [dbo].[icv_Get_OA_Message_sp] TO [public]
GO
