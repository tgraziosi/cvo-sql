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


CREATE FUNCTION [dbo].[IBOrgbyAcct_fn1] (@account_code varchar(32))
RETURNS varchar(30)
AS
BEGIN

	DECLARE @org_id varchar(30),	@ib_offset int,		@ib_length int,		@ib_segment int,
		@ib_flag int, 		@branch_segment varchar(32), @lseg1 int,	@lseg2 int,
		@lseg3 int,		@lseg4 int		     		
		
	
	SELECT @org_id = ''

	SELECT 	@ib_flag  = ib_flag, @ib_offset = ib_offset,	@ib_length = ib_length,	@ib_segment = ib_segment
	FROM	glco

	
	select  @lseg1=isnull(max(len(seg_code)),0) from glseg1
	select  @lseg2=isnull(max(len(seg_code)),0) from glseg2
	select  @lseg3=isnull(max(len(seg_code)),0) from glseg3
	select  @lseg4=isnull(max(len(seg_code)),0) from glseg4
	
	IF (@ib_flag  = 1 )
	BEGIN	
				
		IF @ib_segment = 1
		BEGIN
			SELECT @branch_segment = SUBSTRING(@account_code,1,@lseg1)
		END

		IF @ib_segment = 2
		BEGIN
			SELECT @branch_segment = SUBSTRING(@account_code,@lseg1+1,@lseg2)
		END

		IF @ib_segment = 3
		BEGIN
			SELECT @branch_segment = SUBSTRING(@account_code,@lseg1+@lseg2+1,@lseg3)
		END
		
		IF @ib_segment = 4
		BEGIN
			SELECT @branch_segment = SUBSTRING(@account_code,@lseg1+@lseg2+@lseg3+1,@lseg4)
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

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[IBOrgbyAcct_fn1] TO [public]
GO
