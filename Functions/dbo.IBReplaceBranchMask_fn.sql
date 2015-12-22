SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                



















CREATE FUNCTION [dbo].[IBReplaceBranchMask_fn] (@account_code varchar(32), @org_id varchar(30))
RETURNS varchar(32)
AS
BEGIN

	DECLARE @new_account varchar(32),	@branch_account_number varchar(32),		@seg1 varchar(32),		
		@seg2 varchar(32),		@seg3 varchar(32),				@seg4 varchar(32)
	
	DECLARE @seg1_code	varchar(32), 
		@seg2_code	varchar(32), 
		@seg3_code	varchar(32),
		@seg4_code	varchar(32),
		@acct_mask	varchar(35),
		@ib_segment	int,
		@ib_offset	int,
		@ib_length	int

	IF (SELECT ib_flag FROM glco) <> 1
	BEGIN
		SELECT @new_account = @account_code
	END
	ELSE
	BEGIN	
		SELECT 	@branch_account_number = branch_account_number
		FROM	Organization
		WHERE	organization_id = @org_id
		
		SELECT @ib_segment = ib_segment, @ib_offset = ib_offset, @ib_length = ib_length, @acct_mask = account_format_mask 
		from glco 
		
		SELECT @new_account = dbo.IBReplaceMaskPart_fn(@account_code, @acct_mask, @ib_segment, @ib_offset, @ib_length, @branch_account_number)
	END
	RETURN ISNULL(@new_account,'')
END

/**/                                              
GO
GRANT REFERENCES ON  [dbo].[IBReplaceBranchMask_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[IBReplaceBranchMask_fn] TO [public]
GO
