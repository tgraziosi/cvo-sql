SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

       
    CREATE PROCEDURE [dbo].[icv_Hexadecimal_sp]
        @binvalue varbinary(255),
        @hexvalue varchar(255) OUTPUT
    AS
    -- Converts a binary HRESULT value returned from sp_OAx procedures
    -- to a character value (for display).
    --
    DECLARE @charvalue varchar(255)
    DECLARE @i int
    DECLARE @length int
    DECLARE @hexstring char(16)
    SELECT @charvalue = '0x'
    SELECT @i = 1
    SELECT @length = DATALENGTH(@binvalue)
    SELECT @hexstring = '0123456789abcdef'
    WHILE (@i <= @length)
        BEGIN
        DECLARE @tempint int
        DECLARE @firstint int
        DECLARE @secondint int
        SELECT @tempint = CONVERT(int, 
                                  SUBSTRING(@binvalue, @i, 1))
        SELECT @firstint = FLOOR(@tempint/16)
        SELECT @secondint = @tempint - (@firstint * 16)
        SELECT @charvalue = @charvalue +
                            SUBSTRING(@hexstring, @firstint + 1, 1) +
                            SUBSTRING(@hexstring, @secondint + 1, 1)
        SELECT @i = @i + 1
    END
    SELECT @hexvalue = @charvalue

GO
GRANT EXECUTE ON  [dbo].[icv_Hexadecimal_sp] TO [public]
GO
