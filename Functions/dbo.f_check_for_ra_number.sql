SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Copyright (c) 2012 Epicor Software (UK) Ltd
Name:			f_check_for_ra_number
Project ID:		Issue 1490
Type:			Function
Description:	Returns the first credit return with the RA# passed in
Developer:		Chris Tyler

History
-------
v1.0	18/07/2014	CT	Original version
*/

CREATE FUNCTION [dbo].[f_check_for_ra_number] (@ra_in   VARCHAR(30))
RETURNS INT
AS
BEGIN
	DECLARE @ra      VARCHAR(15),  
			@order_no INT,  
			@ext INT,  
			@charpos INT,  
			@chartest CHAR(1)   
  
	-- Format RA#    
	IF ISNULL(@ra_in, '') = ''    
	BEGIN    
		RETURN 0
	END    
	ELSE    
	BEGIN    
     
		-- 1. Remove dashes    
		SET @ra_in = REPLACE(@ra_in,'-','')    
  
		-- 2. RA cannot be less than 4 digits    
		IF LEN(@ra_in) < 4     
		BEGIN    
			RETURN 0
		END    
     
		-- 3. RA cannot be longer than 15 digits    
		IF LEN(@ra_in) > 15    
		BEGIN    
			RETURN 0
		END    
     
		-- 4. Must only by numeric characters    
		SET @charpos = 1    
		WHILE @charpos <= LEN(@ra_in)    
		BEGIN    
			-- Get next character    
			SET @chartest = SUBSTRING(@ra_in,@charpos,1)    

			-- Ensure it's a numeric    
			IF CHARINDEX (@chartest,'0123456789') = 0    
			BEGIN    
				RETURN 0    
			END    

			SET @charpos = @charpos + 1    
		END    
     
		-- 5. Pad with zeros to make up to 15 characters    
		IF LEN(@ra_in) < 15    
		BEGIN    
			SET @ra = LEFT(@ra_in,3) + RIGHT('000000000000' + RIGHT(@ra_in,(LEN(@ra_in) - 3)), 12)    
		END    
		ELSE    
		BEGIN    
			SET @ra = @ra_in    
		END    
		END    
  
		IF EXISTS (SELECT 1 FROM dbo.cvo_credit_return_ra_vw (NOLOCK) WHERE ra = @ra)  
		BEGIN  
			SELECT TOP 1  
				@order_no = order_no,  
				@ext = ext  
			FROM  
				dbo.cvo_credit_return_ra_vw (NOLOCK)   
			WHERE   
				ra = @ra  
			ORDER BY  
				order_no,   
				ext  

			RETURN ISNULL(@order_no,0) 
		  
		END  
 
	RETURN 0
END  

GO
GRANT REFERENCES ON  [dbo].[f_check_for_ra_number] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_check_for_ra_number] TO [public]
GO
