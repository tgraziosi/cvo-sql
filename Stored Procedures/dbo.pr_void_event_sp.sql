SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[pr_void_event_sp] @contract_ctrl_num VARCHAR(16) = '',
				    @sequence_id INT = 0,
				    @void_flag INT = -1,
				    @userid INT = 0,
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


DECLARE @current_void_flag	INT
DECLARE @date_applied		INT
DECLARE @sid			INT
DECLARE @customer_code		VARCHAR(8)
DECLARE @vendor_code		VARCHAR(12)
DECLARE @part_no		VARCHAR(30)
DECLARE @oper_rebate		FLOAT
DECLARE @home_rebate		FLOAT
DECLARE @qty			FLOAT

SELECT @procedure_name = 'pr_void_event_sp'


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

IF @debug_flag > 0 BEGIN SELECT 'contract_ctrl_num'=@contract_ctrl_num END
IF @debug_flag > 0 BEGIN SELECT 'sequence_id'=@sequence_id END
IF @debug_flag > 0 BEGIN SELECT 'userid'=@userid END
IF @debug_flag > 0 BEGIN SELECT 'debug_flag'=@debug_flag END


IF @contract_ctrl_num = ''
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='contract_ctrl_num must contain a value' END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
END

IF @sequence_id <= 0
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='sequence_id must be greater than zero' END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
END

IF @void_flag = -1
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='void_flag must be zero or one' END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
END

IF EXISTS (SELECT 1 FROM [pr_events] WHERE [contract_ctrl_num] = @contract_ctrl_num AND [sequence_id] = @sequence_id)
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='Requested event does not exist in pr_events' END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
END

SELECT 	@current_void_flag = [void_flag],
	@date_applied = [source_apply_date],
	@customer_code = [customer_code],
	@vendor_code = [vendor_code],
	@part_no = [part_no]
  FROM	[pr_events]
 WHERE	[contract_ctrl_num] = @contract_ctrl_num
   AND 	[sequence_id] = @sequence_id

IF @current_void_flag = @void_flag
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='Void flag not changed' END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=0 END RETURN 0
END

SELECT @location = @procedure_name + ' - ' + 'set void flag' + ' at line ' + RTRIM(LTRIM(STR(71))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [pr_events]
   SET [void_flag] = @void_flag
 WHERE [contract_ctrl_num] = @contract_ctrl_num
   AND [sequence_id] = @sequence_id

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @sid = 0
WHILE (42=42)
BEGIN
	SET ROWCOUNT 1
	SELECT @sid = [sequence_id]
	  FROM [pr_events]
	 WHERE [contract_ctrl_num] = @contract_ctrl_num
	   AND [source_apply_date] >= @date_applied
	   AND [customer_code] = @customer_code
	   AND [vendor_code] = @vendor_code
	   AND [part_no] = @part_no
	   AND [sequence_id] > @sid
	 ORDER BY [sequence_id]
	SELECT @rowcount = @@ROWCOUNT

	SET ROWCOUNT 0

	IF @rowcount = 0
	BEGIN
		BREAK
	END

	SELECT @location = @procedure_name + ' - ' + 'CALL pr_event_rebate_sp for customer home' + ' at line ' + RTRIM(LTRIM(STR(100))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	EXEC @ret = [pr_event_rebate_sp] @contract_ctrl_num, @sequence_id, @customer_code, @vendor_code, @part_no, @debug_flag, @userid, @home_rebate OUTPUT, @qty OUTPUT, 1

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	IF @ret <> 0
	BEGIN
		
-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

		SELECT @text_value = '*UNKNOWN' SELECT @text_value = text_value FROM pr_strings WHERE id = 1 -- '*ERROR: <0> returned <1> at "<2>"'
		SELECT @buf = RTRIM(LTRIM(STR(@ret)))
		EXEC pr_replace_keyword_sp @text_value OUTPUT, '<0>', 'pr_event_rebate_sp'
		EXEC pr_replace_keyword_sp @text_value OUTPUT, '<1>', @buf
		EXEC pr_replace_keyword_sp @text_value OUTPUT, '<2>', @location
		SELECT @buf = @text_value
		RAISERROR (@buf,16,1)
		RETURN -1
	END

	SELECT @location = @procedure_name + ' - ' + 'CALL pr_event_rebate_sp for customer oper' + ' at line ' + RTRIM(LTRIM(STR(117))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	EXEC @ret = [pr_event_rebate_sp] @contract_ctrl_num, @sequence_id, @customer_code, @vendor_code, @part_no, @debug_flag, @userid, @oper_rebate OUTPUT, @qty OUTPUT, 0

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	IF @ret <> 0
	BEGIN
		
-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

		SELECT @text_value = '*UNKNOWN' SELECT @text_value = text_value FROM pr_strings WHERE id = 1 -- '*ERROR: <0> returned <1> at "<2>"'
		SELECT @buf = RTRIM(LTRIM(STR(@ret)))
		EXEC pr_replace_keyword_sp @text_value OUTPUT, '<0>', 'pr_event_rebate_sp'
		EXEC pr_replace_keyword_sp @text_value OUTPUT, '<1>', @buf
		EXEC pr_replace_keyword_sp @text_value OUTPUT, '<2>', @location
		SELECT @buf = @text_value
		RAISERROR (@buf,16,1)
		RETURN -1
	END

	SELECT @location = @procedure_name + ' - ' + 'Update rebate amounts in #pr_events' + ' at line ' + RTRIM(LTRIM(STR(134))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE [#pr_events]
	   SET  [home_rebate_amount] = @home_rebate,
		[oper_rebate_amount] = @oper_rebate
	 WHERE	[contract_ctrl_num] = @contract_ctrl_num
	   AND	[sequence_id] = @sequence_id

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


END


-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"


GO
GRANT EXECUTE ON  [dbo].[pr_void_event_sp] TO [public]
GO
