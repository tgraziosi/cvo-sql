SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*
**
**                      Confidential Information
**          Limited Distribution to Authorized Persons Only
**          Created 1995 and Protected as Unpublished Work
**                  Under the U.S. Copyright Act of 2004
**          Copyright (c) Platinum Software Corporation, 2004
**                          All Rights Reserved
**
**  Tables involved:
**      Read:	glchart, glco, organization
**      Write:
**

**  Remarks : 
**
**  Special Processing:
**
**  Error Conditions:
**
**  Returns: 
*/


CREATE FUNCTION [dbo].[IBAcctMask_fn] (@account_code varchar(32), @org_id varchar(30))
RETURNS varchar(32)
AS
BEGIN

	DECLARE @new_account varchar(32),	@branch_account_number varchar(32),		@seg1 varchar(32),		
		@seg2 varchar(32),		@seg3 varchar(32),				@seg4 varchar(32)
	
	IF (SELECT ib_flag FROM glco) <> 1
	BEGIN
		SELECT @new_account = @account_code
	END
	ELSE
	BEGIN	
		SELECT 	@branch_account_number = branch_account_number
		FROM	Organization
		WHERE	organization_id = @org_id
		
		SELECT 	@seg1 = CASE 	WHEN g.ib_segment  = 1 AND ib_flag = 1 THEN STUFF(coa.seg1_code,g.ib_offset,g.ib_length,@branch_account_number) 
				ELSE	coa.seg1_code END,
			@seg2 = CASE 	WHEN g.ib_segment  = 2 AND ib_flag = 1 THEN STUFF(coa.seg2_code,g.ib_offset,g.ib_length,@branch_account_number) 
				ELSE	coa.seg2_code END,
			@seg3 = CASE 	WHEN g.ib_segment  = 3 AND ib_flag = 1 THEN STUFF(coa.seg3_code,g.ib_offset,g.ib_length,@branch_account_number) 
				ELSE	coa.seg3_code END,
			@seg4 = CASE 	WHEN g.ib_segment  = 4 AND ib_flag = 1 THEN STUFF(coa.seg4_code,g.ib_offset,g.ib_length,@branch_account_number) 
				ELSE	coa.seg4_code END
		FROM	glchart coa, glco g
		WHERE	account_code = @account_code
		
		SELECT @new_account = @seg1 + @seg2 + @seg3 + @seg4 
	END
	RETURN ISNULL(@new_account,'')
END
GO
GRANT REFERENCES ON  [dbo].[IBAcctMask_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[IBAcctMask_fn] TO [public]
GO
