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




















CREATE FUNCTION [dbo].[IBReplaceMaskPart_fn] (@acct_original varchar(32), @acct_mask varchar(35), @ib_segment int
, @ib_offset int, @ib_length int, @branch_account_number varchar(32) ) 
RETURNS varchar(32)
AS
BEGIN
	
	DECLARE @mask_part	varchar(35), @pos int, @intCont int, @pos_acum int
	DECLARE @return_value	varchar(32)
	SET @mask_part = @acct_mask
	SET @intCont = 2
	
	
	IF @ib_segment = 1
	BEGIN
		
		SELECT @pos_acum = 0
	END
	ELSE 
	BEGIN
		


		SELECT @pos_acum = 1 - @ib_segment
		


		SELECT @pos = charindex( '-', @mask_part )
		SELECT @pos_acum = @pos_acum + @pos
		
		SELECT @mask_part = SUBSTRING( @mask_part, @pos+1, len(@mask_part))
		
		WHILE	@intCont < @ib_segment
		BEGIN 
			


			SELECT @pos = charindex( '-', @mask_part )
			SELECT @pos_acum = @pos_acum + @pos 
			
			SELECT @mask_part = SUBSTRING( @mask_part, @pos+1, len(@mask_part))
			SELECT @intCont = @intCont + 1
		END
	END
	
	SELECT @return_value = STUFF(@acct_original,@pos_acum+@ib_offset,@ib_length,@branch_account_number) 
	RETURN @return_value 
END
/**/                                              
GO
GRANT REFERENCES ON  [dbo].[IBReplaceMaskPart_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[IBReplaceMaskPart_fn] TO [public]
GO
