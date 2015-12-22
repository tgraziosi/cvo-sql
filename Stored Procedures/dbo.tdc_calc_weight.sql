SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_calc_weight]
	@carton_no		int,
	@dunnage		decimal(20,8),
	@variance		decimal(20,8),
	@pack_verify		int,
	@calc_weight		decimal(20,8) 	OUTPUT,
	@actual_weight 		decimal(20,8)	OUTPUT			 

AS

if @pack_verify = 1
	SELECT @calc_weight = round(sum(a.pack_qty * b.weight_ea) + d.weight + @dunnage, 1)
	 FROM tdc_carton_detail_tx a(NOLOCK), inv_master b(NOLOCK), tdc_carton_tx c(NOLOCK), tdc_pkg_master d(NOLOCK)
	WHERE a.part_no     = b.part_no
	  AND a.carton_no   = @carton_no
	  AND a.carton_no   = c.carton_no
	  AND c.carton_type = d.pkg_code
	GROUP BY a.carton_no, d.weight
ELSE
	SELECT @calc_weight = round(sum(a.pack_qty * b.weight_ea) + @dunnage, 1)
	 FROM tdc_carton_detail_tx a(NOLOCK), inv_master b(NOLOCK), tdc_carton_tx c(NOLOCK)
	WHERE a.part_no     = b.part_no
	  AND a.carton_no   = @carton_no
	  AND a.carton_no   = c.carton_no
	GROUP BY a.carton_no

SELECT @actual_weight = weight FROM tdc_carton_tx (NOLOCK) WHERE carton_no = @carton_no

SELECT @variance = CASE WHEN @variance >= 0 AND @variance < 1    THEN @variance
                        WHEN @variance >= 1 AND @variance <= 100 THEN @variance/100
                        ELSE -1
                   END
                          
IF @variance = -1
        RETURN 0

IF (ABS(@calc_weight-@actual_weight)/@calc_weight) <= @variance 
	RETURN 1
ELSE
	RETURN -1


GO
GRANT EXECUTE ON  [dbo].[tdc_calc_weight] TO [public]
GO
