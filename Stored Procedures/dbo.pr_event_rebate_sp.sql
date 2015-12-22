SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[pr_event_rebate_sp] @contract_ctrl_num		VARCHAR(16) = '',
				      @sequence_id			INT = 0,
				      @customer_code		 	VARCHAR(8) = '',
				      @vendor_code			VARCHAR(12) = '',	-- SCR 2017
				      @part_no			VARCHAR(30) = '',
				      @debug_flag 			INT = 0,
				      @userid				INT = 0,
				      @rebate				FLOAT OUTPUT,
				      @qty				FLOAT OUTPUT,
				      @satisfied			INT = 0 OUTPUT,
				      @called_by_accumulator		INT = 0,
				      @parent				VARCHAR(16) = '',
				      @home_flag			INT = -1 AS



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
DECLARE @amount				FLOAT
DECLARE @part_category			VARCHAR(10)

DECLARE @level				INT
DECLARE @from				FLOAT
DECLARE @to				FLOAT
DECLARE @pct				FLOAT
DECLARE @percent_flag			INT
DECLARE @type				INT
DECLARE @accumulator_rebate		FLOAT
DECLARE @event_qty			FLOAT
DECLARE @event_amount			FLOAT
DECLARE @rebate_before_event		FLOAT
DECLARE @rebate_after_event		FLOAT
DECLARE @all_parts_flag			INT

DECLARE @date_applied			INT

SELECT @procedure_name = 'pr_event_rebate_sp'


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
IF @debug_flag > 0 BEGIN SELECT 'customer_code'=@customer_code END
IF @debug_flag > 0 BEGIN SELECT 'vendor_code'=@vendor_code END
IF @debug_flag > 0 BEGIN SELECT 'part_no'=@part_no END
IF @debug_flag > 0 BEGIN SELECT 'debug_flag'=@debug_flag END
IF @debug_flag > 0 BEGIN SELECT 'userid'=@userid END
IF @debug_flag > 0 BEGIN SELECT 'called_by_accumulator'=@called_by_accumulator END
IF @debug_flag > 0 BEGIN SELECT 'parent'=@parent END

SELECT @satisfied = 0, @rebate = 0.0

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

IF @called_by_accumulator = 0 AND @type = 2
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='Cannot process accumulators directly' END
	RETURN(-1)
END

IF ISNULL(DATALENGTH(RTRIM(LTRIM(@parent))),0) = 0
BEGIN
	SELECT @parent = @contract_ctrl_num
END

IF @home_flag NOT IN (0,1)
BEGIN
	SELECT @text_value = '*UNKNOWN', @int_value = -99 SELECT @text_value = text_value, @int_value = int_value FROM pr_config WHERE UPPER(item_name) = 'CURRENCY'
	IF UPPER(@text_value) = 'HOME'
	BEGIN
		SELECT @home_flag = 1
	END
	IF UPPER(@text_value) = 'OPER'
	BEGIN
		SELECT @home_flag = 0
	END
END	

IF @home_flag = -1
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='Invalid value for CURRENCY config setting ' + @text_value END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
END

SELECT @all_parts_flag = 0
IF @sequence_id > 0
BEGIN
	SELECT @date_applied = 0
	IF EXISTS (SELECT 1 FROM [pr_events] WHERE [contract_ctrl_num] = @parent AND [sequence_id] = @sequence_id)
	BEGIN
		SELECT @date_applied = [source_apply_date], @all_parts_flag = [all_parts_flag]						-- inclusive contracts
		  FROM [pr_events]
		 WHERE [contract_ctrl_num] = @parent
		   AND [sequence_id] = @sequence_id
	END
	IF EXISTS (SELECT 1 FROM [#pr_events] WHERE [contract_ctrl_num] = @parent AND [sequence_id] = @sequence_id)
	BEGIN
		SELECT @date_applied = [source_apply_date], @all_parts_flag = [all_parts_flag]						-- inclusive contracts
		  FROM [#pr_events]
		 WHERE [contract_ctrl_num] = @parent
		   AND [sequence_id] = @sequence_id
	END
END
ELSE
BEGIN
	SELECT @date_applied = 2147483647
	SELECT @all_parts_flag = [all_parts_flag]
	   FROM [pr_contracts]
	 WHERE [contract_ctrl_num] = @contract_ctrl_num
END
IF @date_applied = 0
BEGIN
	IF @debug_flag > 0 BEGIN SELECT 'debug'='Cannot locate the date_applied for this contract' END
	IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
END


SELECT @create_pr_events = 0
IF EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#pr_events') IS NULL) 
BEGIN
	SELECT @location = @procedure_name + ' - ' + 'Create #pr_events' + ' at line ' + RTRIM(LTRIM(STR(187))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
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


IF @customer_code <> ''
BEGIN
	SELECT @location = @procedure_name + ' - ' + 'Calculate customer totals' + ' at line ' + RTRIM(LTRIM(STR(236))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	SELECT @amount = ISNULL(SUM(CASE @home_flag WHEN 1 THEN [home_amount] + [home_adjusted] ELSE [oper_amount] + [oper_adjusted] END),0.0),
	       @qty = ISNULL(SUM([source_qty_shipped]),0.0)
	  FROM (SELECT [home_amount], [oper_amount], [home_adjusted], [oper_adjusted], [contract_ctrl_num], [customer_code], [part_no], [source_qty_shipped], [source_apply_date], 'temp_sequence_id'=[sequence_id], [all_parts_flag] FROM [#pr_events] WHERE source_trx_type = 2031 UNION ALL SELECT [home_amount], [oper_amount], [home_adjusted], [oper_adjusted], [contract_ctrl_num], [customer_code], [part_no], [source_qty_shipped], [source_apply_date], 'temp_sequence_id'=0, [all_parts_flag] FROM pr_events WHERE source_trx_type = 2031) t 		-- inclusive contracts
	 WHERE [contract_ctrl_num] = @parent
	   AND [customer_code] = @customer_code
	   AND (([part_no] = @part_no) OR ([all_parts_flag] = 1))																																																													-- inclusive contracts
	   AND [source_apply_date] <= @date_applied
	   AND ((@sequence_id = 0) OR ([temp_sequence_id] <= @sequence_id))

	SELECT @amount = @amount - ISNULL(SUM(CASE @home_flag WHEN 1 THEN [home_amount] + [home_adjusted] ELSE [oper_amount] + [oper_adjusted] END),0.0),
	       @qty = @qty - ISNULL(SUM([source_qty_shipped]),0.0)
	  FROM (SELECT [home_amount], [oper_amount], [home_adjusted], [oper_adjusted], [contract_ctrl_num], [customer_code], [part_no], [source_qty_shipped], [source_apply_date], 'temp_sequence_id'=[sequence_id], [all_parts_flag]  FROM [#pr_events] WHERE source_trx_type = 2032 UNION ALL SELECT [home_amount], [oper_amount], [home_adjusted], [oper_adjusted], [contract_ctrl_num], [customer_code], [part_no], [source_qty_shipped], [source_apply_date], 'temp_sequence_id'=0, [all_parts_flag] FROM pr_events WHERE source_trx_type = 2032) t 		-- inclusive contracts
	 WHERE [contract_ctrl_num] = @parent
	   AND [customer_code] = @customer_code
	   AND (([part_no] = @part_no) OR ([all_parts_flag] = 1))																																																													-- inclusive contracts
	   AND [source_apply_date] <= @date_applied
	   AND ((@sequence_id = 0) OR ([temp_sequence_id] <= @sequence_id))
END

IF @vendor_code <> ''
BEGIN

	SELECT @location = @procedure_name + ' - ' + 'Calculate vendor totals' + ' at line ' + RTRIM(LTRIM(STR(259))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	SELECT @amount = ISNULL(SUM(CASE @home_flag WHEN 1 THEN [home_amount] + [home_adjusted] ELSE [oper_amount] + [oper_adjusted] END),0.0),
	       @qty = ISNULL(SUM([source_qty_shipped]),0.0)
	  FROM (SELECT [home_amount], [oper_amount], [home_adjusted], [oper_adjusted], [contract_ctrl_num], [vendor_code], [part_no], [source_qty_shipped], [source_apply_date], 'temp_sequence_id'=[sequence_id], [all_parts_flag] FROM [#pr_events] WHERE source_trx_type = 4091 UNION ALL SELECT [home_amount], [oper_amount], [home_adjusted], [oper_adjusted], [contract_ctrl_num], [vendor_code], [part_no], [source_qty_shipped], [source_apply_date], 'temp_sequence_id'=0, [all_parts_flag] FROM pr_events WHERE source_trx_type = 4091) t 			-- inclusive contracts
	 WHERE [contract_ctrl_num] = @parent
	   AND [vendor_code] = @vendor_code
	   AND (([part_no] = @part_no) OR ([all_parts_flag] = 1))																																																													-- inclusive contracts
	   AND [source_apply_date] <= @date_applied
	   AND ((@sequence_id = 0) OR ([temp_sequence_id] <= @sequence_id))

	SELECT @amount = @amount - ISNULL(SUM(CASE @home_flag WHEN 1 THEN [home_amount] + [home_adjusted] ELSE [oper_amount] + [oper_adjusted] END),0.0),
	       @qty = @qty - ISNULL(SUM([source_qty_shipped]),0.0)
	  FROM (SELECT [home_amount], [oper_amount], [home_adjusted], [oper_adjusted], [contract_ctrl_num], [vendor_code], [part_no], [source_qty_shipped], [source_apply_date], 'temp_sequence_id'=[sequence_id], [all_parts_flag] FROM [#pr_events] WHERE source_trx_type = 4092 UNION ALL SELECT [home_amount], [oper_amount], [home_adjusted], [oper_adjusted], [contract_ctrl_num], [vendor_code], [part_no], [source_qty_shipped], [source_apply_date], 'temp_sequence_id'=0, [all_parts_flag] FROM pr_events WHERE source_trx_type = 4092) t 			-- inclusive contracts
	 WHERE [contract_ctrl_num] = @parent
	   AND [vendor_code] = @vendor_code
	   AND (([part_no] = @part_no) OR ([all_parts_flag] = 1))																																																													-- inclusive contracts
	   AND [source_apply_date] <= @date_applied
	   AND ((@sequence_id = 0) OR ([temp_sequence_id] <= @sequence_id))
END

--
-- Get the quantity and amount of the event, if the sequence_id is zero, the event amount/qty will be @amount/@qty
--
IF @sequence_id > 0
BEGIN
	IF @customer_code <> ''
	BEGIN
		SELECT @location = @procedure_name + ' - ' + 'Calculate event total for customer' + ' at line ' + RTRIM(LTRIM(STR(286))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		SELECT @event_amount = ISNULL(SUM(CASE @home_flag WHEN 1 THEN [home_amount] + [home_adjusted] ELSE [oper_amount] + [oper_adjusted] END),0.0),
		       @event_qty = ISNULL(SUM([source_qty_shipped]),0.0)
		  FROM (SELECT [sequence_id], [home_amount], [oper_amount], [home_adjusted], [oper_adjusted], [contract_ctrl_num], [customer_code], [part_no], [source_qty_shipped], [source_apply_date], [all_parts_flag] FROM [#pr_events] WHERE source_trx_type = 2031) t 		-- inclusive contracts
		 WHERE [contract_ctrl_num] = @parent
		   AND [customer_code] = @customer_code
		   AND (([part_no] = @part_no) OR ([all_parts_flag] = 1))																										-- inclusive contracts
		   AND [sequence_id] = @sequence_id
	
		SELECT @event_amount = @event_amount - ISNULL(SUM(CASE @home_flag WHEN 1 THEN [home_amount] + [home_adjusted] ELSE [oper_amount] + [oper_adjusted] END),0.0),
		       @event_qty = @event_qty - ISNULL(SUM([source_qty_shipped]),0.0)
		  FROM (SELECT [sequence_id], [home_amount], [oper_amount], [home_adjusted], [oper_adjusted], [contract_ctrl_num], [customer_code], [part_no], [source_qty_shipped], [source_apply_date], [all_parts_flag] FROM [#pr_events] WHERE source_trx_type = 2032) t 		-- inclusive contracts
		 WHERE [contract_ctrl_num] = @parent
		   AND [customer_code] = @customer_code
		   AND (([part_no] = @part_no) OR ([all_parts_flag] = 1))																										-- inclusive contracts
		   AND [sequence_id] = @sequence_id
	END

	IF @vendor_code <> ''
	BEGIN

		SELECT @location = @procedure_name + ' - ' + 'Calculate event total for vendor' + ' at line ' + RTRIM(LTRIM(STR(307))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		SELECT @event_amount = ISNULL(SUM(CASE @home_flag WHEN 1 THEN [home_amount] + [home_adjusted] ELSE [oper_amount] + [oper_adjusted] END),0.0),
		       @event_qty = ISNULL(SUM([source_qty_shipped]),0.0)
		  FROM (SELECT [sequence_id], [home_amount], [oper_amount], [home_adjusted], [oper_adjusted], [contract_ctrl_num], [vendor_code], [part_no], [source_qty_shipped], [source_apply_date], [all_parts_flag] FROM [#pr_events] WHERE source_trx_type = 4091) t 		-- inclusive contracts
		 WHERE [contract_ctrl_num] = @parent
		   AND [vendor_code] = @vendor_code
		   AND (([part_no] = @part_no) OR ([all_parts_flag] = 1))																										-- inclusive contracts
		   AND [sequence_id] = @sequence_id

		SELECT @event_amount = @event_amount - ISNULL(SUM(CASE @home_flag WHEN 1 THEN [home_amount] + [home_adjusted] ELSE [oper_amount] + [oper_adjusted] END),0.0),
		       @event_qty = @event_qty - ISNULL(SUM([source_qty_shipped]),0.0)
		  FROM (SELECT [sequence_id], [home_amount], [oper_amount], [home_adjusted], [oper_adjusted], [contract_ctrl_num], [vendor_code], [part_no], [source_qty_shipped], [source_apply_date], [all_parts_flag] FROM [#pr_events] WHERE source_trx_type = 4092) t 		-- inclusive contracts
		 WHERE [contract_ctrl_num] = @parent
		   AND [vendor_code] = @vendor_code
		   AND (([part_no] = @part_no) OR ([all_parts_flag] = 1))																										-- inclusive contracts
		   AND [sequence_id] = @sequence_id
	END
END
ELSE
BEGIN
	SELECT @event_amount = @amount, @event_qty = @qty
END

SELECT @part_category = [category]
  FROM [inv_master]
 WHERE [part_no] = @part_no

IF (@all_parts_flag = 0)
BEGIN
	IF EXISTS (SELECT 1 FROM [pr_parts_vw] WHERE [contract_ctrl_num] = @contract_ctrl_num AND [part_no] = @part_no)
	BEGIN
		SELECT 	@percent_flag = [percent_flag],
			@part_category = [part_category]
		  FROM [pr_parts_vw]
		 WHERE [contract_ctrl_num] = @contract_ctrl_num
		   AND [part_no] = @part_no
	END
	ELSE
	BEGIN
		SELECT 	@percent_flag = [percent_flag],
			@part_no = [part_no]
		  FROM [pr_parts_vw]
		 WHERE [contract_ctrl_num] = @contract_ctrl_num
		   AND [part_category] = @part_category
	END
END
ELSE
BEGIN									
--
-- inclusive contracts
-- All inclusive contracts are percentages based on the total dollars spent by the customer
--
	SELECT @percent_flag = 1,
	       @part_no = [part_no], 
	       @part_category = ''
	  FROM [pr_parts]
	 WHERE [contract_ctrl_num] = @contract_ctrl_num
	   AND [sequence_id] = 1
	SELECT @rowcount = @@ROWCOUNT

	IF (@rowcount = 0)
	BEGIN
		IF @debug_flag > 0 BEGIN SELECT 'debug'='Cannot locate the part for this inclusive contract' END
		IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
	END
END

IF @debug_flag > 0
BEGIN
	SELECT 'event_amount'=@event_amount, 'event_qty'=@event_qty, 'percent_flag'=@percent_flag, 'part_category'=@part_category, 'part_no'=@part_no, 'amount'=@amount, 'qty'=@qty, 'date_applied'=@date_applied, 'all_parts_flag'=@all_parts_flag
END

--
-- If events total zero, then bail
--
IF @percent_flag = 1
BEGIN
	IF @amount = 0
	BEGIN
		IF @debug_flag > 0 BEGIN SELECT 'debug'='Exiting because amount is zero' END
		IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=0 END RETURN 0
	END
END
ELSE
BEGIN
	IF @qty = 0
	BEGIN
		IF @debug_flag > 0 BEGIN SELECT 'debug'='Exiting because qty is zero' END
		IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=0 END RETURN 0
	END
END

--
-- First calculate total rebate, then calculate total rebate before this event.  The event rebate will 
-- be the difference between these two values.
--
SELECT @level = 0, @rebate_after_event = 0
WHILE (42=42)
BEGIN
	SET ROWCOUNT 1

	SELECT 	@level = [level],
		@from = [from_range],
		@to = [to_range],
		@pct = [rebate]
	  FROM	[pr_levels_vw]
	 WHERE	[contract_ctrl_num] = @contract_ctrl_num
	   AND	[part_no] = @part_no
	   AND	[part_category] = @part_category
	   AND	[level] > @level
	 ORDER BY [level]
	SELECT @rowcount = @@ROWCOUNT

	SET ROWCOUNT 0

	IF @rowcount = 0
	BEGIN
		BREAK
	END

	IF @percent_flag = 1
	BEGIN
		IF @to = 0 OR (@amount > @from AND @amount <= @to)
		BEGIN
			SELECT @rebate_after_event = @rebate_after_event + ((@amount - @from) * (@pct/100.00))
			IF @debug_flag > 0
			BEGIN
				SELECT 	'contract_ctrl_num'=@contract_ctrl_num, 'part_no'=@part_no, 'part_category'=@part_category, 'level'=@level, 'from'=@from, 'to'=@to, 'pct'=@pct, 'rebate_after_event'=@rebate_after_event, 'amount'=@amount
			END
			BREAK
		END
		ELSE
		BEGIN
			IF (@amount > @from)
			BEGIN
				SELECT @rebate_after_event = @rebate_after_event + ((@to-@from) * (@pct/100.00))
			END
		END
	END
	ELSE
	BEGIN
		IF @to = 0 OR (@qty > @from AND @qty <= @to)
		BEGIN
			SELECT @rebate_after_event = @rebate_after_event + ((@qty - @from) * @pct)
			IF @debug_flag > 0
			BEGIN
				SELECT 	'contract_ctrl_num'=@contract_ctrl_num, 'part_no'=@part_no, 'part_category'=@part_category, 'level'=@level, 'from'=@from, 'to'=@to, 'pct'=@pct, 'rebate_after_event'=@rebate_after_event, 'qty'=@qty
			END
			BREAK
		END
		ELSE
		BEGIN
			IF (@qty > @from)
			BEGIN
				SELECT @rebate_after_event = @rebate_after_event + ((@to-@from) * @pct)
			END
		END
	END

	IF @debug_flag > 0
	BEGIN
		SELECT 	'contract_ctrl_num'=@contract_ctrl_num, 'part_no'=@part_no, 'part_category'=@part_category, 'level'=@level, 'from'=@from, 'to'=@to, 'pct'=@pct, 'rebate_after_event'=@rebate_after_event, 'amount'=@amount, 'qty'=@qty
	END

END

--
-- If all the levels have been satisfied, then the customer has satisified the contract for this part
--
SELECT @satisfied = 0
IF @rowcount = 0 OR @to = 0
BEGIN
	SELECT @satisfied = 1
END

SELECT @level = 0, @rebate_before_event = 0, @amount = @amount - @event_amount, @qty = @qty - @event_qty

IF ((@percent_flag = 1 AND @amount = 0.00) OR (@percent_flag = 0 AND @qty = 0.00))
BEGIN
	SELECT @rebate_before_event = 0.00
END
ELSE
BEGIN
	WHILE (42=42)
	BEGIN
		SET ROWCOUNT 1
	
		SELECT 	@level = [level],
			@from = [from_range],
			@to = [to_range],
			@pct = [rebate]
		  FROM	[pr_levels_vw]
		 WHERE	[contract_ctrl_num] = @contract_ctrl_num
		   AND	[part_no] = @part_no
		   AND	[part_category] = @part_category
		   AND	[level] > @level
		 ORDER BY [level]
		SELECT @rowcount = @@ROWCOUNT
	
		SET ROWCOUNT 0
	
		IF @rowcount = 0
		BEGIN
			BREAK
		END
	
		IF @percent_flag = 1
		BEGIN
			IF @to = 0 OR (@amount > @from AND @amount <= @to)
			BEGIN
				SELECT @rebate_before_event = @rebate_before_event + ((@amount - @from) * (@pct/100.00))
				IF @debug_flag > 0
				BEGIN
					SELECT 	'contract_ctrl_num'=@contract_ctrl_num, 'part_no'=@part_no, 'part_category'=@part_category, 'level'=@level, 'from'=@from, 'to'=@to, 'pct'=@pct, 'rebate_before_event'=@rebate_before_event, 'amount'=@amount
				END
				BREAK
			END
			ELSE
			BEGIN
				IF (@amount > @from)
				BEGIN
					SELECT @rebate_before_event = @rebate_before_event + ((@to-@from) * (@pct/100.00))
				END
			END
		END
		ELSE
		BEGIN
			IF @to = 0 OR (@qty > @from AND @qty <= @to)
			BEGIN
				SELECT @rebate_before_event = @rebate_before_event + ((@qty - @from) * @pct)
				IF @debug_flag > 0
				BEGIN
					SELECT 	'contract_ctrl_num'=@contract_ctrl_num, 'part_no'=@part_no, 'part_category'=@part_category, 'level'=@level, 'from'=@from, 'to'=@to, 'pct'=@pct, 'rebate_before_event'=@rebate_before_event, 'qty'=@qty
				END
				BREAK
			END
			ELSE
			BEGIN
				IF (@qty > @from)
				BEGIN
					SELECT @rebate_before_event = @rebate_before_event + ((@to-@from) * @pct)
				END
			END
		END
	
		IF @debug_flag > 0
		BEGIN
			SELECT 	'contract_ctrl_num'=@contract_ctrl_num, 'part_no'=@part_no, 'part_category'=@part_category, 'level'=@level, 'from'=@from, 'to'=@to, 'pct'=@pct, 'rebate_before_event'=@rebate_before_event, 'amount'=@amount, 'qty'=@qty
		END
	
	END
END
SELECT @rebate = @rebate_after_event - @rebate_before_event
IF @debug_flag > 0
BEGIN
	SELECT 'rebate'=@rebate, 'rebate_after_event'=@rebate_after_event, 'rebate_before_event'=@rebate_before_event, 'satisfied'=@satisfied 
END

--
-- CHECK ACCUMULATORS
--
IF @called_by_accumulator = 0
BEGIN
	SELECT @accumulator_rebate = 0.0
	IF @customer_code <> ''
	BEGIN
		SELECT @location = @procedure_name + ' - ' + 'Check accumulators for customers' + ' at line ' + RTRIM(LTRIM(STR(573))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		EXEC @ret = pr_accumulators_sp 	@contract_ctrl_num = @contract_ctrl_num,
						@sequence_id = @sequence_id,
						@customer_code = @customer_code,
						@vendor_code = '',
						@rebate = @accumulator_rebate OUTPUT,
						@userid = @userid,
						@debug_flag = @debug_flag
		
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
			EXEC pr_replace_keyword_sp @text_value OUTPUT, '<0>', 'pr_accumulator_sp'
			EXEC pr_replace_keyword_sp @text_value OUTPUT, '<1>', @buf
			EXEC pr_replace_keyword_sp @text_value OUTPUT, '<2>', @location
			SELECT @buf = @text_value
			RAISERROR (@buf,16,1)
			IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
		END
		IF @debug_flag > 0 BEGIN SELECT 'customer_accumulator_rebate'=@accumulator_rebate END
	END

	IF @vendor_code <> ''
	BEGIN
		SELECT @location = @procedure_name + ' - ' + 'Check accumulators for vendors' + ' at line ' + RTRIM(LTRIM(STR(600))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		EXEC @ret = pr_accumulators_sp 	@contract_ctrl_num = @contract_ctrl_num,
						@sequence_id = @sequence_id,
						@customer_code = '',
						@vendor_code = @vendor_code,
						@rebate = @accumulator_rebate,
						@userid = @userid,
						@debug_flag = @debug_flag
		
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
			EXEC pr_replace_keyword_sp @text_value OUTPUT, '<0>', 'pr_accumulator_sp'
			EXEC pr_replace_keyword_sp @text_value OUTPUT, '<1>', @buf
			EXEC pr_replace_keyword_sp @text_value OUTPUT, '<2>', @location
			SELECT @buf = @text_value
			RAISERROR (@buf,16,1)
			IF @debug_flag > 0 BEGIN SELECT 'PS_RETURN'=-1 END RETURN -1
		END
		IF @debug_flag > 0 BEGIN SELECT 'vendor_accumulator_rebate'=@accumulator_rebate END
	END

	SELECT @rebate = @rebate + @accumulator_rebate
END

IF @debug_flag > 0 BEGIN SELECT 'satisfied'=@satisfied END
IF @debug_flag > 0 BEGIN SELECT 'sequence_id'=@sequence_id END
IF @debug_flag > 0 BEGIN SELECT 'rebate'=@rebate END

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
GRANT EXECUTE ON  [dbo].[pr_event_rebate_sp] TO [public]
GO
