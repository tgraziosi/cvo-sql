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























CREATE PROCEDURE [dbo].[arcusmer_sp] @process_ctrl_num VARCHAR(16), @object_id VARCHAR(16), @table_name VARCHAR(128), @column_name VARCHAR(128), @trial_flag INTEGER = 1, @debug_level INTEGER = 0
AS

DECLARE @buf			VARCHAR(255)
DECLARE @rowcount		INTEGER
DECLARE @error			INTEGER
DECLARE @procedure_name		VARCHAR(255)
DECLARE @location		VARCHAR(255)
DECLARE @desc			VARCHAR(255)

DECLARE @sequence_id		INTEGER
DECLARE @proc_name		VARCHAR(128)
DECLARE @sql			VARCHAR(255)

DECLARE @target_customer	VARCHAR(12)
DECLARE @on_order		FLOAT
DECLARE @unposted		FLOAT
DECLARE @posted_count		INTEGER
DECLARE @paid_count		INTEGER
DECLARE @overdue_count		INTEGER
DECLARE @bucket1		FLOAT
DECLARE @bucket2		FLOAT
DECLARE @bucket3		FLOAT
DECLARE @bucket4		FLOAT
DECLARE @bucket5		FLOAT
DECLARE @bucket6		FLOAT
DECLARE @on_account		FLOAT
DECLARE @balance		FLOAT
DECLARE @str_msg_err		VARCHAR(255),
	@str_msg_ps		VARCHAR(255),
	@str_msg_at		VARCHAR(255)

SET NOCOUNT ON
SELECT @procedure_name = 'arcusmer_sp'

SELECT @desc = ISNULL(description, '') FROM arcusmerobjects WHERE object_id = @object_id


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

IF NOT EXISTS (SELECT 1 FROM syscolumns WHERE name = @column_name AND id = OBJECT_ID(@table_name))
BEGIN
	EXEC appgetstring_sp 'STR_TABLE', @str_msg_err OUT
	EXEC appgetstring_sp 'STR_NOT_EXISTS', @str_msg_at OUT

	SELECT @buf = @str_msg_err + ' ' + @table_name + '.' + @column_name + ' ' + @str_msg_at
	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
		SELECT NULL, @process_ctrl_num, @object_id, 0, 0, @buf
	IF @debug_level > 0
		SELECT @buf
	RETURN 0
END


SELECT @target_customer = target_customer
  FROM arcusmerpctrl
 WHERE process_ctrl_num = @process_ctrl_num





SELECT @sql = 'UPDATE ' + @table_name + ' SET ' + @column_name + ' = ''' + @target_customer + ''' WHERE ' + @column_name + ' in (SELECT merged_customer FROM arcusmerpctrldtl WHERE process_ctrl_num = ''' + @process_ctrl_num + ''')'
INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
        SELECT NULL, @process_ctrl_num, 0, 0, @sql

BEGIN TRANSACTION arcusmer_sp
EXEC (@sql)
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
IF @error > 0
BEGIN
	EXEC appgetstring_sp 'STR_1_UPDATING', @location OUT
	EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
	EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
	EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

	SELECT @location = @location + ' ' + RTRIM(LTRIM(@table_name)) + '.' + RTRIM(LTRIM(@column_name))
	SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
	ROLLBACK TRANSACTION arcusmer_sp
	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
	  SELECT NULL, @process_ctrl_num, @object_id, 2, -1000, @buf
	IF @debug_level > 0
		SELECT @buf
	RETURN -1
END

IF @debug_level > 0
	SELECT @sql

IF @trial_flag = 1
	ROLLBACK TRANSACTION arcusmer_sp
ELSE
	COMMIT TRANSACTION arcusmer_sp

EXEC appgetstring_sp 'STR_ROWS_CHANGED', @str_msg_ps  OUT

SELECT @buf = RTRIM(LTRIM(STR(@rowcount))) + ' ' + @str_msg_ps + ' ' + @table_name + '.' + @column_name + ' - ' + @desc
INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
  SELECT NULL, @process_ctrl_num, @object_id, 0, 0, @buf
IF @debug_level > 0
	SELECT @buf
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[arcusmer_sp] TO [public]
GO
