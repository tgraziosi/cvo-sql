SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

       
    CREATE PROCEDURE 
[dbo].[im_log_sp_error_sp] @ILSE_Error_Code INT,
                   @ILSE_SP_Name NVARCHAR(200),
                   @ILSE_String NVARCHAR(200) ,
                   @ILSE_Procedure_Name VARCHAR(200),
                   @ILSE_Log_Activity VARCHAR(10),
                   @im_log_sp_error_sp_User_ID INT = 0
    AS
    --
    -- Log an sp fatal return (into the Import Manager log).
    --
    DECLARE @Text_String NVARCHAR(250)
    DECLARE @Text_String_1 NVARCHAR(250)
    DECLARE @Text_String_2 NVARCHAR(250)
    DECLARE @Text_String_3 NVARCHAR(250)
    DECLARE @Text_String_4 NVARCHAR(250)
    --
    EXEC CVO_Control..im_get_external_string_sp 'sp error part 1',
                                             @Text_String_1 OUT
    EXEC CVO_Control..im_get_external_string_sp 'sp error part 2',
                                             @Text_String_2 OUT
    EXEC CVO_Control..im_get_external_string_sp 'sp error part 3',
                                             @Text_String_3 OUT
    EXEC CVO_Control..im_get_external_string_sp 'sp error part 4',
                                             @Text_String_4 OUT
    SET @Text_String = @Text_String_1 + ' ''' + ISNULL(@ILSE_SP_Name, 'UNKNOWN') + ''' ' + @Text_String_2 + ' ''' + ISNULL(@ILSE_Procedure_Name, 'UNKNOWN') + ''' ' + @Text_String_3 + ' ''' + ISNULL(@ILSE_String, '') + '''' + @Text_String_4 + ' ''' + CAST(@ILSE_Error_Code AS VARCHAR(20)) + ''''
    EXEC im_log_sp @Text_String,
                   @ILSE_Log_Activity,
                   @im_log_sp_error_sp_User_ID
    
GO
GRANT EXECUTE ON  [dbo].[im_log_sp_error_sp] TO [public]
GO
