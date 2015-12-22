SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                





















CREATE PROC [dbo].[poerrprc_sp] @err_num int, @err_msg varchar(80) OUTPUT
 
AS 
DECLARE
	@error_num 			varchar(8),
	@err_in_aperrdef	int,
	@in_err_msg			varchar(80),
	@str_msg			varchar(255)
	
	SELECT @in_err_msg = @err_msg
	
	IF (@in_err_msg != " ")
		SELECT @in_err_msg = @in_err_msg + ", "

	SELECT @err_in_aperrdef = count(*)
 FROM aperrdef
 WHERE e_code = @err_num
 	
 IF (@err_in_aperrdef != 0)
 BEGIN
		SELECT @err_msg = e_ldesc
		FROM aperrdef 
		WHERE e_code = @err_num 
		
	END			
 ELSE
	BEGIN 
	
		IF (@err_num = -2)
		BEGIN
			EXEC appgetstring_sp "STR_APPOXHD1SP_INV_RATE", @str_msg OUT
			SELECT @err_msg = @str_msg
		END
		ELSE
		BEGIN		
			EXEC appgetstring_sp "STR_ERROR", @str_msg OUT	
	 		SELECT @error_num = CONVERT(varchar(8), @err_num)
			SELECT @err_msg = @str_msg + @error_num
		END			
	END

	SELECT @err_msg = @in_err_msg + @err_msg		

GO
GRANT EXECUTE ON  [dbo].[poerrprc_sp] TO [public]
GO
