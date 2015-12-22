SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2009 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2009 Epicor Software Corporation, 2009    
                  All Rights Reserved                    
*/                                                































CREATE PROCEDURE [dbo].[eptolchkSubTotal_sp] (
	@match_ctrl_num		varchar(16),
	@force_correction	smallint 	OUTPUT,
	@message		varchar(40) 	OUTPUT,
	@put_on_hold		smallint 	OUTPUT)
AS

DECLARE
	@tolerance_type		int, 	
 	@active_flag	 smallint, 
 	@tolerance_basis smallint, 
 	@basis_value 	float, 
 	@over_flag 		smallint, 
 	@under_flag 		smallint, 
 	@display_msg_flag	smallint, 

	@exists			smallint,
	@receipt_value		float,		
	@invoice_value		float,
	@tol_msg_flag		smallint	
	
DECLARE 	@tolerance_code		varchar(8)
					
SELECT	
	@exists			= 0,
	@tolerance_type 	= 0,
 	@active_flag 		= 0,
	@force_correction 	= 0,
	@put_on_hold 		= 0,
	@message 		= ''


select @tolerance_code = isnull(tolerance_code,'') from epmchopt


IF (@tolerance_code = 'NONE' OR @tolerance_code = '')
BEGIN
	
	RETURN 0
END


SELECT	@exists = COUNT(*)
FROM	eptollin
WHERE	tolerance_code = @tolerance_code

IF (@exists = 0)
BEGIN
	SELECT @message = 'Unknown tolerance code.'
	
	RETURN -1
END

SELECT 	
	@tolerance_type = tolerance_type,
	@active_flag = active_flag,
	@tolerance_basis = tolerance_basis,
	@basis_value = basis_value,
	@over_flag = over_flag,
	@under_flag = under_flag,
	@display_msg_flag = display_msg_flag,
	@message = message
FROM 	eptollin (nolock)
WHERE 	tolerance_code = @tolerance_code 
AND	tolerance_type = 1

IF (@active_flag = 1)
BEGIN
	SELECT 	@receipt_value = SUM(qty_received*unit_price),
		@invoice_value = SUM( (qty_invoiced*invoice_unit_price)+(amt_prev_invoiced))
	FROM 	#epmchdtl
	WHERE	match_ctrl_num = @match_ctrl_num

END

EXEC eptolchk3_sp 
	@receipt_value,
	@invoice_value,
	@tolerance_basis,
	@basis_value,
	@over_flag,
	@under_flag,
	@display_msg_flag,
	@tol_msg_flag OUTPUT

IF (@tol_msg_flag = 0)
	SELECT @force_correction = 0, @message = '', @put_on_hold = 0

ELSE IF (@tol_msg_flag = 1 OR @tol_msg_flag = 2)
BEGIN	
	SELECT @force_correction = 1, @put_on_hold = 0
	
	RETURN 0
END
ELSE IF (@tol_msg_flag = 3)
BEGIN	
	SELECT @force_correction = 0, @put_on_hold = 1
	
	RETURN 0
END
ELSE IF (@tol_msg_flag = 4)
BEGIN	
	SELECT @force_correction = 0, @message = '', @put_on_hold = 1
	
	RETURN 0
END



RETURN 0
GO
GRANT EXECUTE ON  [dbo].[eptolchkSubTotal_sp] TO [public]
GO
