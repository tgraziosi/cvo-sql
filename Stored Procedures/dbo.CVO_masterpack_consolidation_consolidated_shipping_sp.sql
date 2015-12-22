SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE PROCEDURE [dbo].[CVO_masterpack_consolidation_consolidated_shipping_sp] @carton_no INT    
AS     
BEGIN    
    
	DECLARE @min_order				INT,    
			@min_ext				INT,     
			@sum_freight			DECIMAL(20,8),    
			@sum_tot_ord_freight	DECIMAL(20,8),    
			@frght_amt				DECIMAL (20, 8),       
			@Weight_code			VARCHAR(255),      
			@Max_charge				DECIMAL (20, 8),      
			@zip_code				VARCHAR(15),       
			@weight					DECIMAL(20, 8),     
			@wght					DECIMAL(20, 8),      
			@carrier_code			VARCHAR(255),      
			@freight_type			VARCHAR(30)       


    
	 IF (SELECT COUNT(DISTINCT order_no) FROM dbo.tdc_carton_tx (NOLOCK) WHERE  carton_no  = @carton_no AND order_type = 'S') > 1      
	 BEGIN    
	  
		SELECT TOP 1 
			@min_order = a.order_no,  
			@min_ext = a.order_ext  
		FROM 
			dbo.tdc_carton_tx a (NOLOCK)
		INNER JOIN
		   dbo.orders b (NOLOCK)
		ON
			a.order_no = b.order_no
			AND a.order_ext = b.ext
		INNER JOIN
			dbo.cvo_orders_all c (NOLOCK) 
		ON
			a.order_no = c.order_no
			AND a.order_ext = c.ext
		WHERE 
			a.carton_no   = @carton_no     
			AND a.order_type = 'S'
			AND ISNULL(b.freight_allow_type,'')  <> 'FRTOVRID' 
			AND ISNULL(c.free_shipping,'N') <> 'Y'  
		ORDER BY 
			a.order_no ASC, 
			a.order_ext ASC  
	    
		IF (@min_order IS NULL)  
		 RETURN  
	 
		-- Reset orders     
		UPDATE 
			a    
		SET    
			a.freight         = 0.0,     
			a.tot_ord_freight = 0.0    
		FROM 
			dbo.orders a
		INNER JOIN        
			dbo.tdc_carton_tx b (NOLOCK)
		ON
			a.order_no = b.order_no
			AND a.ext = b.order_ext
		WHERE  
			b.carton_no   = @carton_no     
			AND b.order_type = 'S'           
	    
	   
		SELECT 
			@carrier_code = carrier_code,   
			@weight = weight, 
			@zip_code = zip     
		FROM   
			dbo.tdc_carton_tx (NOLOCK)    
		WHERE  
			carton_no   = @carton_no     
			AND order_type = 'S'     
	  
		 SELECT 
			@weight = ISNULL(SUM(a.pack_qty * i.weight_ea) ,0)  
		 FROM 
			dbo.tdc_carton_detail_tx a (NOLOCK)   
		 INNER JOIN 
			dbo.inv_master i (NOLOCK)   
		 ON  
			a.part_no = i.part_no   
		 INNER JOIN 
			dbo.tdc_carton_tx b  (NOLOCK)
		 ON  
			a.carton_no = b.carton_no  
		 AND a.order_no = b.order_no -- v1.1
		 AND a.order_ext = b.order_ext -- v1.1
		 INNER JOIN 
			dbo.orders_all o (NOLOCK)  
		 ON  
			b.order_no = o.order_no  
			AND  b.order_ext = o.ext  
		 INNER JOIN 
			dbo.cvo_orders_all cv (NOLOCK)  
		 ON  
			o.order_no = cv.order_no  
			AND o.ext = cv.ext  
		 WHERE 
			b.carton_no = @carton_no  
			AND b.order_type = 'S' 
			AND  ISNULL(o.freight_allow_type,'')  <> 'FRTOVRID' 
			AND  ISNULL(cv.free_shipping,'N') <> 'Y' 
	    
	    
		SELECT 
			@wght = MAX(Max_weight)    
		FROM 
			dbo.CVO_carriers (NOLOCK)
		WHERE 
			Carrier = @carrier_code 
			AND Lower_zip <= LEFT(@zip_code,5) 
			AND Upper_zip >= LEFT(@zip_code,5) 
	    

		SELECT 
			@wght = MIN(Max_weight)    
		FROM 
			dbo.CVO_carriers (NOLOCK)
		WHERE 
			Carrier = @carrier_code 
			AND Lower_zip <= LEFT(@zip_code,5) 
			AND Upper_zip >= LEFT(@zip_code,5) 
			AND Max_weight >= @weight    
	    
		SELECT 
			@Weight_code = MIN(Weight_code)    
		FROM 
			dbo.CVO_carriers (NOLOCK)
		WHERE 
			Carrier = @carrier_code 
			AND Lower_zip <= LEFT(@zip_code,5) 
			AND Upper_zip >= LEFT(@zip_code,5) 
			AND	Max_weight = @wght    
	    
		SELECT  @weight = CEILING(@weight)    

		SELECT 
			@frght_amt = ISNULL(MIN(charge), 0)    
		FROM 
			dbo.CVO_weights (NOLOCK)    
		WHERE 
			Weight_code = @Weight_code 
			AND wgt >= @weight    
	     
		SELECT 
			@Max_charge = MAX(Max_charge)    
		FROM 
			dbo.CVO_carriers (NOLOCK)
		WHERE 
			Carrier = @carrier_code 
			AND Lower_zip <= LEFT(@zip_code,5) 
			AND Upper_zip >= LEFT(@zip_code,5)  
	    
		IF @frght_amt > @Max_charge    
		BEGIN    
			SELECT 1, 'Over $' + CAST(CAST(@Max_charge AS MONEY) AS VARCHAR(20))  + ' can’t ship ' + @carrier_code, @frght_amt    
			RETURN    
		END    
	   
	    
		UPDATE 
			orders     
		SET    
			freight         = @frght_amt,     
			tot_ord_freight = @frght_amt    
		WHERE  
			order_no = @min_order 
			AND ext      = @min_ext    
	END    
END    
GO
GRANT EXECUTE ON  [dbo].[CVO_masterpack_consolidation_consolidated_shipping_sp] TO [public]
GO
