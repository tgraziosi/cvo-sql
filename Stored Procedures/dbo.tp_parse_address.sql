SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC dbo.tp_parse_address '3710 W Southern Hills Blvd', 'Rogers, AR 72758-80841', '', '', '', ''
      
CREATE PROC [dbo].[tp_parse_address]	@addr1 varchar(255), 
									@addr2 varchar(255), 
									@addr3 varchar(255), 
									@addr4 varchar(255),  
									@addr5 varchar(255), 
									@addr6 varchar(255)  
AS  
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@a1			varchar(255), 
			@a2			varchar(255), 
			@a3			varchar(255), 
			@a4			varchar(255), 
			@a5			varchar(255),  
			@a6			varchar(255), 
			@acnt		int, 
			@ccnt		int, 
			@a			varchar(255), 
			@mcnt		int,  
			@pos		int, 
			@rc			int,  
			@acity		varchar(255), 
			@astate		varchar(255), 
			@azip		varchar(255),  
			@addr_line_0 varchar(2000), 
			@addr_line_1 varchar(2000),  
			@city		varchar(255),
			@state		varchar(255), 
			@zip		varchar(255),  
			@country_cd varchar(3),
			@country	varchar(255)

	SET @rc = 1  
	SET @acnt = 1  
	SET @ccnt = 0  
	SELECT @acity = '', @astate = '', @azip = ''  
  
	WHILE @acnt < 7  
	BEGIN  
		SELECT @a = CASE @acnt WHEN 1 THEN ltrim(@addr1) 
							   WHEN 2 THEN ltrim(@addr2)  
							   WHEN 3 THEN ltrim(@addr3)  
							   WHEN 4 THEN ltrim(@addr4)  
							   WHEN 5 THEN ltrim(@addr5)  
							   WHEN 6 THEN ltrim(@addr6) END,  
		@acnt = @acnt + 1  
  
		IF ISNULL(@a,'') = ''  
			CONTINUE  
		
		IF @a like '3PB=%'  
			CONTINUE  
  
		SELECT @ccnt = @ccnt + 1  
	
		IF @ccnt = 1  
			SELECT @a1 = @a  
  
		IF @ccnt = 2  
			SELECT @a2 = @a  
  
		IF @ccnt = 3  
			SELECT @a3 = @a  

		IF @ccnt = 4  
			SELECT @a4 = @a  

		IF @ccnt = 5  
			SELECT @a5 = @a  

		IF @ccnt = 6  
			SELECT @a6 = @a  
	END  
  
	IF @ccnt <= 1  
	BEGIN  
		SELECT	LEFT(@city,40) city, 
				LEFT(@state,40) state, 
				LEFT(@zip,15) zip 
		RETURN  
	END  
  
	SELECT @mcnt = @ccnt  
  
	SET @acnt = 1  

	WHILE @ccnt > 0 and @acnt < 4  
	BEGIN  
		SELECT @a = RTRIM(CASE @ccnt WHEN 1 THEN @a1  
									 WHEN 2 THEN @a2  
									 WHEN 3 THEN @a3  
									 WHEN 4 THEN @a4  
									 WHEN 5 THEN @a5  
									 WHEN 6 THEN @a6 END),  
		@ccnt = @ccnt - 1  
  
		SELECT @a = REVERSE(@a)  
  
		-- Zip Code  
		IF @acnt = 1  
		BEGIN  
			IF CHARINDEX(' ', @a) > 0  
			BEGIN  
				SELECT @azip = LTRIM(REVERSE(SUBSTRING(@a,1, ( CHARINDEX(' ', @a) - 1))))  
				SELECT @a = LTRIM( SUBSTRING(@a, (CHARINDEX(' ', @a)), 255))   
			END  
			ELSE  
				SELECT @azip = Reverse(@a), @a = ''  
  
			IF UPPER(@azip) LIKE '[0-9][A-Z][0-9]' -- Canadian postal codes in ANA NAN format  
			BEGIN  
				if CHARINDEX(' ', @a) > 0  
				BEGIN  
					SELECT @azip = LTRIM(REVERSE(SUBSTRING(@a,1, (CHARINDEX(' ', @a) - 1)))) + ' ' + @azip  
					SELECT @a = LTRIM( SUBSTRING(@a, (CHARINDEX(' ', @a)), 255))   
				END  
				ELSE  
					SELECT @azip = REVERSE(@a) + ' ' + @azip, @a = ''  
			END  
  
			SELECT @acnt = @acnt + 1  
    
			IF @a = ''    
				CONTINUE  
		END  
  
		-- State  
		IF @acnt = 2  
		BEGIN  
			SET @pos = CHARINDEX(',', @a)  
    
			IF @pos = 0   
				SET @pos = CHARINDEX(' ', @a)  
        
			IF @pos > 0  
			BEGIN  
				SELECT @astate = LTRIM(REVERSE(SUBSTRING(@a,1, ( @pos - 1))))  
				SELECT @a = LTRIM( SUBSTRING(@a, ( @pos), 255))   
      
				IF SUBSTRING(@a, 1, 1) = ','  
					SELECT @a = LTRIM( SUBSTRING(@a, 2, 255))  
				ELSE  
					SELECT @a = LTRIM(@a)  
			END  
			ELSE  
			BEGIN  
				SELECT @astate = REVERSE(@a), @a = ''  
   
				IF @acnt = @mcnt AND DATALENGTH(@astate) < 2  
					SELECT @astate = '', @azip = ''  
			END  
  
			SELECT @acnt = @acnt + 1  
		
			IF @a = ''    
				CONTINUE  
		END  
  
		-- City  
		IF @acnt = 3  
		BEGIN  
			IF @astate = ''  
			BEGIN  
				SELECT @acnt = 4  
				CONTINUE  
			END  
  
			SELECT @acity = ltrim(Reverse(@a))  
			SELECT @acnt = 4  
			SELECT @a = ''   
		END  
	END  
  
	SELECT	@a1 = ISNULL(@a1,''),  
			@a2 = ISNULL(@a2,''),  
			@a3 = ISNULL(@a3,''),  
			@a4 = ISNULL(@a4,''),  
			@a5 = ISNULL(@a5,''),  
			@a6 = ISNULL(@a6,''),  
			@acity = ISNULL(@acity,''),  
			@astate = ISNULL(@astate,''),  
			@azip = ISNULL(@azip,'')  
  
  
	SELECT	@addr_line_1 = @a1 + '~!' + @a2 + '~!' + @a3 + '~!' + @a4 + '~!' + @a5 + '~!' + @a6 + '~!' + @acity + '~!' + @astate + + '~!' + @azip   
	SELECT @addr_line_0 = ISNULL(@addr1,'') + '~!' + ISNULL(@addr2,'')  + '~!' + ISNULL(@addr3,'') + '~!' + ISNULL(@addr4,'')  + '~!' + ISNULL(@addr5,'')  + '~!' + ISNULL(@addr6,'')   
			+ '~!' + ISNULL(@city,'') + '~!' + ISNULL(@state,'') +  '~!' + ISNULL(@zip,'')   
  
	IF @addr_line_0 = @addr_line_1  
		SET @rc = 2  
   
	SELECT  @city = @acity,  
			@state = @astate,  
			@zip = @azip  
  

    SELECT	LEFT(@acity,40) city, 
			LEFT(@astate,40) state, 
			LEFT(@azip,15) zip
			
	RETURN @rc  
END  
GO
GRANT EXECUTE ON  [dbo].[tp_parse_address] TO [public]
GO
