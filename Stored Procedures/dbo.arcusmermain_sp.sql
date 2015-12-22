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























CREATE PROCEDURE [dbo].[arcusmermain_sp] @process_ctrl_num VARCHAR(16), @trial_flag INTEGER = 1, @debug_level INTEGER = 0
AS

DECLARE @buf			VARCHAR(255)
DECLARE @rowcount		INTEGER
DECLARE @error			INTEGER
DECLARE @procedure_name		VARCHAR(255)
DECLARE @location		VARCHAR(255)

DECLARE @sequence_id		INTEGER
DECLARE @object_id		VARCHAR(16)
DECLARE @table_name		VARCHAR(128)
DECLARE @column_name		VARCHAR(128)
DECLARE @proc_name		VARCHAR(128)
DECLARE @sql			VARCHAR(255)

DECLARE @seqid			INTEGER
DECLARE @maxseqid		INTEGER

DECLARE @merged_customer	VARCHAR(12)
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
DECLARE @arstat_status_type 	SMALLINT
DECLARE @smusers_user_id 	SMALLINT
DECLARE @str_msg_err		VARCHAR(255),
	@str_msg_ps		VARCHAR(255),
	@str_msg_at		VARCHAR(255)

SET NOCOUNT ON
SELECT @procedure_name = 'arcusmermain_sp'


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

EXEC appgetstring_sp 'STR_MERGE_START', @str_msg_at OUT
EXEC appgetstring_sp 'STR_CTRL_NUMBER', @str_msg_ps OUT

SELECT @buf = @str_msg_at + ' ' + RTRIM(LTRIM(CONVERT(CHAR,GETDATE()))) + ' ' + @str_msg_ps + ' ' + @process_ctrl_num
INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
  SELECT NULL, @process_ctrl_num, 0, 0, @buf


SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR

IF @error > 0
BEGIN
	EXEC appgetstring_sp 'STR_TRANS_ARCUSMERMAIN', @location OUT
	EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
	EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
	EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

	SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
	        SELECT NULL, @process_ctrl_num, 0, 0, @buf
  	IF @debug_level > 0
		SELECT @buf
    RETURN -1
END



SELECT @seqid = 1

select @maxseqid = max(sequence_id)  from arcusmerobjects

WHILE @seqid <= @maxseqid
BEGIN

	SELECT 	@sequence_id	= sequence_id, 
		@object_id	= object_id, 
		@table_name	= table_name, 
		@column_name	= column_name, 
		@proc_name	= procedure_name
	FROM 	arcusmerobjects
	WHERE	sequence_id = @seqid

	SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR

	IF @error > 0
	BEGIN
		EXEC appgetstring_sp 'STR_ARCUSMEROBJECTS', @location OUT
		EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
		EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
		EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

		SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
		INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
	        	SELECT NULL, @process_ctrl_num, 0, 0, @buf
		IF @debug_level > 0
			SELECT @buf
		RETURN -1
	END

	SELECT @buf = @proc_name + ' ''' + @process_ctrl_num + ''', ''' + @object_id + ''', ''' + @table_name + ''', ''' + @column_name + ''', ' + RTRIM(LTRIM(STR(@trial_flag))) + ', ' + RTRIM(LTRIM(STR(@debug_level)))
        
	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
		SELECT NULL, @process_ctrl_num, 0, 0, @buf

	EXEC (@buf)

	SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR

	IF @error > 0 

	BEGIN
		EXEC appgetstring_sp 'STR_EXEC_DYNAMIC_SQL', @location OUT
		EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
		EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
		EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

		SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
		INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
	        	SELECT NULL, @process_ctrl_num, 0, 0, @buf
		IF @debug_level > 0
			SELECT @buf
		RETURN -1
	END

	IF @debug_level > 0
		SELECT @buf

	IF EXISTS (SELECT 1 FROM arcusmerlog WHERE [level] = 2 AND [process_ctrl_num] = @process_ctrl_num)

	BEGIN
		EXEC appgetstring_sp 'STR_MERGE_ERROR', @str_msg_ps OUT
		EXEC appgetstring_sp 'STR_CTRL_NUMBER', @str_msg_at OUT
		SELECT @buf = @str_msg_ps + ' ' + RTRIM(LTRIM(CONVERT(CHAR,GETDATE()))) + ' ' + @str_msg_at + ' ' + @process_ctrl_num
		INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
		        SELECT NULL, @process_ctrl_num, 0, 0, @buf
		IF @debug_level > 0
			SELECT @buf
		RETURN -1
        END
	
	SELECT 	@seqid = min(sequence_id)
	FROM	arcusmerobjects
	WHERE	sequence_id > @seqid
END

    --
    -- Mark the merged customers "inactive".
    --
    SELECT @arstat_status_type = [status_type]
            FROM [arstat]
            WHERE UPPER([status_code]) = 'INACTIVE'
    IF @@ROWCOUNT = 0         
        BEGIN
			EXEC appgetstring_sp 'STR_ERROR_PROCEDURE', @str_msg_err OUT
			EXEC appgetstring_sp 'STR_STATUS_ARSTAT', @location OUT
			EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at OUT
			SELECT @buf = @str_msg_err + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
			INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
                SELECT NULL, @process_ctrl_num, @object_id, 2, -1000, @buf
			IF @debug_level > 0
				SELECT @buf 
			RETURN -1
        END

    SELECT @smusers_user_id = [user_id] 
        FROM [CVO_Control]..[smusers] 
        WHERE [user_name] = SUSER_SNAME() 
                AND [deleted] = 0
    IF @@ROWCOUNT = 0
        SET @smusers_user_id = 1  

    
          
    SET @sql = 'UPDATE [arcust] SET [status_type] = ' + CAST(@arstat_status_type AS VARCHAR) + ', [added_by_date] = NULL, [modified_by_user_name] = ''' + CAST(@smusers_user_id AS VARCHAR) + ''', [modified_by_date] = GETDATE() WHERE [customer_code] IN (SELECT [merged_customer] FROM [arcusmerpctrldtl] WHERE [process_ctrl_num] = ''' + @process_ctrl_num + ''')'
 
    EXEC appgetstring_sp 'STR_MERGE_INACTIVE', @str_msg_ps  OUT

    INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
            SELECT NULL, @process_ctrl_num, 0, 0, @sql + ' ' + @str_msg_ps  

    BEGIN TRANSACTION arcusmermain_sp

    EXEC (@sql)

    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error > 0
        BEGIN
			EXEC appgetstring_sp 'STR_UPDATE_ARCUST', @location OUT
			EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
			EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
			EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

			SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
			ROLLBACK TRANSACTION arcusmermain_sp
			INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text)
                SELECT NULL, @process_ctrl_num, @object_id, 2, -1000, @buf
			IF @debug_level > 0
				SELECT @buf
			RETURN -1
		END

	IF @debug_level > 0
		SELECT @sql

    IF @trial_flag = 1
	ROLLBACK TRANSACTION arcusmermain_sp
    ELSE
	COMMIT TRANSACTION arcusmermain_sp

 
EXEC appgetstring_sp 'STR_CTRL_NUMBER', @str_msg_ps OUT
EXEC appgetstring_sp 'STR_MERGE_COMPLETE', @str_msg_at OUT

SELECT @buf = @str_msg_at + ' ' + RTRIM(LTRIM(CONVERT(CHAR,GETDATE()))) + ' ' + @str_msg_ps + ' ' + @process_ctrl_num
INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
  SELECT NULL, @process_ctrl_num, 0, 0, @buf

IF @debug_level > 0
	SELECT @buf

GO
GRANT EXECUTE ON  [dbo].[arcusmermain_sp] TO [public]
GO
