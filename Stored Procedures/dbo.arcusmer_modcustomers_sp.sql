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






















    
CREATE PROCEDURE [dbo].[arcusmer_modcustomers_sp] @process_ctrl_num VARCHAR(16), @object_id VARCHAR(16), @table_name VARCHAR(128), @column_name VARCHAR(128), @trial_flag INTEGER = 1, @debug_level INTEGER = 0
AS

DECLARE @buf			VARCHAR(255)
DECLARE @rowcount		INTEGER
DECLARE @error			INTEGER
DECLARE @procedure_name		VARCHAR(255)
DECLARE @location		VARCHAR(255)
DECLARE @str_msg_err		VARCHAR(255),
	@str_msg_ps		VARCHAR(255),
	@str_msg_at		VARCHAR(255)

SET NOCOUNT ON
SELECT @procedure_name = 'arcusmer_modcustomers_sp'


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

IF NOT EXISTS (SELECT 1 FROM mod_customers a, arcusmerpctrl b WHERE a.customer_key = b.target_customer AND b.process_ctrl_num = @process_ctrl_num)
BEGIN

BEGIN TRANSACTION mod_customers_sp

	INSERT INTO mod_customers (customer_key) 
	  SELECT target_customer 
	    FROM arcusmerpctrl 
	   WHERE process_ctrl_num = @process_ctrl_num

	IF @trial_flag = 1
		ROLLBACK TRANSACTION mod_customers_sp
	ELSE
		COMMIT TRANSACTION mod_customers_sp

	EXEC appgetstring_sp 'STR_CUSTOMER_KEY', @str_msg_err OUT
	EXEC appgetstring_sp 'STR_INSERT_MODCUSTOMERS', @str_msg_at OUT

	SELECT @buf = @str_msg_err + ' ' + RTRIM(LTRIM(target_customer)) + ' ' + @str_msg_at
	  FROM arcusmerpctrl
	 WHERE process_ctrl_num = @process_ctrl_num
	INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text, char1)
	  SELECT NULL, @process_ctrl_num, @object_id, 0, 0, @buf, @procedure_name
	IF @debug_level > 0
		SELECT @buf
END
RETURN 0

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arcusmer_modcustomers_sp] TO [public]
GO
