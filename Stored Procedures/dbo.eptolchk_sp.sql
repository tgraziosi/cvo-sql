SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[eptolchk_sp] (
	@match_ctrl_num		varchar(16),
	@match_line_num		int,
	@tolerance_code		varchar(8),
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
	
	@qty_received 	float,		
	@qty_invoiced 	float,
	@qty_prev_invoiced 	float,
	@amt_prev_invoiced 	float,
	@unit_price 	float,
	@invoice_unit_price 	float,

	@exists			smallint,
	@receipt_value		float,		
	@invoice_value		float,
	@tol_msg_flag		smallint	
						
						
						
						



	
SELECT	
	@exists			= 0,
	@tolerance_type 	= 0,
 	@active_flag 		= 0,
	@force_correction 	= 0,
	@put_on_hold 		= 0,
	@message 		= ''

IF (@tolerance_code = 'NONE' OR @tolerance_code = '')
BEGIN
	SELECT @force_correction, @message, @put_on_hold
	RETURN 0
END

SELECT	@exists = COUNT(*)
FROM	eptollin
WHERE	tolerance_code = @tolerance_code

IF (@exists = 0)
BEGIN
	SELECT @message = 'Unknown tolerance code.'
	SELECT @force_correction, @message, @put_on_hold
	RETURN -1
END

IF (@match_line_num = 0)

BEGIN
	SELECT 	
		@tolerance_type = tolerance_type,
		@active_flag = active_flag,
		@tolerance_basis = tolerance_basis,
		@basis_value = basis_value,
		@over_flag = over_flag,
		@under_flag = under_flag,
		@display_msg_flag = display_msg_flag,
		@message = message
	FROM 	eptollin
	WHERE 	tolerance_code = @tolerance_code 
	AND	tolerance_type = 1
	
	IF (@active_flag = 1)
	BEGIN
		SELECT 	@receipt_value = SUM(qty_received*unit_price),
			@invoice_value = SUM( (qty_invoiced*invoice_unit_price)+(amt_prev_invoiced))
		FROM 	epmchdtl
		WHERE	match_ctrl_num = @match_ctrl_num

	END
	
	EXEC eptolchk2_sp 
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
		SELECT @force_correction, @message, @put_on_hold
		RETURN 0
	END
	ELSE IF (@tol_msg_flag = 3)
	BEGIN	
		SELECT @force_correction = 0, @put_on_hold = 1
		SELECT @force_correction, @message, @put_on_hold
		RETURN 0
	END
	ELSE IF (@tol_msg_flag = 4)
	BEGIN	
		SELECT @force_correction = 0, @message = '', @put_on_hold = 1
		SELECT @force_correction, @message, @put_on_hold
		RETURN 0
	END

END
ELSE

BEGIN
	
	SELECT
		@qty_received		= qty_received,
		@qty_invoiced		= qty_invoiced,	
		@qty_prev_invoiced	= qty_prev_invoiced,
		@amt_prev_invoiced	= amt_prev_invoiced,
		@unit_price		= unit_price,
		@invoice_unit_price	= invoice_unit_price
	FROM	#epmchdtl
	WHERE	match_ctrl_num		= @match_ctrl_num
	AND	sequence_id		= @match_line_num

	
	SELECT @active_flag = 0
	SELECT 	
		@tolerance_type = tolerance_type,
		@active_flag = active_flag,
		@tolerance_basis = tolerance_basis,
		@basis_value = basis_value,
		@over_flag = over_flag,
		@under_flag = under_flag,
		@display_msg_flag = display_msg_flag,
		@message = message
	FROM 	eptollin
	WHERE 	tolerance_code = @tolerance_code 
	AND	tolerance_type = 2

	IF (@active_flag = 1)
	BEGIN
		SELECT @receipt_value = (@qty_received * @unit_price)
		SELECT @invoice_value = (@qty_invoiced * @invoice_unit_price) + @amt_prev_invoiced
	END
	
	EXEC eptolchk2_sp 
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
		SELECT @force_correction, @message, @put_on_hold
		RETURN 0
	END
	ELSE IF (@tol_msg_flag = 3)
	BEGIN	
		SELECT @force_correction = 0, @put_on_hold = 1
		SELECT @force_correction, @message, @put_on_hold
		RETURN 0
	END
	ELSE IF (@tol_msg_flag = 4)
	BEGIN	
		SELECT @force_correction = 0, @message = '', @put_on_hold = 1
		SELECT @force_correction, @message, @put_on_hold
		RETURN 0
	END

	
	SELECT @active_flag = 0
	SELECT 	
		@tolerance_type = tolerance_type,
		@active_flag = active_flag,
		@tolerance_basis = tolerance_basis,
		@basis_value = basis_value,
		@over_flag = over_flag,
		@under_flag = under_flag,
		@display_msg_flag = display_msg_flag,
		@message = message
	FROM 	eptollin
	WHERE 	tolerance_code = @tolerance_code 
	AND	tolerance_type = 3

	IF (@active_flag = 1)
	BEGIN
		SELECT @receipt_value = @unit_price
		SELECT @invoice_value = @invoice_unit_price
	END

	
	EXEC eptolchk2_sp 
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
		SELECT @force_correction, @message, @put_on_hold
		RETURN 0
	END
	ELSE IF (@tol_msg_flag = 3)
	BEGIN	
		SELECT @force_correction = 0, @put_on_hold = 1
		SELECT @force_correction, @message, @put_on_hold
		RETURN 0
	END
	ELSE IF (@tol_msg_flag = 4)
	BEGIN	
		SELECT @force_correction = 0, @message = '', @put_on_hold = 1
		SELECT @force_correction, @message, @put_on_hold
		RETURN 0
	END
	
	SELECT @active_flag = 0
	SELECT 	
		@tolerance_type = tolerance_type,
		@active_flag = active_flag,
		@tolerance_basis = tolerance_basis,
		@basis_value = basis_value,
		@over_flag = over_flag,
		@under_flag = under_flag,
		@display_msg_flag = display_msg_flag,
		@message = message
	FROM 	eptollin
	WHERE 	tolerance_code = @tolerance_code 
	AND	tolerance_type = 4

	IF (@active_flag = 1)
	BEGIN
		SELECT @receipt_value = @qty_received
		SELECT @invoice_value = @qty_invoiced + @qty_prev_invoiced
	END
	
	EXEC eptolchk2_sp 
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
		SELECT @force_correction, @message, @put_on_hold
		RETURN 0
	END
	ELSE IF (@tol_msg_flag = 3)
	BEGIN	
		SELECT @force_correction = 0, @put_on_hold = 1
		SELECT @force_correction, @message, @put_on_hold
		RETURN 0
	END
	ELSE IF (@tol_msg_flag = 4)
	BEGIN	
		SELECT @force_correction = 0, @message = '', @put_on_hold = 1
		SELECT @force_correction, @message, @put_on_hold
		RETURN 0
	END

END

SELECT @force_correction, @message, @put_on_hold
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[eptolchk_sp] TO [public]
GO
