SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                


























CREATE PROC [dbo].[ibvalidateptax_sp]
 
		@debug_flag	integer=0,
		@level	integer=2
		


AS

-- #include "STANDARD DECLARES.INC"





































DECLARE @rowcount		INT
DECLARE @error			INT
DECLARE @errmsg			VARCHAR(128)
DECLARE @log_activity		VARCHAR(128)
DECLARE @procedure_name		VARCHAR(128)
DECLARE @location		VARCHAR(128)
DECLARE @buf			VARCHAR(1000)
DECLARE @ret			INT
DECLARE @text_value		VARCHAR(255)
DECLARE @int_value		INT
DECLARE @return_value		INT
DECLARE @transaction_started	INT
DECLARE @version			VARCHAR(128)
DECLARE @len				INTEGER
DECLARE @i				INTEGER

-- end "STANDARD DECLARES.INC"



DECLARE @ibtaxdetail_exists		INTEGER
DECLARE @ibio_exists			INTEGER
DECLARE @iberror_exists			INTEGER
DECLARE @error_code			INTEGER
DECLARE @error_level			INTEGER
DECLARE @active				INTEGER
DECLARE @home_currency			NVARCHAR(8)
DECLARE @oper_currency			NVARCHAR(8)
DECLARE @rate_type_home			NVARCHAR(8)
DECLARE @rate_type_oper			NVARCHAR(8)
DECLARE @current_period_end_date	INTEGER


SET @procedure_name='ibvalidate_sp'

    -- #include "STANDARD ENTRY.INC"
    SET NOCOUNT ON
    SELECT @location = @procedure_name + ': Location ' + 'STANDARD ENTRY' + ', line: ' + RTRIM(LTRIM(STR(3))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
    SELECT @version='1.0'
    IF @debug_flag > 0
        BEGIN
        SELECT 'PS_SIGNAL'='DIAGNOSTIC ON'
        END
    SELECT @buf = @procedure_name + ': Entry (version ' + @version + ') at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END
    SELECT @return_value = 0, @transaction_started = 0
    -- end "STANDARD ENTRY.INC"


SELECT @return_value = 0

--
-- Check for table existence
--	
	SELECT    @ibio_exists=0,@iberror_exists = 0, @ibtaxdetail_exists =0
	IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#ibio') IS NULL) BEGIN
		SELECT @ibio_exists = 1
	END
	IF @ibio_exists = 0  BEGIN
		
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

		RETURN -100
	END

	IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#ibtaxtdetail') IS NULL) BEGIN
		SELECT @ibtaxdetail_exists = 1
	END
	IF @ibtaxdetail_exists = 0  BEGIN
		
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

		RETURN -100
	END

	IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#iberror') IS NULL) BEGIN
		SELECT @iberror_exists = 1
	END
	IF @iberror_exists = 0 BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Create table #iberror' + ', line: ' + RTRIM(LTRIM(STR(79))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		--CREATE TABLE #iberror �
		

CREATE TABLE [#iberror]
(	[id]				uniqueidentifier,
	[error_code]			integer,
	[info1]				nvarchar(30),
	[info2]				nvarchar(30),
	[infoint]			integer,
	[infodecimal]			decimal(20,8),
	[link1]				nvarchar(1024),
	[link2]				nvarchar(1024),
	[link3]				nvarchar(1024)
	)

		
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	END
	

SELECT @location = @procedure_name + ': Location ' + 'Get currency info from glco' + ', line: ' + RTRIM(LTRIM(STR(86))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	SELECT @home_currency = home_currency, @oper_currency = oper_currency,
		@rate_type_home = rate_type_home, @rate_type_oper = rate_type_oper,
		@current_period_end_date =period_end_date
	    FROM glco
	
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	




--
-- Error 213 - Tax Payable Account code is invalid
-- 
	SELECT @error_code = 213
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code


	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 213 � 1' + ', line: ' + RTRIM(LTRIM(STR(107))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibtaxtdetail 
		        SET state_flag = @error_code
		
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

		SELECT @location = @procedure_name + ': Location ' + 'Validate 213 � 2' + ', line: ' + RTRIM(LTRIM(STR(111))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibtaxtdetail
				SET state_flag = 0
			     FROM #ibtaxtdetail o, glchart t
		  WHERE o.account_code = t.account_code
		
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 213 � 3' + ', line: ' + RTRIM(LTRIM(STR(118))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT ed.id, ed.state_flag, ed.account_code, '', 0, 0.0,  link1, link2, link3
		       FROM #ibtaxtdetail ed, #ibio i
		    WHERE ed.state_flag = @error_code 
			AND	i.id = ed.id
		
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	END





--
-- Error 223 -  Tax Payable Account  code is restricted to a currency code that is not compatible with the home 
--			and operational currency defined in General Ledger.
-- 
	SELECT @error_code = 222
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code


	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 223 � 1' + ', line: ' + RTRIM(LTRIM(STR(142))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibtaxtdetail 
		        SET state_flag = @error_code
		
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

		SELECT @location = @procedure_name + ': Location ' + 'Validate 223 � 2' + ', line: ' + RTRIM(LTRIM(STR(146))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibtaxtdetail
				SET state_flag = 0
			     FROM #ibtaxtdetail o, glchart t
		  WHERE o.account_code = t.account_code
		        AND ( (DATALENGTH(ISNULL(RTRIM(LTRIM(t.currency_code)),0))=0)   OR 
		  (t.currency_code = @home_currency AND t.rate_type_home = @rate_type_home AND
		   t.currency_code = @oper_currency AND t.rate_type_oper = @rate_type_oper))
		
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 223 � 3' + ', line: ' + RTRIM(LTRIM(STR(156))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT ed.id, ed.state_flag, ed.account_code, '', 0, 0.0,  link1, link2, link3
		       FROM #ibtaxtdetail ed, #ibio i
		    WHERE ed.state_flag = @error_code
		    AND	i.id = ed.id
		    AND ed.account_code IN (SELECT account_code FROM glchart)
		
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	END




--
-- Error 280 - Apply date is outside the active range for this account.
-- 
	SELECT @error_code = 280
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code


	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 280 � 1' + ', line: ' + RTRIM(LTRIM(STR(179))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
			-- Then account_code
				INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
				   SELECT ed.id, @error_code, ed.account_code,date_applied , 0, 0.0, link1, link2, link3
				       FROM #ibtaxtdetail ed, glchart ch, #ibio  i
				    WHERE ed.account_code = ch.account_code
					AND	i.id = ed.id
				  AND ((date_applied NOT BETWEEN active_date AND inactive_date
				          AND (active_date > 0 AND inactive_date > 0))
				 	    OR (date_applied < active_date AND inactive_date = 0)) 
				
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END

	END


--
-- Error 281 - Apply date is outside the active range for this account.
-- 
	SELECT @error_code = 281
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

  

	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 281 � 1' + ', line: ' + RTRIM(LTRIM(STR(204))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
				INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
				   SELECT ed.id, @error_code, ed.account_code,'', 0, 0.0, link1, link2, link3
				          FROM #ibtaxtdetail ed, glchart ch, #ibio  i
				    WHERE ed.account_code = ch.account_code
					AND	i.id = ed.id
					AND ch.inactive_flag =1 
				
    -- "STANDARD ERROR.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
        RETURN -1
        END
    -- "STANDARD ERROR.INC" END


	END



ibvalidate_sp_error_exit:
SELECT @location = @procedure_name + ': Location ' + 'Drop temp tables' + ', line: ' + RTRIM(LTRIM(STR(218))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF @iberror_exists = 0 BEGIN
	DROP TABLE #iberror
END



    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

RETURN @return_value
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ibvalidateptax_sp] TO [public]
GO
