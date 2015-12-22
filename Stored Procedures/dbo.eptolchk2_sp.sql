SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[eptolchk2_sp] (
	@receipt_value		float,
	@invoice_value		float,
 	@tolerance_basis smallint, 
 	@basis_value 	float, 
 	@over_flag 		smallint, 
 	@under_flag 		smallint, 
 	@display_msg_flag	smallint, 
	@tol_msg_flag		smallint OUTPUT)

AS
DECLARE
	@over_limit		float,
	@under_limit		float,
	@over_rng_flag		smallint,
	@under_rng_flag		smallint

	IF ( @tolerance_basis = 1 OR @tolerance_basis = 2 )
	BEGIN
		SELECT @over_limit 	= @receipt_value + @basis_value
		SELECT @under_limit	= @receipt_value - @basis_value
	END
	ELSE IF ( @tolerance_basis = 3 )
	BEGIN
		SELECT @over_limit = @receipt_value + ( @receipt_value * @basis_value/100 )
		SELECT @under_limit = @receipt_value - ( @receipt_value * @basis_value/100 )
	END
	
	
	SELECT @over_rng_flag = 0
	SELECT @under_rng_flag = 0
	
	IF ( @invoice_value > @over_limit )
		SELECT @over_rng_flag = 1
	IF ( @invoice_value < @under_limit )
		SELECT @under_rng_flag = 1

	IF (@over_flag = 2 AND @under_flag = 2)
	BEGIN
		IF (@over_rng_flag = 1 OR @under_rng_flag = 1)
		BEGIN
			IF (@display_msg_flag = 1)
				SELECT @tol_msg_flag = 1
			ELSE
				SELECT @tol_msg_flag = 2
		END
	END
	ELSE IF (@over_flag = 2)
	BEGIN
		IF (@over_rng_flag = 1)
		BEGIN
			IF @display_msg_flag = 1
				SELECT @tol_msg_flag = 1
			ELSE
				SELECT @tol_msg_flag = 2
		END
		ELSE IF (@under_flag = 1 AND @under_rng_flag = 1)
		BEGIN
			IF (@display_msg_flag = 1)
				SELECT @tol_msg_flag = 3
			ELSE
				SELECT @tol_msg_flag = 4
		END
	END
	ELSE IF (@under_flag = 2)
	BEGIN
		IF (@under_rng_flag = 1)
		BEGIN
			IF @display_msg_flag = 1
				SELECT @tol_msg_flag = 1
			ELSE
				SELECT @tol_msg_flag = 2
		END
		ELSE IF (@over_flag = 1 AND @over_rng_flag = 1)
		BEGIN
			IF (@display_msg_flag = 1)
				SELECT @tol_msg_flag = 3
			ELSE
				SELECT @tol_msg_flag = 4
		END
	END
			
	ELSE IF (@over_flag = 1 AND @under_flag = 1)
	BEGIN
		IF (@over_rng_flag = 1 OR @under_rng_flag = 1)
		BEGIN
			IF (@display_msg_flag = 1)
				SELECT @tol_msg_flag = 3
			ELSE
				SELECT @tol_msg_flag = 4
		END
	END
	ELSE IF (@over_flag = 1)
	BEGIN
		IF (@over_rng_flag = 1)
		BEGIN
			IF @display_msg_flag = 1
				SELECT @tol_msg_flag = 3
			ELSE
				SELECT @tol_msg_flag = 4
		END
	END
	ELSE IF (@under_flag = 1)
	BEGIN
		IF (@under_rng_flag = 1)
		BEGIN
			IF @display_msg_flag = 1
				SELECT @tol_msg_flag = 3
			ELSE
				SELECT @tol_msg_flag = 4
		END
	END
					

SELECT @tol_msg_flag
RETURN	0
GO
GRANT EXECUTE ON  [dbo].[eptolchk2_sp] TO [public]
GO
