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























CREATE PROCEDURE [dbo].[arcusmer_admarcontacts_sp] @process_ctrl_num VARCHAR(16), @object_id VARCHAR(16), @table_name VARCHAR(128), @column_name VARCHAR(128), @trial_flag INTEGER = 1, @debug_level INTEGER = 0
AS

DECLARE @buf			VARCHAR(255)
DECLARE @rowcount		INTEGER
DECLARE @error			INTEGER
DECLARE @procedure_name		VARCHAR(255)
DECLARE @location		VARCHAR(255)

DECLARE @target_customer_code	VARCHAR(12)
DECLARE @max_contact_no		INTEGER
DECLARE @mincustomer_code	VARCHAR(12)
DECLARE @minship_to_code	VARCHAR(12)
DECLARE @mincontact_no		INTEGER
DECLARE @insrows		INTEGER
DECLARE @str_msg_err		VARCHAR(255),
	@str_msg_ps		VARCHAR(255),
	@str_msg_at		VARCHAR(255)


SET NOCOUNT ON
SELECT @procedure_name = 'arcusmer_admarcontacts_sp'


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

SELECT 	@target_customer_code = target_customer
FROM 	arcusmerpctrl
 WHERE process_ctrl_num = @process_ctrl_num

SELECT @max_contact_no = 0

SELECT @max_contact_no = ISNULL(MAX(contact_no), 0)
  FROM adm_arcontacts
 WHERE customer_code = @target_customer_code





SELECT	@mincustomer_code = min(a.customer_code)
FROM	adm_arcontacts a, arcusmerpctrldtl b
WHERE	a.customer_code 	= b.merged_customer
AND	b.process_ctrl_num 	= @process_ctrl_num

SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
IF @error > 0
BEGIN
	EXEC appgetstring_sp 'STR_1_CUSTOMER_CODE', @location OUT
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


WHILE @mincustomer_code IS NOT NULL
BEGIN







	SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
	IF @error > 0
	BEGIN
		EXEC appgetstring_sp 'STR_NEXT_CUSTOMER_CODE', @location OUT
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





	SELECT	@minship_to_code = min(a.ship_to_code)
	FROM	adm_arcontacts a, arcusmerpctrldtl b
	WHERE	a.customer_code 	= b.merged_customer
	AND	b.process_ctrl_num 	= @process_ctrl_num
	AND     a.customer_code		= @mincustomer_code

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

	WHILE @minship_to_code IS NOT NULL
	BEGIN







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
			IF @debug_level > 0
				SELECT @buf
			RETURN -1
		END







		SELECT	@mincontact_no = min(a.contact_no)
		FROM	adm_arcontacts a, arcusmerpctrldtl b
		WHERE	a.customer_code 	= b.merged_customer
		AND	b.process_ctrl_num 	= @process_ctrl_num
		AND     a.customer_code		= @mincustomer_code
		AND	a.ship_to_code		= @minship_to_code


		SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
		IF @error > 0
		BEGIN
			EXEC appgetstring_sp 'STR_1_CONTACT_NUMBER', @location OUT
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

		WHILE @mincontact_no is not null
		BEGIN
		BEGIN TRANSACTION admarcontacts







			SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
			IF @error > 0
			BEGIN
				EXEC appgetstring_sp 'STR_NEXT_CONTACT_NUMBER', @location OUT
				EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
				EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
				EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

				SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
				ROLLBACK TRANSACTION admarcontacts
				INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
	        		SELECT NULL, @process_ctrl_num, 2, 0, @buf
				IF @debug_level > 0
					SELECT @buf
				RETURN -1
			END

			SELECT @max_contact_no = @max_contact_no + 1





			

			INSERT INTO adm_arcontacts (
							customer_code, 	ship_to_code, 	contact_no, 	contact_code,
							contact_name, 	contact_phone, 	contact_fax, 	contact_email )
	  			SELECT 	@target_customer_code,	ship_to_code,	@max_contact_no,	contact_code,
					contact_name,		contact_phone,	contact_fax,		contact_email
	    			FROM 	adm_arcontacts
	   			WHERE 	customer_code 	= @mincustomer_code
	     			AND ship_to_code 	= @minship_to_code
	     			AND contact_no 		= @mincontact_no

			SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
			
			IF @error > 0
			BEGIN
				EXEC appgetstring_sp 'STR_INSERT_ADMARCONTACTS', @location OUT
				EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
				EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
				EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

				SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
				ROLLBACK TRANSACTION admarcontacts
				INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
		       		SELECT NULL, @process_ctrl_num, 2, 0, @buf
				IF @debug_level > 0
					SELECT @buf
				RETURN -1
			END

			SELECT @insrows = @rowcount




			DELETE adm_arcontacts
	 		WHERE customer_code = @mincustomer_code
	   		AND ship_to_code = @minship_to_code
	   		AND contact_no = @mincontact_no

			SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
			IF @error > 0
			BEGIN
				EXEC appgetstring_sp 'STR_DELETE_ADMARCONTACTS', @location OUT
				EXEC appgetstring_sp 'STR_ERROR_UCASE', @str_msg_err OUT
				EXEC appgetstring_sp 'STR_IN_PROCEDURE', @str_msg_ps  OUT
				EXEC appgetstring_sp 'STR_AT_LOCATION', @str_msg_at  OUT

				SELECT @buf = @str_msg_err + ' "' + RTRIM(LTRIM(CONVERT(CHAR,@error))) + '" ' + @str_msg_ps + ' ' + @procedure_name + ' ' + @str_msg_at + ' "' + @location + '"'
				ROLLBACK TRANSACTION admarcontacts
				INSERT INTO arcusmerlog (entry_date, process_ctrl_num, [level], error_code, error_text)
					SELECT NULL, @process_ctrl_num, 2, 0, @buf
				IF @debug_level > 0
					SELECT @buf
				RETURN -1
			END
			
    			IF @trial_flag = 1
				ROLLBACK TRANSACTION admarcontacts
   			ELSE
				COMMIT TRANSACTION admarcontacts

			EXEC appgetstring_sp 'STR_INSERT_TABLE', @str_msg_ps  OUT
			EXEC appgetstring_sp 'STR_ARCONTACTS_SHIPTO', @str_msg_at  OUT
			SELECT @buf = RTRIM(LTRIM(STR(@insrows))) + ' ' + @str_msg_ps + ' ' + @table_name + ' ' + @str_msg_at
			INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text, target_customer, char1, char2)
  				SELECT NULL, @process_ctrl_num, @object_id, 0, 0, @buf, @target_customer_code,'ship_to: '+ @minship_to_code, 'contact_no: ' + RTRIM(LTRIM(STR(@max_contact_no)))
			IF @debug_level > 0
				SELECT @buf

			EXEC appgetstring_sp 'STR_DELETE_TABLE', @str_msg_ps  OUT
			SELECT @buf = RTRIM(LTRIM(STR(@insrows))) + ' ' + @str_msg_ps + ' ' + @table_name + ' ' + @str_msg_at
			INSERT INTO arcusmerlog (entry_date, process_ctrl_num, object_id, [level], error_code, error_text, merged_customer, char1, char2)
  				SELECT NULL, @process_ctrl_num, @object_id, 0, 0, @buf, @mincustomer_code, 'ship_to: '+ @minship_to_code, 'contact_no: ' + RTRIM(LTRIM(STR(@mincontact_no)))
			IF @debug_level > 0
				SELECT @buf
			
			SELECT	@mincontact_no = MIN(a.contact_no) 
			FROM	adm_arcontacts a, arcusmerpctrldtl b
			WHERE	a.customer_code 	= b.merged_customer
			AND	b.process_ctrl_num 	= @process_ctrl_num
			AND     a.customer_code		= @mincustomer_code
			AND	a.ship_to_code		= @minship_to_code
			AND	a.contact_no		> @mincontact_no
			

		END

		SELECT	@minship_to_code = MIN(a.ship_to_code)
		FROM	adm_arcontacts a, arcusmerpctrldtl b
		WHERE	a.customer_code 	= b.merged_customer
		AND	b.process_ctrl_num 	= @process_ctrl_num
		AND     a.customer_code		= @mincustomer_code
		AND	a.ship_to_code		> @minship_to_code
		
	END

	SELECT	@mincustomer_code = MIN(a.customer_code)
	FROM	adm_arcontacts a, arcusmerpctrldtl b
	WHERE	a.customer_code 	= b.merged_customer
	AND	b.process_ctrl_num 	= @process_ctrl_num
	AND	a.customer_code > @mincustomer_code

END



RETURN 0

GO
GRANT EXECUTE ON  [dbo].[arcusmer_admarcontacts_sp] TO [public]
GO
