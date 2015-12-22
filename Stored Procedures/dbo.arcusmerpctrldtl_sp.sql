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























CREATE PROCEDURE [dbo].[arcusmerpctrldtl_sp] @customer_code VARCHAR(12), @process_ctrl_num VARCHAR(16), @trial_flag INTEGER = 1, @debug_level INTEGER = 0
AS

DECLARE @buf			VARCHAR(255)
DECLARE @rowcount		INTEGER
DECLARE @error			INTEGER
DECLARE @procedure_name		VARCHAR(255)
DECLARE @location		VARCHAR(255)

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
DECLARE @str_msg_err		VARCHAR(255),
	@str_msg_ps		VARCHAR(255),
	@str_msg_at		VARCHAR(255)

SET NOCOUNT ON
SELECT @procedure_name = 'arcusmerpctrldtl_sp'


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

IF EXISTS (SELECT 1 FROM arcusmerpctrldtl WHERE process_ctrl_num = @process_ctrl_num AND merged_customer = @customer_code)
BEGIN
	IF @debug_level > 0
	BEGIN
		EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
		EXEC appgetstring_sp 'STR_EXIST_ARCUSMERPCTRLDTL', @str_msg_at OUT
		SELECT @buf = @str_msg_err + ': ' + @process_ctrl_num + ' - ' + @customer_code + ' ' + @str_msg_at
		INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
	                SELECT NULL, @process_ctrl_num, 0, 0, @buf
		IF @debug_level > 0
			SELECT @buf
		RETURN -1
	END
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


INSERT INTO arcusmerpctrldtl (process_ctrl_num, 	merged_customer, 	on_order,
			      unposted,			posted_count,		paid_count,
			      overdue_count, 		bucket1,		bucket2,
			      bucket3,			bucket4,		bucket5,
			      bucket6,			on_account,		balance) 
VALUES 			     (@process_ctrl_num,	@customer_code,		@on_order,
			      @unposted,		@posted_count,		@paid_count,
			      @overdue_count,		@bucket1,		@bucket2,
			      @bucket3,			@bucket4,		@bucket5,
			      @bucket6,			@on_account,		@balance)
SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR

IF @error > 0
BEGIN
	EXEC appgetstring_sp 'STR_INSERT_ARCUSMERPCTRLDTL', @location OUT
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

EXEC appgetstring_sp 'STR_ADD_CUSTOMERMERGE', @str_msg_at  OUT

SELECT @buf = @customer_code + ' ' + @str_msg_at
INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
	SELECT NULL, @process_ctrl_num, 0, 0, @buf

IF @debug_level > 0
	SELECT @buf
GO
GRANT EXECUTE ON  [dbo].[arcusmerpctrldtl_sp] TO [public]
GO
