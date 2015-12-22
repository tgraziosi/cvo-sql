SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[pr_next_range_sp] @range_in VARCHAR(3000),
				    @start    INT OUTPUT,
				    @range_out VARCHAR(3000) OUTPUT,
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

DECLARE @i1	INT
DECLARE @i2	INT

SELECT @procedure_name = 'pr_next_range_sp'


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

IF @debug_flag > 0 BEGIN SELECT 'range_in'=@range_in END
IF @debug_flag > 0 BEGIN SELECT 'start'=@start END
IF @debug_flag > 0 BEGIN SELECT 'debug_flag'=@debug_flag END

SELECT @len = DATALENGTH(@range_in)
IF @start >= @len
BEGIN
	SELECT @start = 0
	SELECT @buf = 'Start (' + RTRIM(LTRIM(STR(@start))) + ') is >= length (' + RTRIM(LTRIM(STR(@len))) + ')'
	IF @debug_flag > 0 BEGIN SELECT 'debug'=@buf END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=1 END RETURN 1
END

SELECT @i1 = CHARINDEX('( (', @range_in, @start)
IF @i1 = 0
BEGIN	
	SELECT @start = 0
	IF @debug_flag > 0 BEGIN SELECT 'debug'='No more ranges' END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=1 END RETURN 1
END

SELECT @i2 = CHARINDEX(') )', @range_in, @i1)
IF @i2 = 0
BEGIN
	SELECT @buf = 'Invalid range ' + RTRIM(LTRIM(STR(@i1))) + ' ' + SUBSTRING(@range_in, @i1, 200)
	IF @debug_flag > 0 BEGIN SELECT 'debug'=@buf END
	SELECT @start = 0
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=1 END RETURN 1
END
SELECT @i2 = @i2 + 3

SELECT @range_out = SUBSTRING(@range_in, @i1, @i2 - @i1)
SELECT @start = @i2
IF @debug_flag > 0 BEGIN SELECT 'start'=@start END
IF @debug_flag > 0 BEGIN SELECT 'i1'=@i1 END
IF @debug_flag > 0 BEGIN SELECT 'i2'=@i2 END
IF @debug_flag > 0 BEGIN SELECT 'range_out'=@range_out END
IF @debug_flag > 0 BEGIN SELECT 'start'=@start END


-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=0 END RETURN 0

GO
GRANT EXECUTE ON  [dbo].[pr_next_range_sp] TO [public]
GO
