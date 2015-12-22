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
























CREATE PROCEDURE [dbo].[arcusmerpctrl_sp] @customer_code VARCHAR(12), @trial_flag INTEGER = 1, @debug_level INTEGER = 0, @curruser VARCHAR(30)
AS
DECLARE @process_ctrl_num	VARCHAR(16)
DECLARE @buf			VARCHAR(255)
DECLARE @rowcount		INTEGER
DECLARE @error			INTEGER
DECLARE @procedure_name		VARCHAR(255)
DECLARE @location		VARCHAR(255)
DECLARE @sql			VARCHAR(255)
DECLARE @num			INTEGER

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
DECLARE @mincust_code		VARCHAR(12)
DECLARE @str_msg_err		VARCHAR(255),
	@str_msg_ps		VARCHAR(255),
	@str_msg_at		VARCHAR(255)

SET NOCOUNT ON
SELECT @procedure_name = 'arcusmerpctrl_sp'

BEGIN TRANSACTION arcusmerpctrl_sp

EXEC @error = ARGetNextControl_SP 	2140,  
					@process_ctrl_num OUTPUT,  
					@num OUTPUT

SELECT @process_ctrl_num = RTRIM(@process_ctrl_num)

INSERT INTO arcusmerpctrl (process_ctrl_num, 	target_customer, 	on_order,
			  unposted,		posted_count,		paid_count,
			  overdue_count, 	bucket1,		bucket2,
			  bucket3,		bucket4,		bucket5,
			  bucket6,		on_account,		balance, 
			  trial_flag, 		entry_date, username, date_executed) 
VALUES 			 (@process_ctrl_num,	@customer_code,		0.0,
			  0,			0,			0,
			  0,			0.0,			0.0,
			  0.0,			0.0,			0.0,
			  0.0,			0.0,			0.0,
			  0,			NULL,	@curruser,	GETDATE())
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR

IF @error > 0
BEGIN
	EXEC appgetstring_sp 'STR_INSERT_ARCUSMERPCTRL', @location OUT
	EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
	EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
	EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

	SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
	ROLLBACK TRANSACTION arcusmerpctrl_sp
	INSERT INTO arcusmerlog (entry_date, [level], error_code, error_text)
        SELECT NULL, 0, 0, @buf
	IF (@debug_level > 0)
		SELECT @buf
	RETURN -1
END

	EXEC appgetstring_sp 'STR_TARGET_CUSTOMER', @str_msg_ps OUT
	SELECT @buf = @customer_code + ' ' + @str_msg_ps
	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
		SELECT NULL, @process_ctrl_num, 0, 0, @buf

	IF (@debug_level > 0)
	SELECT @buf

COMMIT TRANSACTION arcusmerpctrl_sp


IF NOT EXISTS (SELECT 1 FROM arcust WHERE customer_code = @customer_code)
BEGIN	
	EXEC appgetstring_sp 'STR_INVALID_CUSCODE', @location OUT
	EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
	EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
	EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

	SELECT @error = -1000
	SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
	INSERT INTO arcusmerlog (entry_date, [level], error_code, error_text)
        SELECT NULL, 0, 0, @buf
	IF (@debug_level > 0)
	SELECT @buf
	RETURN -1
END

SELECT	@posted_count = 0,     		@paid_count = 0,	 	@overdue_count = 0, 
	@bucket1 = 0.0,			@bucket2 = 0.0,			@bucket3 = 0.0,
	@bucket4 = 0.0,			@bucket5 = 0.0,			@bucket6 = 0.0,
	@on_order = 0.0,		@unposted = 0.0,		@balance = 0.0,
	@on_account = 0.0

SELECT	@posted_count = num_inv,     	@paid_count = num_inv_paid, 	@overdue_count = num_overdue_pyt, 
	@bucket1 = amt_age_bracket1,	@bucket2 = amt_age_bracket2,	@bucket3 = amt_age_bracket3, 
	@bucket4 = amt_age_bracket4,	@bucket5 = amt_age_bracket5,	@bucket6 = amt_age_bracket6,
	@on_order = amt_on_order,	@unposted = amt_inv_unposted,	@balance = amt_balance,		
	@on_account = amt_on_acct
FROM	aractcus
WHERE	aractcus.customer_code = @customer_code
SELECT @rowcount = @@ROWCOUNT


UPDATE arcusmerpctrl
   SET target_customer = @customer_code,
       on_order = @on_order,
       unposted = @unposted,
       posted_count = @posted_count,
       paid_count = @paid_count,
       overdue_count = @overdue_count,
       bucket1 = @bucket1,
       bucket2 = @bucket2,
       bucket3 = @bucket3,
       bucket4 = @bucket4,
       bucket5 = @bucket5,
       bucket6 = @bucket6,
       on_account = @on_account,
       balance = @balance,
       trial_flag = @trial_flag
 WHERE process_ctrl_num = @process_ctrl_num
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR

IF @error > 0
BEGIN
	EXEC appgetstring_sp 'STR_UPDATE_ARCUSMERPCTRL', @location OUT
	EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
	EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
	EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

	SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
	INSERT INTO arcusmerlog (entry_date, [level], error_code, error_text)
        SELECT NULL, 0, 0, @buf
	IF (@debug_level > 0)
	SELECT @buf
	RETURN -1
END

SELECT DISTINCT customer_code INTO #arcusmerdtl FROM #arcusmertmp

SELECT	@mincust_code = min(customer_code) FROM #arcusmerdtl

WHILE	@mincust_code IS NOT NULL
BEGIN

	SELECT @sql = 'arcusmerpctrldtl_sp ''' + @mincust_code + ''',''' + @process_ctrl_num + ''', ' + RTRIM(LTRIM(STR(@trial_flag))) + ', ' + RTRIM(LTRIM(STR(@debug_level)))
    
	EXEC(@sql)

	SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR

	IF @error > 0 

	BEGIN
		EXEC appgetstring_sp 'STR_EXEC_ARCUSMERPCTRLDTL', @location OUT
		EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
		EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
		EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

		SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
		INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
	        	SELECT NULL, @process_ctrl_num, 0, 0, @buf
		IF (@debug_level > 0)
		SELECT @buf
		RETURN -1
	END

	IF (@debug_level > 0)
	SELECT @sql

	SELECT	@mincust_code = min(customer_code) FROM #arcusmerdtl WHERE customer_code > @mincust_code

END

SELECT @sql = 'arcusmermain_sp ''' + @process_ctrl_num + ''', ' + RTRIM(LTRIM(STR(@trial_flag))) + ', ' + RTRIM(LTRIM(STR(@debug_level)))

EXEC (@sql)


SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR

IF @error > 0 

BEGIN
	EXEC appgetstring_sp 'STR_EXEC_ARCUSMERMAIN', @location OUT
	EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
	EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
	EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

	SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
        	SELECT NULL, @process_ctrl_num, 0, 0, @buf
	IF (@debug_level > 0)
	SELECT @buf
	RETURN -1
END

	IF (@debug_level > 0)
	SELECT @sql
GO
GRANT EXECUTE ON  [dbo].[arcusmerpctrl_sp] TO [public]
GO
