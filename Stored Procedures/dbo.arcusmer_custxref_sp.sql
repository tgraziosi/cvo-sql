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























CREATE PROCEDURE [dbo].[arcusmer_custxref_sp] @process_ctrl_num VARCHAR(16), @object_id VARCHAR(16), @table_name VARCHAR(128), @column_name VARCHAR(128), @trial_flag INTEGER = 1, @debug_level INTEGER = 0
AS

DECLARE @buf				VARCHAR(255)
DECLARE @rowcount			INTEGER
DECLARE @error				INTEGER
DECLARE @procedure_name		VARCHAR(255)
DECLARE @location			VARCHAR(255)

DECLARE @target_customer 	VARCHAR(12)
DECLARE @minpart_no			VARCHAR(30)
DECLARE @delrows			INTEGER
DECLARE @insrows			INTEGER
DECLARE @str_msg_err		VARCHAR(255),
	@str_msg_ps		VARCHAR(255),
	@str_msg_at		VARCHAR(255)

SET NOCOUNT ON
SELECT @procedure_name = 'arcusmer_custxref_sp'

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

SELECT @insrows = 0

SELECT @target_customer = ''
SELECT @target_customer = ISNULL(target_customer,'')
  FROM arcusmerpctrl
 WHERE process_ctrl_num = @process_ctrl_num

BEGIN TRANSACTION cust_xref_sp

DELETE cust_xref
FROM cust_xref a
WHERE a.customer_key in (SELECT merged_customer FROM arcusmerpctrldtl WHERE process_ctrl_num = @process_ctrl_num)
AND a.part_no in (SELECT b.part_no FROM cust_xref b WHERE b.customer_key = @target_customer)

SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
SELECT @delrows = @rowcount
IF @error > 0
BEGIN
	EXEC appgetstring_sp 'STR_DELETE_CUSTXREF', @location OUT
	EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
	EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
	EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

	SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
	ROLLBACK TRANSACTION cust_xref_sp
	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
		SELECT NULL, @process_ctrl_num, @object_id, 2, -1000, @buf
	IF @debug_level > 0
		SELECT @buf
	RETURN -1
END


SELECT	@target_customer 'customer_key', a.part_no, a.location, a.last_date, a.ordered, a.shipped, a.last_price, a.cust_part, a.order_no, a.order_ext, a.note
INTO	#cust_xref
FROM	cust_xref a
WHERE	a.customer_key in (SELECT merged_customer FROM arcusmerpctrldtl WHERE process_ctrl_num = @process_ctrl_num)

SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
IF @error > 0
BEGIN
	EXEC appgetstring_sp 'STR_CREATE_#CUSTXREF', @location OUT
	EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
	EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
	EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

	SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
	ROLLBACK TRANSACTION cust_xref_sp
	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
		SELECT NULL, @process_ctrl_num, @object_id, 2, -1000, @buf
	IF @debug_level > 0
		SELECT @buf
	RETURN -1
END

SELECT	@minpart_no = MIN(part_no)
FROM	#cust_xref

WHILE	@minpart_no IS NOT NULL
BEGIN

	INSERT INTO cust_xref (customer_key, part_no, location, last_date, ordered, shipped, last_price, cust_part, order_no, order_ext, note)
		SELECT top 1 * from #cust_xref
		WHERE part_no = @minpart_no
		ORDER BY last_date DESC

	SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
	IF @error > 0
	BEGIN
		EXEC appgetstring_sp 'STR_INSERT_CUSTXREF', @location OUT
		EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
		EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
		EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

		SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
		ROLLBACK TRANSACTION cust_xref_sp
		INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
			SELECT NULL, @process_ctrl_num, @object_id, 2, -1000, @buf
		IF @debug_level > 0
			SELECT @buf
		RETURN -1
	END

	SELECT @insrows = @insrows + 1

	SELECT	@minpart_no = MIN(part_no)
	FROM	#cust_xref
	WHERE	part_no > @minpart_no

END

DELETE	cust_xref
WHERE	customer_key in (SELECT merged_customer FROM arcusmerpctrldtl WHERE process_ctrl_num = @process_ctrl_num)

SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
IF @error > 0
BEGIN
	EXEC appgetstring_sp 'STR_DELETE_NOUSE_CUSTXREF', @location OUT
	EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
	EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
	EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

	SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
	ROLLBACK TRANSACTION cust_xref_sp
	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
		SELECT NULL, @process_ctrl_num, @object_id, 2, -1000, @buf
	IF @debug_level > 0
		SELECT @buf
	RETURN -1
END

SELECT @delrows = @delrows + @rowcount


drop table #cust_xref

IF @trial_flag = 1
	ROLLBACK TRANSACTION cust_xref_sp
ELSE
	COMMIT TRANSACTION cust_xref_sp

EXEC appgetstring_sp 'STR_INSERTED_CUSTXREF', @str_msg_at  OUT
SELECT @buf = LTRIM(RTRIM(STR(@insrows))) + ' ' + @str_msg_at
INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text )
	SELECT NULL, @process_ctrl_num, @object_id, 0, 0, @buf
IF @debug_level > 0
	SELECT @buf
EXEC appgetstring_sp 'STR_DELETED_CUSTXREF', @str_msg_at  OUT
SELECT @buf = LTRIM(RTRIM(STR(@delrows))) + ' ' + @str_msg_at
INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text )
  SELECT NULL, @process_ctrl_num, @object_id, 0, 0, @buf
IF @debug_level > 0
	SELECT @buf

GO
GRANT EXECUTE ON  [dbo].[arcusmer_custxref_sp] TO [public]
GO
