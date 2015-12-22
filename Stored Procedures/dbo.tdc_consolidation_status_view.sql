SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_consolidation_status_view]
(
	@include_archived_records	int
)
AS

DECLARE @consolidation_no 	int,
	@total_orders	  	int,
	@total_cartons		int,
	@consolidation_name	varchar(100),
	@description		varchar(100),
	@created_by		varchar(50),
	@creation_date		datetime,
	@orders_assigned	decimal(20,2),
	@pre_packed		decimal(20,2),
	@pre_pack_ready		decimal(20,2),
	@pack_printed		decimal(20,2),
	@pack_verified		decimal(20,2),
	@wave_allocated		decimal(20,2),
	@qty_in_soft_alloc	decimal(20,8), 
	@qty_ordered		decimal(20,8),
	@qty_shipped		decimal(20,8),
	@status			varchar(10)

/*
----------------------------------------------------------------------------------------------------------------
--	Now get the statuses
-- 	Per Mike.
----------------------------------------------------------------------------------------------------------------

Status = "Orders Assigned" 
	This will reflect 0% if a consolidation number was created but no orders assigned.  
	Otherwise it will reflect 100% as we will never know the number of orders that we are to assign until they do so.

Status = "% in Replenish Bins"
	This will reflect the % of inventory that has been moved to the replenishment bins(area).  
	i.e. 1000 partA's on 10 orders (assigned to the same wave) and 200 are still on the queue scheduled 
	to be moved via a PLWB2B move transaction.  This example will reflect 80% complete.


Status = "Pre-Packed"
	This will be the status of any wave that has had cartons assigned to the wave/orders.  
	This will always be 100% for true and 0% if no cartons have been assigned.
	JVC: Is it possible to show the % based on the number of orders in the wave that have a carton created vs. 
	the total number of orders? It is possible that the planners would pre-pack a single order and then the pre-pack % 
	would be at 100 when there are other orders that need to be pre-packed.
	01-08-2003 -- Change the output to char(1) of 'Y' or 'N'


Status = "Printed"
	The % will be 100 if the pick slips have been printed and 0 if not. 
	JVC: Do you keep track of printing at the order level? It would be good to know if only some of the packing list were printed. 

Status = "Pack Verified"
	The % will reflect the total number of cartons that have been pack verified.  
	i.e. if 100 cartons are assigned to 20 orders in a wave and 50 of the cartons have been pack verified, 
	then the % will reflect 50%.

----------------------------------------------------------------------------------------------------------------
*/
IF @include_archived_records = 1
BEGIN
	DECLARE cons_cursor CURSOR FOR 
		SELECT consolidation_no,          ISNULL(consolidation_name, ''), 
		       ISNULL([description], ''), ISNULL(created_by,         ''), 
		       ISNULL(creation_date, ''),                                 
		       (SELECT COUNT(order_no) FROM tdc_cons_ords co (NOLOCK)     
		         WHERE m.consolidation_no = co.consolidation_no),         
		       0, 0, 0, 0, 0, 0, 'Active'    											          
		  FROM tdc_main m (NOLOCK)          
		 WHERE m.order_type = 'S'                                             
		   AND (EXISTS(SELECT *                                               
		                 FROM tdc_cons_ords b (NOLOCK),                       
		                      orders c (NOLOCK)                               
		                WHERE b.consolidation_no = m.consolidation_no         
		                  AND b.order_no = c.order_no                         
		                  AND b.order_ext = c.ext                             
		                  AND c.status < 'R'))                                
		    OR (NOT EXISTS (SELECT *                                          
		                      FROM tdc_cons_ords (NOLOCK)                     
		                     WHERE consolidation_no = m.consolidation_no)) 
		UNION                              
		SELECT consolidation_no,          ISNULL(consolidation_name, ''), 
		       ISNULL([description], ''), ISNULL(created_by,         ''), 
		       ISNULL(creation_date, ''),                                 
		       (SELECT COUNT(order_no) FROM tdc_cons_ords co (NOLOCK)     
		         WHERE m.consolidation_no = co.consolidation_no),         
		       0, 0, 0, 0, 0, 0, 'Inactive'    											          
		  FROM tdc_main_arch m (NOLOCK)          
		 WHERE m.order_type = 'S'                                             
		   AND (EXISTS(SELECT *                                               
		                 FROM tdc_cons_ords b (NOLOCK),                       
		                      orders c (NOLOCK)                               
		                WHERE b.consolidation_no = m.consolidation_no         
		                  AND b.order_no = c.order_no                         
		                  AND b.order_ext = c.ext                             
		                  AND c.status < 'R'))                                
		    OR (NOT EXISTS (SELECT *                                          
		                      FROM tdc_cons_ords (NOLOCK)                     
		                     WHERE consolidation_no = m.consolidation_no)) 
	OPEN cons_cursor
END
ELSE
BEGIN
	DECLARE cons_cursor CURSOR FOR 
		SELECT consolidation_no,          ISNULL(consolidation_name, ''), 
		       ISNULL([description], ''), ISNULL(created_by,         ''), 
		       ISNULL(creation_date, ''),                                 
		       (SELECT COUNT(order_no) FROM tdc_cons_ords co (NOLOCK)     
		         WHERE m.consolidation_no = co.consolidation_no),         
		       0, 0, 0, 0, 0, 0, 'Active'    											          
		  FROM tdc_main m (NOLOCK)          
		 WHERE m.order_type = 'S'                                             
		   AND (EXISTS(SELECT *                                               
		                 FROM tdc_cons_ords b (NOLOCK),                       
		                      orders c (NOLOCK)                               
		                WHERE b.consolidation_no = m.consolidation_no         
		                  AND b.order_no = c.order_no                         
		                  AND b.order_ext = c.ext                             
		                  AND c.status < 'R'))                                
		    OR (NOT EXISTS (SELECT *                                          
		                      FROM tdc_cons_ords (NOLOCK)                     
		                     WHERE consolidation_no = m.consolidation_no)) 
	OPEN cons_cursor
END
FETCH NEXT FROM cons_cursor INTO	@consolidation_no, 	@consolidation_name, 	@description, 		@created_by,     
        				@creation_date, 	@total_orders, 		@orders_assigned, 	@wave_allocated,
					@pre_pack_ready, 	@pre_packed, 		@pack_printed, 		@pack_verified,
					@status

WHILE (@@FETCH_STATUS = 0)
BEGIN
	------------------------------------------------------------------------------------
	-- Calculate wave allocated
	------------------------------------------------------------------------------------
	SET @wave_allocated = 0

	-- Get qty in soft allocate
	SELECT @qty_in_soft_alloc = SUM(qty)
	  FROM tdc_soft_alloc_tbl a,
	       tdc_cons_ords b
	 WHERE a.order_no = b.order_no
	   AND a.order_Ext = b.order_ext
	   AND b.consolidation_no = @consolidation_no

	-- Get qty ordered
	SELECT @qty_ordered = SUM(ordered),
	       @qty_shipped = SUM(shipped)
	  FROM ord_list a,
	       tdc_cons_ords b
	 WHERE a.order_no = b.order_no
	   AND a.order_ext = b.order_ext
	   AND b.consolidation_no = @consolidation_no
 

	SELECT @wave_allocated = (ISNULL(@qty_in_soft_alloc, 0) + ISNULL(@qty_shipped, 0)) / @qty_ordered
	IF @wave_allocated > 100 SELECT @wave_allocated = 100
	IF @wave_allocated < 0 SELECT @wave_allocated = 0
	IF @wave_allocated IS NULL SELECT @wave_allocated = 0
	SELECT @wave_allocated = @wave_allocated * 100

	------------------------------------------------------------------------------------
	 
	-- Calculate orders_assigned
	SET @orders_assigned = 0
	SET @orders_assigned = CASE WHEN EXISTS (SELECT top 1 * 
						   FROM tdc_cons_ords (NOLOCK) 
						  WHERE consolidation_no = @consolidation_no)
     	    			    THEN 100
	    			    ELSE 0
       				END 											

	-- Calculate pack_verified
	SET @pack_verified = 0
	
	SELECT @total_cartons = (SELECT COUNT(DISTINCT a.carton_no) 
				   FROM tdc_carton_tx      a (NOLOCK), 
	             		        tdc_cons_ords      b (NOLOCK)    
				  WHERE a.order_no  = b.order_no  
				    AND a.order_ext = b.order_ext                
				    AND a.order_type = 'S'
				    AND b.consolidation_no = @consolidation_no)
/*
******************  THIS BLOCK OF CODE WAS COMMENTED OUT TO SPEED UP THE EXECUTION OF THIS STORED PROCEDURE
******************  THIS ELIMINATES A VALID VALUE FOR PACK_VERIFIED BEING CALCULATED
	IF @total_cartons > 0 
	BEGIN		
		SET @pack_verified = 100 * (SELECT COUNT(DISTINCT a.carton_no) 
					      FROM tdc_carton_detail_tx a (NOLOCK), 
		             		           tdc_cons_ords      	b (NOLOCK)    
					     WHERE a.order_no  = b.order_no  
					       AND a.order_ext = b.order_ext  
					       AND a.pack_tx   = 'Pack Verify' 
					       AND a.pack_qty >= a.qty_to_pack
					       AND b.consolidation_no = @consolidation_no) 		
	      				   / @total_cartons	
	END

	IF (@pack_verified = 100)
	BEGIN
   		SELECT @pre_packed     = 0, @pre_pack_ready = 0, @pack_printed   = 0		
	END
	ELSE
	BEGIN */
		-- Calculate pre_packed
		SET @pre_packed = 0
		IF @total_orders > 0 
		BEGIN
			SET @pre_packed = 100 * (SELECT COUNT(DISTINCT a.order_no)
					  	 FROM tdc_cons_ords a,
					       	      tdc_carton_tx b
					 	WHERE a.order_No = b.order_no
					   	  AND a.order_Ext = b.order_Ext
						  AND b.order_type = 'S'
						  AND a.consolidation_no = @consolidation_no)
						/ @total_orders
		END
		
		-- Calculate pre_pack_ready
		SET @pre_pack_ready = 0
	      	SET @pre_pack_ready = ISNULL(100 - 100 * 
						ISNULL((SELECT SUM(qty_to_process) 
						          FROM tdc_pick_queue (NOLOCK) 
		               				 WHERE trans_type_no = @consolidation_no 
						  	   AND trans         = 'PLWB2B'), 0)
		      				/
					       (SELECT SUM(ordered) 
					          FROM ord_list      a (NOLOCK),             
					               tdc_cons_ords b (NOLOCK)    
					         WHERE a.order_no  	      = b.order_no                    
					           AND a.order_ext 	      = b.order_ext                                 
					           AND b.consolidation_no = @consolidation_no), 0)
				     
		-- Calculate pack_printed
		SET @pack_printed = 0
		IF @total_orders > 0 
		BEGIN
			SET @pack_printed = 100 * 
					       (SELECT COUNT(DISTINCT a.order_no) 
						  FROM tdc_carton_tx      a (NOLOCK), 
			             		       tdc_cons_ords      b (NOLOCK)    
						 WHERE a.order_no  = b.order_no  
						   AND a.order_ext = b.order_ext 
						   AND a.order_type = 'S'        
						   AND a.status >= 'Q'         
						   AND b.consolidation_no = @consolidation_no) 		
		      				/ 
						@total_orders
		END
/*	END
******************  THIS BLOCK OF CODE WAS COMMENTED OUT TO SPEED UP THE EXECUTION OF THIS STORED PROCEDURE
******************  THIS ELIMINATES A VALID VALUE FOR PACK_VERIFIED BEING CALCULATED
*/
	INSERT INTO #consolidation_status_view                            
	       VALUES ( @consolidation_no, @consolidation_name, @description, @created_by,     
	        	@creation_date, @total_orders, @orders_assigned, @wave_allocated,
			@pre_pack_ready, @pre_packed, @pack_printed, @pack_verified, @status)    
	FETCH NEXT FROM cons_cursor INTO	@consolidation_no, 	@consolidation_name, 	@description, 		@created_by,     
	        				@creation_date, 	@total_orders, 		@orders_assigned, 	@wave_allocated,
						@pre_pack_ready, 	@pre_packed, 		@pack_printed, 		@pack_verified,
						@status
END
CLOSE 	   cons_cursor
DEALLOCATE cons_cursor
GO
GRANT EXECUTE ON  [dbo].[tdc_consolidation_status_view] TO [public]
GO
