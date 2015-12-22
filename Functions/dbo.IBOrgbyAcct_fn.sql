SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2007 Epicor Software Corporation, 2007    
                  All Rights Reserved                    
*/                                                





























CREATE FUNCTION [dbo].[IBOrgbyAcct_fn] (@account_code varchar(32))
RETURNS varchar(30)
AS
BEGIN

	DECLARE @org_id varchar(30),	@ib_offset int,		@ib_length int,		@ib_segment int,
		@ib_flag int, 		@branch_segment varchar(32)
	
	SELECT @org_id = ''

	SELECT 	@ib_flag  = ib_flag, @ib_offset = ib_offset,	@ib_length = ib_length,	@ib_segment = ib_segment
	FROM	glco
	
	IF (@ib_flag  = 1 )
	BEGIN	
				
		IF @ib_segment = 1
		BEGIN
			SELECT 	@branch_segment = SUBSTRING(seg1_code,@ib_offset,@ib_length)
			FROM	glchart
			WHERE	account_code = @account_code
		END

		IF @ib_segment = 2
		BEGIN
			SELECT 	@branch_segment = SUBSTRING(seg2_code,@ib_offset,@ib_length)
			FROM	glchart
			WHERE	account_code = @account_code
		END
		IF @ib_segment = 3
		BEGIN
			SELECT @branch_segment = SUBSTRING(seg3_code,@ib_offset,@ib_length)
			FROM	glchart
			WHERE	account_code = @account_code
		END
		
		IF @ib_segment = 4
		BEGIN
			SELECT @branch_segment = SUBSTRING(seg4_code,@ib_offset,@ib_length)
			FROM	glchart
			WHERE	account_code = @account_code
		END

		SELECT 	@org_id 	= organization_id
		FROM	Organization_all				
		WHERE	branch_account_number = @branch_segment
		
	END
	
	IF 	(@org_id = '' OR @ib_flag <> 1  )
	BEGIN

		SELECT 	@org_id = organization_id
		FROM	Organization_all			
		WHERE	outline_num = '1'			
		
	END

	RETURN @org_id

END
GO
GRANT REFERENCES ON  [dbo].[IBOrgbyAcct_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[IBOrgbyAcct_fn] TO [public]
GO
