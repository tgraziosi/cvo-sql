SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 20/03/2015 - Performance Changes  
  
CREATE proc [dbo].[adm_validate_address] @trx_area char(2), @debug int = 0  
AS   
BEGIN  

	SET NOCOUNT ON  

	-- Scratch variables used in the script  
	DECLARE	@retVal				INT,  
			@comHandle			INT,  
			@errorSource		VARCHAR(8000),  
			@errorDescription	VARCHAR(8000),  
			@retString			VARCHAR(100),  
			@l_url				varchar(900),   
			@l_viaurl			varchar(900),   
			@l_username			varchar(50),   
			@l_password			varchar(50),  
			@l_company_id		int,  
			@return_type		varchar(50),   
			@in_cursor			int,  
			@index_required		smallint,  
			@aAddressLine1		varchar(40),   
			@aAddressLine2		varchar(40),   
			@aAddressLine3		varchar(40),   
			@aAddressLine4		varchar(40),   
			@aAddressLine5		varchar(40),   
			@acity				varchar(40),   
			@aRegion			varchar(40),   
			@aPostalCode		varchar(40),   
			@aCountry			varchar(40),  
			@seq_id				int,  
			@addr_ind			int,  
			@l_requesttimeout	int,  
			@tc_flag			int,
			@valor				varchar(2000)    
  
	IF NOT EXISTS (SELECT 1 FROM #address_data)   
		RETURN -1  
  
	SET @tc_flag = 0  
  
	IF UPPER(@trx_area) IN ( 'AR' ,'')  
		SELECT	@l_company_id = company_id,  
				@tc_flag = ISNULL(tax_connect_flag,0)  
		FROM	arco (NOLOCK)  
  
	IF @tc_flag = 0  
		SELECT	@l_company_id = company_id,  
				@tc_flag = ISNULL(tax_connect_flag,0)  
		FROM	apco (nolock)  
  
	IF ISNULL(@tc_flag,0) != 1  
		RETURN 2  
  
	CREATE TABLE #return_parameters (
		seq_id			int, 
		return_type		varchar(50), 
		index_required	smallint)  
  
	INSERT #return_parameters VALUES (1, 'get_Line1',1)  
	INSERT #return_parameters VALUES (2, 'get_Line2',1)  
	INSERT #return_parameters VALUES (3, 'get_Line3',1)  
	INSERT #return_parameters VALUES (4, 'get_Line4',1)  
	INSERT #return_parameters VALUES (6, 'get_City',1)  
	INSERT #return_parameters VALUES (7, 'get_Region',1)  
	INSERT #return_parameters VALUES (8, 'get_County',1)  
	INSERT #return_parameters VALUES (9, 'get_Country',1)  
	INSERT #return_parameters VALUES (10, 'get_PostalCode',1)  
	INSERT #return_parameters VALUES (11, 'get_AddressCode',1)  
	INSERT #return_parameters VALUES (12, 'get_AddressType',1)  
	INSERT #return_parameters VALUES (13, 'get_CarrierRoute',1)  
	INSERT #return_parameters VALUES (14, 'get_FipsCode',1)  
	INSERT #return_parameters VALUES (15, 'get_PostNet',1)  
	  
	-- Initialize the COM component. fsavataxlink.AddressValidator  
	EXEC @retVal = sp_OACreate '{32942B9A-B3EF-41DA-A31B-DE5C78FC4815}', @comHandle OUTPUT, 4  

	IF (@retVal <> 0) GOTO Exit_Bad  
  
	SET @in_cursor = 0  
  
	SELECT	@l_url = url,   
			@l_viaurl = viaurl,  
			@l_username = username,  
			@l_password = password,  
			@l_requesttimeout = requesttimeout  
	FROM	gltcconfig (NOLOCK)  
	WHERE	company_id = @l_company_id  
  
	-- Call a method into the component  
	EXEC @retVal = sp_OAMethod @comHandle, 'fSetConfig', @retString OUTPUT,   
				@a_url = @l_url, @a_viaurl = @l_viaurl, @a_username = @l_username, @a_password = @l_password,  
				@a_requesttimeout = @l_requesttimeout  

	IF (@retVal <> 0) GOTO Exit_Bad  
  
	SELECT	@aAddressLine1 = '', @aAddressLine2 = '', @aAddressLine3 = '',   
			@acity = '', @aRegion = '', @aPostalCode = '', @aCountry = ''  
  
	-- v1.0 Start
	DECLARE	@row_id			int,
			@last_row_id	int

	CREATE TABLE #adm_address_lines (
		row_id			int IDENTITY(1,1),
		addr_type		varchar(50),
		addr_value		varchar(100))

	INSERT	#adm_address_lines (addr_type, addr_value)
	SELECT	LOWER(addr_type), addr_value  
	FROM	#address_data 
	WHERE	orig_ind = 1  

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@return_type = addr_type,
			@retstring = addr_value
	FROM	#adm_address_lines
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN
  
		IF @return_type = 'line1' 
			SELECT @aAddressLine1 = @retString  
		ELSE IF @return_type = 'line2' 
			SELECT @aAddressLine2 = @retString  
		ELSE IF @return_type = 'line3' 
			SELECT @aAddressLine3 = @retString  
		ELSE IF @return_type = 'line4' 
			SELECT @aAddressLine4 = @retString  
		ELSE IF @return_type = 'line5' 
			SELECT @aAddressLine5 = @retString  
		ELSE IF @return_type = 'city' 
			SELECT @acity = @retString  
		ELSE IF @return_type = 'region' 
			SELECT @aRegion = @retString  
		ELSE IF @return_type = 'postalcode' 
			SELECT @aPostalCode = @retString  
		ELSE IF @return_type = 'country' 
			SELECT @aCountry = @retString  
	  
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@return_type = addr_type,
				@retstring = addr_value
		FROM	#adm_address_lines
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC
	END

	DROP TABLE #adm_address_lines
  
	EXEC adm_parse_address @nonupdate_ind = 0,
			@select_ind = 0,  
			@addr1 = @aAddressLine1 out,  
			@addr2 = @aAddressLine2 out,  
			@addr3 = @aAddressLine3 out,  
			@addr4 = @aAddressLine4 OUT, 
			@addr5 = @aAddressLine5 OUT, 
			@addr6 = ''  
  
	EXEC @retVal = sp_OAMethod @comHandle, 'AddressValidation', null,   
			@aAddressLine1 = @aAddressLine1,  @aAddressLine2 = @aAddressLine2,   
			@aAddressLine3 = @aAddressLine3, @acity = @acity,  
			@aRegion = @aRegion,   @aPostalCode = @aPostalCode,  
			@aCountry = @aCountry,  @aShowResults = 0  

	IF (@retVal <> 0) GOTO Exit_Bad  
  
	EXEC @retVal = sp_OAMethod @comHandle, 'get_MessageReturn', @retString OUTPUT  
	
	IF (@retVal <> 0) GOTO Exit_Bad  
  
	INSERT #address_data VALUES(0, 0, 'MessageReturn', @retString, -1)  
  
	EXEC @retVal = sp_OAMethod @comHandle, 'AddressCount', @retString OUTPUT  
	
	IF (@retVal <> 0) GOTO Exit_Bad  
  
	IF CONVERT(int,@retString) > 0  
	BEGIN  
		-- header return values  
		CREATE TABLE #adm_address_lines2 (
			row_id			int IDENTITY(1,1),
			return_type		varchar(50),
			seq_id			int)

		INSERT	#adm_address_lines2 (return_type, seq_id)
		SELECT	return_type, seq_id  
		FROM	#return_parameters 
		WHERE	index_required = 1  
		ORDER BY seq_id 

		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id,
				@return_type = return_type,
				@seq_id = seq_id
		FROM	#adm_address_lines2
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			-- Call a method into the component  
			EXEC @retVal = sp_OAMethod @comHandle, @return_type, @retString OUTPUT, @index = 0  
			
			IF (@retVal <> 0) GOTO Exit_Bad  
  
			IF LOWER(SUBSTRING(@return_type,5,4)) = 'line'   
				SET @addr_ind = 1  
			ELSE   
				SET @addr_ind = 2  
    
			IF @retString <> ''   
			BEGIN
				INSERT	#address_data   
				VALUES	(0, @addr_ind, LOWER(SUBSTRING(@return_type,5,40)), LEFT(@retString,40), @seq_id)  
			END
    
			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id,
					@return_type = return_type,
					@seq_id = seq_id
			FROM	#adm_address_lines2
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC
		END
	
		DROP TABLE #adm_address_lines2
        
		SELECT	@acity = (SELECT addr_value FROM #address_data WHERE addr_ind = 2 AND orig_ind = 0 AND addr_type = 'city'),  
				@aRegion = (SELECT addr_value FROM #address_data WHERE addr_ind = 2 AND orig_ind = 0 AND addr_type = 'region'),  
				@aPostalCode = (SELECT addr_value FROM #address_data WHERE addr_ind = 2 AND orig_ind = 0 AND addr_type = 'postalcode')  
  
		UPDATE	#address_data   
		SET		addr_value = @acity + ', ' + @aRegion + ' ' + @aPostalCode   
		WHERE	addr_ind = 1 
		AND		orig_ind = 0  
		AND		LOWER(addr_value) = LOWER(@acity + ' ' + @aRegion + ' ' + @aPostalCode)  
    END  
	ELSE  
	BEGIN  
		RETURN -3 -- no address returned  
	END  
  
	-- Release the reference to the COM object  
	EXEC sp_OADestroy @comHandle  
  
	GOTO Exit_Good  
  
	Exit_Bad:  
		-- Trap errors if any  
		EXEC sp_OAGetErrorInfo @comHandle, @errorSource OUTPUT, @errorDescription OUTPUT  
 
		IF @debug > 0   
			SELECT [Error Source] = @errorSource, [Description] = @errorDescription  
  
		INSERT #address_data VALUES (0, 0, 'MessageReturn', @errorDescription, -1)  
  
        RETURN -2  
  
	Exit_Good:  
		RETURN 1  
END
GO
GRANT EXECUTE ON  [dbo].[adm_validate_address] TO [public]
GO
