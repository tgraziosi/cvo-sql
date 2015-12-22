SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[pr_posting_sp] @range				VARCHAR(1000) = '',
				 @exclude_promotions 		INT = 0,
				 @exclude_rebates 		INT = 0,
				 @exclude_2031 			INT = 0,
				 @exclude_2032 			INT = 0,
				 @exclude_4091 			INT = 0,
				 @exclude_4092 			INT = 0,
				 @table_name			VARCHAR(255) = 'pr_posting',
				 @trial_flag			INT = 1,
				 @debug_flag 			INT = 0,
				 @userid			INT = 0,
				 @id				VARCHAR(36) = '' OUTPUT AS



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


DECLARE @min_apply_date		INT
DECLARE @max_apply_date		INT
DECLARE @max_grace_date		INT

DECLARE @trx_ctrl_num		VARCHAR(16)
DECLARE @sequence_id		INT
DECLARE	@customer_code 		VARCHAR(8)
DECLARE	@vendor_code		VARCHAR(12)		-- SCR 2017
DECLARE	@part_no		VARCHAR(30)
DECLARE	@doc_ctrl_num		VARCHAR(16)
DECLARE	@trx_type		INT 
DECLARE	@apply_date		INT 
DECLARE	@qty			FLOAT 
DECLARE	@unit_price		FLOAT 
DECLARE	@gross_amount		FLOAT 
DECLARE	@discount_amount	FLOAT 
DECLARE	@flag			INT 

DECLARE @process_ctrl_num	VARCHAR(16)
DECLARE @process_description	VARCHAR(40)
DECLARE @process_user_id	INT
DECLARE @process_parent_app	INT
DECLARE @process_parent_company	VARCHAR(8)
DECLARE @process_type		INT

DECLARE @contract_ctrl_num	VARCHAR(16)
DECLARE @home_rebate		FLOAT
DECLARE @oper_rebate		FLOAT
DECLARE @source_trx_type 	INT
DECLARE @customer_class		VARCHAR(8)
DECLARE @vendor_class		VARCHAR(8)
DECLARE @part_category		VARCHAR(10)

DECLARE @sql			VARCHAR(3000)

DECLARE @range_out		VARCHAR(3000)
DECLARE @start			INT

DECLARE @currency_flag		INT

SELECT @procedure_name = 'pr_posting_sp'


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

IF @debug_flag > 0 BEGIN SELECT 'range'=@range END
IF @debug_flag > 0 BEGIN SELECT 'exclude_promotions'=@exclude_promotions END
IF @debug_flag > 0 BEGIN SELECT 'exclude_rebates'=@exclude_rebates END
IF @debug_flag > 0 BEGIN SELECT 'exclude_2031'=@exclude_2031 END
IF @debug_flag > 0 BEGIN SELECT 'exclude_2032'=@exclude_2032 END
IF @debug_flag > 0 BEGIN SELECT 'exclude_4091'=@exclude_4091 END
IF @debug_flag > 0 BEGIN SELECT 'exclude_4092'=@exclude_4092 END
IF @debug_flag > 0 BEGIN SELECT 'debug_flag'=@debug_flag END
IF @debug_flag > 0 BEGIN SELECT 'userid'=@userid END
IF @debug_flag > 0 BEGIN SELECT 'id'=@id END
IF @debug_flag > 0 BEGIN SELECT 'table_name'=@table_name END
IF @debug_flag > 0 BEGIN SELECT 'trial_flag'=@trial_flag END

IF @id = ''
BEGIN
	SELECT @id = NEWID()
END

--*****
--** CREATE TEMP TABLES
--*****

SELECT @location = @procedure_name + ' - ' + 'Create #pr_events' + ' at line ' + RTRIM(LTRIM(STR(85))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
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
	[contract_ctrl_num]		VARCHAR(16) NOT NULL,
	[sequence_id]			INT NOT NULL,
	[process_ctrl_num]		VARCHAR(16) NOT NULL,
	[post_date]			INT NOT NULL,
	[customer_code]			VARCHAR(8) NOT NULL,
	[price_class]			VARCHAR(8) NULL,
	[na_parent_code]		VARCHAR(8) NOT NULL,
	[vendor_code]			VARCHAR(12) NOT NULL,		-- SCR 2017
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
	[source_amt_cost]		FLOAT NOT NULL,
	[all_parts_flag]		INT NOT NULL,
	[flag]				INT NOT NULL
)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Create #possible_events' + ' at line ' + RTRIM(LTRIM(STR(137))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#possible_events') IS NULL) 
BEGIN
	DROP TABLE [#possible_events]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

CREATE TABLE [#possible_events] (
	[customer_code] 		VARCHAR(8) NULL,
	[customer_class]		VARCHAR(8) NULL,
	[vendor_code]			VARCHAR(12) NULL,		-- SCR 2017
	[vendor_class]			VARCHAR(8) NULL,
	[part_no]			VARCHAR(30) NULL,
	[part_category]			VARCHAR(10) NULL,
	[trx_ctrl_num]			VARCHAR(16) NULL,
	[doc_ctrl_num]			VARCHAR(16) NULL,
	[sequence_id]			INT NULL,
	[trx_type]			INT NULL,
	[apply_date]			INT NULL,
	[qty]				FLOAT NULL,
	[unit_price]			FLOAT NULL,
	[gross_amount]			FLOAT NULL,
	[discount_amount]		FLOAT NULL,
	[nat_cur_code]			VARCHAR(8) NOT NULL,
	[rate_type_home]		VARCHAR(8) NOT NULL,
	[rate_type_oper]		VARCHAR(8) NOT NULL,
	[rate_home]			FLOAT NOT NULL,
	[rate_oper]			FLOAT NOT NULL,
	[flag]				INT NULL,
	[amt_cost]			FLOAT NULL,
	[kit_multiplier]		FLOAT NULL,
	[kit_part_no]			VARCHAR(30) NULL,
	[source_amt_cost]		FLOAT NULL,
	[all_parts_flag]		INT NULL				-- inclusive contracts
)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @location = @procedure_name + ' - ' + 'Create #possible_customers' + ' at line ' + RTRIM(LTRIM(STR(175))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#possible_customers') IS NULL) 
BEGIN
	DROP TABLE [#possible_customers]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

CREATE TABLE [#possible_customers] (
	[customer_code] 		VARCHAR(8) NULL,
	[customer_class]		VARCHAR(8) NULL,
	[flag]				INT NULL
)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"




SELECT @location = @procedure_name + ' - ' + 'Create #possible_vendors' + ' at line ' + RTRIM(LTRIM(STR(191))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#possible_vendors') IS NULL) 
BEGIN
	DROP TABLE [#possible_vendors]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

CREATE TABLE [#possible_vendors] (
	[vendor_code] 			VARCHAR(12) NULL,		-- SCR 2017
	[vendor_class]			VARCHAR(8) NULL,
	[flag]				INT NULL
)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

	


SELECT @location = @procedure_name + ' - ' + 'Create #possible_parts' + ' at line ' + RTRIM(LTRIM(STR(207))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#possible_parts') IS NULL) 
BEGIN
	DROP TABLE [#possible_parts]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

CREATE TABLE [#possible_parts] (
	[part_no] 			VARCHAR(30) NULL,
	[part_category]			VARCHAR(10) NULL,
	[status]			VARCHAR(1) NULL,
	[flag]				INT NULL,
	[kit_multiplier]		FLOAT NULL,
	[kit_part_no]			VARCHAR(30) NULL,
	[all_parts_flag]		INT NULL			-- inclusive contracts flag
)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

	


SELECT @location = @procedure_name + ' - ' + 'Create #possible_contracts' + ' at line ' + RTRIM(LTRIM(STR(227))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#possible_contracts') IS NULL) 
BEGIN
	DROP TABLE [#possible_contracts]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

CREATE TABLE [#possible_contracts] (
	[contract_ctrl_num] 		VARCHAR(16) NULL,
	[start_date]			INT NULL,
	[end_date]			INT NULL,
	[grace_date]			INT NULL,
	[all_parts_flag]		INT NULL,			-- inclusive contracts flag
	[type]				INT NULL,
	[flag]				INT NULL
)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	

SELECT @location = @procedure_name + ' - ' + 'Create #pr_customers' + ' at line ' + RTRIM(LTRIM(STR(247))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#pr_customers') IS NULL) 
BEGIN
	DROP TABLE [#pr_customers]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

CREATE TABLE [#pr_customers] (
	[contract_ctrl_num] 		VARCHAR(16) NULL,
	[customer_code]			VARCHAR(8) NULL,
	[customer_class]		VARCHAR(8) NULL,
	[amount_rebate_oper]		FLOAT NULL,
	[amount_rebate_home]		FLOAT NULL,
	[flag]				INT NULL
)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	

SELECT @location = @procedure_name + ' - ' + 'Create #pr_vendors' + ' at line ' + RTRIM(LTRIM(STR(266))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#pr_vendors') IS NULL) 
BEGIN
	DROP TABLE [#pr_vendors]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

CREATE TABLE [#pr_vendors] (
	[contract_ctrl_num] 		VARCHAR(16) NULL,
	[vendor_code]			VARCHAR(12) NULL,		-- SCR 2017
	[vendor_class]			VARCHAR(8) NULL,
	[amount_rebate_oper]		FLOAT NULL,
	[amount_rebate_home]		FLOAT NULL,
	[flag]				INT NULL
)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	

SELECT @location = @procedure_name + ' - ' + 'Create #pr_parts' + ' at line ' + RTRIM(LTRIM(STR(285))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#pr_parts') IS NULL) 
BEGIN
	DROP TABLE [#pr_parts]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

CREATE TABLE [#pr_parts] (
	[contract_ctrl_num] 		VARCHAR(16) NULL,
	[part_no]			VARCHAR(30) NULL,
	[part_category]			VARCHAR(10) NULL,
	[trx_type]			INT NULL,
	[amount_rebate_oper]		FLOAT NULL,
	[amount_rebate_home]		FLOAT NULL,
	[flag]				INT NULL
)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	

SELECT @location = @procedure_name + ' - ' + 'Create #pr_accumulators' + ' at line ' + RTRIM(LTRIM(STR(305))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#pr_accumulators') IS NULL) 
BEGIN
	DROP TABLE [#pr_accumulators]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

CREATE TABLE [#pr_accumulators] (
	[contract_ctrl_num] 		VARCHAR(16) NULL,
	[sequence_id]			INT NULL,
	[accumulator]			VARCHAR(16) NULL,
	[customer_code]			VARCHAR(8) NULL,
	[vendor_code]			VARCHAR(12) NULL,		-- SCR 2017
	[part_no]			VARCHAR(30) NULL,
	[amount_rebate]			FLOAT NULL,
	[flag]				INT NULL
)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

	


SELECT @location = @procedure_name + ' - ' + 'Create #ranges' + ' at line ' + RTRIM(LTRIM(STR(326))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#range') IS NULL) 
BEGIN
	DROP TABLE [#ranges]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

CREATE TABLE [#ranges] (
	[type] 				INT NULL,
	[range]				VARCHAR(3000) NULL
)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


--*****
--** PARSE THE RANGE
--*****

SELECT @ret = 0, @start=0, @range_out=''
WHILE 42=42
BEGIN
	EXEC @ret = pr_next_range_sp @range, @start OUTPUT, @range_out OUTPUT, @debug_flag

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

	
	IF @ret < 0
	BEGIN
		
-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

		SELECT @text_value = '*UNKNOWN' SELECT @text_value = text_value FROM pr_strings WHERE id = 1 -- '*ERROR: <0> returned <1> at "<2>"'
		SELECT @buf = RTRIM(LTRIM(STR(@ret)))
		EXEC pr_replace_keyword_sp @text_value OUTPUT, '<0>', 'pr_next_range_sp'
		EXEC pr_replace_keyword_sp @text_value OUTPUT, '<1>', @buf
		EXEC pr_replace_keyword_sp @text_value OUTPUT, '<2>', @location
		SELECT @buf = @text_value
		RAISERROR (@buf,16,1)
		RETURN -1
	END

	IF @ret = 1
	BEGIN
		BREAK
	END

	IF CHARINDEX('contract_num.', @range_out, 0) > 0 BEGIN EXEC pr_replace_keyword_sp @range_out OUTPUT, 'contract_num.', '', @debug_flag EXEC pr_replace_keyword_sp @range_out OUTPUT, '"', '''', @debug_flag IF NOT EXISTS (SELECT 1 FROM [#ranges] WHERE [type] = 1) INSERT INTO [#ranges] VALUES (1, @range_out) CONTINUE END	
	IF CHARINDEX('customer_code.', @range_out, 0) > 0 BEGIN EXEC pr_replace_keyword_sp @range_out OUTPUT, 'customer_code.', '', @debug_flag EXEC pr_replace_keyword_sp @range_out OUTPUT, '"', '''', @debug_flag IF NOT EXISTS (SELECT 1 FROM [#ranges] WHERE [type] = 2) INSERT INTO [#ranges] VALUES (2, @range_out) CONTINUE END	
	IF CHARINDEX('customer_class.', @range_out, 0) > 0 BEGIN EXEC pr_replace_keyword_sp @range_out OUTPUT, 'customer_class.', '', @debug_flag EXEC pr_replace_keyword_sp @range_out OUTPUT, '"', '''', @debug_flag IF NOT EXISTS (SELECT 1 FROM [#ranges] WHERE [type] = 3) INSERT INTO [#ranges] VALUES (3, @range_out) CONTINUE END	
	IF CHARINDEX('vendor_code.', @range_out, 0) > 0 BEGIN EXEC pr_replace_keyword_sp @range_out OUTPUT, 'vendor_code.', '', @debug_flag EXEC pr_replace_keyword_sp @range_out OUTPUT, '"', '''', @debug_flag IF NOT EXISTS (SELECT 1 FROM [#ranges] WHERE [type] = 4) INSERT INTO [#ranges] VALUES (4, @range_out) CONTINUE END	
	IF CHARINDEX('vendor_class.', @range_out, 0) > 0 BEGIN EXEC pr_replace_keyword_sp @range_out OUTPUT, 'vendor_class.', '', @debug_flag EXEC pr_replace_keyword_sp @range_out OUTPUT, '"', '''', @debug_flag IF NOT EXISTS (SELECT 1 FROM [#ranges] WHERE [type] = 5) INSERT INTO [#ranges] VALUES (5, @range_out) CONTINUE END	
	IF CHARINDEX('part_no.', @range_out, 0) > 0 BEGIN EXEC pr_replace_keyword_sp @range_out OUTPUT, 'part_no.', '', @debug_flag EXEC pr_replace_keyword_sp @range_out OUTPUT, '"', '''', @debug_flag IF NOT EXISTS (SELECT 1 FROM [#ranges] WHERE [type] = 6) INSERT INTO [#ranges] VALUES (6, @range_out) CONTINUE END	
	IF CHARINDEX('part_category.', @range_out, 0) > 0 BEGIN EXEC pr_replace_keyword_sp @range_out OUTPUT, 'part_category.', '', @debug_flag EXEC pr_replace_keyword_sp @range_out OUTPUT, '"', '''', @debug_flag IF NOT EXISTS (SELECT 1 FROM [#ranges] WHERE [type] = 7) INSERT INTO [#ranges] VALUES (7, @range_out) CONTINUE END	
	IF CHARINDEX('apply_date.', @range_out, 0) > 0 BEGIN EXEC pr_replace_keyword_sp @range_out OUTPUT, 'apply_date.', '', @debug_flag EXEC pr_replace_keyword_sp @range_out OUTPUT, '"', '''', @debug_flag IF NOT EXISTS (SELECT 1 FROM [#ranges] WHERE [type] = 8) INSERT INTO [#ranges] VALUES (8, @range_out) CONTINUE END	
END


IF @debug_flag > 0
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='Dump #ranges' END
	SELECT * FROM [#ranges] ORDER BY [type]
END

SELECT @location = @procedure_name + ' - ' + 'Update range to work with #pr_events' + ' at line ' + RTRIM(LTRIM(STR(384))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
SELECT @range_out = @range
EXEC pr_replace_keyword_sp @range_out OUTPUT, 'contract_num.contract_ctrl_num', 'contract_ctrl_num', @debug_flag 
EXEC pr_replace_keyword_sp @range_out OUTPUT, 'customer_code.customer_code', 'customer_code', @debug_flag 
EXEC pr_replace_keyword_sp @range_out OUTPUT, 'customer_class.customer_class', 'price_class', @debug_flag 
EXEC pr_replace_keyword_sp @range_out OUTPUT, 'vendor_code.vendor_code', 'vendor_code', @debug_flag 
EXEC pr_replace_keyword_sp @range_out OUTPUT, 'vendor_class.vendor_class', 'vendor_class', @debug_flag 
EXEC pr_replace_keyword_sp @range_out OUTPUT, 'part_no.part_no', 'part_no', @debug_flag 
EXEC pr_replace_keyword_sp @range_out OUTPUT, 'part_category.part_category', 'category', @debug_flag 
EXEC pr_replace_keyword_sp @range_out OUTPUT, 'apply_date.apply_date', 'source_apply_date', @debug_flag 
EXEC pr_replace_keyword_sp @range_out OUTPUT, '"', '''', @debug_flag 

IF @debug_flag > 0 BEGIN SELECT 'range_out'=@range_out END

SELECT @currency_flag = -1
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'CURRENCY'
IF UPPER(@text_value) = 'HOME'
BEGIN
	SELECT @currency_flag = 1
END
IF UPPER(@text_value) = 'OPER'
BEGIN
	SELECT @currency_flag = 0
END

IF @currency_flag = -1
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='Invalid value for CURRENCY config setting ' + @text_value END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
END



--*****
--** GET POSSIBLE CUSTOMERS
--*****



SELECT @location = @procedure_name + ' - ' + 'Populate #possible_customers with customer codes' + ' at line ' + RTRIM(LTRIM(STR(423))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#possible_customers] ([customer_code], [customer_class], [flag])
	SELECT [customer_code], [price_code], 1
	  FROM [arcustok_vw]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @location = @procedure_name + ' - ' + 'Populate #possible_customers with customer classes' + ' at line ' + RTRIM(LTRIM(STR(430))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#possible_customers] ([customer_code], [customer_class], [flag])
	SELECT [customer_code], [price_code], 2
	  FROM [arcustok_vw]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @location = @procedure_name + ' - ' + 'Removing customer codes that are outside selected range' + ' at line ' + RTRIM(LTRIM(STR(437))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF EXISTS (SELECT 1 FROM [#ranges] WHERE [type] = 2)
BEGIN
	SELECT @sql = ''
	SELECT @sql = @sql + 'DELETE [#possible_customers] '
	SELECT @sql = @sql + ' WHERE NOT (' + [range] + ')' FROM [#ranges] WHERE [type] = 2
	SELECT @sql = @sql + '   AND [flag] = 1 '

	IF @debug_flag > 0
	BEGIN
		BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
	END

	EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

SELECT @location = @procedure_name + ' - ' + 'Removing customer classes that are outside selected range' + ' at line ' + RTRIM(LTRIM(STR(454))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF EXISTS (SELECT 1 FROM [#ranges] WHERE [type] = 3)
BEGIN
	SELECT @sql = ''
	SELECT @sql = @sql + 'DELETE [#possible_customers] '
	SELECT @sql = @sql + ' WHERE NOT (' + [range] + ')' FROM [#ranges] WHERE [type] = 3
	SELECT @sql = @sql + '   AND [flag] = 2 '

	IF @debug_flag > 0
	BEGIN
		BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
	END

	EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END



--*****
--** GET POSSIBLE VENDORS
--*****
SELECT @location = @procedure_name + ' - ' + 'Populate #possible_vendors with vendor codes' + ' at line ' + RTRIM(LTRIM(STR(476))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#possible_vendors] ([vendor_code], [vendor_class], [flag])
	SELECT [vendor_code], [vend_class_code], 1
	  FROM [apvendok_vw]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @location = @procedure_name + ' - ' + 'Populate #possible_vendors with vendor classes' + ' at line ' + RTRIM(LTRIM(STR(483))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#possible_vendors] ([vendor_code], [vendor_class], [flag])
	SELECT [vendor_code], [vend_class_code], 2
	  FROM [apvendok_vw]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @location = @procedure_name + ' - ' + 'Removing vendor codes that are outside selected range' + ' at line ' + RTRIM(LTRIM(STR(490))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF EXISTS (SELECT 1 FROM [#ranges] WHERE [type] = 4)
BEGIN
	SELECT @sql = ''
	SELECT @sql = @sql + 'DELETE [#possible_vendors] '
	SELECT @sql = @sql + ' WHERE NOT (' + [range] + ')' FROM [#ranges] WHERE [type] = 4
	SELECT @sql = @sql + '   AND [flag] = 1 '

	IF @debug_flag > 0
	BEGIN
		BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
	END

	EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

SELECT @location = @procedure_name + ' - ' + 'Removing vendor classes that are outside selected range' + ' at line ' + RTRIM(LTRIM(STR(507))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF EXISTS (SELECT 1 FROM [#ranges] WHERE [type] = 5)
BEGIN
	SELECT @sql = ''
	SELECT @sql = @sql + 'DELETE [#possible_vendors] '
	SELECT @sql = @sql + ' WHERE NOT (' + [range] + ')' FROM [#ranges] WHERE [type] = 5
	SELECT @sql = @sql + '   AND [flag] = 2 '

	IF @debug_flag > 0
	BEGIN
		BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
	END

	EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END




--*****
--** GET POSSIBLE PARTS
--*****


SELECT @location = @procedure_name + ' - ' + 'Populate #possible_parts with part no' + ' at line ' + RTRIM(LTRIM(STR(532))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#possible_parts] ([part_no], [part_category], [status], [flag], [kit_multiplier], [kit_part_no], [all_parts_flag] )	-- inclusive contracts flag
	SELECT [part_no], [category], [status], 1, 0.0, '', 0										-- inclusive contracts flag
	  FROM [inv_master]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @location = @procedure_name + ' - ' + 'Populate #possible_parts with part_no' + ' at line ' + RTRIM(LTRIM(STR(539))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#possible_parts] ([part_no], [part_category], [status], [flag], [kit_multiplier], [kit_part_no], [all_parts_flag])		-- inclusive contracts flag
	SELECT [part_no], [category], [status], 2, 0.0, '', 0										-- inclusive contracts flag
	  FROM [inv_master]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @location = @procedure_name + ' - ' + 'Removing part nos that are outside selected range' + ' at line ' + RTRIM(LTRIM(STR(546))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF EXISTS (SELECT 1 FROM [#ranges] WHERE [type] = 6)
BEGIN
	SELECT @sql = ''
	SELECT @sql = @sql + 'DELETE [#possible_parts] '
	SELECT @sql = @sql + ' WHERE NOT (' + [range] + ')' FROM [#ranges] WHERE [type] = 6
	SELECT @sql = @sql + '   AND [flag] = 1 '

	IF @debug_flag > 0
	BEGIN
		BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
	END

	EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

SELECT @location = @procedure_name + ' - ' + 'Removing part categories that are outside selected range' + ' at line ' + RTRIM(LTRIM(STR(563))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF EXISTS (SELECT 1 FROM [#ranges] WHERE [type] = 7)
BEGIN
	SELECT @sql = ''
	SELECT @sql = @sql + 'DELETE [#possible_parts] '
	SELECT @sql = @sql + ' WHERE NOT (' + [range] + ')' FROM [#ranges] WHERE [type] = 7
	SELECT @sql = @sql + '   AND [flag] = 2 '

	IF @debug_flag > 0
	BEGIN
		BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
	END

	EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END





--*****
--** GET POSSIBLE CONTRACTS
--*****


SELECT @location = @procedure_name + ' - ' + 'Populate #possible_contracts with contracts' + ' at line ' + RTRIM(LTRIM(STR(589))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#possible_contracts] ([contract_ctrl_num], [start_date], [end_date], [grace_date], [all_parts_flag], [type], [flag])	-- add inclusive contracts flag
	SELECT [contract_ctrl_num], [start_date], [end_date], [end_date] + [grace_days], [all_parts_flag], [type], 0			-- add inclusive contracts flag
	  FROM [pr_contracts]
	 WHERE [status] = 0
	   AND [type] <> 2

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @location = @procedure_name + ' - ' + 'Removing contracts that are outside selected range' + ' at line ' + RTRIM(LTRIM(STR(598))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF EXISTS (SELECT 1 FROM [#ranges] WHERE [type] = 1)
BEGIN
	SELECT @sql = ''
	SELECT @sql = @sql + 'DELETE [#possible_contracts] '
	SELECT @sql = @sql + ' WHERE NOT (' + [range] + ')' FROM [#ranges] WHERE [type] = 1

	IF @debug_flag > 0
	BEGIN
		BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
	END

	EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

IF @exclude_promotions = 1
BEGIN
	DELETE [#possible_contracts]
	 WHERE [type] = 1

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

IF @exclude_rebates = 1
BEGIN
	DELETE [#possible_contracts]
	 WHERE [type] = 0

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

SELECT @location = @procedure_name + ' - ' + 'Add in accumulators' + ' at line ' + RTRIM(LTRIM(STR(628))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#possible_contracts] ([contract_ctrl_num], [start_date], [end_date], [grace_date], [all_parts_flag], [type], [flag])		-- add inclusive contracts flag
	SELECT c.[contract_ctrl_num], c.[start_date], c.[end_date], c.[end_date] + c.[grace_days], c.[all_parts_flag], c.[type], 0		-- add inclusive contracts flag
	  FROM [pr_contracts] c, [pr_accumulator] a, [#possible_contracts] pcont
	 WHERE c.[status] = 0
	   AND c.[type] = 2
	   AND pcont.[contract_ctrl_num] = a.[contract_ctrl_num]
	   AND c.[contract_ctrl_num] = a.[accumulator]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"








SELECT @location = @procedure_name + ' - ' + 'Check for contracts that record events regardless of the part number' + ' at line ' + RTRIM(LTRIM(STR(644))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#possible_parts] ([part_no], [part_category], [status], [flag], [kit_multiplier], [kit_part_no], [all_parts_flag])
	SELECT [part_no], '', 'P', 3, 0.0, '', pc.[all_parts_flag]
	  FROM [#possible_contracts] pc, [pr_parts] pp
	 WHERE pc.[contract_ctrl_num] = pp.[contract_ctrl_num]
	   AND pc.[all_parts_flag] = 1

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



--*****
--** REMOVE CUSTOMERS, VENDORS AND PARTS THAT ARE NOT ASSOCIATED WITH 0 CONTRACTS
--*****

SELECT @location = @procedure_name + ' - ' + 'Remove customers that are not part of a selected contract' + ' at line ' + RTRIM(LTRIM(STR(657))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_customers]
   SET [flag] = 0
  FROM [#possible_customers] pcust, [#possible_contracts] pcont, [pr_customers_vw] cust
 WHERE pcust.[customer_code] = cust.[customer_code]
   AND pcont.[contract_ctrl_num] = cust.[contract_ctrl_num]
   AND pcust.[flag] = 1
   AND cust.[void] = 0
   AND cust.[price_class_flag] = 0

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Remove customer classes that are not part of a selected contract' + ' at line ' + RTRIM(LTRIM(STR(668))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_customers]
   SET [flag] = 0
  FROM [#possible_customers] pcust, [#possible_contracts] pcont, [pr_customers_vw] cust
 WHERE pcust.[customer_class] = cust.[price_class]
   AND pcont.[contract_ctrl_num] = cust.[contract_ctrl_num]
   AND pcust.[flag] = 2
   AND cust.[void] = 0
   AND cust.[price_class_flag] = 1

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'DELETE customers/classes that are not part of a selected contract' + ' at line ' + RTRIM(LTRIM(STR(679))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
DELETE [#possible_customers]
 WHERE [flag] <> 0

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Get rid of duplicate customer codes' + ' at line ' + RTRIM(LTRIM(STR(684))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#possible_customers] ([customer_code], [customer_class], [flag])
	SELECT DISTINCT [customer_code], [customer_class], 1
	  FROM [#possible_customers]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


DELETE [#possible_customers]
 WHERE [flag] <> 1

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"




SELECT @location = @procedure_name + ' - ' + 'Remove vendors that are not part of a selected contract' + ' at line ' + RTRIM(LTRIM(STR(696))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_vendors]
   SET [flag] = 0
  FROM [#possible_vendors] pvend, [#possible_contracts] pcont, [pr_vendors_vw] vend
 WHERE pvend.[vendor_code] = vend.[vendor_code]
   AND pcont.[contract_ctrl_num] = vend.[contract_ctrl_num]
   AND pvend.[flag] = 1
   AND vend.[void] = 0
   AND vend.[vendor_class_flag] = 0

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Remove vendor classes that are not part of a selected contract' + ' at line ' + RTRIM(LTRIM(STR(707))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_vendors]
   SET [flag] = 0
  FROM [#possible_vendors] pvend, [#possible_contracts] pcont, [pr_vendors_vw] vend
 WHERE pvend.[vendor_class] = vend.[vendor_class]
   AND pcont.[contract_ctrl_num] = vend.[contract_ctrl_num]
   AND pvend.[flag] = 2
   AND vend.[void] = 0
   AND vend.[vendor_class_flag] = 1

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'DELETE vendors/classes that are not part of a selected contract' + ' at line ' + RTRIM(LTRIM(STR(718))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
DELETE [#possible_vendors]
 WHERE [flag] <> 0

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Get rid of duplicate vendor codes' + ' at line ' + RTRIM(LTRIM(STR(723))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#possible_vendors] ([vendor_code], [vendor_class], [flag])
	SELECT DISTINCT [vendor_code], [vendor_class], 1
	  FROM [#possible_vendors]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


DELETE [#possible_vendors]
 WHERE [flag] <> 1

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"




SELECT @location = @procedure_name + ' - ' + 'Remove parts that are not part of a selected contract' + ' at line ' + RTRIM(LTRIM(STR(735))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_parts]
   SET [flag] = 0
  FROM [#possible_parts] ppart, [#possible_contracts] pcont, [pr_parts_vw] part
 WHERE ppart.[part_no] = part.[part_no]
   AND pcont.[contract_ctrl_num] = part.[contract_ctrl_num]
   AND ppart.[flag] = 1
   AND part.[void] = 0
   AND part.[part_class_flag] = 0

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Remove part category that are not part of a selected contract' + ' at line ' + RTRIM(LTRIM(STR(746))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_parts]
   SET [flag] = 0
  FROM [#possible_parts] ppart, [#possible_contracts] pcont, [pr_parts_vw] part
 WHERE ppart.[part_category] = part.[part_category]
   AND pcont.[contract_ctrl_num] = part.[contract_ctrl_num]
   AND ppart.[flag] = 2
   AND part.[void] = 0
   AND part.[part_class_flag] = 1

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'DELETE parts/categories that are not part of a selected contract' + ' at line ' + RTRIM(LTRIM(STR(757))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
DELETE [#possible_parts]
 WHERE [flag] <> 0
   AND [all_parts_flag] = 0					-- inclusive contracts

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Populate #possible_parts with kits that contained selected part_no' + ' at line ' + RTRIM(LTRIM(STR(763))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#possible_parts] ([part_no], [part_category], [status], [flag], [kit_multiplier], [kit_part_no], [all_parts_flag])		-- inclusive contracts
	SELECT w.[asm_no], i.[category], i.[status], 0, w.[qty], w.[part_no], 0								-- inclusive contracts
	  FROM [inv_master] i, [what_part] w, [#possible_parts] p
	 WHERE i.[part_no] = w.[asm_no]
	   AND p.[part_no] = w.[part_no]
	   AND p.[flag] IN (1,2)				-- Inclusive contracts are not considered for kits

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Get rid of duplicate part nos' + ' at line ' + RTRIM(LTRIM(STR(772))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#possible_parts] ([part_no], [part_category], [status], [flag], [kit_multiplier], [kit_part_no], [all_parts_flag])		-- inclusive contracts
	SELECT [part_no], MAX([part_category]), MAX([status]), 1, [kit_multiplier], [kit_part_no], MAX([all_parts_flag]) 				-- inclusive contracts
	  FROM [#possible_parts]
	 GROUP BY [part_no], [kit_multiplier], [kit_part_no]							-- inclusive contracts

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


DELETE [#possible_parts]
 WHERE [flag] <> 1

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



IF @debug_flag > 0
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='Dumping #possible_contracts' END
	SELECT * FROM [#possible_contracts]

	IF @debug_flag > 0 BEGIN SELECT 'debug'='Dumping #possible_customers' END
	SELECT * FROM [#possible_customers]

	IF @debug_flag > 0 BEGIN SELECT 'debug'='Dumping #possible_vendors' END
	SELECT * FROM [#possible_vendors]

	IF @debug_flag > 0 BEGIN SELECT 'debug'='Dumping #possible_parts' END
	SELECT * FROM [#possible_parts]
END

IF NOT EXISTS (SELECT 1 FROM [#possible_contracts])
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='No contracts to process' END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=0 END RETURN 0
END


--*****
--** IDENTIFY POSSIBLE EVENTS
--*****

SELECT @location = @procedure_name + ' - ' + 'Loading possible events' + ' at line ' + RTRIM(LTRIM(STR(810))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
SELECT 	@min_apply_date = MIN([start_date]), 
	@max_apply_date = MAX([end_date]),
	@max_grace_date = MAX([grace_date])
  FROM	[#possible_contracts]

IF @debug_flag > 0 BEGIN SELECT 'min_apply_date'=@min_apply_date END
IF @debug_flag > 0 BEGIN SELECT 'max_apply_date'=@max_apply_date END
IF @debug_flag > 0 BEGIN SELECT 'max_grace_date'=@max_grace_date END

IF @exclude_2031 = 0
BEGIN
	SELECT @location = @procedure_name + ' - ' + 'Get invoice events' + ' at line ' + RTRIM(LTRIM(STR(822))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	INSERT INTO [#possible_events] ([customer_code], [customer_class], [vendor_code], [vendor_class], [part_no], [part_category], [trx_ctrl_num], [doc_ctrl_num], [sequence_id], [trx_type], [apply_date], [qty], [unit_price], [gross_amount], [discount_amount], [nat_cur_code], [rate_type_home], [rate_type_oper], [rate_home], [rate_oper], [flag], [amt_cost], [kit_multiplier], [kit_part_no], [source_amt_cost], [all_parts_flag])		-- inclusive contracts
	  SELECT h.[customer_code], [price_code], '', '', d.[item_code], ISNULL(i.[category],''), d.[trx_ctrl_num], d.[doc_ctrl_num], d.[sequence_id], d.[trx_type], h.[date_applied], d.[qty_shipped], d.[unit_price], d.[qty_shipped] * d.[unit_price], d.[discount_amt], h.[nat_cur_code], h.[rate_type_home], h.[rate_type_oper], h.[rate_home], h.[rate_oper], 0, ISNULL(d.[amt_cost],0.0), 0.0, '', d.[amt_cost], 0				-- inclusive contracts
	    FROM [artrxcdt] d LEFT OUTER JOIN [inv_master] i ON ( d.[item_code] = i.[part_no]), [artrx] h          -- Include contracts even if the part number is not in inv_master (inclusive contracts)
	   WHERE h.[trx_ctrl_num] = d.[trx_ctrl_num]
	     AND h.[date_applied] BETWEEN @min_apply_date AND @max_apply_date
	     AND d.[trx_type] = 2031


-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END


IF @exclude_2032 = 0
BEGIN
	INSERT INTO [#possible_events] ([customer_code], [customer_class], [vendor_code], [vendor_class], [part_no], [part_category], [trx_ctrl_num], [doc_ctrl_num], [sequence_id], [trx_type], [apply_date], [qty], [unit_price], [gross_amount], [discount_amount], [nat_cur_code], [rate_type_home], [rate_type_oper], [rate_home], [rate_oper], [flag], [amt_cost], [kit_multiplier], [kit_part_no], [source_amt_cost], [all_parts_flag])		-- inclusive contracts
	  SELECT h.[customer_code], [price_code], '', '', d.[item_code], ISNULL(i.[category],''), d.[trx_ctrl_num], d.[doc_ctrl_num], d.[sequence_id], d.[trx_type], h.[date_applied], d.[qty_returned], d.[unit_price], d.[qty_returned] * d.[unit_price], d.[discount_amt], h.[nat_cur_code], h.[rate_type_home], h.[rate_type_oper], h.[rate_home], h.[rate_oper], 0, ISNULL(d.[amt_cost],0.0),0.0,'', d.[amt_cost], 0				-- inclusive contracts
	    FROM [artrxcdt] d LEFT OUTER JOIN [inv_master] i ON ( d.[item_code] = i.[part_no]), [artrx] h      -- Include contracts even if the part number is not in inv_master (inclusive contracts) 
	   WHERE h.[trx_ctrl_num] = d.[trx_ctrl_num]
	     AND h.[date_applied] BETWEEN @min_apply_date AND @max_grace_date
	     AND d.[trx_type] = 2032

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

IF @exclude_4091 = 0
BEGIN
	SELECT @location = @procedure_name + ' - ' + 'Get voucher events' + ' at line ' + RTRIM(LTRIM(STR(848))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	INSERT INTO [#possible_events] ([customer_code], [customer_class], [vendor_code], [vendor_class], [part_no], [part_category], [trx_ctrl_num], [doc_ctrl_num], [sequence_id], [trx_type], [apply_date], [qty], [unit_price], [gross_amount], [discount_amount], [nat_cur_code], [rate_type_home], [rate_type_oper], [rate_home], [rate_oper], [flag], [amt_cost], [kit_multiplier], [kit_part_no], [source_amt_cost])
	  SELECT '', '', h.[vendor_code], h.[class_code], d.[item_code], ISNULL(i.[category],''), d.[trx_ctrl_num], h.[doc_ctrl_num], d.[sequence_id], 4091, h.[date_applied], d.[qty_received], d.[unit_price], d.[qty_received] * d.[unit_price], d.[amt_discount], h.[currency_code], h.[rate_type_home], h.[rate_type_oper], h.[rate_home], h.[rate_oper], 0, 0.0, 0.0, '', 0.0
	    FROM [apvodet] d LEFT OUTER JOIN [inv_master] i ON ( d.[item_code] = i.[part_no]), [apvohdr] h    -- Include contracts even if the part number is not in inv_master (inclusive contracts)
	   WHERE h.[trx_ctrl_num] = d.[trx_ctrl_num]
	     AND h.[date_applied] BETWEEN @min_apply_date AND @max_apply_date

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END


IF @exclude_4092 = 0
BEGIN
	SELECT @location = @procedure_name + ' - ' + 'Get debit memo events' + ' at line ' + RTRIM(LTRIM(STR(861))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	INSERT INTO [#possible_events] ([customer_code], [customer_class], [vendor_code], [vendor_class], [part_no], [part_category], [trx_ctrl_num], [doc_ctrl_num], [sequence_id], [trx_type], [apply_date], [qty], [unit_price], [gross_amount], [discount_amount], [nat_cur_code], [rate_type_home], [rate_type_oper], [rate_home], [rate_oper], [flag], [amt_cost], [kit_multiplier], [kit_part_no], [source_amt_cost])
	  SELECT '', '', h.[vendor_code], h.[class_code], d.[item_code], ISNULL(i.[category],''), d.[trx_ctrl_num], h.[doc_ctrl_num], d.[sequence_id], 4092, h.[date_applied], d.[qty_returned], d.[unit_price], d.[qty_returned] * d.[unit_price], d.[amt_discount], h.[currency_code], h.[rate_type_home], h.[rate_type_oper], h.[rate_home], h.[rate_oper], 0, 0.0, 0.0, '', 0.0
	    FROM [apdmdet] d LEFT OUTER JOIN [inv_master] i ON ( d.[item_code] = i.[part_no]), [apdmhdr] h    -- Include contracts even if the part number is not in inv_master (inclusive contracts)
	   WHERE h.[trx_ctrl_num] = d.[trx_ctrl_num]
	     AND h.[date_applied] BETWEEN @min_apply_date AND @max_grace_date

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

SELECT @location = @procedure_name + ' - ' + 'Reset #possible_events flag' + ' at line ' + RTRIM(LTRIM(STR(871))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_events]
   SET [flag] = 0

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Identify customers that do not belong' + ' at line ' + RTRIM(LTRIM(STR(876))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_events]
   SET [flag] = 1
  FROM [#possible_events] pe, [#possible_customers] pc
 WHERE pe.[customer_code] = pc.[customer_code]
   AND pe.[trx_type] IN (2031, 2032)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Remove customers that do not belong' + ' at line ' + RTRIM(LTRIM(STR(884))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
DELETE [#possible_events]
 WHERE [flag] = 0
   AND [trx_type] IN (2031, 2032)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Identify vendors that do not belong' + ' at line ' + RTRIM(LTRIM(STR(890))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_events]
   SET [flag] = 1
  FROM [#possible_events] pe, [#possible_vendors] pv
 WHERE pe.[vendor_code] = pv.[vendor_code]
   AND pe.[trx_type] IN (4091, 4092)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Remove vendors that do not belong' + ' at line ' + RTRIM(LTRIM(STR(898))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
DELETE [#possible_events]
 WHERE [flag] = 0
   AND [trx_type] IN (4091, 4092)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Reset #possible_events flag' + ' at line ' + RTRIM(LTRIM(STR(904))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_events]
   SET [flag] = 0

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Identify parts that do not belong' + ' at line ' + RTRIM(LTRIM(STR(909))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_events]
   SET [flag] = 1
  FROM [#possible_events] pe, [#possible_parts] pp
 WHERE pe.[part_no] = pp.[part_no]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Identify customer events for inclusive contracts' + ' at line ' + RTRIM(LTRIM(STR(916))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_events]
   SET [flag] = 1
  FROM [#possible_events] pe, [pr_contracts] pc, [pr_customers] pcust
 WHERE pe.[customer_code] = pcust.[customer_code]
   AND pcust.[contract_ctrl_num] = pc.[contract_ctrl_num]
   AND pc.[all_parts_flag] = 1

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Identify price class events for inclusive contracts' + ' at line ' + RTRIM(LTRIM(STR(925))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_events]
   SET [flag] = 1
  FROM [#possible_events] pe, [pr_contracts] pc, [pr_customer_class] pcust
 WHERE pe.[customer_class] = pcust.[price_class]
   AND pcust.[contract_ctrl_num] = pc.[contract_ctrl_num]
   AND pc.[all_parts_flag] = 1

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Identify vendor events for inclusive contracts' + ' at line ' + RTRIM(LTRIM(STR(934))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_events]
   SET [flag] = 1
  FROM [#possible_events] pe, [pr_contracts] pc, [pr_vendors] pvend
 WHERE pe.[vendor_code] = pvend.[vendor_code]				
   AND pvend.[contract_ctrl_num] = pc.[contract_ctrl_num]
   AND pc.[all_parts_flag] = 1

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Identify vendor class events for inclusive contracts' + ' at line ' + RTRIM(LTRIM(STR(943))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#possible_events]
   SET [flag] = 1
  FROM [#possible_events] pe, [pr_contracts] pc, [pr_vendor_class] pvend
 WHERE pe.[vendor_class] = pvend.[vendor_class]
   AND pvend.[contract_ctrl_num] = pc.[contract_ctrl_num]
   AND pc.[all_parts_flag] = 1

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Remove parts that do not belong' + ' at line ' + RTRIM(LTRIM(STR(952))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
DELETE [#possible_events]
 WHERE [flag] = 0

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Spin up the kits into possible events' + ' at line ' + RTRIM(LTRIM(STR(957))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#possible_events] ([customer_code], [customer_class], [vendor_code], [vendor_class], [part_no], [part_category], [trx_ctrl_num], [doc_ctrl_num], [sequence_id], [trx_type], [apply_date], [qty], [unit_price], [gross_amount], [discount_amount], [nat_cur_code], [rate_type_home], [rate_type_oper], [rate_home], [rate_oper], [flag], [amt_cost], [kit_multiplier], [kit_part_no], [source_amt_cost])
  SELECT pe.[customer_code], pe.[customer_class], pe.[vendor_code], pe.[vendor_class], pp.[kit_part_no], pe.[part_category], pe.[trx_ctrl_num], pe.[doc_ctrl_num], pe.[sequence_id], pe.[trx_type], pe.[apply_date], pe.[qty]*pp.[kit_multiplier], pe.[unit_price], pe.[gross_amount]*pp.[kit_multiplier], pe.[discount_amount]*pp.[kit_multiplier], pe.[nat_cur_code], pe.[rate_type_home], pe.[rate_type_oper], pe.[rate_home], pe.[rate_oper], pe.[flag], pe.[amt_cost]*pp.[kit_multiplier], pp.[kit_multiplier], pe.[part_no], pe.[source_amt_cost]
    FROM [#possible_events] pe, [#possible_parts] pp
   WHERE ISNULL(DATALENGTH(RTRIM(LTRIM(pp.[kit_part_no]))),0) > 0
     AND pe.[part_no] = pp.[part_no]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Get rid of kit parents from possible events' + ' at line ' + RTRIM(LTRIM(STR(965))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
DELETE [#possible_events]
  FROM [#possible_events] pe, [#possible_parts] pp
 WHERE ISNULL(DATALENGTH(RTRIM(LTRIM(pp.[kit_part_no]))),0) > 0
   AND pe.[part_no] = pp.[part_no]

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


IF @debug_flag > 0
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='Dumping #possible_events' END
	SELECT * FROM [#possible_events] ORDER BY [trx_type], [trx_ctrl_num], [sequence_id]
END

--*******
--** POPULATE EVENTS TABLE
--*******

SELECT 	@process_description = 'PR Posting',
	@process_user_id = @userid,
	@process_parent_app = 21000,
	@process_parent_company = v.[company_code],
	@process_type = 0
  FROM	[glco] c, [glcomp_vw] v
 WHERE	c.[company_id] = v.[company_id]

SELECT @location = @procedure_name + ' - ' + 'Get process_ctrl_num' + ' at line ' + RTRIM(LTRIM(STR(990))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC @ret = [pctrladd_sp] @process_ctrl_num OUTPUT,
			  @process_description, 
 			  @process_user_id,
			  @process_parent_app, 
	 		  @process_parent_company,
			  @process_type

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
	EXEC pr_replace_keyword_sp @text_value OUTPUT, '<0>', 'pctrladd_sp'
	EXEC pr_replace_keyword_sp @text_value OUTPUT, '<1>', @buf
	EXEC pr_replace_keyword_sp @text_value OUTPUT, '<2>', @location
	SELECT @buf = @text_value
	RAISERROR (@buf,16,1)
	RETURN -1
END


SELECT @location = @procedure_name + ' - ' + 'Record invoice events' + ' at line ' + RTRIM(LTRIM(STR(1013))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#pr_events] ([contract_ctrl_num], [sequence_id], [process_ctrl_num], [post_date], [customer_code],
			  [price_class], [na_parent_code], [vendor_code], [vendor_class], [part_no], [category],
			  [source_trx_ctrl_num], [source_sequence_id], [source_doc_ctrl_num], [source_trx_type],
			  [source_apply_date], [source_qty_shipped], [source_unit_price], [source_gross_amount],
			  [source_discount_amount], [amount_adjusted], [void], [nat_cur_code], [rate_type_home],
			  [rate_type_oper], [rate_home], [rate_oper], [home_amount], [oper_amount], [home_adjusted],
			  [oper_adjusted], [userid], [home_rebate_amount], [oper_rebate_amount], [home_amt_cost], 
			  [oper_amt_cost], [kit_multiplier], [kit_part_no], [source_amt_cost], [all_parts_flag], [flag])								-- inclusive contracts
  SELECT DISTINCT cust.[contract_ctrl_num], 0, @process_ctrl_num, DATEDIFF(DD,'1/1/80',GETDATE())+722815, pe.[customer_code],
	 pe.[customer_class], '', pe.[vendor_code], pe.[vendor_class], pe.[part_no], pe.[part_category],
	 pe.[trx_ctrl_num], pe.[sequence_id], pe.[doc_ctrl_num], pe.[trx_type],
	 pe.[apply_date], pe.[qty], pe.[unit_price], pe.[gross_amount],
	 pe.[discount_amount], 0.0, 0, pe.[nat_cur_code], pe.[rate_type_home],
	 pe.[rate_type_oper], pe.[rate_home], pe.[rate_oper], CASE WHEN pe.[rate_home] < 0 THEN (pe.[gross_amount]-pe.[discount_amount]) / ABS((pe.[rate_home])) ELSE (pe.[gross_amount]-pe.[discount_amount]) * (pe.[rate_home]) END,
	 CASE WHEN pe.[rate_oper] < 0 THEN (pe.[gross_amount]-pe.[discount_amount]) / ABS((pe.[rate_oper])) ELSE (pe.[gross_amount]-pe.[discount_amount]) * (pe.[rate_oper]) END, 0.0, 0.0, @userid, 0.0, 0.0,
	 CASE WHEN pe.[rate_home] < 0 THEN (pe.[amt_cost]) / ABS((pe.[rate_home])) ELSE (pe.[amt_cost]) * (pe.[rate_home]) END, CASE WHEN pe.[rate_oper] < 0 THEN (pe.[amt_cost]) / ABS((pe.[rate_oper])) ELSE (pe.[amt_cost]) * (pe.[rate_oper]) END, pe.[kit_multiplier], pe.[kit_part_no], pe.[source_amt_cost], c.[all_parts_flag], 0		-- inclusive contracts
    FROM [pr_contracts] c, [#possible_events] pe, [pr_customers_vw] cust, [pr_parts_vw] part
   WHERE ((pe.[customer_code] = cust.[customer_code] AND cust.[source] = 0) OR (pe.[customer_class] = cust.[price_class] AND cust.[source] = 1))
     AND ((pe.[part_no] = part.[part_no] AND part.[source] = 0) OR (pe.[part_category] = part.[part_category] AND part.[source] = 1) OR (c.[all_parts_flag] = 1))		-- (inclusive contracts)
     AND part.[contract_ctrl_num] = cust.[contract_ctrl_num]
     AND cust.[contract_ctrl_num] = c.[contract_ctrl_num]
     AND pe.[apply_date] BETWEEN c.[start_date] AND c.[end_date]
     AND pe.[trx_type] = 2031
     AND c.type <> 2

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Record credit memo events' + ' at line ' + RTRIM(LTRIM(STR(1040))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#pr_events] ([contract_ctrl_num], [sequence_id], [process_ctrl_num], [post_date], [customer_code],
			  [price_class], [na_parent_code], [vendor_code], [vendor_class], [part_no], [category],
			  [source_trx_ctrl_num], [source_sequence_id], [source_doc_ctrl_num], [source_trx_type],
			  [source_apply_date], [source_qty_shipped], [source_unit_price], [source_gross_amount],
			  [source_discount_amount], [amount_adjusted], [void], [nat_cur_code], [rate_type_home],
			  [rate_type_oper], [rate_home], [rate_oper], [home_amount], [oper_amount], [home_adjusted],
			  [oper_adjusted], [userid], [home_rebate_amount], [oper_rebate_amount], [home_amt_cost], 
			  [oper_amt_cost], [kit_multiplier], [kit_part_no], [source_amt_cost], [all_parts_flag], [flag])								-- inclusive contracts
  SELECT DISTINCT cust.[contract_ctrl_num], 0, @process_ctrl_num, DATEDIFF(DD,'1/1/80',GETDATE())+722815, pe.[customer_code],
	 pe.[customer_class], '', pe.[vendor_code], pe.[vendor_class], pe.[part_no], pe.[part_category],
	 pe.[trx_ctrl_num], pe.[sequence_id], pe.[doc_ctrl_num], pe.[trx_type],
	 pe.[apply_date], pe.[qty], pe.[unit_price], pe.[gross_amount],
	 pe.[discount_amount], 0.0, 0, pe.[nat_cur_code], pe.[rate_type_home],
	 pe.[rate_type_oper], pe.[rate_home], pe.[rate_oper], CASE WHEN pe.[rate_home] < 0 THEN (pe.[gross_amount]-pe.[discount_amount]) / ABS((pe.[rate_home])) ELSE (pe.[gross_amount]-pe.[discount_amount]) * (pe.[rate_home]) END,
	 CASE WHEN pe.[rate_oper] < 0 THEN (pe.[gross_amount]-pe.[discount_amount]) / ABS((pe.[rate_oper])) ELSE (pe.[gross_amount]-pe.[discount_amount]) * (pe.[rate_oper]) END, 0.0, 0.0, @userid, 0.0, 0.0,
	 CASE WHEN pe.[rate_home] < 0 THEN (pe.[amt_cost]) / ABS((pe.[rate_home])) ELSE (pe.[amt_cost]) * (pe.[rate_home]) END, CASE WHEN pe.[rate_oper] < 0 THEN (pe.[amt_cost]) / ABS((pe.[rate_oper])) ELSE (pe.[amt_cost]) * (pe.[rate_oper]) END, pe.[kit_multiplier], pe.[kit_part_no], pe.[source_amt_cost], c.[all_parts_flag], 0		-- inclusive contracts
    FROM [pr_contracts] c, [#possible_events] pe, [pr_customers_vw] cust, [pr_parts_vw] part
   WHERE ((pe.[customer_code] = cust.[customer_code] AND cust.[source] = 0) OR (pe.[customer_class] = cust.[price_class] AND cust.[source] = 1))
     AND ((pe.[part_no] = part.[part_no] AND part.[source] = 0) OR (pe.[part_category] = part.[part_category] AND part.[source] = 1) OR (c.[all_parts_flag] = 1))		-- (inclusive contracts)
     AND part.[contract_ctrl_num] = cust.[contract_ctrl_num]
     AND cust.[contract_ctrl_num] = c.[contract_ctrl_num]
     AND pe.[apply_date] BETWEEN c.[start_date] AND c.[end_date] + c.[grace_days]
     AND pe.[trx_type] = 2032
     AND c.type <> 2

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Record voucher events' + ' at line ' + RTRIM(LTRIM(STR(1067))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#pr_events] ([contract_ctrl_num], [sequence_id], [process_ctrl_num], [post_date], [customer_code],
			  [price_class], [na_parent_code], [vendor_code], [vendor_class], [part_no], [category],
			  [source_trx_ctrl_num], [source_sequence_id], [source_doc_ctrl_num], [source_trx_type],
			  [source_apply_date], [source_qty_shipped], [source_unit_price], [source_gross_amount],
			  [source_discount_amount], [amount_adjusted], [void], [nat_cur_code], [rate_type_home],
			  [rate_type_oper], [rate_home], [rate_oper], [home_amount], [oper_amount], [home_adjusted],
			  [oper_adjusted], [userid], [home_rebate_amount], [oper_rebate_amount], [home_amt_cost], 
			  [oper_amt_cost], [kit_multiplier], [kit_part_no], [source_amt_cost], [all_parts_flag], [flag])								-- inclusive contracts
  SELECT DISTINCT vend.[contract_ctrl_num], 0, @process_ctrl_num, DATEDIFF(DD,'1/1/80',GETDATE())+722815, pe.[customer_code],
	 pe.[customer_class], '', pe.[vendor_code], pe.[vendor_class], pe.[part_no], pe.[part_category],
	 pe.[trx_ctrl_num], pe.[sequence_id], pe.[doc_ctrl_num], pe.[trx_type],
	 pe.[apply_date], pe.[qty], pe.[unit_price], pe.[gross_amount],
	 pe.[discount_amount], 0.0, 0, pe.[nat_cur_code], pe.[rate_type_home],
	 pe.[rate_type_oper], pe.[rate_home], pe.[rate_oper], CASE WHEN pe.[rate_home] < 0 THEN (pe.[gross_amount]-pe.[discount_amount]) / ABS((pe.[rate_home])) ELSE (pe.[gross_amount]-pe.[discount_amount]) * (pe.[rate_home]) END,
	 CASE WHEN pe.[rate_oper] < 0 THEN (pe.[gross_amount]-pe.[discount_amount]) / ABS((pe.[rate_oper])) ELSE (pe.[gross_amount]-pe.[discount_amount]) * (pe.[rate_oper]) END,  0.0, 0.0, @userid, 0.0, 0.0,
	 CASE WHEN pe.[rate_home] < 0 THEN (pe.[amt_cost]) / ABS((pe.[rate_home])) ELSE (pe.[amt_cost]) * (pe.[rate_home]) END, CASE WHEN pe.[rate_oper] < 0 THEN (pe.[amt_cost]) / ABS((pe.[rate_oper])) ELSE (pe.[amt_cost]) * (pe.[rate_oper]) END, pe.[kit_multiplier], pe.[kit_part_no], pe.[source_amt_cost], c.[all_parts_flag], 0		-- inclusive contracts
    FROM [pr_contracts] c, [#possible_events] pe, [pr_vendors_vw] vend, [pr_parts_vw] part
   WHERE ((pe.[vendor_code] = vend.[vendor_code] AND vend.[source] = 0) OR (pe.[vendor_class] = vend.[vendor_class] AND vend.[source] = 1))
     AND ((pe.[part_no] = part.[part_no] AND part.[source] = 0) OR (pe.[part_category] = part.[part_category] AND part.[source] = 1) OR (c.[all_parts_flag] = 1))		-- (inclusive contracts)
     AND part.[contract_ctrl_num] = vend.[contract_ctrl_num]
     AND vend.[contract_ctrl_num] = c.[contract_ctrl_num]
     AND pe.[apply_date] BETWEEN c.[start_date] AND c.[end_date]
     AND pe.[trx_type] = 4091
     AND c.type <> 2

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Record debit memo events' + ' at line ' + RTRIM(LTRIM(STR(1094))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO [#pr_events] ([contract_ctrl_num], [sequence_id], [process_ctrl_num], [post_date], [customer_code],
			  [price_class], [na_parent_code], [vendor_code], [vendor_class], [part_no], [category],
			  [source_trx_ctrl_num], [source_sequence_id], [source_doc_ctrl_num], [source_trx_type],
			  [source_apply_date], [source_qty_shipped], [source_unit_price], [source_gross_amount],
			  [source_discount_amount], [amount_adjusted], [void], [nat_cur_code], [rate_type_home],
			  [rate_type_oper], [rate_home], [rate_oper], [home_amount], [oper_amount], [home_adjusted],
			  [oper_adjusted], [userid], [home_rebate_amount], [oper_rebate_amount], [home_amt_cost], 
			  [oper_amt_cost], [kit_multiplier], [kit_part_no], [source_amt_cost], [all_parts_flag], [flag])								-- inclusive contracts
  SELECT DISTINCT vend.[contract_ctrl_num], 0, @process_ctrl_num, DATEDIFF(DD,'1/1/80',GETDATE())+722815, pe.[customer_code],
	 pe.[customer_class], '', pe.[vendor_code], pe.[vendor_class], pe.[part_no], pe.[part_category],
	 pe.[trx_ctrl_num], pe.[sequence_id], pe.[doc_ctrl_num], pe.[trx_type],
	 pe.[apply_date], pe.[qty], pe.[unit_price], pe.[gross_amount],
	 pe.[discount_amount], 0.0, 0, pe.[nat_cur_code], pe.[rate_type_home],
	 pe.[rate_type_oper], pe.[rate_home], pe.[rate_oper], CASE WHEN pe.[rate_home] < 0 THEN (pe.[gross_amount]-pe.[discount_amount]) / ABS((pe.[rate_home])) ELSE (pe.[gross_amount]-pe.[discount_amount]) * (pe.[rate_home]) END,
	 CASE WHEN pe.[rate_oper] < 0 THEN (pe.[gross_amount]-pe.[discount_amount]) / ABS((pe.[rate_oper])) ELSE (pe.[gross_amount]-pe.[discount_amount]) * (pe.[rate_oper]) END, 0.0, 0.0, @userid, 0.0, 0.0,
	 CASE WHEN pe.[rate_home] < 0 THEN (pe.[amt_cost]) / ABS((pe.[rate_home])) ELSE (pe.[amt_cost]) * (pe.[rate_home]) END, CASE WHEN pe.[rate_oper] < 0 THEN (pe.[amt_cost]) / ABS((pe.[rate_oper])) ELSE (pe.[amt_cost]) * (pe.[rate_oper]) END, pe.[kit_multiplier], pe.[kit_part_no], pe.[source_amt_cost], c.[all_parts_flag], 0		-- inclusive contracts
    FROM [pr_contracts] c, [#possible_events] pe, [pr_vendors_vw] vend, [pr_parts_vw] part
   WHERE ((pe.[vendor_code] = vend.[vendor_code] AND vend.[source] = 0) OR (pe.[vendor_class] = vend.[vendor_class] AND vend.[source] = 1))
     AND ((pe.[part_no] = part.[part_no] AND part.[source] = 0) OR (pe.[part_category] = part.[part_category] AND part.[source] = 1) OR (c.[all_parts_flag] = 1))		-- (inclusive contracts)
     AND part.[contract_ctrl_num] = vend.[contract_ctrl_num]
     AND vend.[contract_ctrl_num] = c.[contract_ctrl_num]
     AND pe.[apply_date] BETWEEN c.[start_date] AND c.[end_date] + c.[grace_days]
     AND pe.[trx_type] = 4092
     AND c.type <> 2

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Final pass to apply range to #pr_events' + ' at line ' + RTRIM(LTRIM(STR(1121))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
SELECT @sql = 'DELETE [#pr_events] WHERE NOT (' + @range_out + ')'

SELECT @location = @procedure_name + ' - ' + 'Identify existing events' + ' at line ' + RTRIM(LTRIM(STR(1124))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE [#pr_events]
   SET [flag] = 1
  FROM [pr_events] e, [#pr_events] pe
 WHERE e.[source_trx_ctrl_num] = pe.[source_trx_ctrl_num]
   AND e.[source_sequence_id] = pe.[source_sequence_id]
   AND e.[source_trx_type] = pe.[source_trx_type]
   AND e.[contract_ctrl_num] = pe.[contract_ctrl_num]
   AND e.[void_flag] = 0

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @location = @procedure_name + ' - ' + 'Remove existing events' + ' at line ' + RTRIM(LTRIM(STR(1135))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
DELETE [#pr_events]
 WHERE [flag] = 1

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



IF @debug_flag > 0
BEGIN
	SELECT 'DUMP #pr_events'
	SELECT * FROM [#pr_events]
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @location = @procedure_name + ' - ' + 'Resequnce #pr_events' + ' at line ' + RTRIM(LTRIM(STR(1152))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
SELECT @contract_ctrl_num = ''

WHILE (42=42)
BEGIN
	SET ROWCOUNT 1

	SELECT @contract_ctrl_num = [contract_ctrl_num]
	  FROM [#pr_events]
	 WHERE [contract_ctrl_num] > @contract_ctrl_num
	 ORDER BY [contract_ctrl_num]
	SELECT @rowcount = @@ROWCOUNT

	SET ROWCOUNT 0
	IF @rowcount = 0
	BEGIN
		BREAK
	END

	SET @sequence_id = 1
	WHILE (42=42)
	BEGIN
		SET ROWCOUNT 1

		UPDATE [#pr_events]
		   SET [sequence_id] = @sequence_id
		 WHERE [contract_ctrl_num] = @contract_ctrl_num
		   AND [sequence_id] = 0
		SELECT @rowcount = @@rowcount

		SET ROWCOUNT 0
		IF @rowcount = 0
		BEGIN
			BREAK
		END

		SELECT @sequence_id = @sequence_id + 1
	END
END

IF @debug_flag > 0
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='DUMP #pr_events' END
	SELECT * FROM [#pr_events] ORDER BY [contract_ctrl_num], [sequence_id]
END


--*******
--** PROCESS EACH NEW EVENT AND UPDATE THE amount_rebate for the customers, vendors and parts
--*******

SELECT @contract_ctrl_num = ''
WHILE (42=42)
BEGIN

	SET ROWCOUNT 1
	SELECT @contract_ctrl_num = [contract_ctrl_num]
	  FROM [#pr_events]
	 WHERE [contract_ctrl_num] > @contract_ctrl_num
	 ORDER BY [contract_ctrl_num]
	SELECT @rowcount = @@ROWCOUNT

	SET ROWCOUNT 0

	IF @rowcount = 0
	BEGIN
		BREAK
	END

	SELECT @sequence_id = 0
	WHILE (42=42)
	BEGIN
		SET ROWCOUNT 1
		SELECT 	@sequence_id = [sequence_id],
			@source_trx_type = [source_trx_type],
			@customer_code = [customer_code],
			@vendor_code = [vendor_code],
			@part_no = [part_no],
			@trx_type = [source_trx_type]
		  FROM [#pr_events]
		 WHERE [sequence_id] > @sequence_id
		   AND [contract_ctrl_num] = @contract_ctrl_num
		 ORDER BY [contract_ctrl_num], [sequence_id]
		SELECT @rowcount = @@ROWCOUNT

		SET ROWCOUNT 0

		IF @rowcount = 0 
		BEGIN
			BREAK
		END

		SELECT @customer_class = ISNULL([price_code], '')
		  FROM [arcustok_vw]
		 WHERE [customer_code] = @customer_code

		SELECT @vendor_class = ISNULL([vend_class_code], '')
		  FROM [apvendok_vw]
		 WHERE [vendor_code] = @vendor_code

		SELECT @part_category = ISNULL([category], '')
		  FROM [inv_master]
		 WHERE [part_no] = @part_no

		IF @source_trx_type IN (2031,2032)
		BEGIN
			SELECT @location = @procedure_name + ' - ' + 'CALL pr_event_rebate_sp for customer home' + ' at line ' + RTRIM(LTRIM(STR(1258))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
			EXEC @ret = [pr_event_rebate_sp] @contract_ctrl_num, @sequence_id, @customer_code, '', @part_no, @debug_flag, @userid, @home_rebate OUTPUT, @qty OUTPUT, 1

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

			SELECT @location = @procedure_name + ' - ' + 'CALL pr_event_rebate_sp for customer oper' + ' at line ' + RTRIM(LTRIM(STR(1275))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
			EXEC @ret = [pr_event_rebate_sp] @contract_ctrl_num, @sequence_id, @customer_code, '', @part_no, @debug_flag, @userid, @oper_rebate OUTPUT, @qty OUTPUT, 0

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

			SELECT @location = @procedure_name + ' - ' + 'Update rebate amounts in #pr_events' + ' at line ' + RTRIM(LTRIM(STR(1292))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
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

		IF @source_trx_type IN (4091,4092)
		BEGIN
			SELECT @location = @procedure_name + ' - ' + 'CALL pr_event_rebate_sp for vendor home' + ' at line ' + RTRIM(LTRIM(STR(1304))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
			EXEC @ret = [pr_event_rebate_sp] @contract_ctrl_num, @sequence_id, '', @vendor_code, @part_no, @debug_flag, @userid, @home_rebate OUTPUT, @qty OUTPUT, 1

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

			SELECT @location = @procedure_name + ' - ' + 'CALL pr_event_rebate_sp for vendor oper' + ' at line ' + RTRIM(LTRIM(STR(1321))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
			EXEC @ret = [pr_event_rebate_sp] @contract_ctrl_num, @sequence_id, '', @vendor_code, @part_no, @debug_flag, @userid, @oper_rebate OUTPUT, @qty OUTPUT, 0

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

			SELECT @location = @procedure_name + ' - ' + 'Update rebate amounts in #pr_events' + ' at line ' + RTRIM(LTRIM(STR(1338))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
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
	END
END


--
-- Total rebates for customer, vendors and parts that are part of this posting
--
SELECT @location = @procedure_name + ' - ' + 'CALL pr_rebate_totals_sp' + ' at line ' + RTRIM(LTRIM(STR(1354))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC @ret = [pr_rebate_totals_sp] 0, @debug_flag, @userid

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
	EXEC pr_replace_keyword_sp @text_value OUTPUT, '<0>', 'pr_rebate_totals_sp'
	EXEC pr_replace_keyword_sp @text_value OUTPUT, '<1>', @buf
	EXEC pr_replace_keyword_sp @text_value OUTPUT, '<2>', @location
	SELECT @buf = @text_value
	RAISERROR (@buf,16,1)
	RETURN -1
END

IF @debug_flag > 0
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='Dump #pr_events, #pr_customers, #pr_vendors and #pr_accumulators' END
	SELECT * FROM #pr_events
	SELECT * FROM #pr_customers
	SELECT * FROM #pr_vendors
	SELECT * FROM #pr_accumulators
END

SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'PURGE_REPORT_TABLE'

SELECT @location = @procedure_name + ' - ' + 'Purge report table' + ' at line ' + RTRIM(LTRIM(STR(1382))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
SELECT @sql = ''
SELECT @sql = @sql + 'DELETE [' + RTRIM(LTRIM(@table_name)) + '] '
SELECT @sql = @sql + ' WHERE [post_date] < ' + RTRIM(LTRIM(STR(DATEDIFF(DD,'1/1/80',GETDATE())+722815 - @int_value)))

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


SELECT @sql = ''
SELECT @sql = @sql + 'INSERT INTO [' + RTRIM(LTRIM(@table_name)) + '] ([id], [section], [contract_ctrl_num], [sequence_id], [process_ctrl_num], '
SELECT @sql = @sql + '[post_date], [customer_code], [price_class], [na_parent_code], [vendor_code], [vendor_class], '
SELECT @sql = @sql + '[part_no], [category], [source_trx_ctrl_num], [source_sequence_id], [source_doc_ctrl_num], '
SELECT @sql = @sql + '[source_trx_type], [source_apply_date], [source_qty_shipped], [source_unit_price], '
SELECT @sql = @sql + '[source_gross_amount], [source_discount_amount], [amount_adjusted], [void], [nat_cur_code], '
SELECT @sql = @sql + '[rate_type_home], [rate_type_oper], [rate_home], [rate_oper], [home_amount], [oper_amount], '
SELECT @sql = @sql + '[home_adjusted], [oper_adjusted], [userid], [customer_class], [amount_rebate], [amount_accrued_oper], '
SELECT @sql = @sql + '[amount_accrued_home], [flag], [part_category], '
SELECT @sql = @sql + '[exclude_promotions], [exclude_rebates], [exclude_2031], [exclude_2032], [exclude_4091], [exclude_4092], '
SELECT @sql = @sql + '[table_name], [trial_flag], [debug_flag], [accumulator], [range], [type], '
SELECT @sql = @sql + '[contract_description], [customer_name], [customer_class_name], [vendor_name], [vendor_class_name], '
SELECT @sql = @sql + '[part_description], [part_category_description], '
SELECT @sql = @sql + '[natural_currency_mask], [natural_currency_precision], [home_currency_mask], [home_currency_precision],'
SELECT @sql = @sql + '[oper_currency_mask], [oper_currency_precision], [home_symbol], [oper_symbol], [symbol], '
SELECT @sql = @sql + '[home_rebate_amount], [oper_rebate_amount], [kit_multiplier], [kit_part_no], '
SELECT @sql = @sql + '[home_amt_cost], [oper_amt_cost]) '
SELECT @sql = @sql + 'SELECT ''' + RTRIM(LTRIM(@id)) + ''',2,[contract_ctrl_num],[sequence_id],[process_ctrl_num],'
SELECT @sql = @sql + '[post_date],[customer_code],[price_class],'''',[vendor_code],[vendor_class],'		 --post_date
SELECT @sql = @sql + '[part_no],[category],[source_trx_ctrl_num],[source_sequence_id],[source_doc_ctrl_num],'	 --part_no
SELECT @sql = @sql + '[source_trx_type],[source_apply_date],[source_qty_shipped],[source_unit_price],'		 --source_trx_type
SELECT @sql = @sql + '[source_gross_amount],[source_discount_amount],[amount_adjusted],[void],[nat_cur_code],'	 --source_gross_amount
SELECT @sql = @sql + '[rate_type_home],[rate_type_oper],[rate_home],[rate_oper],[home_amount],[oper_amount],'	 --rate_type_home
SELECT @sql = @sql + '[home_adjusted],[oper_adjusted],[userid],'''',0.0,0.0,'				 	 --home_adjusted
SELECT @sql = @sql + '0.0,0,'''','										 --amount_accrued_home
SELECT @sql = @sql + '0,0,0,0,0,0,'										 --exclude_promotions
SELECT @sql = @sql + ''''',0,0,'''', '''', 0, ' 								 --table_name
SELECT @sql = @sql + ''''', '''', '''', '''', '''', '								 --contract_description
SELECT @sql = @sql + ''''', '''', '										 --part_description
SELECT @sql = @sql + ''''', 0, '''', 0, '									 --natural_currency_mask
SELECT @sql = @sql + ''''', 0, '''', '''', '''', '								 --oper_currency_mask
SELECT @sql = @sql + '[home_rebate_amount], [oper_rebate_amount], [kit_multiplier], [kit_part_no], '		 --home_rebate_amount
SELECT @sql = @sql + '[home_amt_cost],[oper_amt_cost] '								 --home_amt_cost
SELECT @sql = @sql + 'FROM [#pr_events]'

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

SELECT @location = @procedure_name + ' - ' + 'Loading section 2, #pr_events, into table' + ' at line ' + RTRIM(LTRIM(STR(1435))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"




SELECT @sql = ''
SELECT @sql = @sql + 'INSERT INTO [' + RTRIM(LTRIM(@table_name)) + '] ([id], [section], [contract_ctrl_num], [sequence_id], [process_ctrl_num], '
SELECT @sql = @sql + '[post_date], [customer_code], [price_class], [na_parent_code], [vendor_code], [vendor_class], '
SELECT @sql = @sql + '[part_no], [category], [source_trx_ctrl_num], [source_sequence_id], [source_doc_ctrl_num], '
SELECT @sql = @sql + '[source_trx_type], [source_apply_date], [source_qty_shipped], [source_unit_price], '
SELECT @sql = @sql + '[source_gross_amount], [source_discount_amount], [amount_adjusted], [void], [nat_cur_code], '
SELECT @sql = @sql + '[rate_type_home], [rate_type_oper], [rate_home], [rate_oper], [home_amount], [oper_amount], '
SELECT @sql = @sql + '[home_adjusted], [oper_adjusted], [userid], [customer_class], [amount_rebate], [amount_accrued_oper], '
SELECT @sql = @sql + '[amount_accrued_home], [flag], [part_category], '
SELECT @sql = @sql + '[exclude_promotions], [exclude_rebates], [exclude_2031], [exclude_2032], [exclude_4091], [exclude_4092], '
SELECT @sql = @sql + '[table_name], [trial_flag], [debug_flag], [accumulator], [range], [type], '
SELECT @sql = @sql + '[contract_description], [customer_name], [customer_class_name], [vendor_name], [vendor_class_name], '
SELECT @sql = @sql + '[part_description], [part_category_description], '
SELECT @sql = @sql + '[natural_currency_mask], [natural_currency_precision], [home_currency_mask], [home_currency_precision],'
SELECT @sql = @sql + '[oper_currency_mask], [oper_currency_precision], [home_symbol], [oper_symbol], [symbol], '
SELECT @sql = @sql + '[home_rebate_amount], [oper_rebate_amount], [kit_multiplier], [kit_part_no], '
SELECT @sql = @sql + '[home_amt_cost], [oper_amt_cost]) '
SELECT @sql = @sql + 'SELECT ''' + RTRIM(LTRIM(@id)) + ''',3,[contract_ctrl_num],0,'''','
SELECT @sql = @sql + RTRIM(LTRIM(STR(@today))) + ',[customer_code],'''','''','''','''','		 			 --post_date
SELECT @sql = @sql + ''''','''','''',0,'''','	 								 --part_no
SELECT @sql = @sql + '0,0,0.0,0.0,'		 								 --source_trx_type
SELECT @sql = @sql + '0.0,0.0,0.0,0,'''','	 								 --source_gross_amount
SELECT @sql = @sql + ''''','''',0.0,0.0,0.0,0.0,'	 							 --rate_type_home
SELECT @sql = @sql + '0.0,0.0,0,[customer_class],0.0,[amount_rebate_oper],'			 		 --home_adjusted
SELECT @sql = @sql + '[amount_rebate_home],[flag],'''','						 	 --amount_accrued_home
SELECT @sql = @sql + '0,0,0,0,0,0,'										 --exclude_promotions
SELECT @sql = @sql + ''''',0,0,'''', '''', 0, ' 								 --table_name
SELECT @sql = @sql + ''''', '''', '''', '''', '''', '								 --contract_description
SELECT @sql = @sql + ''''', '''', '										 --part_description
SELECT @sql = @sql + ''''', 0, '''', 0, '									 --natural_currency_mask
SELECT @sql = @sql + ''''', 0, '''', '''', '''', '								 --oper_currency_mask
SELECT @sql = @sql + '0.0, 0.0, 0.0, '''', '									 --home_rebate_amount
SELECT @sql = @sql + '0.0,0.0 '											 --home_amt_cost
SELECT @sql = @sql + 'FROM [#pr_customers]'

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

SELECT @location = @procedure_name + ' - ' + 'Loading section 3, #pr_customers, into table' + ' at line ' + RTRIM(LTRIM(STR(1481))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"




SELECT @sql = ''
SELECT @sql = @sql + 'INSERT INTO [' + RTRIM(LTRIM(@table_name)) + '] ([id], [section], [contract_ctrl_num], [sequence_id], [process_ctrl_num], '
SELECT @sql = @sql + '[post_date], [customer_code], [price_class], [na_parent_code], [vendor_code], [vendor_class], '
SELECT @sql = @sql + '[part_no], [category], [source_trx_ctrl_num], [source_sequence_id], [source_doc_ctrl_num], '
SELECT @sql = @sql + '[source_trx_type], [source_apply_date], [source_qty_shipped], [source_unit_price], '
SELECT @sql = @sql + '[source_gross_amount], [source_discount_amount], [amount_adjusted], [void], [nat_cur_code], '
SELECT @sql = @sql + '[rate_type_home], [rate_type_oper], [rate_home], [rate_oper], [home_amount], [oper_amount], '
SELECT @sql = @sql + '[home_adjusted], [oper_adjusted], [userid], [customer_class], [amount_rebate], [amount_accrued_oper], '
SELECT @sql = @sql + '[amount_accrued_home], [flag], [part_category], '
SELECT @sql = @sql + '[exclude_promotions], [exclude_rebates], [exclude_2031], [exclude_2032], [exclude_4091], [exclude_4092], '
SELECT @sql = @sql + '[table_name], [trial_flag], [debug_flag], [accumulator], [range], [type], '
SELECT @sql = @sql + '[contract_description], [customer_name], [customer_class_name], [vendor_name], [vendor_class_name], '
SELECT @sql = @sql + '[part_description], [part_category_description], '
SELECT @sql = @sql + '[natural_currency_mask], [natural_currency_precision], [home_currency_mask], [home_currency_precision],'
SELECT @sql = @sql + '[oper_currency_mask], [oper_currency_precision], [home_symbol], [oper_symbol], [symbol], '
SELECT @sql = @sql + '[home_rebate_amount], [oper_rebate_amount], [kit_multiplier], [kit_part_no], '
SELECT @sql = @sql + '[home_amt_cost], [oper_amt_cost]) '
SELECT @sql = @sql + 'SELECT ''' + RTRIM(LTRIM(@id)) + ''',4,[contract_ctrl_num],0,'''','
SELECT @sql = @sql + RTRIM(LTRIM(STR(@today))) + ','''','''','''',[vendor_code],[vendor_class],'		 		 --post_date
SELECT @sql = @sql + ''''','''','''',0,'''','	 								 --part_no
SELECT @sql = @sql + '0,0,0.0,0.0,'		 								 --source_trx_type
SELECT @sql = @sql + '0.0,0.0,0.0,0,'''','	 								 --source_gross_amount
SELECT @sql = @sql + ''''','''',0.0,0.0,0.0,0.0,'	 							 --rate_type_home
SELECT @sql = @sql + '0.0,0.0,0,'''',0.0,[amount_rebate_oper],'			 				 --home_adjusted
SELECT @sql = @sql + '[amount_rebate_home],[flag],'''','						 	 --amount_accrued_home
SELECT @sql = @sql + '0,0,0,0,0,0,'										 --exclude_promotions
SELECT @sql = @sql + ''''',0,0,'''', '''', 0, ' 								 --table_name
SELECT @sql = @sql + ''''', '''', '''', '''', '''', '								 --contract_description
SELECT @sql = @sql + ''''', '''', '										 --part_description
SELECT @sql = @sql + ''''', 0, '''', 0, '									 --natural_currency_mask
SELECT @sql = @sql + ''''', 0, '''', '''', '''', '								 --oper_currency_mask
SELECT @sql = @sql + '0.0, 0.0, 0.0, '''', '									 --home_rebate_amount
SELECT @sql = @sql + '0.0,0.0 '											 --home_amt_cost
SELECT @sql = @sql + 'FROM [#pr_vendors]'

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

SELECT @location = @procedure_name + ' - ' + 'Loading section 4, #pr_vendors, into table' + ' at line ' + RTRIM(LTRIM(STR(1527))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"




SELECT @sql = ''
SELECT @sql = @sql + 'INSERT INTO [' + RTRIM(LTRIM(@table_name)) + '] ([id], [section], [contract_ctrl_num], [sequence_id], [process_ctrl_num], '
SELECT @sql = @sql + '[post_date], [customer_code], [price_class], [na_parent_code], [vendor_code], [vendor_class], '
SELECT @sql = @sql + '[part_no], [category], [source_trx_ctrl_num], [source_sequence_id], [source_doc_ctrl_num], '
SELECT @sql = @sql + '[source_trx_type], [source_apply_date], [source_qty_shipped], [source_unit_price], '
SELECT @sql = @sql + '[source_gross_amount], [source_discount_amount], [amount_adjusted], [void], [nat_cur_code], '
SELECT @sql = @sql + '[rate_type_home], [rate_type_oper], [rate_home], [rate_oper], [home_amount], [oper_amount], '
SELECT @sql = @sql + '[home_adjusted], [oper_adjusted], [userid], [customer_class], [amount_rebate], [amount_accrued_oper], '
SELECT @sql = @sql + '[amount_accrued_home], [flag], [part_category], '
SELECT @sql = @sql + '[exclude_promotions], [exclude_rebates], [exclude_2031], [exclude_2032], [exclude_4091], [exclude_4092], '
SELECT @sql = @sql + '[table_name], [trial_flag], [debug_flag], [accumulator], [range], [type], '
SELECT @sql = @sql + '[contract_description], [customer_name], [customer_class_name], [vendor_name], [vendor_class_name], '
SELECT @sql = @sql + '[part_description], [part_category_description], '
SELECT @sql = @sql + '[natural_currency_mask], [natural_currency_precision], [home_currency_mask], [home_currency_precision],'
SELECT @sql = @sql + '[oper_currency_mask], [oper_currency_precision], [home_symbol], [oper_symbol], [symbol], '
SELECT @sql = @sql + '[home_rebate_amount], [oper_rebate_amount], [kit_multiplier], [kit_part_no], '
SELECT @sql = @sql + '[home_amt_cost], [oper_amt_cost]) '
SELECT @sql = @sql + 'SELECT ''' + RTRIM(LTRIM(@id)) + ''',5,[contract_ctrl_num],[sequence_id],'''','
SELECT @sql = @sql + RTRIM(LTRIM(STR(@today))) + ',[customer_code],'''','''',[vendor_code],'''','		 		 --post_date
SELECT @sql = @sql + '[part_no],'''','''',0,'''','	 							 --part_no
SELECT @sql = @sql + '0,0,0.0,0.0,'		 								 --source_trx_type
SELECT @sql = @sql + '0.0,0.0,0.0,0,'''','	 								 --source_gross_amount
SELECT @sql = @sql + ''''','''',0.0,0.0,0.0,0.0,'	 							 --rate_type_home
SELECT @sql = @sql + '0.0,0.0,0,'''',[amount_rebate],0.0,'			 		 		 --home_adjusted
SELECT @sql = @sql + '0.0,[flag],'''', '									 --amount_accrued_home
SELECT @sql = @sql + '0,0,0,0,0,0,'										 --exclude_promotions
SELECT @sql = @sql + ''''',0,0,[accumulator], '''', 0, ' 							 --table_name
SELECT @sql = @sql + ''''', '''', '''', '''', '''', '								 --contract_description
SELECT @sql = @sql + ''''', '''', '										 --part_description
SELECT @sql = @sql + ''''', 0, '''', 0, '									 --natural_currency_mask
SELECT @sql = @sql + ''''', 0, '''', '''', '''', '								 --oper_currency_mask
SELECT @sql = @sql + '0.0, 0.0, 0.0, '''', '									 --home_rebate_amount
SELECT @sql = @sql + '0.0,0.0 '											 --home_amt_cost
SELECT @sql = @sql + 'FROM [#pr_accumulators]'

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

SELECT @location = @procedure_name + ' - ' + 'Loading section 5, #pr_accumulators, into table' + ' at line ' + RTRIM(LTRIM(STR(1573))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @sql = ''
SELECT @sql = @sql + 'UPDATE [' + RTRIM(LTRIM(@table_name)) + '] '
SELECT @sql = @sql + '   SET [contract_description] = b.[description] '
SELECT @sql = @sql + '  FROM [' + RTRIM(LTRIM(@table_name)) + '] a, [pr_contracts] b '
SELECT @sql = @sql + ' WHERE a.[contract_ctrl_num] = b.[contract_ctrl_num] '
SELECT @sql = @sql + '   AND DATALENGTH(ISNULL(RTRIM(LTRIM(a.[contract_ctrl_num])),'''')) > 0 '
SELECT @sql = @sql + '   AND a.[id] = ''' + RTRIM(LTRIM(@id)) + ''''

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

SELECT @location = @procedure_name + ' - ' + 'Updating contract_ctrl_num' + ' at line ' + RTRIM(LTRIM(STR(1591))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @sql = ''
SELECT @sql = @sql + 'UPDATE [' + RTRIM(LTRIM(@table_name)) + '] '
SELECT @sql = @sql + '   SET [customer_name] = b.[address_name] '
SELECT @sql = @sql + '  FROM [' + RTRIM(LTRIM(@table_name)) + '] a, [arcustok_vw] b '
SELECT @sql = @sql + ' WHERE a.[customer_code] = b.[customer_code] '
SELECT @sql = @sql + '   AND DATALENGTH(ISNULL(RTRIM(LTRIM(a.[customer_code])),'''')) > 0 '
SELECT @sql = @sql + '   AND a.[id] = ''' + RTRIM(LTRIM(@id)) + ''''

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

SELECT @location = @procedure_name + ' - ' + 'Updating customer_name' + ' at line ' + RTRIM(LTRIM(STR(1609))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @sql = ''
SELECT @sql = @sql + 'UPDATE [' + RTRIM(LTRIM(@table_name)) + '] '
SELECT @sql = @sql + '   SET [customer_class_name] = b.[description] '
SELECT @sql = @sql + '  FROM [' + RTRIM(LTRIM(@table_name)) + '] a, [arprice] b '
SELECT @sql = @sql + ' WHERE a.[customer_class] = b.[price_code] '
SELECT @sql = @sql + '   AND DATALENGTH(ISNULL(RTRIM(LTRIM(a.[customer_class])),'''')) > 0 '
SELECT @sql = @sql + '   AND a.[id] = ''' + RTRIM(LTRIM(@id)) + ''''

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

SELECT @location = @procedure_name + ' - ' + 'Updating customer_class' + ' at line ' + RTRIM(LTRIM(STR(1627))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @sql = ''
SELECT @sql = @sql + 'UPDATE [' + RTRIM(LTRIM(@table_name)) + '] '
SELECT @sql = @sql + '   SET [vendor_name] = b.[vendor_name] '
SELECT @sql = @sql + '  FROM [' + RTRIM(LTRIM(@table_name)) + '] a, [apvendok_vw] b '
SELECT @sql = @sql + ' WHERE a.[vendor_code] = b.[vendor_code] '
SELECT @sql = @sql + '   AND DATALENGTH(ISNULL(RTRIM(LTRIM(a.[vendor_code])),'''')) > 0 '
SELECT @sql = @sql + '   AND a.[id] = ''' + RTRIM(LTRIM(@id)) + ''''

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

SELECT @location = @procedure_name + ' - ' + 'Updating vendor_name' + ' at line ' + RTRIM(LTRIM(STR(1645))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @sql = ''
SELECT @sql = @sql + 'UPDATE [' + RTRIM(LTRIM(@table_name)) + '] '
SELECT @sql = @sql + '   SET [vendor_class_name] = b.[description] '
SELECT @sql = @sql + '  FROM [' + RTRIM(LTRIM(@table_name)) + '] a, [apclass] b '
SELECT @sql = @sql + ' WHERE a.[vendor_class] = b.[class_code] '
SELECT @sql = @sql + '   AND DATALENGTH(ISNULL(RTRIM(LTRIM(a.[vendor_class])),'''')) > 0 '
SELECT @sql = @sql + '   AND a.[id] = ''' + RTRIM(LTRIM(@id)) + ''''

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

SELECT @location = @procedure_name + ' - ' + 'Updating vendor_class_name' + ' at line ' + RTRIM(LTRIM(STR(1663))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @sql = ''
SELECT @sql = @sql + 'UPDATE [' + RTRIM(LTRIM(@table_name)) + '] '
SELECT @sql = @sql + '   SET [part_description] = b.[description] '
SELECT @sql = @sql + '  FROM [' + RTRIM(LTRIM(@table_name)) + '] a, [inv_master] b '
SELECT @sql = @sql + ' WHERE a.[part_no] = b.[part_no] '
SELECT @sql = @sql + '   AND DATALENGTH(ISNULL(RTRIM(LTRIM(a.[part_no])),'''')) > 0 '
SELECT @sql = @sql + '   AND a.[id] = ''' + RTRIM(LTRIM(@id)) + ''''

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

SELECT @location = @procedure_name + ' - ' + 'Updating part_description' + ' at line ' + RTRIM(LTRIM(STR(1681))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @sql = ''
SELECT @sql = @sql + 'UPDATE [' + RTRIM(LTRIM(@table_name)) + '] '
SELECT @sql = @sql + '   SET [part_category_description] = b.[description] '
SELECT @sql = @sql + '  FROM [' + RTRIM(LTRIM(@table_name)) + '] a, [category] b '
SELECT @sql = @sql + ' WHERE a.[category] = b.[kys] '
SELECT @sql = @sql + '   AND DATALENGTH(ISNULL(RTRIM(LTRIM(a.[category])),'''')) > 0 '
SELECT @sql = @sql + '   AND a.[id] = ''' + RTRIM(LTRIM(@id)) + ''''

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

SELECT @location = @procedure_name + ' - ' + 'Updating part_category_description' + ' at line ' + RTRIM(LTRIM(STR(1699))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @sql = ''
SELECT @sql = @sql + 'UPDATE [' + RTRIM(LTRIM(@table_name)) + '] '
SELECT @sql = @sql + '   SET [process_ctrl_num] = ''' + RTRIM(LTRIM(@process_ctrl_num)) + ''', '
SELECT @sql = @sql + '       [post_date] = ' + RTRIM(LTRIM(STR(DATEDIFF(DD,'1/1/80',GETDATE())+722815)))
SELECT @sql = @sql + ' WHERE [section] = 1 '

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

SELECT @location = @procedure_name + ' - ' + 'Updating process_ctrl_num' + ' at line ' + RTRIM(LTRIM(STR(1715))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @sql = ''
SELECT @sql = @sql + 'UPDATE [' + RTRIM(LTRIM(@table_name)) + '] '
SELECT @sql = @sql + '   SET [natural_currency_mask] = LTRIM(RTRIM(CASE CHARINDEX('';'', c.[currency_mask]) WHEN 0 THEN SUBSTRING(c.[currency_mask],2,DATALENGTH(c.[currency_mask])) ELSE SUBSTRING(c.[currency_mask],2,CHARINDEX('';'',c.[currency_mask])-2) END)), '
SELECT @sql = @sql + '       [natural_currency_precision] = c.[curr_precision], '
SELECT @sql = @sql + '       [symbol] = c.[symbol] '
SELECT @sql = @sql + '  FROM [' + RTRIM(LTRIM(@table_name)) + '] a, [glcurr_vw] c '
SELECT @sql = @sql + ' WHERE DATALENGTH(ISNULL(RTRIM(LTRIM(a.[nat_cur_code])),'''')) > 0 '
SELECT @sql = @sql + '   AND a.[nat_cur_code] = c.[currency_code] '

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

SELECT @location = @procedure_name + ' - ' + 'Updating currency mask and precision' + ' at line ' + RTRIM(LTRIM(STR(1734))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @sql = ''
SELECT @sql = @sql + 'UPDATE [' + RTRIM(LTRIM(@table_name)) + '] '
SELECT @sql = @sql + '   SET [home_currency_mask] = LTRIM(RTRIM(CASE CHARINDEX('';'', c.[currency_mask]) WHEN 0 THEN SUBSTRING(c.[currency_mask],2,DATALENGTH(c.[currency_mask])) ELSE SUBSTRING(c.[currency_mask],2,CHARINDEX('';'',c.[currency_mask])-2) END)), '
SELECT @sql = @sql + '       [home_currency_precision] = c.[curr_precision], '
SELECT @sql = @sql + '       [home_symbol] = c.[symbol] '
SELECT @sql = @sql + '  FROM [glco] b, [glcurr_vw] c '
SELECT @sql = @sql + ' WHERE b.[home_currency] = c.[currency_code] '

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

SELECT @location = @procedure_name + ' - ' + 'Updating home currency mask and precision' + ' at line ' + RTRIM(LTRIM(STR(1752))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"



SELECT @sql = ''
SELECT @sql = @sql + 'UPDATE [' + RTRIM(LTRIM(@table_name)) + '] '
SELECT @sql = @sql + '   SET [oper_currency_mask] = LTRIM(RTRIM(CASE CHARINDEX('';'', c.[currency_mask]) WHEN 0 THEN SUBSTRING(c.[currency_mask],2,DATALENGTH(c.[currency_mask])) ELSE SUBSTRING(c.[currency_mask],2,CHARINDEX('';'',c.[currency_mask])-2) END)), '
SELECT @sql = @sql + '       [oper_currency_precision] = c.[curr_precision], '
SELECT @sql = @sql + '       [oper_symbol] = c.[symbol] '
SELECT @sql = @sql + '  FROM [glco] b, [glcurr_vw] c '
SELECT @sql = @sql + ' WHERE b.[oper_currency] = c.[currency_code] '

IF @debug_flag > 0
BEGIN
	BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
END

SELECT @location = @procedure_name + ' - ' + 'Updating oper currency mask and precision' + ' at line ' + RTRIM(LTRIM(STR(1770))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


IF @debug_flag > 0
BEGIN
	SELECT @buf = 'Dumping ' + RTRIM(LTRIM(@table_name))
	IF @debug_flag > 0 BEGIN SELECT 'debug'=@buf END
	SELECT @sql = 'SELECT * FROM [' + RTRIM(LTRIM(@table_name)) + '] WHERE [id] = ''' + RTRIM(LTRIM(@id)) + ''' ORDER BY [section]'

	IF @debug_flag > 0
	BEGIN
		BEGIN SELECT @len=DATALENGTH(RTRIM(LTRIM(@sql))),@i=0 SELECT '===BD' WHILE (@len>0) BEGIN SELECT @buf=SUBSTRING(@sql,@i*100,100) SELECT @buf SELECT @i=@i+1,@len=@len-100 END SELECT '===BD' END
	END

	SELECT @location = @procedure_name + ' - ' + 'Dump report table' + ' at line ' + RTRIM(LTRIM(STR(1785))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	EXEC (@sql)

-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

END

--*****
--** CHECK TO SEE IF THIS IS A FINAL RUN
--*****
IF @trial_flag <> 1
BEGIN
	SELECT @location = @procedure_name + ' - ' + 'Final mode, begin transaction' + ' at line ' + RTRIM(LTRIM(STR(1795))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	IF @@TRANCOUNT = 0 BEGIN BEGIN TRANSACTION SELECT @transaction_started = 1 SELECT 'PS_TRACE'='BEGIN transaction: ' + 'prpost' END

	--
	-- Total rebates for customer, vendors and parts that are part of this posting
	--
	SELECT @location = @procedure_name + ' - ' + 'Truncating #pr_customers' + ' at line ' + RTRIM(LTRIM(STR(1801))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	TRUNCATE TABLE [#pr_customers]
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Truncating #pr_vendors' + ' at line ' + RTRIM(LTRIM(STR(1805))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	TRUNCATE TABLE [#pr_vendors]
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Truncating #pr_parts' + ' at line ' + RTRIM(LTRIM(STR(1809))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	TRUNCATE TABLE [#pr_parts]
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'CALL pr_rebate_totals_sp' + ' at line ' + RTRIM(LTRIM(STR(1813))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	EXEC @ret = [pr_rebate_totals_sp] 1, @debug_flag, @userid
	
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
		EXEC pr_replace_keyword_sp @text_value OUTPUT, '<0>', 'pr_rebate_totals_sp'
		EXEC pr_replace_keyword_sp @text_value OUTPUT, '<1>', @buf
		EXEC pr_replace_keyword_sp @text_value OUTPUT, '<2>', @location
		SELECT @buf = @text_value
		RAISERROR (@buf,16,1)
		RETURN -1
	END

	--
	-- Get rid of entries that are not for customers or vendors in this posting
	--
	SELECT @location = @procedure_name + ' - ' + 'Identify customers to delete' + ' at line ' + RTRIM(LTRIM(STR(1833))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE [#pr_customers]
	   SET [flag] = c.[flag] + 10
	  FROM [#pr_customers] c, [#pr_events] e
	 WHERE c.[customer_code] = e.[customer_code]
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Delete flagged customers' + ' at line ' + RTRIM(LTRIM(STR(1840))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	DELETE [#pr_customers]
	 WHERE [flag] < 10
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Reset customer flags' + ' at line ' + RTRIM(LTRIM(STR(1845))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE [#pr_customers]
	   SET [flag] = [flag] - 10
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Identify vendors to delete' + ' at line ' + RTRIM(LTRIM(STR(1850))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE [#pr_vendors]
	   SET [flag] = v.[flag] + 10
	  FROM [#pr_vendors] v, [#pr_events] e
	 WHERE v.[vendor_code] = e.[vendor_code]
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Delete flagged vendors' + ' at line ' + RTRIM(LTRIM(STR(1857))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	DELETE [#pr_vendors]
	 WHERE [flag] < 10
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Reset vendor flags' + ' at line ' + RTRIM(LTRIM(STR(1862))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE [#pr_vendors]
	   SET [flag] = [flag] - 10
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	IF @debug_flag > 0
	BEGIN
		IF @debug_flag > 0 BEGIN SELECT 'debug'='Dump #pr_customers and #pr_vendors' END
		SELECT * FROM #pr_customers
		SELECT * FROM #pr_vendors
	END

	--
	-- Update sequence ids of the events
	--
	SELECT @location = @procedure_name + ' - ' + 'Resequnce #pr_events again' + ' at line ' + RTRIM(LTRIM(STR(1877))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	SELECT @contract_ctrl_num = ''

	WHILE (42=42)
	BEGIN
		SET ROWCOUNT 1

		SELECT @contract_ctrl_num = [contract_ctrl_num]
		  FROM [#pr_events]
		 WHERE [contract_ctrl_num] > @contract_ctrl_num
		 ORDER BY [contract_ctrl_num]
		SELECT @rowcount = @@ROWCOUNT

		SET ROWCOUNT 0
		IF @rowcount = 0
		BEGIN
			BREAK
		END

		SELECT @sequence_id = ISNULL(MAX(sequence_id),0)
		  FROM [pr_events]
	 	 WHERE [contract_ctrl_num] = @contract_ctrl_num

		UPDATE [#pr_events]
		   SET [sequence_id] = [sequence_id] + @sequence_id
		 WHERE [contract_ctrl_num] = @contract_ctrl_num
	END

	IF @debug_flag > 0
	BEGIN
		IF @debug_flag > 0 BEGIN SELECT 'debug'='DUMP #pr_events' END
		SELECT * FROM [#pr_events] ORDER BY [contract_ctrl_num], [sequence_id]
	END


	SELECT @location = @procedure_name + ' - ' + 'Populate pr_events' + ' at line ' + RTRIM(LTRIM(STR(1912))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	INSERT INTO [pr_events] ([contract_ctrl_num], [sequence_id], [process_ctrl_num], [post_date], [customer_code], 
				 [price_class], [na_parent_code], [vendor_code], [vendor_class], [part_no], [part_category],
				 [source_trx_ctrl_num], [source_sequence_id], [source_doc_ctrl_num], [source_trx_type],
				 [source_apply_date], [source_qty_shipped], [source_unit_price], [source_gross_amount],
				 [source_discount_amount], [amount_adjusted], [void_flag], [nat_cur_code], [rate_type_home],
				 [rate_type_oper], [rate_home], [rate_oper], [home_amount], [oper_amount], [home_adjusted],
				 [oper_adjusted], [userid], [home_rebate_amount], 
				 [oper_rebate_amount], [home_amt_cost], [oper_amt_cost], [kit_multiplier], [kit_part_no],
				 [source_amt_cost], [all_parts_flag])									-- inclusive contracts
	SELECT  [contract_ctrl_num], [sequence_id], [process_ctrl_num], [post_date], [customer_code], 
		[price_class], [na_parent_code], [vendor_code], [vendor_class], [part_no], [category],
		[source_trx_ctrl_num], [source_sequence_id], [source_doc_ctrl_num], [source_trx_type],
		[source_apply_date], [source_qty_shipped], [source_unit_price], [source_gross_amount],
		[source_discount_amount], [amount_adjusted], [void], [nat_cur_code], [rate_type_home],
		[rate_type_oper], [rate_home], [rate_oper], [home_amount], [oper_amount], [home_adjusted],
		[oper_adjusted], [userid], [home_rebate_amount], 
		[oper_rebate_amount], [home_amt_cost], [oper_amt_cost], [kit_multiplier], [kit_part_no], 
		[source_amt_cost], [all_parts_flag]											-- inclusive contracts
	  FROM	[#pr_events]
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Update pr_customers' + ' at line ' + RTRIM(LTRIM(STR(1934))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE [pr_customers]
	   SET [amount_accrued_home] = t.[amount_rebate_home],
		[amount_accrued_oper] = t.[amount_rebate_oper]
	  FROM [pr_customers] c, [#pr_customers] t
	 WHERE c.[contract_ctrl_num] = t.[contract_ctrl_num]
	   AND c.[customer_code] = t.[customer_code]
	   AND t.[flag] = 0
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Update pr_customer_class' + ' at line ' + RTRIM(LTRIM(STR(1944))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE [pr_customer_class]
	   SET [amount_accrued_home] = t.[amount_rebate_home],
		[amount_accrued_oper] = t.[amount_rebate_oper]
	  FROM [pr_customer_class] c, [#pr_customers] t
	 WHERE c.[contract_ctrl_num] = t.[contract_ctrl_num]
	   AND c.[price_class] = t.[customer_class]
	   AND t.[flag] = 1
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Update pr_vendors' + ' at line ' + RTRIM(LTRIM(STR(1954))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE [pr_vendors]
	   SET [amount_accrued_home] = t.[amount_rebate_home],
		[amount_accrued_oper] = t.[amount_rebate_oper]
	  FROM [pr_vendors] c, [#pr_vendors] t
	 WHERE c.[contract_ctrl_num] = t.[contract_ctrl_num]
	   AND c.[vendor_code] = t.[vendor_code]
	   AND t.[flag] = 0
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Update pr_vendor_class' + ' at line ' + RTRIM(LTRIM(STR(1964))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE [pr_vendor_class]
	   SET [amount_accrued_home] = t.[amount_rebate_home],
		[amount_accrued_oper] = t.[amount_rebate_oper]
	  FROM [pr_vendor_class] c, [#pr_vendors] t
	 WHERE c.[contract_ctrl_num] = t.[contract_ctrl_num]
	   AND c.[vendor_class] = t.[vendor_class]
	   AND t.[flag] = 1
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Update pr_parts' + ' at line ' + RTRIM(LTRIM(STR(1974))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE [pr_parts]
	   SET [amount_accrued_home] = t.[amount_rebate_home],
		[amount_accrued_oper] = t.[amount_rebate_oper]
	  FROM [pr_parts] c, [#pr_parts] t
	 WHERE c.[contract_ctrl_num] = t.[contract_ctrl_num]
	   AND c.[part_no] = t.[part_no]
	   AND t.[flag] = 0
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Update pr_part_category' + ' at line ' + RTRIM(LTRIM(STR(1984))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE [pr_part_category]
	   SET [amount_accrued_home] = t.[amount_rebate_home],
		[amount_accrued_oper] = t.[amount_rebate_oper]
	  FROM [pr_part_category] c, [#pr_parts] t
	 WHERE c.[contract_ctrl_num] = t.[contract_ctrl_num]
	   AND c.[part_category] = t.[part_category]
	   AND t.[flag] = 1
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Create #contracts' + ' at line ' + RTRIM(LTRIM(STR(1994))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	CREATE TABLE [#contracts] ([contract_ctrl_num]		VARCHAR(16) NULL)
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Create #contract_totals' + ' at line ' + RTRIM(LTRIM(STR(1998))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	CREATE TABLE [#contract_totals] (
		[contract_ctrl_num]		VARCHAR(16) NULL,
		[amount_paid_to_date_home]	FLOAT NULL,
		[amount_paid_to_date_oper]	FLOAT NULL,
		[amount_accrued_home]		FLOAT NULL,
		[amount_accrued_oper]		FLOAT NULL,
		[flag]				INT NULL
	)
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Populate #contracts' + ' at line ' + RTRIM(LTRIM(STR(2009))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	INSERT INTO [#contracts] ([contract_ctrl_num])
	  SELECT t.[contract_ctrl_num]
	    FROM (SELECT [contract_ctrl_num] FROM [#pr_customers] UNION SELECT [contract_ctrl_num] FROM [#pr_vendors]) t
	   GROUP BY t.[contract_ctrl_num]
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Populate #contract_totals' + ' at line ' + RTRIM(LTRIM(STR(2016))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	INSERT INTO [#contract_totals] ([contract_ctrl_num], [amount_paid_to_date_home], [amount_paid_to_date_oper],
					[amount_accrued_home], [amount_accrued_oper], [flag])
	  SELECT [contract_ctrl_num], SUM([amount_paid_to_date_home]), SUM([amount_paid_to_date_oper]), 
		 SUM([amount_accrued_home]), SUM([amount_accrued_oper]), 0
	    FROM (SELECT p.[contract_ctrl_num], [amount_paid_to_date_home], [amount_paid_to_date_oper], [amount_accrued_home], [amount_accrued_oper] 
		    FROM [pr_customers] p, [#contracts] c
		   WHERE p.[contract_ctrl_num] = c.[contract_ctrl_num]
		  UNION ALL
	          SELECT p.[contract_ctrl_num], [amount_paid_to_date_home], [amount_paid_to_date_oper], [amount_accrued_home], [amount_accrued_oper] 
		    FROM [pr_customer_class] p, [#contracts] c
		   WHERE p.[contract_ctrl_num] = c.[contract_ctrl_num]
		  UNION ALL
	          SELECT p.[contract_ctrl_num], [amount_paid_to_date_home], [amount_paid_to_date_oper], [amount_accrued_home], [amount_accrued_oper] 
		    FROM [pr_vendors] p, [#contracts] c
		   WHERE p.[contract_ctrl_num] = c.[contract_ctrl_num] 
		  UNION ALL
	          SELECT p.[contract_ctrl_num], [amount_paid_to_date_home], [amount_paid_to_date_oper], [amount_accrued_home], [amount_accrued_oper] 
		    FROM [pr_vendor_class] p, [#contracts] c
		   WHERE p.[contract_ctrl_num] = c.[contract_ctrl_num] ) t
	   GROUP BY [contract_ctrl_num]
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"


	SELECT @location = @procedure_name + ' - ' + 'Update pr_contracts' + ' at line ' + RTRIM(LTRIM(STR(2039))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE [pr_contracts]
	   SET [amount_paid_to_date_home] = t.[amount_paid_to_date_home],
	       [amount_paid_to_date_oper] = t.[amount_paid_to_date_oper],
	       [amount_accrued_home] = t.[amount_accrued_home],
	       [amount_accrued_oper] = t.[amount_accrued_home]
	  FROM [pr_contracts] c, [#contract_totals] t
	 WHERE c.[contract_ctrl_num] = t.[contract_ctrl_num]
	
-- #include "STANDARD ERROR.INC"
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR IF @error <> 0 BEGIN 

-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @transaction_started > 0 BEGIN ROLLBACK TRANSACTION END SELECT @buf = '*ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location RAISERROR (@buf,16,1) RETURN -1 END
-- end "STANDARD ERROR.INC"

	
	IF @transaction_started = 1 BEGIN COMMIT TRANSACTION SELECT @transaction_started = 0 SELECT 'PS_TRACE'='COMMIT transaction: ' + 'prpost' END
END

IF @debug_flag > 0 BEGIN SELECT 'debug'='Posting complete' END


DROP TABLE [#pr_events]
DROP TABLE [#possible_events]
DROP TABLE [#possible_customers]
DROP TABLE [#possible_vendors]
DROP TABLE [#possible_parts]
DROP TABLE [#possible_contracts]
DROP TABLE [#pr_customers]
DROP TABLE [#pr_vendors]
DROP TABLE [#pr_parts]
DROP TABLE [#pr_accumulators]



-- #include "STANDARD EXIT.INC"
SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'VERSION' SELECT @buf = 'Exiting ' + @procedure_name + ' version:' + @text_value + ' Build:' + RTRIM(LTRIM(STR(@int_value))) + ' at ' + CONVERT(CHAR(20),GETDATE()) IF @debug_flag > 0 BEGIN SELECT 'Exit'=@buf END
-- end "STANDARD EXIT.INC"

IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=0 END RETURN 0

GO
GRANT EXECUTE ON  [dbo].[pr_posting_sp] TO [public]
GO
