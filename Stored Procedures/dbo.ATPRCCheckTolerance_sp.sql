SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[ATPRCCheckTolerance_sp] (	@tolerance_code		varchar(8),
						@qty_received 		float,		
						@qty_invoiced 		float,
						@qty_prev_invoiced 	float,
						@amt_prev_invoiced 	float,
						@unit_price 		float,
						@invoice_unit_price 	float,
						@precision		smallint,
						@put_on_hold		smallint 	OUTPUT)
AS

DECLARE
	@tolerance_type		int, 	
 	@active_flag	 	smallint, 
 	@tolerance_basis 	smallint, 
 	@basis_value 		float, 
 	@over_flag 		smallint, 
 	@under_flag 		smallint, 
 	@display_msg_flag	smallint, 
	@exists			smallint,
	@receipt_value		float,		
	@invoice_value		float,
	@tol_msg_flag		smallint	
					
SELECT	
	@exists			= 0,
	@tolerance_type 	= 0,
 	@active_flag 		= 0,
	@put_on_hold 		= 0

DECLARE tolerance_validation CURSOR SCROLL FOR
			SELECT 	tolerance_type,	active_flag,	tolerance_basis,	basis_value,
				over_flag,	under_flag,	display_msg_flag
			FROM 	eptollin
			WHERE 	tolerance_code = @tolerance_code 
			AND	active_flag = 1	
			AND 	tolerance_type in (2,3,4)

OPEN tolerance_validation 

FETCH tolerance_validation 
INTO	@tolerance_type,	@active_flag,		@tolerance_basis,	@basis_value,
	@over_flag,		@under_flag,		@display_msg_flag

WHILE @@FETCH_STATUS = 0
BEGIN
	IF  (@tolerance_type = 2)
	BEGIN
		SELECT @receipt_value = ROUND((@qty_received * @unit_price),@precision), @invoice_value = ROUND((@qty_invoiced * @invoice_unit_price),@precision) + @amt_prev_invoiced
	END

	IF  (@tolerance_type = 3)
	BEGIN
		
		SELECT @receipt_value = @unit_price,  @invoice_value = ROUND(@invoice_unit_price,@precision)

	END 
	

	IF  (@tolerance_type = 4)
	BEGIN

		SELECT @receipt_value = @qty_received, @invoice_value = ROUND(@qty_invoiced + @qty_prev_invoiced,@precision)

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
		SELECT @put_on_hold = 0

	ELSE IF (@tol_msg_flag = 1 OR @tol_msg_flag = 2)
	BEGIN	
		SELECT @put_on_hold = 1
		
	END
	ELSE IF (@tol_msg_flag = 3)
	BEGIN	
		SELECT @put_on_hold = 1
		BREAK
	END
	ELSE IF (@tol_msg_flag = 4)
	BEGIN	
		SELECT @put_on_hold = 1
		BREAK
	END
		

	FETCH tolerance_validation 
	INTO	@tolerance_type,	@active_flag,		@tolerance_basis,	@basis_value,
	@over_flag,		@under_flag,		@display_msg_flag

END


CLOSE tolerance_validation
DEALLOCATE tolerance_validation


RETURN 0



GO
GRANT EXECUTE ON  [dbo].[ATPRCCheckTolerance_sp] TO [public]
GO
