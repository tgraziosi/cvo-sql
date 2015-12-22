SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[pr_get_price_sp] @cust VARCHAR(10), 
				   @shipto VARCHAR(10),
				   @clevel CHAR(1), 
				   @pn VARCHAR(30),
 				   @loc VARCHAR(10), 
				   @plevel CHAR(1),
 				   @qty MONEY, 
				   @pct MONEY,
 				   @curr_key VARCHAR(10), 
				   @curr_factor DECIMAL(20,8),
				   @svc_agr CHAR(1),
				   @promo_type CHAR(1) OUTPUT,
				   @promo_rate decimal(20,8) OUTPUT,
				   @dt DATETIME OUTPUT,
				   @promo_start_date DATETIME OUTPUT,
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

DECLARE @category		VARCHAR(10)
DECLARE @contract_ctrl_num	VARCHAR(16)
DECLARE @percent		INT
DECLARE @rebate			DECIMAL(20,8)
DECLARE @create_pp_table	INT
DECLARE @level			INT
DECLARE @to_range		FLOAT
DECLARE @from_range		FLOAT
DECLARE @next_rebate		FLOAT
DECLARE @source			INT

SELECT @procedure_name = 'pr_get_price_sp'


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



IF @debug_flag > 0
BEGIN
	SELECT 'cust'=@cust, 'shipto'=@shipto, 'clevel'=@clevel, 'pn'=@pn, 'loc'=@loc, 'plevel'=@plevel,
		'qty'=@qty, 'pct'=@pct, 'curr_key'=@curr_key, 'curr_factor'=@curr_factor, 'svc_agr'=@svc_agr,
		'promo_type'=@promo_type, 'promo_rate'=@promo_rate, 'dt'=@dt, 'promo_start_date'=@promo_start_date,
		'debug_flag'=@debug_flag
END

SELECT @category = [category]
  FROM [inv_master]
 WHERE [part_no] = @pn

SELECT @location = @procedure_name + ' - ' + 'Create #possible_price table' + ' at line ' + RTRIM(LTRIM(STR(51))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
SELECT @create_pp_table = 0
IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#possible_price') IS NULL)
BEGIN
	SELECT @create_pp_table = 1
	CREATE TABLE [#possible_price] (
		[contract_ctrl_num]		VARCHAR(16) NULL,
		[part_number]			VARCHAR(30) NULL,
		[description]			VARCHAR(255) NULL,
		[quantity_purchased_to_date]	FLOAT NULL,
		[amount_purchased_to_date]	FLOAT NULL,
		[unit_price]			FLOAT NULL,
		[next_quantity_break]		FLOAT NULL,
		[next_unit_price]		FLOAT NULL,
		[rebate]			FLOAT NULL,
		[level]				INT NULL,
		[next_rebate]			FLOAT NULL,
		[rebate_percent_flag]		INT NULL
	)
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END
ELSE
BEGIN
	SELECT @location = @procedure_name + ' - ' + 'Truncating possible_price' + ' at line ' + RTRIM(LTRIM(STR(74))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	TRUNCATE TABLE [#possible_price]
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

SELECT @location = @procedure_name + ' - ' + 'Populate #possible_price' + ' at line ' + RTRIM(LTRIM(STR(79))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#possible_price] ([contract_ctrl_num], [part_number], [description], [quantity_purchased_to_date],
				[amount_purchased_to_date], [unit_price], [next_quantity_break], [next_unit_price], [rebate], 
				[level], [next_rebate], [rebate_percent_flag])
  SELECT '', @pn, [description], 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0, 0.00, 0
    FROM [inv_master]
   WHERE [part_no] = @pn

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Create #pr_events' + ' at line ' + RTRIM(LTRIM(STR(88))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#pr_events') IS NULL) 
BEGIN
	DROP TABLE [#pr_events]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

CREATE TABLE [#pr_events] (
	[contract_ctrl_num]		VARCHAR(16) NULL,
	[amount]			FLOAT NULL,
	[qty]				FLOAT NULL )

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Create #pr_levels' + ' at line ' + RTRIM(LTRIM(STR(101))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#pr_levels') IS NULL) 
BEGIN
	DROP TABLE [#pr_levels]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

CREATE TABLE [#pr_levels] (
	[contract_ctrl_num]		VARCHAR(16) NULL,
	[level]				INT NULL,
	[rebate]			FLOAT NULL,
	[percent]			INT NULL,
	[amount]			FLOAT NULL,
	[to_range]			FLOAT NULL,
	[source]			INT NULL )

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Populate #pr_events' + ' at line ' + RTRIM(LTRIM(STR(118))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#pr_events] ([contract_ctrl_num], [amount], [qty])
  SELECT e.[contract_ctrl_num], SUM([source_gross_amount]) - SUM([source_discount_amount]), SUM([source_qty_shipped])
    FROM [pr_events] e, [pr_contracts] c
   WHERE c.[type] = 1
     AND e.[contract_ctrl_num] = c.[contract_ctrl_num]
     AND e.[part_no] = @pn
     AND e.[customer_code] = @cust
     AND e.[void_flag] = 0
     AND c.[status] = 0
   GROUP BY e.[contract_ctrl_num]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


IF @rowcount = 0
BEGIN
	
-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=0 END RETURN 0
END

SELECT @location = @procedure_name + ' - ' + 'Add in current request to amount' + ' at line ' + RTRIM(LTRIM(STR(137))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#pr_events]
   SET [amount] = [amount] + (([amount]/[qty]) * @qty)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Add in current request to qty' + ' at line ' + RTRIM(LTRIM(STR(142))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#pr_events]
   SET [qty] = [qty] + @qty

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Populate #pr_levels from pr_part_levels' + ' at line ' + RTRIM(LTRIM(STR(147))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#pr_levels] ([contract_ctrl_num], [level], [rebate], [percent], [amount], [to_range], [source])
  SELECT e.[contract_ctrl_num], l.[level], l.[rebate], p.[percent_flag], 0.0, l.[to_range], 0
    FROM [#pr_events] e, [pr_part_levels] l, [pr_parts] p
   WHERE e.[contract_ctrl_num] = l.[contract_ctrl_num]
     AND l.[part_no] = @pn
     AND e.[contract_ctrl_num] = p.[contract_ctrl_num]
     AND p.[part_no] = @pn
     AND ((p.[percent_flag] = 0 
		AND ((e.[qty] >= l.[from_range] AND e.[qty] < l.[to_range]) OR (e.[qty] >= l.[from_range] AND l.[to_range] = 0)))
	   OR
          (p.[percent_flag] = 1 
		AND ((e.[amount] >= l.[from_range] AND e.[amount] < l.[to_range]) OR (e.[amount] >= l.[from_range] AND l.[to_range] = 0))))

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Populate #pr_levels from pr_category_levels' + ' at line ' + RTRIM(LTRIM(STR(162))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#pr_levels] ([contract_ctrl_num], [level], [rebate], [percent], [amount], [to_range], [source])
  SELECT e.[contract_ctrl_num], l.[level], l.[rebate], p.[percent_flag], 0.0, l.[to_range], 1
    FROM [#pr_events] e, [pr_category_levels] l, [pr_part_category] p
   WHERE e.[contract_ctrl_num] = l.[contract_ctrl_num]
     AND l.[part_category] = @category
     AND e.[contract_ctrl_num] = p.[contract_ctrl_num]
     AND p.[part_category] = @category
     AND ((p.[percent_flag] = 0 
		AND ((e.[qty] >= l.[from_range] AND e.[qty] < l.[to_range]) OR (e.[qty] >= l.[from_range] AND l.[to_range] = 0)))
	   OR
          (p.[percent_flag] = 1 
		AND ((e.[amount] >= l.[from_range] AND e.[amount] < l.[to_range]) OR (e.[amount] >= l.[from_range] AND l.[to_range] = 0))))

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Set #pr_levels.amount 1' + ' at line ' + RTRIM(LTRIM(STR(177))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#pr_levels]
   SET [amount] = [rebate]
 WHERE [percent] = 0

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Set #pr_levels.amount 2' + ' at line ' + RTRIM(LTRIM(STR(183))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#pr_levels]
   SET [amount] = ([rebate]/100) * (e.[amount]/e.[qty])
  FROM [#pr_levels] l, [#pr_events] e
 WHERE l.[percent] = 1
   AND l.[contract_ctrl_num] = e.[contract_ctrl_num]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @rowcount = COUNT(*) 
  FROM [#pr_levels]

IF @rowcount = 0
BEGIN
	
-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=0 END RETURN 0
END

IF @debug_flag > 0
BEGIN
	SELECT 'DUMPING #pr_events and #pr_levels'
	SELECT * FROM [#pr_events] ORDER BY [contract_ctrl_num]
	SELECT * FROM [#pr_levels] ORDER BY [contract_ctrl_num]
END

SET ROWCOUNT 1
SELECT @percent = [percent], @rebate = [rebate], @contract_ctrl_num = [contract_ctrl_num], @level = [level], @to_range = [to_range], @source = [source]
  FROM [#pr_levels]
 ORDER BY [amount] DESC
SET ROWCOUNT 0

IF @percent = 0
BEGIN
	SELECT @promo_type = 'X'
END
ELSE
BEGIN
	SELECT @promo_type = 'D'
END
SELECT @promo_rate = @rebate
SELECT @dt = CONVERT(VARCHAR(10),(DATEADD(dd,[end_date]-693594,'12/30/1899')),101),
       @promo_start_date = CONVERT(VARCHAR(10),(DATEADD(dd,[start_date]-693594,'12/30/1899')),101)
  FROM [pr_contracts]
 WHERE [contract_ctrl_num] = @contract_ctrl_num

IF @debug_flag > 0
BEGIN
	SELECT 'promo_type'=@promo_type, 'promo_rate'=@promo_rate, 'dt'=@dt, 'promo_start_date'=@promo_start_date, 'to_range'=@to_range, 'source'=@source
END

--
-- Determine next price break
--
IF @source = 0
BEGIN
	SELECT @from_range = -1
	SET ROWCOUNT 1
	SELECT @from_range = [from_range], @next_rebate = [rebate]
	  FROM [pr_part_levels]
	 WHERE [contract_ctrl_num] = @contract_ctrl_num
	   AND [level] > @level
	 ORDER BY [level]
	SET ROWCOUNT 0

	IF @from_range = -1
	BEGIN
		SELECT @from_range = 0, @next_rebate = @rebate
	END
END
ELSE
BEGIN
	SELECT @from_range = -1
	SET ROWCOUNT 1
	SELECT @from_range = [from_range], @next_rebate = [rebate]
	  FROM [pr_category_level]
	 WHERE [contract_ctrl_num] = @contract_ctrl_num
	   AND [level] > @level
	 ORDER BY [level]
	SET ROWCOUNT 0

	IF @from_range = -1
	BEGIN
		SELECT @from_range = 0, @next_rebate = @rebate
	END
END

SELECT @location = @procedure_name + ' - ' + 'Update possible_price - 1' + ' at line ' + RTRIM(LTRIM(STR(268))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_price]
   SET [contract_ctrl_num] = @contract_ctrl_num,
	[level] = @level,
	[rebate] = @rebate,
	[rebate_percent_flag] = @percent,
	[quantity_purchased_to_date] = [amount],
	[amount_purchased_to_date] = [qty],
	[unit_price] = 0.00,
	[next_quantity_break] = @from_range,
	[next_unit_price] = 0.00,
	[next_rebate] = @next_rebate
  FROM [#pr_events] pe
 WHERE pe.[contract_ctrl_num] = @contract_ctrl_num

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


IF @debug_flag > 0
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='Dumping #possible_price' END
	SELECT * FROM [#possible_price]
END

IF @create_pp_table = 1
BEGIN
	SELECT @location = @procedure_name + ' - ' + 'Drop possible_price table' + ' at line ' + RTRIM(LTRIM(STR(292))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	DROP TABLE [#possible_price]
	
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
GRANT EXECUTE ON  [dbo].[pr_get_price_sp] TO [public]
GO
