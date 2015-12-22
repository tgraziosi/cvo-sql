SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

       
    CREATE PROCEDURE 
[dbo].[icv_Get_External_String_sp]
        @SIGES_String_Name varchar(255),
        @SIGES_String varchar(255) OUTPUT
    AS
    -- Retrieve an external string
    --
    -- RETURN values:
    --     -1001          Retrieval failed
    --
    SELECT @SIGES_String = CONVERT(varchar(255), string_value) FROM icv_strings WHERE string_name = @SIGES_String_Name
    IF @@ROWCOUNT = 1
        BEGIN
        RETURN 0
        END
    ELSE
        BEGIN
        SELECT @SIGES_String = @SIGES_String_Name
        END

GO
GRANT EXECUTE ON  [dbo].[icv_Get_External_String_sp] TO [public]
GO
