SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--######################################################################
-- 
-- When unfreighting a carton, this procedure is called to 
-- subtract the freight amount of the carton from the 
-- freight amount of the order
--
--######################################################################

CREATE PROCEDURE [dbo].[tdc_update_order_freight_sp]
(
  @carton_no int,
  @bSubtract int
)
AS 

DECLARE @ord_no  	INT
DECLARE @ord_ext 	INT
DECLARE @freight_amt 	DECIMAL


SELECT @ord_no = order_no FROM tdc_carton_detail_tx where carton_no = @carton_no
SELECT @ord_ext = order_ext FROM tdc_carton_detail_tx where carton_no = @carton_no

--Get the freight amount from the carton
SELECT @freight_amt = ISNULL(carton_content_value,0) FROM tdc_carton_tx
	WHERE carton_no = @carton_no 

--If subtracting carton freight amount, set the amount to negative
IF (@bSubtract = 1)
	SELECT @freight_amt = 0 - @freight_amt

--Check to ensure the freight type is NOT free freight (freight_allow_type = 8)
IF(SELECT COUNT(*) FROM orders (NOLOCK) WHERE order_no = @ord_no AND ext = @ord_ext AND freight_allow_type = 8) = 0
	BEGIN
		--update the freight amount on the orders table with the freight amount from the carton
		UPDATE orders SET freight = freight + @freight_amt 
		WHERE order_no = @ord_no 
		AND ext = @ord_ext
	END
GO
GRANT EXECUTE ON  [dbo].[tdc_update_order_freight_sp] TO [public]
GO
