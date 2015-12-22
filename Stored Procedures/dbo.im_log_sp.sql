SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

       
    CREATE PROCEDURE [dbo].[im_log_sp] @IL_Text NVARCHAR(1000), 
                               @IL_Log_Activity VARCHAR(10),
                               @im_log_sp_User_ID INT = 0
    AS
    --
    -- Insert a record into the Import Manager log
    --
    IF @IL_Log_Activity <> 'YES'
        RETURN 0
    INSERT INTO [imlog] ([now],
                         [text],
                         [User_ID])
            VALUES (GETDATE(), 
                    @IL_Text,
                    @im_log_sp_User_ID)
    IF @@ROWCOUNT = 1
        BEGIN
        RETURN 0
        END
    ELSE
        BEGIN
        RETURN -1
        END
GO
GRANT EXECUTE ON  [dbo].[im_log_sp] TO [public]
GO
