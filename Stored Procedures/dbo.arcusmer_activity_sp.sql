SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                























CREATE PROCEDURE [dbo].[arcusmer_activity_sp] @process_ctrl_num VARCHAR(16), @object_id VARCHAR(16), @table_name VARCHAR(128), @column_name VARCHAR(128) , @trial_flag INTEGER = 1, @debug_level INTEGER = 0
AS

DECLARE @buf			VARCHAR(255)
DECLARE @rowcount		INTEGER
DECLARE @error			INTEGER
DECLARE @procedure_name		VARCHAR(255)
DECLARE @location		VARCHAR(255)

DECLARE @today			INTEGER
DECLARE @target_customer_code	VARCHAR(12)
DECLARE @str_msg_err		VARCHAR(255),
	@str_msg_ps		VARCHAR(255),
	@str_msg_at		VARCHAR(255)

SET NOCOUNT ON
SELECT @procedure_name = 'arcusmer_activity_sp'


IF NOT EXISTS (SELECT 1 FROM arcusmerpctrl WHERE process_ctrl_num = @process_ctrl_num)
BEGIN

		EXEC appgetstring_sp 'STR_ERROR_CTRLNUM', @str_msg_err OUT
		EXEC appgetstring_sp 'STR_NOTEXISTS_CUSMERPCTRL', @str_msg_at OUT

		SELECT @buf = @str_msg_err + ' ' + @process_ctrl_num + ' ' + @str_msg_at
		INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
	                SELECT NULL, @process_ctrl_num, 0, 0, @buf
		IF @debug_level > 0
			SELECT @buf
		RETURN -1
END

IF NOT EXISTS (SELECT 1 FROM arcusmerpctrldtl WHERE process_ctrl_num = @process_ctrl_num)
BEGIN
		EXEC appgetstring_sp 'STR_ERROR_CTRLNUM', @str_msg_err OUT
		EXEC appgetstring_sp 'STR_NOTEXISTS_CUSMERPCTRLDTL', @str_msg_at OUT

		SELECT @buf = @str_msg_err + ' ' + @process_ctrl_num + ' ' + @str_msg_at
		INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
	                SELECT NULL, @process_ctrl_num, 0, 0, @buf
		IF @debug_level > 0
			SELECT @buf
		RETURN -1
END

IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = @table_name AND type = 'U')
BEGIN
		EXEC appgetstring_sp 'STR_TABLE', @str_msg_err OUT
		EXEC appgetstring_sp 'STR_NOT_EXISTS', @str_msg_at OUT

	SELECT @buf = @str_msg_err + ' ' + @table_name + ' ' + @str_msg_at
	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
	  SELECT NULL, @process_ctrl_num, @object_id, 0, 0, @buf
	IF @debug_level > 0
		SELECT @buf
	RETURN 0
END





IF UPPER(@table_name) = 'ARACTCUS'
BEGIN 

BEGIN TRANSACTION ARACTCUS_SP
	EXEC aractsum_sp 1, 0, 0, 0, 0, 0, 0, 0, 0, 0
	SELECT @error = @@ERROR
	IF @error > 0
	BEGIN
		EXEC appgetstring_sp 'STR_LOCATION_CUSTOMER_ACTIVITY', @location OUT
		EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
		EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
		EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

		SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
		ROLLBACK TRANSACTION ARACTCUS_SP
		INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
			SELECT NULL, @process_ctrl_num, @object_id, 2, -1000, @buf
		IF @debug_level > 0
			SELECT @buf
		RETURN -1
	END
IF @trial_flag = 1
	ROLLBACK TRANSACTION ARACTCUS_SP
ELSE
	COMMIT TRANSACTION ARACTCUS_SP

	EXEC appgetstring_sp 'STR_CUSTOMER_ACTIVITY_UPD', @buf OUT

	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
		SELECT NULL, @process_ctrl_num, @object_id, 0, 0, @buf
	IF @debug_level > 0
		SELECT @buf
	RETURN 0
END





IF UPPER(@table_name) = 'ARACTSHP'
BEGIN 

BEGIN TRANSACTION ARACTSHP_SP
	EXEC aractsum_sp 0, 1, 0, 0, 0, 0, 0, 0, 0, 0
	SELECT @error = @@ERROR
	IF @error > 0
	BEGIN

		EXEC appgetstring_sp 'STR_LOCATION_SHIPTO_ACTIVITY', @location OUT
		EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
		EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
		EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

		SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
		ROLLBACK TRANSACTION ARACTSHP_SP
		INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
			SELECT NULL, @process_ctrl_num, @object_id, 2, -1000, @buf
		IF @debug_level > 0
			SELECT @buf
		RETURN -1
	END

IF @trial_flag = 1
	ROLLBACK TRANSACTION ARACTSHP_SP
ELSE
	COMMIT TRANSACTION ARACTSHP_SP

	EXEC appgetstring_sp 'STR_CUSTOMER_ACTIVITY_UPD', @buf OUT
	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text, char1)
		SELECT NULL, @process_ctrl_num, @object_id, 0, 0, @buf, @procedure_name
	IF @debug_level > 0
		SELECT @buf
	RETURN 0
END





IF UPPER(@table_name) = 'ARSUMCUS'
BEGIN 

BEGIN TRANSACTION ARSUMCUS_SP
	EXEC aractsum_sp 0, 0, 0, 0, 0, 1, 0, 0, 0, 0
	SELECT @error = @@ERROR
	IF @error > 0
	BEGIN
		EXEC appgetstring_sp 'STR_CUSTOMER_SUMMARY', @location OUT
		EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
		EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
		EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

		SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps+ ' ' + @procedure_name + ' ' + @str_msg_at +' "' + @location + '"'
		ROLLBACK TRANSACTION ARSUMCUS_SP
		INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
			SELECT NULL, @process_ctrl_num, @object_id, 2, -1000, @buf
		IF @debug_level > 0
			SELECT @buf
		RETURN -1
	END

IF @trial_flag = 1
	ROLLBACK TRANSACTION ARSUMCUS_SP
ELSE
	COMMIT TRANSACTION ARSUMCUS_SP

	EXEC appgetstring_sp 'STR_CUSTOMER_SUMMARY_UPD', @buf OUT
	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text, char1)
		SELECT NULL, @process_ctrl_num, @object_id, 0, 0, @buf, @procedure_name
	IF @debug_level > 0
		SELECT @buf
	RETURN 0
END





IF UPPER(@table_name) = 'ARSUMSHP'
BEGIN 

BEGIN TRANSACTION ARSUMSHP_SP
	EXEC aractsum_sp 0, 0, 0, 0, 0, 0, 1, 0, 0, 0
	SELECT @error = @@ERROR
	IF @error > 0
	BEGIN
		EXEC appgetstring_sp 'STR_SHIPTO_SUMMARY', @location OUT
		EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
		EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
		EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

		SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps+ ' ' + @procedure_name + ' ' + @str_msg_at +' "' + @location + '"'
		ROLLBACK TRANSACTION ARSUMSHP_SP
		INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
			SELECT NULL, @process_ctrl_num, @object_id, 2, -1000, @buf
		IF @debug_level > 0
			SELECT @buf
		RETURN -1
	END

IF @trial_flag = 1
	ROLLBACK TRANSACTION ARSUMSHP_SP
ELSE
	COMMIT TRANSACTION ARSUMSHP_SP

	EXEC appgetstring_sp 'STR_SHIPTO_SUMMARY_UPD', @buf OUT
	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text, char1)
		SELECT NULL, @process_ctrl_num, @object_id, 0, 0, @buf, @procedure_name
	IF @debug_level > 0
		SELECT @buf
	RETURN 0
END





IF UPPER(@table_name) = 'AGING'
BEGIN 

BEGIN TRANSACTION AGING_SP
	SELECT @target_customer_code = target_customer
	  FROM arcusmerpctrl
	 WHERE process_ctrl_num = @process_ctrl_num

	SELECT @today = DATEDIFF(DD,'1/1/80',GETDATE())+722815

	EXEC arageact_sp @today, 1, 0, 0, 0,@target_customer_code, @target_customer_code, "<First>", "<Last>", "<First>", "<Last>","<First>", "<Last>", 1, 0, 0, 0
	SELECT @error = @@ERROR
	IF @error > 0
	BEGIN
		EXEC appgetstring_sp 'STR_AGING_ACTIVITY', @location OUT
		EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
		EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
		EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

		SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps+ ' ' + @procedure_name + ' ' + @str_msg_at +' "' + @location + '"'
		ROLLBACK TRANSACTION AGING_SP
		INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
			SELECT NULL, @process_ctrl_num, @object_id, 2, -1000, @buf
		IF @debug_level > 0
			SELECT @buf
		RETURN -1
	END

IF @trial_flag = 1
	ROLLBACK TRANSACTION AGING_SP
ELSE
	COMMIT TRANSACTION AGING_SP

	EXEC appgetstring_sp 'STR_AGING_ACTIVITY_UPD', @buf OUT

	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text, char1)
		SELECT NULL, @process_ctrl_num, @object_id, 0, 0, @buf, @procedure_name
	IF @debug_level > 0
		SELECT @buf
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[arcusmer_activity_sp] TO [public]
GO
