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































CREATE PROC [dbo].[ibvalidate_sp]
 
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
	SELECT @ibio_exists = 0,  @iberror_exists = 0
	
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

	IF NOT EXISTS (SELECT 1 WHERE OBJECT_ID('tempdb..#iberror') IS NULL) BEGIN
		SELECT @iberror_exists = 1
	END
	IF @iberror_exists = 0 BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Create table #iberror' + ', line: ' + RTRIM(LTRIM(STR(78))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
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

SELECT @location = @procedure_name + ': Location ' + 'Create table #rates' + ', line: ' + RTRIM(LTRIM(STR(84))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	--CREATE TABLE [#rates]
	
CREATE TABLE  #rates (   from_currency   varchar(8),
			to_currency     varchar(8),
			rate_type       varchar(8),
			date_applied    int,
			rate            float)



	
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


SELECT @location = @procedure_name + ': Location ' + 'Get currency info from glco' + ', line: ' + RTRIM(LTRIM(STR(89))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
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
-- Error 100 - Date entered is invalid
-- 
	SELECT @error_code = 100
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

	  
      
	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 100 � 1' + ', line: ' + RTRIM(LTRIM(STR(109))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
			UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 100 � 2' + ', line: ' + RTRIM(LTRIM(STR(113))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
			UPDATE #ibio
					SET state_flag = 0
			WHERE ISDATE(date_entered)=1
			
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 100 � 3' + ', line: ' + RTRIM(LTRIM(STR(119))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, date_entered, '', 0, 0.0, link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code
		
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
-- Error 110 - Date applied is invalid
-- 
	SELECT @error_code = 110
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

  

	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 110 � 1' + ', line: ' + RTRIM(LTRIM(STR(138))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 110 � 2' + ', line: ' + RTRIM(LTRIM(STR(142))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
		  WHERE ISDATE(date_applied)=1
		
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 110 � 3' + ', line: ' + RTRIM(LTRIM(STR(148))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, date_applied, '', 0, 0.0, link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code
		
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
-- Error 120 - trx_type is invalid. 
-- 

























--
-- Error 130 - Controlling organization ID is invalid 
-- 
	SELECT @error_code = 130
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

  


	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 130 � 1' + ', line: ' + RTRIM(LTRIM(STR(196))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 130 � 2' + ', line: ' + RTRIM(LTRIM(STR(200))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
			     FROM #ibio o, Organization t
		  WHERE o.controlling_org_id = t.organization_id
			AND t.active_flag =1
		
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 130 � 3' + ', line: ' + RTRIM(LTRIM(STR(208))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, controlling_org_id, '', 0, 0.0,  link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code
		
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
-- Error 140 - Controlling organization does not have a relationship with the Detail organization.
-- 
	SELECT @error_code = 140
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

  

	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 140 � 1' + ', line: ' + RTRIM(LTRIM(STR(227))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 140 � 2' + ', line: ' + RTRIM(LTRIM(STR(231))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
			     FROM #ibio o, OrganizationOrganizationRel t
		  WHERE o.controlling_org_id = t.controlling_org_id
			AND o.detail_org_id = t.detail_org_id		
		
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 140 � 3' + ', line: ' + RTRIM(LTRIM(STR(239))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, controlling_org_id, detail_org_id, 0, 0.0,  link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code
		
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
-- Error 150 - Detail organization ID is invalid
-- 
	SELECT @error_code = 150
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

  


	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 150 � 1' + ', line: ' + RTRIM(LTRIM(STR(259))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 150 � 2' + ', line: ' + RTRIM(LTRIM(STR(263))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
			     FROM #ibio o, Organization t
		  WHERE o.detail_org_id = t.organization_id
			AND t.active_flag =1
		
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 150 � 3' + ', line: ' + RTRIM(LTRIM(STR(271))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, detail_org_id, '', 0, 0.0,  link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code
		
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
-- Error 180 - Invalid currency code
-- 
	SELECT @error_code = 180
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

  

	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 180 � 1' + ', line: ' + RTRIM(LTRIM(STR(318))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 180 � 2' + ', line: ' + RTRIM(LTRIM(STR(322))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
			     FROM #ibio o, CVO_Control..mccurr t
		  WHERE o.currency_code = t.currency_code
		
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 180 � 3' + ', line: ' + RTRIM(LTRIM(STR(329))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, currency_code, '', 0, 0.0, link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code
		
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
-- Error 190 - Translation does not exist for this currency code conversion 
-- 
	SELECT @error_code = 190
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

  

	IF (@active = 1 AND @error_level & @level > 0) BEGIN
	SELECT @location = @procedure_name + ': Location ' + 'Validate 190 � 1' + ', line: ' + RTRIM(LTRIM(STR(348))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE #ibio 
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

	
	SELECT @location = @procedure_name + ': Location ' + 'Validate 190 � 1a' + ', line: ' + RTRIM(LTRIM(STR(353))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	INSERT INTO #rates (from_currency, to_currency, rate_type, date_applied, rate)
	SELECT DISTINCT currency_code, @home_currency, @rate_type_home, DATEDIFF(DD,'1/1/80', date_applied)+722815, 0.0
	     FROM #ibio
	
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

	
	SELECT @location = @procedure_name + ': Location ' + 'Validate 190 � 1b' + ', line: ' + RTRIM(LTRIM(STR(359))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	EXEC @ret = CVO_Control..mcrates_sp
	
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

	IF @ret <> 0 BEGIN
			SELECT @return_value = -110
			GOTO ibvalidate_sp_error_exit
	END
	
	SELECT @location = @procedure_name + ': Location ' + 'Validate 190 � 2' + ', line: ' + RTRIM(LTRIM(STR(367))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE #ibio
			SET state_flag = 0
		     FROM #ibio o, #rates r
	  WHERE o.currency_code = r.from_currency
	AND DATEDIFF(DD,'1/1/80', o.date_applied)+722815 = r.date_applied
	AND r.rate <> 0.0
	
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

	
	SELECT @location = @procedure_name + ': Location ' + 'Validate 190 � 3' + ', line: ' + RTRIM(LTRIM(STR(376))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
	   SELECT id, state_flag, currency_code, @home_currency, DATEDIFF(DD,'1/1/80', o.date_applied)+722815, 0.0, link1, link2, link3
	       FROM #ibio o
	    WHERE state_flag = @error_code
	
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

	
	SELECT @location = @procedure_name + ': Location ' + 'Validate 190 � 10' + ', line: ' + RTRIM(LTRIM(STR(383))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE #ibio 
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

	
	SELECT @location = @procedure_name + ': Location ' + 'Clear #rates table' + ', line: ' + RTRIM(LTRIM(STR(388))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	DELETE #rates
	
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

	
	SELECT @location = @procedure_name + ': Location ' + 'Validate 190 � 10a' + ', line: ' + RTRIM(LTRIM(STR(392))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	INSERT INTO #rates (from_currency, to_currency, rate_type, date_applied, rate)
	SELECT DISTINCT currency_code, @oper_currency, @rate_type_oper, DATEDIFF(DD,'1/1/80', date_applied)+722815, 0.0
	     FROM #ibio
	
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

	
	SELECT @location = @procedure_name + ': Location ' + 'Validate 190 � 10b' + ', line: ' + RTRIM(LTRIM(STR(398))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	EXEC @ret = CVO_Control..mcrates_sp
	
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

	IF @ret <> 0 BEGIN
			SELECT @return_value = -110
			GOTO ibvalidate_sp_error_exit
	END
	
	SELECT @location = @procedure_name + ': Location ' + 'Validate 190 � 12' + ', line: ' + RTRIM(LTRIM(STR(406))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	UPDATE #ibio
			SET state_flag = 0
		     FROM #ibio o, #rates r
	  WHERE o.currency_code = r.from_currency
	AND DATEDIFF(DD,'1/1/80', o.date_applied)+722815 = r.date_applied
	AND r.rate <> 0.0
	
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

	
	SELECT @location = @procedure_name + ': Location ' + 'Validate 190 � 13' + ', line: ' + RTRIM(LTRIM(STR(415))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
	   SELECT id, state_flag, currency_code, @oper_currency, DATEDIFF(DD,'1/1/80', o.date_applied)+722815, 0.0, link1, link2, link3
	       FROM #ibio o
	    WHERE state_flag = @error_code
	
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
-- Error 200 - Tax code is invalid
-- 
	SELECT @error_code = 200
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

  

	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 200 � 1' + ', line: ' + RTRIM(LTRIM(STR(434))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 200 � 2' + ', line: ' + RTRIM(LTRIM(STR(438))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
			     FROM #ibio o, artax t
		  WHERE o.tax_code = t.tax_code
		
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 200 � 3' + ', line: ' + RTRIM(LTRIM(STR(445))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, tax_code, '', 0, 0.0, link1, link2, link3
		       FROM #ibio 
		    WHERE state_flag = @error_code AND (DATALENGTH(ISNULL(RTRIM(LTRIM(tax_code)),0))<>0) 
		
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
-- Error 210 -  Recipient account code is invalid
-- 
	SELECT @error_code = 210
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code


  


	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 210 � 1' + ', line: ' + RTRIM(LTRIM(STR(466))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 210 � 2' + ', line: ' + RTRIM(LTRIM(STR(470))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
			     FROM #ibio o, glchart t
		  WHERE o.recipient_code = t.account_code

		
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 210 � 3' + ', line: ' + RTRIM(LTRIM(STR(478))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, recipient_code, '', 0, 0.0,link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code
		
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
-- Error 211 -  Originator account code is invalid
-- 

	SELECT @error_code = 211
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

  

	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 211 � 1' + ', line: ' + RTRIM(LTRIM(STR(498))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 211 � 2' + ', line: ' + RTRIM(LTRIM(STR(502))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
			     FROM #ibio o, glchart t
		  WHERE o.originator_code = t.account_code
		
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 211 � 3' + ', line: ' + RTRIM(LTRIM(STR(509))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, originator_code, '', 0, 0.0, link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code
		
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
-- Error 212 - Tax Expense Account code is invalid	
-- 

	SELECT @error_code = 212
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code


  

	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 212 � 1' + ', line: ' + RTRIM(LTRIM(STR(530))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 212 � 2' + ', line: ' + RTRIM(LTRIM(STR(534))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
			     FROM #ibio o, glchart t
		  WHERE o.tax_expense_code = t.account_code
		
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 212 � 3' + ', line: ' + RTRIM(LTRIM(STR(541))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, tax_expense_code, '', 0, 0.0, link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code AND (DATALENGTH(ISNULL(RTRIM(LTRIM(tax_expense_code)),0))<>0) 
		
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
-- Error 213 - Tax Payable Account code is invalid
-- 
	SELECT @error_code = 213
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

  

	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 213 � 1' + ', line: ' + RTRIM(LTRIM(STR(560))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 213 � 2' + ', line: ' + RTRIM(LTRIM(STR(564))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
			     FROM #ibio o, glchart t
		  WHERE o.tax_payable_code = t.account_code
		
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 213 � 3' + ', line: ' + RTRIM(LTRIM(STR(571))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, tax_payable_code, '', 0, 0.0, link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code AND (DATALENGTH(ISNULL(RTRIM(LTRIM(tax_payable_code)),0))<>0) 
		
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
-- Error 220 - Recipient account code is restricted to a currency code that is not compatible with the home 
--			and operational currency defined in General Ledger.
-- 
	SELECT @error_code = 220
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code


  

	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 220 � 1' + ', line: ' + RTRIM(LTRIM(STR(592))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 220 � 2' + ', line: ' + RTRIM(LTRIM(STR(596))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
			     FROM #ibio o, glchart t
		  WHERE o.recipient_code = t.account_code
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 220 � 3' + ', line: ' + RTRIM(LTRIM(STR(606))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, recipient_code, '', 0, 0.0, link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code
		    AND recipient_code IN (SELECT account_code FROM glchart)
		
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
-- Error 221 - Originator account code is restricted to a currency code that is not compatible with the home 
--			and operational currency defined in General Ledger.
-- 
	SELECT @error_code = 221
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

  

	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 221 � 1' + ', line: ' + RTRIM(LTRIM(STR(627))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 221 � 2' + ', line: ' + RTRIM(LTRIM(STR(631))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
			     FROM #ibio o, glchart t
		  WHERE o.originator_code = t.account_code
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 221 � 3' + ', line: ' + RTRIM(LTRIM(STR(641))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, originator_code, '', 0, 0.0, link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code
		  AND originator_code IN (SELECT account_code FROM glchart)
		
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
-- Error 222 - Tax Expense Account code is restricted to a currency code that is not compatible with the home 
--			and operational currency defined in General Ledger.
-- 
	SELECT @error_code = 222
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

  

	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 222 � 1' + ', line: ' + RTRIM(LTRIM(STR(662))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 222 � 2' + ', line: ' + RTRIM(LTRIM(STR(666))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
			     FROM #ibio o, glchart t
		  WHERE o.tax_expense_code = t.account_code
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 222 � 3' + ', line: ' + RTRIM(LTRIM(STR(676))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, tax_expense_code, '', 0, 0.0, link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code
		 AND tax_expense_code IN (SELECT account_code FROM glchart)
		
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
		SELECT @location = @procedure_name + ': Location ' + 'Validate 223 � 1' + ', line: ' + RTRIM(LTRIM(STR(698))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 223 � 2' + ', line: ' + RTRIM(LTRIM(STR(702))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
			     FROM #ibio o, glchart t
		  WHERE o.tax_payable_code = t.account_code
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 223 � 3' + ', line: ' + RTRIM(LTRIM(STR(712))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, tax_payable_code, '', 0, 0.0, link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code
		    AND tax_payable_code IN (SELECT account_code FROM glchart)
		
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
-- Error 240 - Username is invalid.
-- 
	SELECT @error_code = 240
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

  

	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 240 � 1' + ', line: ' + RTRIM(LTRIM(STR(732))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 240 � 2' + ', line: ' + RTRIM(LTRIM(STR(736))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
			     FROM #ibio o, CVO_Control..smusers t
		  WHERE o.username = t.user_name
		
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 240 � 3' + ', line: ' + RTRIM(LTRIM(STR(743))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, username, '', 0, 0.0, link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code
		
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
-- Error 250 - Reference code is invalid.
-- 
	SELECT @error_code = 250
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

  


	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 250 � 1' + ', line: ' + RTRIM(LTRIM(STR(763))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 250 � 2' + ', line: ' + RTRIM(LTRIM(STR(767))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
				SET state_flag = 0
			     FROM #ibio  o, glref t
		  WHERE o.reference_code = t.reference_code
			AND  (DATALENGTH(ISNULL(RTRIM(LTRIM(t.reference_code)),0))<>0)
		
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 250 � 3' + ', line: ' + RTRIM(LTRIM(STR(775))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag,  reference_code, '', 0, 0.0, link1, link2, link3
		       FROM #ibio 
		    WHERE state_flag = @error_code
			AND  (DATALENGTH(ISNULL(RTRIM(LTRIM(reference_code)),0))<>0)
		
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
-- Error 260 - The apply date for the transaction is not valid.
-- 
	SELECT @error_code = 260
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code

  

	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 260 � 1' + ', line: ' + RTRIM(LTRIM(STR(795))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio 
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

		SELECT @location = @procedure_name + ': Location ' + 'Validate 260 � 2' + ', line: ' + RTRIM(LTRIM(STR(799))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		UPDATE #ibio
				SET state_flag = 0
			     FROM #ibio o, glprd t
		  WHERE DATEDIFF(DD,'1/1/80',date_applied)+722815  BETWEEN t.period_start_date and t.period_end_date
		
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

		
		SELECT @location = @procedure_name + ': Location ' + 'Validate 260 � 3' + ', line: ' + RTRIM(LTRIM(STR(806))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, state_flag, date_applied, '', 0, 0.0, link1, link2, link3
		       FROM #ibio
		    WHERE state_flag = @error_code
		
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
		SELECT @location = @procedure_name + ': Location ' + 'Validate 280 � 1' + ', line: ' + RTRIM(LTRIM(STR(825))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
			-- Fist recipient_code 
				INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
				   SELECT id, @error_code, date_applied, ed.recipient_code, 0, 0.0, link1, link2, link3
				       FROM #ibio ed, glchart ch
				    WHERE ed.recipient_code = ch.account_code
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

			-- Then originator_code
				INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
				   SELECT id, @error_code, date_applied, ed.originator_code, 0, 0.0, link1, link2, link3
				       FROM #ibio ed, glchart ch
				    WHERE ed.originator_code = ch.account_code
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

			-- Then tax_payable_code
				INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
				   SELECT id, @error_code, date_applied, ed.tax_payable_code, 0, 0.0, link1, link2, link3
				       FROM #ibio ed, glchart ch
				    WHERE ed.tax_payable_code = ch.account_code
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

			-- Then tax_expense_code
				INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
				   SELECT id, @error_code, date_applied, ed.tax_expense_code, 0, 0.0, link1, link2, link3
				       FROM #ibio ed, glchart ch
				    WHERE ed.tax_expense_code = ch.account_code
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
		SELECT @location = @procedure_name + ': Location ' + 'Validate 281 � 1' + ', line: ' + RTRIM(LTRIM(STR(875))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
			-- Fist recipient_code 
				INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
				   SELECT id, @error_code, date_applied, ed.recipient_code, 0, 0.0, link1, link2, link3
				       FROM #ibio ed, glchart ch
				    WHERE ed.recipient_code = ch.account_code
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

			-- Then originator_code
				INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
				   SELECT id, @error_code, date_applied, ed.originator_code, 0, 0.0, link1, link2, link3
				       FROM #ibio ed, glchart ch
				    WHERE ed.originator_code = ch.account_code
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

			-- Then tax_payable_code
				INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
				   SELECT id, @error_code, date_applied, ed.tax_payable_code, 0, 0.0, link1, link2, link3
				       FROM #ibio ed, glchart ch
				    WHERE ed.tax_payable_code = ch.account_code
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

			-- Then tax_expense_code
				INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
				   SELECT id, @error_code, date_applied, ed.tax_expense_code, 0, 0.0, link1, link2, link3
				       FROM #ibio ed, glchart ch
				    WHERE ed.tax_expense_code = ch.account_code
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


--
-- Error 290 - Apply date is in a prior period.
-- 
	SELECT @error_code = 290
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code



	IF (@active = 1 AND @error_level & @level > 0) BEGIN
		SELECT @location = @procedure_name + ': Location ' + 'Validate 290 � 1' + ', line: ' + RTRIM(LTRIM(STR(918))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
		INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
		   SELECT id, @error_code, date_applied, '', 0, 0.0,  link1, link2, link3
		       FROM #ibio hdr, glprd prd
		    WHERE DATEDIFF(DD,'1/1/80',hdr.date_applied)+722815 < prd.period_start_date
		 	  AND prd.period_end_date = @current_period_end_date
		
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
-- Error 300 - Apply date is in a future period.
-- 
	SELECT @error_code = 300
	SELECT @error_level = level, @active = active
	    FROM ibedterr
	 WHERE code = @error_code


	IF (@active = 1 AND @error_level & @level > 0) BEGIN
	SELECT @location = @procedure_name + ': Location ' + 'Validate 300 � 1' + ', line: ' + RTRIM(LTRIM(STR(937))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
	INSERT INTO #iberror (id, error_code, info1, info2, infoint, infodecimal, link1, link2, link3)
	   SELECT id, @error_code, date_applied, '', 0, 0.0,  link1, link2, link3
	       FROM #ibio hdr, glprd prd
	    WHERE DATEDIFF(DD,'1/1/80',hdr.date_applied)+722815  > prd.period_end_date
	 	  AND prd.period_end_date = @current_period_end_date
	
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

SELECT @location = @procedure_name + ': Location ' + 'Reset #ibio state_flag to zero' + ', line: ' + RTRIM(LTRIM(STR(946))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE #ibio
        SET state_flag = 0

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


SELECT @location = @procedure_name + ': Location ' + 'Reset #ibio state_flag to zero' + ', line: ' + RTRIM(LTRIM(STR(951))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE #ibio
        SET state_flag = 0

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


SELECT @location = @procedure_name + ': Location ' + 'Mark rows in #ibio that are in error' + ', line: ' + RTRIM(LTRIM(STR(956))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE #ibio
        SET state_flag = 1
    FROM #ibio o, #iberror t
 WHERE o.id = t.id

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


SELECT @location = @procedure_name + ': Location ' + 'Mark rows in #ibio that are in error' + ', line: ' + RTRIM(LTRIM(STR(963))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
UPDATE #ibio
        SET state_flag = 1
    FROM #ibio o, #iberror t
 WHERE o.id = t.id

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


ibvalidate_sp_error_exit:
SELECT @location = @procedure_name + ': Location ' + 'Drop temp tables' + ', line: ' + RTRIM(LTRIM(STR(971))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF @iberror_exists = 0 BEGIN
DROP TABLE #iberror
END
DROP TABLE #rates

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



    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

RETURN @return_value
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ibvalidate_sp] TO [public]
GO
