SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[pr_accumulators_sp] @contract_ctrl_num VARCHAR(16) = '',
				      @sequence_id INT = 0,
				      @customer_code VARCHAR(8) = '',
				      @vendor_code VARCHAR(12) = '',	-- SCR 2017
				      @rebate FLOAT = 0.0 OUTPUT,
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


DECLARE @type			INT
DECLARE @home_flag		INT
DECLARE @sequence		INT
DECLARE @customer_class		VARCHAR(8)
DECLARE @vendor_class		VARCHAR(8)
DECLARE @part_no		VARCHAR(30)
DECLARE @part_category		VARCHAR(10)
DECLARE @rebate1		FLOAT
DECLARE @qty			FLOAT
DECLARE @satisfied		INT
DECLARE @accumulator		VARCHAR(16)

SELECT @procedure_name = 'pr_accumulators_sp'


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
IF @debug_flag > 0 BEGIN SELECT 'customer_code'=@customer_code END
IF @debug_flag > 0 BEGIN SELECT 'vendor_code'=@vendor_code END
IF @debug_flag > 0 BEGIN SELECT 'rebate'=@rebate END
IF @debug_flag > 0 BEGIN SELECT 'userid'=@userid END
IF @debug_flag > 0 BEGIN SELECT 'debug_flag'=@debug_flag END

SELECT @rebate = 0.0

--
-- VALIDATE PARAMETERS
--
IF @customer_code = '' AND @vendor_code = ''
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='customer_code or vendor_code must contain a value' END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
END

IF @customer_code <> '' AND @vendor_code <> ''
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='Either customer_code or vendor_code must be blank' END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
END


SELECT @type = [type]
  FROM [pr_contracts]
 WHERE [contract_ctrl_num] = @contract_ctrl_num

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

IF @rowcount = 0
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='Contract could not be located in pr_contracts' END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
END

SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'CURRENCY'
SELECT @home_flag = 2
IF UPPER(@text_value) = 'HOME'
BEGIN
	SELECT @home_flag = 1
END
IF UPPER(@text_value) = 'OPER'
BEGIN
	SELECT @home_flag = 0
END

IF @home_flag = 2
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='Invalid value for CURRENCY config setting ' + @text_value END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
END

IF @customer_code <> ''
BEGIN
	SELECT @sequence = 0, @customer_class = ''

	SELECT @customer_class = [price_code]
	  FROM [arcustok_vw]
	 WHERE [customer_code] = @customer_code 

	SELECT @sequence = ISNULL([sequence_id],0)
	  FROM [pr_customers_vw]
	 WHERE [contract_ctrl_num] = @contract_ctrl_num
	   AND [customer_code] = @customer_code

	IF @sequence = 0
	BEGIN
		SELECT @sequence = ISNULL([sequence_id],0)
		  FROM [pr_customers_vw]
		 WHERE [contract_ctrl_num] = @contract_ctrl_num
		   AND [price_class] = @customer_class
	END

	IF @sequence = 0
	BEGIN
		IF @debug_flag > 0 BEGIN SELECT 'debug'='customer code is not part of the contract' END
		IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
	END
END


IF @vendor_code <> ''
BEGIN
	SELECT @sequence = 0, @vendor_class = ''

	SELECT @vendor_class = [vend_class_code]
	  FROM [apvendok_vw]
	 WHERE [vendor_code] = @vendor_code

	SELECT @sequence = ISNULL([sequence_id],0)
	  FROM [pr_vendors_vw]
	 WHERE [contract_ctrl_num] = @contract_ctrl_num
	   AND [vendor_code] = @vendor_code

	IF @sequence = 0
	BEGIN
		SELECT @sequence = ISNULL([sequence_id],0)
		  FROM [pr_vendors_vw]
		 WHERE [contract_ctrl_num] = @contract_ctrl_num
		   AND [vendor_class] = @vendor_class
	END

	IF @sequence = 0
	BEGIN
		IF @debug_flag > 0 BEGIN SELECT 'debug'='vendor code is not part of the contract' END
		IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
	END
END

--
-- See if this contract has any accumulators
--

IF NOT EXISTS (SELECT 1 FROM [pr_accumulator] WHERE [contract_ctrl_num] = @contract_ctrl_num)
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='Contract has no accumlators' END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=0 END RETURN 0
END

--
-- Check to see if a contract has been satisfied.
-- A contract is considered satisfied when all the parts associated
-- with the contracted have their highest level met AND
-- at least one part of each part category associated with 
-- the contract has been satisfied.
--
SELECT @part_no = ''
WHILE (42=42)
BEGIN
	SET ROWCOUNT 1

	SELECT @part_no = [part_no]
	  FROM [pr_parts_vw]
	 WHERE [contract_ctrl_num] = @contract_ctrl_num
	   AND [part_class_flag] = 0
	   AND [part_no] > @part_no
	 ORDER BY [part_no]
	SELECT @rowcount = @@ROWCOUNT

	SET ROWCOUNT 0

	IF @rowcount = 0
	BEGIN
		BREAK
	END

	SELECT @location = @procedure_name + ' - ' + 'Calling pr_event_rebate_sp for part_no' + ' at line ' + RTRIM(LTRIM(STR(225))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	EXEC @ret = pr_event_rebate_sp @contract_ctrl_num = @contract_ctrl_num,
				       @sequence_id = @sequence_id,
				       @customer_code = @customer_code,
				       @vendor_code = @vendor_code,
				       @part_no = @part_no,
				       @debug_flag = @debug_flag,
				       @userid = @userid,
				       @rebate = @rebate OUTPUT,
				       @qty = @qty OUTPUT,
				       @satisfied = @satisfied OUTPUT,
				       @called_by_accumulator = 1
	
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
		IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
	END

	IF @satisfied = 0
	BEGIN
		IF @debug_flag > 0 BEGIN SELECT 'debug'='Contract has not been satisfied, part' END
		SELECT @rebate = 0.00
		IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=0 END RETURN 0
	END
END

SELECT @part_category = ''
WHILE (42=42)
BEGIN
	SET ROWCOUNT 1
	
	SELECT @part_category = [part_category]
	  FROM [pr_parts_vw]
	 WHERE [contract_ctrl_num] = @contract_ctrl_num
	   AND [part_class_flag] = 1
	   AND [part_category] > @part_category
	 ORDER BY [part_category]
	SELECT @rowcount = @@ROWCOUNT

	SET ROWCOUNT 0

	IF @rowcount = 0
	BEGIN
		BREAK
	END

	--
	-- If there are no events in the pr_events table or the #pr_events table 
	-- for this part_category and contract, then bail because we know that it
	-- cannot be satisfied
	--
	IF NOT EXISTS (SELECT 1 FROM [pr_events] WHERE [contract_ctrl_num] = @contract_ctrl_num AND [part_category] = @part_category)
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM [#pr_events] WHERE [contract_ctrl_num] = @contract_ctrl_num AND [category] = @part_category)
		BEGIN
			IF @debug_flag > 0 BEGIN SELECT 'debug'='Contract has not been satisfied, part_category 1' END
			IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=0 END RETURN 0
		END
	END	

	SELECT @part_no = ''
	WHILE (42=42)
	BEGIN

		SET ROWCOUNT 1

		SELECT @part_no = [part_no]
		  FROM (SELECT [part_no] FROM [pr_events] WHERE [contract_ctrl_num] = @contract_ctrl_num AND [part_category] = @part_category
			UNION
			SELECT [part_no] FROM [#pr_events] WHERE [contract_ctrl_num] = @contract_ctrl_num AND [category] = @part_category) t
		 WHERE [part_no] > @part_no
		 ORDER BY [part_no]

		SET ROWCOUNT 0

		IF @rowcount = 0
		BEGIN
			BREAK
		END

		SELECT @location = @procedure_name + ' - ' + 'Calling pr_event_rebate_sp for part_no' + ' at line ' + RTRIM(LTRIM(STR(313))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		EXEC @ret = pr_event_rebate_sp @contract_ctrl_num = @contract_ctrl_num,
					       @sequence_id = @sequence_id,
					       @customer_code = @customer_code,
					       @vendor_code = @vendor_code,
					       @part_no = @part_no,
					       @debug_flag = @debug_flag,
					       @userid = @userid,
					       @rebate = @rebate OUTPUT,
					       @qty = @qty OUTPUT,
					       @satisfied = @satisfied OUTPUT,
					       @called_by_accumulator = 1
		
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
			IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
		END

		IF @satisfied = 1
		BEGIN
			BREAK
		END
	END

	IF @satisfied = 0
	BEGIN
		IF @debug_flag > 0 BEGIN SELECT 'debug'='Contract has not been satisfied, part_category 2' END
		SELECT @rebate = 0.00
		IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=0 END RETURN 0
	END
END







SELECT @accumulator = '', @rebate = 0.0
WHILE (42=42)
BEGIN
	SET ROWCOUNT 1
	SELECT @accumulator = [accumulator],
		@sequence = [sequence_id]
	  FROM [pr_accumulator]
	 WHERE [contract_ctrl_num] = @contract_ctrl_num
	   AND [accumulator] > @accumulator
	 ORDER BY [accumulator]
	SELECT @rowcount = @@ROWCOUNT

	SET ROWCOUNT 0

	IF @rowcount = 0
	BEGIN
		BREAK
	END

	SELECT @part_no = ''
	WHILE(42=42)
	BEGIN
		SET ROWCOUNT 1
		SELECT @part_no = [part_no]
		  FROM [pr_parts_vw]
		 WHERE [contract_ctrl_num] = @accumulator
		   AND [part_no] > @part_no
		 ORDER BY [part_no]
		SELECT @rowcount = @@ROWCOUNT

		SET ROWCOUNT 0

		IF @rowcount = 0
		BEGIN
			BREAK
		END

		SELECT @location = @procedure_name + ' - ' + 'Calling pr_event_rebate_sp for part_no' + ' at line ' + RTRIM(LTRIM(STR(396))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		EXEC @ret = pr_event_rebate_sp @contract_ctrl_num = @accumulator,
					       @sequence_id = @sequence_id,
					       @customer_code = @customer_code,
					       @vendor_code = @vendor_code,
					       @part_no = @part_no,
					       @debug_flag = @debug_flag,
					       @userid = @userid,
					       @rebate = @rebate1 OUTPUT,
					       @qty = @qty OUTPUT,
					       @satisfied = @satisfied OUTPUT,
					       @called_by_accumulator = 1,
					       @parent = @contract_ctrl_num
		
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
			IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
		END	

		SELECT @location = @procedure_name + ' - ' + 'INSERT INTO #pr_accumulators' + ' at line ' + RTRIM(LTRIM(STR(423))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO [#pr_accumulators] ([contract_ctrl_num], [sequence_id], [accumulator], [customer_code],
						[vendor_code], [part_no], [amount_rebate], [flag])
		  SELECT @contract_ctrl_num, @sequence, @accumulator, @customer_code, 
			 @vendor_code, @part_no, @rebate1, 0
		
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


		IF @debug_flag > 0
		BEGIN
			SELECT RTRIM(LTRIM(STR(@rebate + @rebate1))) + ' = ' + RTRIM(LTRIM(STR(@rebate))) + ' + ' + RTRIM(LTRIM(STR(@rebate1)))
		END
		SELECT @rebate = @rebate + @rebate1	
	END
END



-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=0 END RETURN 0
GO
GRANT EXECUTE ON  [dbo].[pr_accumulators_sp] TO [public]
GO
