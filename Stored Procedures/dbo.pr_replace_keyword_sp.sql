SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[pr_replace_keyword_sp] @sql AS vARCHAR(255) OUTPUT,
					 @token AS VARCHAR(255),
					 @value AS VARCHAR(255),
					 @debug_flag INT = 0 AS



-- #include "STANDARD DECLARES.INC"



























































































DECLARE @rowcount		INT
DECLARE @error			INT
DECLARE @errmsg			VARCHAR(128)
DECLARE @log_activity		VARCHAR(128)
DECLARE @procedure_name		VARCHAR(128)
DECLARE @location		VARCHAR(128)
DECLARE @buf			VARCHAR(3000)
DECLARE @ret			INT
DECLARE @text_value		VARCHAR(255)
DECLARE @int_value		INT
DECLARE @return_value		INT
DECLARE @transaction_started	INT
DECLARE @len			INT
DECLARE @i			INT
DECLARE @today			INT

-- end "STANDARD DECLARES.INC"

DECLARE @l	INT
DECLARE @s	VARCHAR(255)

SELECT @procedure_name = 'pr_replace_keyword_sp'


-- #include "STANDARD ENTRY.INC"
SET NOCOUNT ON SELECT @location = 'Standard entry get config value' SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @today = DATEDIFF(DD,'1/1/80',GETDATE())+722815

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

IF @debug_flag > 0 BEGIN SELECT 'PS_SIGNAL'='DIAGNOSTIC ON' END SELECT @buf = 'Entering ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Entry'=@buf END SELECT @return_value = 0, @transaction_started = 0
-- end "STANDARD ENTRY.INC"


SELECT @s = @sql, @l = LEN(@token), @i = CHARINDEX(@token, @sql, 1)

WHILE (@i <> 0)
BEGIN
	SELECT @s = SUBSTRING(@s, 1, @i-1) + @value + SUBSTRING(@s, @i + @l, LEN(@s))
	SELECT @i = CHARINDEX(@token, @s, 1)
END

SELECT @sql = @s


-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"


GO
GRANT EXECUTE ON  [dbo].[pr_replace_keyword_sp] TO [public]
GO
