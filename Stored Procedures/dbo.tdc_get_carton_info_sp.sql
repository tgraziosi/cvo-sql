SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 08/05/2014 - Issue #572 - Masterpack - Polarized Labs    
CREATE PROCEDURE [dbo].[tdc_get_carton_info_sp]	@tran_code  char(1),    
											@tran_no  int,    
											@tran_ext  int    
AS    
    
IF @TRAN_CODE = 'O'  --Orders    
BEGIN    
	SELECT carton_no, carrier_code, date_shipped, cs_tracking_no, weight, cs_dim_weight, cs_published_freight,    
               cs_disc_freight, adjust_rate, charge_code, cs_zone,carton_type, carton_class    
	FROM tdc_carton_tx (nolock)    
	WHERE order_type = 'S' AND order_no = @tran_no AND order_ext = @tran_ext 
	UNION 
	SELECT	a.pack_no carton_no, a.carrier_code,  NULL date_shipped, a.cs_tracking_no, a.weight, a.cs_dim_weight, a.cs_published_freight,    
			a.cs_disc_freight, a.adjust_rate, a.charge_code, a.cs_zone, 'MP' carton_type, '' carton_class    
	FROM	tdc_master_pack_tbl a (NOLOCK)
	JOIN	tdc_master_pack_ctn_tbl b (NOLOCK)
    ON		a.pack_no = b.pack_no
	JOIN	tdc_carton_tx c (NOLOCK)
	ON		b.carton_no = c.carton_no
	JOIN	orders_all d (NOLOCK)
	ON		c.order_no = d.order_no
	AND		c.order_ext = d.ext
	WHERE   c.order_no = @tran_no AND order_ext = @tran_ext 
	AND		ISNULL(d.sold_to,'') > ''
	AND		RIGHT(d.user_category,2) = 'PL'     
  
END    
ELSE IF @TRAN_CODE = 'X' --Transfers    
BEGIN    
	SELECT carton_no, carrier_code, date_shipped, cs_tracking_no, weight, cs_dim_weight, cs_published_freight,    
               cs_disc_freight, adjust_rate, charge_code, cs_zone,carton_type, carton_class    
	FROM tdc_carton_tx (nolock)    
	WHERE order_type = 'T' AND order_no = @tran_no AND order_ext = 0    
END 

GO
GRANT EXECUTE ON  [dbo].[tdc_get_carton_info_sp] TO [public]
GO
