SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_pre_pack_print_sel_sp]
	@con_no int
AS
	TRUNCATE TABLE #pre_pack_print_sel

	---------------------------------------------------------------------------------------
	-- Consolidation Sets
	---------------------------------------------------------------------------------------
	IF @con_no > 0
	BEGIN
		INSERT INTO #pre_pack_print_sel (sel_flg, order_no, order_ext, no_cartons)
		SELECT DISTINCT 0, c.order_no, c.order_ext, 
		       no_cartons = ISNULL((SELECT COUNT(*) 
					      FROM tdc_carton_tx(NOLOCK)
					     WHERE order_no  = c.order_no
					       AND order_ext = c.order_ext),0)       
		 FROM tdc_main           a (NOLOCK),                    
		      tdc_cons_ords      b (NOLOCK),                    
		      tdc_soft_alloc_tbl c (NOLOCK),
		      tdc_carton_tx	 d (NOLOCK)                      
		WHERE a.consolidation_no = b.consolidation_no   
		  AND a.pre_pack	   = 'Y'
		  AND a.consolidation_no = @con_no        
		  AND c.order_no     	   = b.order_no                       
		  AND c.order_ext    	   = b.order_ext                      
		  AND c.order_type   	   = 'S'                              
		  AND c.location     	   = b.location            
		  AND d.order_no	   = b.order_no
		  AND d.order_ext	   = b.order_ext     
		  AND b.alloc_type         = 'PR'     
	END
	ELSE
	---------------------------------------------------------------------------------------
	-- ONE FOR ONE
	---------------------------------------------------------------------------------------
	BEGIN
 
		INSERT INTO #pre_pack_print_sel (sel_flg, order_no, order_ext, no_cartons)
		SELECT DISTINCT 0, c.order_no, c.order_ext, 
		       no_cartons = ISNULL((SELECT COUNT(*) 
					      FROM tdc_carton_tx(NOLOCK)
					     WHERE order_no  = c.order_no
					       AND order_ext = c.order_ext),0)       
		 FROM tdc_main           a (NOLOCK),                    
		      tdc_cons_ords      b (NOLOCK),                    
		      tdc_soft_alloc_tbl c (NOLOCK),
		      tdc_carton_tx	 d (NOLOCK)                       
		WHERE a.consolidation_no = b.consolidation_no   
		  AND a.pre_pack	   = 'Y'    
		  AND c.order_no     	   = b.order_no                       
		  AND c.order_ext    	   = b.order_ext                      
		  AND c.order_type   	   = 'S'                              
		  AND c.location     	   = b.location  
		  AND d.order_no	   = b.order_no
		  AND d.order_ext	   = b.order_ext   
		  AND b.alloc_type         = 'PR'     
		  AND a.consolidation_no IN (SELECT consolidation_no 
					       FROM tdc_cons_ords (NOLOCK)
					      GROUP BY consolidation_no
					     HAVING COUNT (consolidation_no) = 1)		
	END

RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_pre_pack_print_sel_sp] TO [public]
GO
