SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[ATADMCheckTolerance_sp] 	@part_no 	varchar(30),
					@qty	 	float,
					@qty_ordered	float,
					@po_no		varchar(16),
					@line_no	int,
					@price		float,
					@current_cost	decimal(20,8),
					@precision	smallint,
					@put_on_hold	smallint 	OUTPUT
			
AS

DECLARE @tolerance_code 		varchar(10),
	@receipts_qty_action 		char(1),
	@matching_qty_action 		char(1),
	@receipts_unit_price_action 	char(1), 
	@matching_unit_price_action 	char(1),
	@qty_over_pct 			int,
	@qty_under_pct 			int,
	@unit_price_over_pct 		int,
	@unit_price_under_pct 		int,
	@amt_over_ext_price 		decimal(20,8),
	@amt_under_ext_price 		decimal(20,8),
	@dec_variance			decimal(20,8),	
	@ord_extended_price		decimal(20,8),
	@recd_extended_price		decimal(20,8),
	@dollar_variance		decimal(20,8)


SELECT 	@tolerance_code = '',@put_on_hold = 0

SELECT 	@tolerance_code = tolerance_code
FROM 	pur_list (nolock)
WHERE	po_no 	= @po_no 	AND 
	part_no = @part_no 	AND 
	line 	= @line_no

IF	@tolerance_code = ''
BEGIN

	SELECT	@tolerance_code = ISNULL(tolerance_cd, 'NONE')
	FROM	inv_master (nolock)
	WHERE	part_no = @part_no


	IF	(@tolerance_code = 'NONE' OR @tolerance_code = '') 
	BEGIN
		SELECT 	@tolerance_code = value_str
		FROM	config
		WHERE	flag = 'RCV_DFT_TOLERANCE_CD'

	END 
END






IF @tolerance_code = 'NONE' OR @tolerance_code = ''
BEGIN
	SELECT @put_on_hold = 1
END 






SELECT	@receipts_qty_action 	= receipts_qty_action,
	@matching_qty_action 	= matching_qty_action,
	@receipts_unit_price_action = receipts_unit_price_action, 
	@matching_unit_price_action = matching_unit_price_action,
	@qty_over_pct 		= qty_over_pct,
	@qty_under_pct 		= qty_under_pct,
	@unit_price_over_pct 	= unit_price_over_pct,
	@unit_price_under_pct 	= unit_price_under_pct,
	@amt_over_ext_price 	= amt_over_ext_price,
	@amt_under_ext_price 	= amt_under_ext_price
FROM	tolerance (nolock)
WHERE	tolerance_cd = @tolerance_code








IF ((@qty < @qty_ordered) AND (@matching_qty_action <> 'N'))
BEGIN
	IF (@qty_ordered != 0) 
		SELECT @dec_variance = 100 - ((@qty / @qty_ordered) * 100)
	ELSE 
		SELECT @dec_variance = 100

	


	IF (@dec_variance > @qty_under_pct)
	BEGIN
		IF @matching_qty_action = 'E'
		BEGIN
			


			SELECT @put_on_hold = 1
		END

	END  -- End @dec_variance > @qty_under_pct
END





IF ((@qty > @qty_ordered) AND (@matching_qty_action <> 'N'))
BEGIN
	


	IF (@qty_ordered != 0)
		SELECT @dec_variance =  (((@qty - @qty_ordered) / @qty_ordered) * 100)
	ELSE
		SELECT @dec_variance = 100

	
	


	IF (@dec_variance > @qty_over_pct)
	BEGIN
		
		IF @matching_qty_action = 'E'
		BEGIN
			


			 SELECT @put_on_hold = 1
		END

	END 
END	 















SELECT	@ord_extended_price = ROUND(@qty_ordered * @current_cost, @precision)





IF (@price = -1)
	SELECT @recd_extended_price = ROUND(@qty * @current_cost, @precision)
ELSE
	SELECT @recd_extended_price = ROUND(@qty * @price, @precision)





IF ( @recd_extended_price < @ord_extended_price )
BEGIN
	


	IF ( @recd_extended_price <= 0 )
		SELECT @dec_variance = 100
	ELSE
		SELECT @dec_variance = 100 - ROUND(((@recd_extended_price / @ord_extended_price) * 100), @precision)


	


	SELECT @dollar_variance = ROUND((@ord_extended_price - @recd_extended_price), @precision)

	



	IF (@dec_variance > @unit_price_under_pct AND ((@unit_price_under_pct != 0) OR (@amt_under_ext_price = 0)) )
	BEGIN
		
		IF @matching_unit_price_action = 'E'
		BEGIN
			


			SELECT @put_on_hold = 1
		END		
	END 
	



	



	IF (@dollar_variance > @amt_under_ext_price AND ((@amt_under_ext_price <> 0) OR (@unit_price_under_pct = 0)))
	BEGIN
		
		IF @matching_unit_price_action = 'E'
		BEGIN
			


			SELECT @put_on_hold = 1
		END		
		
	END  
END 








IF @recd_extended_price > @ord_extended_price 
BEGIN

	
	IF @ord_extended_price > 0 
		SELECT @dec_variance =  ROUND((((@recd_extended_price - @ord_extended_price) / @ord_extended_price) * 100), @precision)
	else
		SELECT @dec_variance = 100
	

	
	SELECT @dollar_variance = (@recd_extended_price - @ord_extended_price)

	

	IF ((@dec_variance > @unit_price_over_pct) AND ((@unit_price_over_pct <> 0) OR (@amt_over_ext_price = 0)))
	BEGIN
		
		IF @matching_unit_price_action = 'E'
		BEGIN
			


			SELECT @put_on_hold = 1
		END				
	END 

	

	IF ((@dollar_variance > @amt_over_ext_price) AND ((@amt_over_ext_price <> 0) OR (@unit_price_over_pct = 0)))
	BEGIN
		
		IF @matching_unit_price_action = 'E'
		BEGIN
			


			SELECT @put_on_hold = 1
		END				


	END 

END 





RETURN 0


GO
GRANT EXECUTE ON  [dbo].[ATADMCheckTolerance_sp] TO [public]
GO
