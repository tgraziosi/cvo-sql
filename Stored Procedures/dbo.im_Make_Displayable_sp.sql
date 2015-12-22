SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

    CREATE PROCEDURE
[dbo].[im_Make_Displayable_sp](@IMD_Input_String VARCHAR(8000),
                       @IMD_Output_String VARCHAR(8000) OUTPUT)
    AS
    DECLARE @CHAR_Value SMALLINT
    DECLARE @Work_String VARCHAR(8000)
    --
    SET @CHAR_Value = -1
    SET @Work_String = @IMD_Input_String
    WHILE @CHAR_Value < 32
        BEGIN
        SET @CHAR_Value = @CHAR_Value + 1
        SET @Work_String = REPLACE(@Work_String, CHAR(@CHAR_Value), '*')
        END
    SET @IMD_Output_String = @Work_String
    RETURN
GO
GRANT EXECUTE ON  [dbo].[im_Make_Displayable_sp] TO [public]
GO
