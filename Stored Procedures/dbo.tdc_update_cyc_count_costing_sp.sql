SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_update_cyc_count_costing_sp]
		@location	varchar(10),
		@part_no	varchar(30),
		@lot_ser	varchar(25),
		@bin_no		varchar(12),
		@qty_at_count 	decimal(20,2),
		@post_qty	decimal(20,2),
		@costing	varchar(30) OUTPUT
AS

DECLARE @inv_cost_method	varchar(1),
	@amount			decimal(20,2),
	@difference             decimal(20,0),
	@curr_key		varchar(4)


SELECT @inv_cost_method = inv_cost_method FROM inv_master (NOLOCK) WHERE part_no = @part_no

IF @inv_cost_method <> 'S'
BEGIN
	SELECT @amount = avg_cost FROM inventory (NOLOCK) WHERE part_no = @part_no and location = @location
END
ELSE
BEGIN
	SELECT @amount = std_cost FROM inventory (NOLOCK) WHERE part_no = @part_no and location = @location
END
	
SELECT @difference = @qty_at_count - @post_qty
SELECT @amount     = @difference * @amount
	
SELECT @curr_key = curr_key FROM part_price (NOLOCK) WHERE part_no = @part_no
	
IF @difference < 0
	SELECT @costing = CAST(ABS(@amount) AS VARCHAR(20)) + ' ' + @curr_key 
ELSE
	SELECT @costing = '(' + CAST(@amount AS VARCHAR(20)) + ')' + ' ' + @curr_key

SELECT @costing

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_update_cyc_count_costing_sp] TO [public]
GO
