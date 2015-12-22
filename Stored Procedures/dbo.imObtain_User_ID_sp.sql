SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


    CREATE PROC
[dbo].[imObtain_User_ID_sp] @imObtain_User_ID_sp_Module VARCHAR(16) = '',
                    @imObtain_User_ID_sp_User_ID INT OUTPUT,
                    @imObtain_User_ID_sp_User_Name VARCHAR(30) OUTPUT,
                    @userid INT = 0,
                    @imObtain_User_ID_sp_Override_User_Name VARCHAR(30) = ''
    AS
    -- 
    -- Retrieve user ID.
    --
    -- If SUSER_SNAME() returns a string containing a backslash, then the user name
    -- is a Windows login name and not a SQL Server login name.
    --
    DECLARE @External_String NVARCHAR(1000)
    DECLARE @OBTAIN_USERID_BCI INT
    DECLARE @OBTAIN_USERID_User_Name VARCHAR(256)
    DECLARE @OBTAIN_USERID_User_Name_30 VARCHAR(30)
    DECLARE @OBTAIN_USERID_User_ID INT
    DECLARE @SQL NVARCHAR(1000)
    --
    IF DATALENGTH(LTRIM(RTRIM(ISNULL(@imObtain_User_ID_sp_Override_User_Name, '')))) = 0
        SELECT @OBTAIN_USERID_User_Name = SUSER_SNAME()    
    ELSE
        SET @OBTAIN_USERID_User_Name = @imObtain_User_ID_sp_Override_User_Name   
    SELECT @OBTAIN_USERID_BCI = CHARINDEX('\', @OBTAIN_USERID_User_Name)
    IF @OBTAIN_USERID_BCI > 0
        BEGIN
        SET @OBTAIN_USERID_User_Name = SUBSTRING(@OBTAIN_USERID_User_Name, @OBTAIN_USERID_BCI + 1, LEN(@OBTAIN_USERID_User_Name) - @OBTAIN_USERID_BCI)
        END
    SET @OBTAIN_USERID_User_Name_30 = RTRIM(LEFT(@OBTAIN_USERID_User_Name, 30))
    SET @OBTAIN_USERID_User_Name = RTRIM(@OBTAIN_USERID_User_Name_30)
    SET @OBTAIN_USERID_User_ID = 0
    SELECT @OBTAIN_USERID_User_ID = LTRIM(RTRIM(ISNULL([user_id], 0))),
           @OBTAIN_USERID_User_Name = LTRIM(RTRIM([user_name])) 
            FROM [CVO_Control]..[smusers]
            WHERE UPPER(LTRIM(RTRIM([user_name]))) = UPPER(@OBTAIN_USERID_User_Name)
    IF @OBTAIN_USERID_User_ID = 0
        BEGIN
        EXEC [CVO_Control]..[im_get_external_string_sp] @IGES_String_Name = 'user id unobtainable', 
                                                     @IGES_String = @External_String OUT 
        SET @SQL = 'INSERT INTO [imlog] ([now], [module], [text], [User_ID]) VALUES (GETDATE(), ''' + @imObtain_User_ID_sp_Module + ''', N''' + @External_String + @OBTAIN_USERID_User_Name + ''', ' + CAST(@userid AS VARCHAR) + ')' 
        EXEC (@SQL)
        RETURN -1
        END
    SET @imObtain_User_ID_sp_User_ID = @OBTAIN_USERID_User_ID
    SET @imObtain_User_ID_sp_User_Name = @OBTAIN_USERID_User_Name
    RETURN 0    
GO
GRANT EXECUTE ON  [dbo].[imObtain_User_ID_sp] TO [public]
GO
