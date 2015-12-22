SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\icv_parse_expiration.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


 
CREATE PROCEDURE [dbo].[icv_parse_expiration]	@expiration	VARCHAR(30),
					@month		INT OUTPUT,
					@year	 	INT OUTPUT,
					@dateValid	INT OUTPUT
AS
BEGIN
	DECLARE @buf			CHAR(255)
	DECLARE	@LogActivity		CHAR(3)
	DECLARE	@slashLocation		INT


	SET NOCOUNT ON

	

	IF @expiration IS NULL
	BEGIN
		SELECT @month = 0, @year = 0, @dateValid = 0
		RETURN @dateValid
	END

	SELECT @slashLocation = CHARINDEX('/', RTRIM(LTRIM(@expiration))), @dateValid = 0
	IF @slashLocation = 0						-- Formats 5, 6, 7 or 8
	BEGIN
		IF DATALENGTH(RTRIM(LTRIM(@expiration))) = 4		-- Formats 5 or 7
		BEGIN
			SELECT @month = CONVERT(INT, SUBSTRING(@expiration,1,2))
			IF @month > 0 AND @month < 13			-- Format 5
			BEGIN
				SELECT @year = CONVERT(INT, SUBSTRING(@expiration,3,2)), @dateValid = 5
			END
			ELSE						-- Format 7
			BEGIN
				SELECT @year = @month
				SELECT @month = CONVERT(INT, SUBSTRING(@expiration,3,2)), @dateValid = 7
			END
		END
		ELSE							-- Formats 6 or 8
		BEGIN
			IF DATALENGTH(RTRIM(LTRIM(@expiration))) = 6
			BEGIN
				SELECT @month = CONVERT(INT, SUBSTRING(@expiration,1,2))
				IF @month > 0 AND @month < 13 		-- Format 6
				BEGIN
					SELECT @year = CONVERT(INT, SUBSTRING(@expiration,3,4)), @dateValid = 6
				END
				ELSE					-- Format 8
				BEGIN
					SELECT @year = CONVERT(INT, SUBSTRING(@expiration,1,4)), @month = CONVERT(INT, SUBSTRING(@expiration,5,2)), @dateValid = 8
				END
			END
		END
	END

	IF @slashLocation = 3						-- Formats 1, 2 or 3
	BEGIN
		SELECT @month = CONVERT(INT, SUBSTRING(@expiration,1,2))
		IF @month = 0 OR @month > 12
		BEGIN
			IF DATALENGTH(RTRIM(LTRIM(@expiration))) = 5 	-- Format 3
			BEGIN
				SELECT @year = @month
				SELECT @month = CONVERT(INT, SUBSTRING(@expiration,4,2)), @dateValid = 3
			END
		END
		ELSE
		BEGIN
			IF DATALENGTH(RTRIM(LTRIM(@expiration))) = 5 	-- Format 1
			BEGIN
				SELECT @year = CONVERT(INT, SUBSTRING(@expiration,4,2)), @dateValid = 1
			END
			IF DATALENGTH(RTRIM(LTRIM(@expiration))) = 7	-- Format 2
			BEGIN
				SELECT @year = CONVERT(INT, SUBSTRING(@expiration,4,4)), @dateValid = 2
			END
		END
	END

	IF @slashLocation = 5						-- Format 4
	BEGIN
		IF DATALENGTH(RTRIM(LTRIM(@expiration))) = 7
		BEGIN
			SELECT @year = CONVERT(INT, SUBSTRING(@expiration,1,4)), @month = CONVERT(INT, SUBSTRING(@expiration,6,2)), @dateValid = 4
		END
	END

	IF @dateValid > 0
	BEGIN
		IF @month < 1 OR @month > 12
		BEGIN
			SELECT @dateValid = 0
		END
		IF @year < 100
		BEGIN
			SELECT @year = @year + 2000
		END
		IF @year < 2000
		BEGIN
			SELECT @dateValid = 0
		END
	END

	RETURN @dateValid
END
GO
GRANT EXECUTE ON  [dbo].[icv_parse_expiration] TO [public]
GO
