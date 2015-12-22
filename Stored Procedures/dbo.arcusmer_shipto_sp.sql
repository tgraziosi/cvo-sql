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























CREATE PROCEDURE [dbo].[arcusmer_shipto_sp] @process_ctrl_num VARCHAR(16), @object_id VARCHAR(16), @table_name VARCHAR(128), @column_name VARCHAR(128) = '', @trial_flag INTEGER = 1, @debug_level INTEGER = 0
AS

DECLARE @buf				VARCHAR(255)
DECLARE @sql				VARCHAR(255)
DECLARE @rowcount			INTEGER
DECLARE @error				INTEGER
DECLARE @procedure_name		VARCHAR(255)
DECLARE @location			VARCHAR(255)
DECLARE @target_customer	VARCHAR(12)
DECLARE @target_shipto		VARCHAR(8)
DECLARE @minmerged_shipto	VARCHAR(8)
DECLARE @minmerged_customer	VARCHAR(12)
DECLARE @updrows			INTEGER
DECLARE @str_msg_err		VARCHAR(255),
	@str_msg_ps		VARCHAR(255),
	@str_msg_at		VARCHAR(255)

SET NOCOUNT ON
SELECT @procedure_name = 'arcusmer_shipto_sp'


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
	RETURN -1
END

SELECT @updrows = 0

SELECT	@target_customer = target_customer
FROM	arcusmerpctrl
WHERE	process_ctrl_num = @process_ctrl_num

SELECT	@minmerged_customer = min(merged_customer) 
FROM	arcusmerpctrldtl 
WHERE	process_ctrl_num =  @process_ctrl_num

SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
IF @error > 0
BEGIN
	EXEC appgetstring_sp 'STR_1_MERGE_CUSTOMER', @location OUT
	EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
	EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
	EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

	SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
		SELECT NULL, @process_ctrl_num, 2, 0, @buf
	IF @debug_level > 0
		SELECT @buf
	RETURN -1
END




IF EXISTS (SELECT 1 FROM armaster_all where customer_code = @minmerged_customer AND address_type = 1)
BEGIN
	BEGIN TRANSACTION shipto_sp

	WHILE	@minmerged_customer IS NOT NULL
	BEGIN

		SELECT	@minmerged_shipto = min(ship_to_code) 
		FROM	armaster_all 
		WHERE	customer_code = @minmerged_customer
		AND		address_type = 1

		SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
		IF @error > 0
		BEGIN
			EXEC appgetstring_sp 'STR_1_SHIPTO_CODE', @location OUT
			EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
			EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
			EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

			SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
			INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
				SELECT NULL, @process_ctrl_num, 2, 0, @buf
			IF @debug_level > 0
				SELECT @buf
			RETURN -1
		END


		WHILE	@minmerged_shipto IS NOT NULL
		BEGIN

			IF		@minmerged_shipto not in 
					(
						SELECT	ship_to_code
						FROM	armaster_all
						WHERE	customer_code = @target_customer
						AND		address_type  = 1
					 )
			BEGIN

				SELECT @sql = 'UPDATE armaster_all SET customer_code = ''' + @target_customer + ''' WHERE customer_code = ''' + @minmerged_customer + ''' AND ship_to_code = ''' + @minmerged_shipto + ''' AND address_type = 1'

				

					EXEC(@sql)			

					SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
					IF @error > 0
					BEGIN
						EXEC appgetstring_sp 'STR_1_SHIPTO_CODE', @location OUT
						EXEC appgetstring_sp 'STR_UPDATING', @str_msg_err OUT
						EXEC appgetstring_sp 'STR_CUSTOMER', @str_msg_ps  OUT
						EXEC appgetstring_sp 'STR_AND_SHIPTO', @str_msg_at  OUT
						SELECT @location = @str_msg_err + ' ' + @table_name + ' ' + @str_msg_ps + ' ' + @minmerged_customer + ' ' + @str_msg_at + ' ' + @minmerged_shipto

						EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
						EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
						EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

						SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'

						ROLLBACK TRANSACTION shipto_sp
						INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
		       				SELECT NULL, @process_ctrl_num, 2, 0, @buf
						RETURN -1
					END
			
					SELECT @updrows = @updrows + @rowcount

			END
			
			SELECT	@minmerged_shipto = min(ship_to_code) 
			FROM	armaster_all 
			WHERE	customer_code = @minmerged_customer
			AND		address_type = 1
			AND		ship_to_code > @minmerged_shipto

			SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR

			IF @error > 0
				BEGIN
					EXEC appgetstring_sp 'STR_NEXT_SHIPTO_CODE', @location OUT
					EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
					EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
					EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

					SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
					INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
	        			SELECT NULL, @process_ctrl_num, 2, 0, @buf
					RETURN -1
				END


		END

		SELECT	@minmerged_customer = min(merged_customer) 
		FROM	arcusmerpctrldtl 
		WHERE	process_ctrl_num =  @process_ctrl_num
		AND		merged_customer  >  @minmerged_customer

		SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
		IF @error > 0
		BEGIN
			EXEC appgetstring_sp 'STR_NEXT_MERGE_CUSTOMER', @location OUT
			EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
			EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
			EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

			SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
			INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
				SELECT NULL, @process_ctrl_num, 2, 0, @buf
			IF @debug_level > 0
				SELECT @buf
			RETURN -1
		END
	END

	IF @trial_flag = 1
		ROLLBACK TRANSACTION shipto_sp
	ELSE
		COMMIT TRANSACTION shipto_sp

END

EXEC appgetstring_sp 'STR_ROWS_CHANGED', @str_msg_ps  OUT
SELECT @buf = RTRIM(LTRIM(STR(@updrows))) + ' ' + @str_msg_ps + ' ' + @table_name + '.' + @column_name
INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
	SELECT NULL, @process_ctrl_num, @object_id, 0, 0, @buf

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[arcusmer_shipto_sp] TO [public]
GO
