SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/ 

CREATE PROCEDURE [dbo].[ValidateItemLocation] (
	@part_num VARCHAR(30),
	@ship_from VARCHAR(30),
	@ship_to VARCHAR(30),
	@process_type INTEGER = NULL)

AS

DECLARE @result INTEGER

SET @result = 0

IF (ISNULL(@process_type,0) = 0) 
BEGIN
	SET @result = 0
END

IF (@process_type = 1)
BEGIN
	EXEC @result = adm_ep_valid_xfr @part_no = @part_num, @from_loc = @ship_from, @to_loc = @ship_to
END

IF (@process_type = 2)
BEGIN
	EXEC @result = adm_ep_valid_xfr_OTS @part_no = @part_num, @to_loc = @ship_to
END

SELECT @result AS isvalid


GRANT EXECUTE ON ValidateItemLocation TO PUBLIC





GO
GRANT EXECUTE ON  [dbo].[ValidateItemLocation] TO [public]
GO
