SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[pr_rebate_totals_sp] @include_posted			INT = 1,
				       @debug_flag 			INT = 0,
				       @userid				INT = 0 AS



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


DECLARE @create_pr_events		INT


SELECT @procedure_name = 'pr_rebate_totals_sp'


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

IF @debug_flag > 0 BEGIN SELECT 'include_posted'=@include_posted END
IF @debug_flag > 0 BEGIN SELECT 'debug_flag'=@debug_flag END
IF @debug_flag > 0 BEGIN SELECT 'userid'=@userid END

--*****
--** CREATE TEMP TABLES
--*****

SELECT @create_pr_events = 0
IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#pr_events') IS NULL) 
BEGIN
	SELECT @location = @procedure_name + ' - ' + 'Create #pr_events' + ' at line ' + RTRIM(LTRIM(STR(99))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	CREATE TABLE [#pr_events] (
		[contract_ctrl_num]		VARCHAR(16) NOT NULL,
		[sequence_id]			INT NOT NULL,
		[process_ctrl_num]		VARCHAR(16) NOT NULL,
		[post_date]			INT NOT NULL,
		[customer_code]			VARCHAR(8) NOT NULL,
		[price_class]			VARCHAR(8) NULL,
		[na_parent_code]		VARCHAR(8) NOT NULL,
		[vendor_code]			VARCHAR(12) NOT NULL,
		[vendor_class]			VARCHAR(8) NULL,
		[part_no]			VARCHAR(30) NOT NULL,
		[category]			VARCHAR(10) NULL,
		[source_trx_ctrl_num]		VARCHAR(16) NOT NULL,
		[source_sequence_id]		INT NOT NULL,
		[source_doc_ctrl_num]		VARCHAR(16) NOT NULL,
		[source_trx_type]		INT NOT NULL,
		[source_apply_date]		INT NOT NULL,
		[source_qty_shipped]		FLOAT NOT NULL,
		[source_unit_price]		FLOAT NOT NULL,
		[source_gross_amount]		FLOAT NOT NULL,
		[source_discount_amount]	FLOAT NOT NULL,
		[amount_adjusted]		FLOAT NOT NULL,
		[void]				INT NOT NULL,
		[nat_cur_code]			VARCHAR(8) NOT NULL,
		[rate_type_home]		VARCHAR(8) NOT NULL,
		[rate_type_oper]		VARCHAR(8) NOT NULL,
		[rate_home]			FLOAT NOT NULL,
		[rate_oper]			FLOAT NOT NULL,
		[home_amount]			FLOAT NOT NULL,
		[oper_amount]			FLOAT NOT NULL,
		[home_adjusted]			FLOAT NOT NULL,
		[oper_adjusted]			FLOAT NOT NULL,
		[userid]			INT NOT NULL,
		[home_rebate_amount]		FLOAT NOT NULL,
		[oper_rebate_amount]		FLOAT NOT NULL,
		[home_amt_cost]			FLOAT NOT NULL,
		[oper_amt_cost]			FLOAT NOT NULL,
		[kit_multiplier]		FLOAT NOT NULL,
		[kit_part_no]			VARCHAR(30) NOT NULL,
		[source_amt_cost]		FLOAT NOT NULL)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @create_pr_events = 1
END

--
-- Calculate rebate totals for customer, vendors and parts
--
SELECT @location = @procedure_name + ' - ' + 'Total customers' + ' at line ' + RTRIM(LTRIM(STR(148))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#pr_customers] ([contract_ctrl_num], [customer_code], [customer_class], [amount_rebate_oper], [amount_rebate_home], [flag])
  SELECT [contract_ctrl_num], [customer_code], MIN([price_class]), SUM([home_rebate_amount]), SUM([oper_rebate_amount]), 0
    FROM (SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], 'category'=[part_category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type] FROM [pr_events] WHERE [void_flag] = 0 AND 1 = @include_posted
	   UNION ALL
    	  SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], [category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type] FROM [#pr_events] WHERE [void] = 0 ) t
   WHERE ISNULL(DATALENGTH(RTRIM(LTRIM([customer_code]))),0) > 0
   GROUP BY [contract_ctrl_num], [customer_code]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Total customer class' + ' at line ' + RTRIM(LTRIM(STR(158))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#pr_customers] ([contract_ctrl_num], [customer_code], [customer_class], [amount_rebate_oper], [amount_rebate_home], [flag])
  SELECT [contract_ctrl_num], MIN([customer_code]), [price_class], SUM([home_rebate_amount]), SUM([oper_rebate_amount]), 1
    FROM (SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], 'category'=[part_category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type], [void_flag] FROM [pr_events] WHERE [void_flag] = 0 AND 1 = @include_posted
	   UNION ALL
     	  SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], [category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type], [void] FROM [#pr_events] WHERE [void] = 0 ) t
   WHERE ISNULL(DATALENGTH(RTRIM(LTRIM([price_class]))),0) > 0
   GROUP BY [contract_ctrl_num], [price_class]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Total vendors' + ' at line ' + RTRIM(LTRIM(STR(168))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#pr_vendors] ([contract_ctrl_num], [vendor_code], [vendor_class], [amount_rebate_oper], [amount_rebate_home], [flag])
  SELECT [contract_ctrl_num], [vendor_code], MIN([vendor_class]), SUM([home_rebate_amount]), SUM([oper_rebate_amount]), 0
    FROM (SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], 'category'=[part_category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type], [void_flag] FROM [pr_events] WHERE [void_flag] = 0 AND 1 = @include_posted
	   UNION ALL
    	  SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], [category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type], [void] FROM [#pr_events] WHERE [void] = 0 ) t
   WHERE ISNULL(DATALENGTH(RTRIM(LTRIM([vendor_code]))),0) > 0
   GROUP BY [contract_ctrl_num], [vendor_code]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Total vendor class' + ' at line ' + RTRIM(LTRIM(STR(178))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#pr_vendors] ([contract_ctrl_num], [vendor_code], [vendor_class], [amount_rebate_oper], [amount_rebate_home], [flag])
  SELECT [contract_ctrl_num], MIN([vendor_code]), [vendor_class], SUM([home_rebate_amount]), SUM([oper_rebate_amount]), 1
    FROM (SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], 'category'=[part_category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type], [void_flag] FROM [pr_events] WHERE [void_flag] = 0 AND 1 = @include_posted
	   UNION ALL
    	  SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], [category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type], [void] FROM [#pr_events] WHERE [void] = 0 ) t
   WHERE ISNULL(DATALENGTH(RTRIM(LTRIM([vendor_class]))),0) > 0
   GROUP BY [contract_ctrl_num], [vendor_class]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Total parts - 2030' + ' at line ' + RTRIM(LTRIM(STR(188))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#pr_parts] ([contract_ctrl_num], [part_no], [part_category], [trx_type], [amount_rebate_oper], [amount_rebate_home], [flag])
  SELECT [contract_ctrl_num], [part_no], MIN([category]), 2030, SUM([home_rebate_amount]), SUM([oper_rebate_amount]), 0
    FROM (SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], 'category'=[part_category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type], [void_flag] FROM [pr_events] WHERE [void_flag] = 0 AND 1 = @include_posted
	   UNION ALL
    	  SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], [category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type], [void] FROM [#pr_events] WHERE [void] = 0 ) t
   WHERE [source_trx_type] IN (2031,2032)
     AND ISNULL(DATALENGTH(RTRIM(LTRIM([part_no]))),0) > 0
   GROUP BY [contract_ctrl_num], [part_no]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Total part category - 2030' + ' at line ' + RTRIM(LTRIM(STR(199))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#pr_parts] ([contract_ctrl_num], [part_no], [part_category], [trx_type], [amount_rebate_oper], [amount_rebate_home], [flag])
  SELECT [contract_ctrl_num], MIN([part_no]), [category], 2030, SUM([home_rebate_amount]), SUM([oper_rebate_amount]), 1
    FROM (SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], 'category'=[part_category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type], [void_flag] FROM [pr_events] WHERE [void_flag] = 0 AND 1 = @include_posted
	   UNION ALL
    	  SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], [category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type], [void] FROM [#pr_events] WHERE [void] = 0 ) t
   WHERE ISNULL(DATALENGTH(RTRIM(LTRIM([category]))),0) > 0
     AND [source_trx_type] IN (2031,2032)
   GROUP BY [contract_ctrl_num], [category]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Total parts - 4090' + ' at line ' + RTRIM(LTRIM(STR(210))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#pr_parts] ([contract_ctrl_num], [part_no], [part_category], [trx_type], [amount_rebate_oper], [amount_rebate_home], [flag])
  SELECT [contract_ctrl_num], [part_no], MIN([category]), 4090, SUM([home_rebate_amount]), SUM([oper_rebate_amount]), 0
    FROM (SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], 'category'=[part_category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type], [void_flag] FROM [pr_events] WHERE [void_flag] = 0 AND 1 = @include_posted
	   UNION ALL
    	  SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], [category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type], [void] FROM [#pr_events] WHERE [void] = 0 ) t
   WHERE [source_trx_type] IN (4091,4092)
   GROUP BY [contract_ctrl_num], [part_no]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Total part category - 4090' + ' at line ' + RTRIM(LTRIM(STR(220))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#pr_parts] ([contract_ctrl_num], [part_no], [part_category], [trx_type], [amount_rebate_oper], [amount_rebate_home], [flag])
  SELECT [contract_ctrl_num], MIN([part_no]), [category], 4090, SUM([home_rebate_amount]), SUM([oper_rebate_amount]), 1
    FROM (SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], 'category'=[part_category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type], [void_flag] FROM [pr_events] WHERE [void_flag] = 0 AND 1 = @include_posted
	   UNION ALL
    	  SELECT [contract_ctrl_num], [customer_code], [price_class], [vendor_code], [vendor_class], [part_no], [category], [home_rebate_amount], [oper_rebate_amount], [source_trx_type], [void] FROM [#pr_events] WHERE [void] = 0 ) t
   WHERE ISNULL(DATALENGTH(RTRIM(LTRIM([category]))),0) > 0
     AND [source_trx_type] IN (4091,4092)
   GROUP BY [contract_ctrl_num], [category]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



IF @create_pr_events = 1
BEGIN
	DROP TABLE [#pr_events]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

	SELECT @create_pr_events = 0
END


-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=0 END RETURN 0

GO
GRANT EXECUTE ON  [dbo].[pr_rebate_totals_sp] TO [public]
GO
