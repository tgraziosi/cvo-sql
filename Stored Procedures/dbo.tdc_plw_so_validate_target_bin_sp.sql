SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_plw_so_validate_target_bin_sp]
@order_no	 int,
@order_ext	 int,
@location	 varchar(30),
@part_no	 varchar(30),
@picking_bin	 varchar(50),
@packgroup	 varchar(12),
@auto_alloc_type int,
@usage_type_code varchar(50),
@err_msg	 varchar(255) OUTPUT
 
AS

	--Order, ext
    	IF @order_no > 0
	BEGIN
		-- Validate Order
        	IF NOT EXISTS(SELECT * FROM #so_alloc_management               
                 	       WHERE sel_flg  != 0                               
                  	         AND order_no  = @order_no
			         AND order_ext = @order_ext)
		BEGIN
			SELECT @err_msg = 'Invalid order'
			RETURN -1
		END
	END

	-- Validate Location
	IF NOT EXISTS(SELECT * FROM #so_alloc_management           
              	       WHERE sel_flg  != 0                           
      		 	 AND location  = @location
			 AND (  (    order_no  = @order_no
			         AND order_ext = @order_ext)
			      OR(   @order_no  = 0)))
	BEGIN
		SELECT @err_msg = 'Invalid location'
		RETURN -1
	END

	-- Validate Part
	IF @part_no <> 'ALL'
	BEGIN
		IF NOT EXISTS(SELECT b.* 
				FROM #so_alloc_management a,
				     #so_allocation_detail_view b
	              	       WHERE a.order_no  = b.order_no
				 AND a.order_ext = b.order_ext
				 AND a.location  = b.location
				 AND a.sel_flg  != 0                           
	      		 	 AND b.location  = @location
				 AND b.part_no   = @part_no
				 AND (  (    b.order_no  = @order_no
				         AND b.order_ext = @order_ext)
				      OR(   @order_no  = 0)))
		BEGIN
			SELECT @err_msg = 'Invalid part number'
			RETURN -1
		END
	END

	-- Picking bin
    	IF @auto_alloc_type = 0
	BEGIN
		IF NOT EXISTS(SELECT * FROM tdc_bin_master (NOLOCK)       
                  	       WHERE bin_no = @picking_bin
                  		 AND location = @location
                  		 AND usage_type_code = @usage_type_code)
		BEGIN
			SELECT @err_msg = 'Invalid picking bin'
			RETURN -1
		END
	END



    	-- Pass bin
	IF NOT EXISTS( SELECT a.group_id  
			 FROM tdc_pack_station_group_tbl a (NOLOCK),  
			      tdc_pack_station_tbl b(NOLOCK)  
			 WHERE a.group_id = b.group_id  
			   AND a.group_id = @packgroup )
	BEGIN
		SELECT @err_msg = 'Invalid pack group'
		RETURN -1
	END
    
	IF EXISTS(SELECT *                                                     
                    FROM #so_alloc_management a,  
			 #so_allocation_detail_view b,                                    
                         tdc_soft_alloc_tbl c(NOLOCK)                          
               	   WHERE (@order_no = 0 OR (a.order_no = @order_no
			       		    AND a.order_ext = @order_ext))
                     AND a.location         = @location
		     AND a.sel_flg	   != 0		     
		     AND b.order_no         = a.order_no                       
                     AND b.order_ext        = a.order_ext  
		     AND b.location         = a.location      
		     AND (@part_no = 'ALL' OR b.part_no = @part_no)  
		     AND c.order_no         = a.order_no                       
                     AND c.order_ext        = a.order_ext  
		     AND c.location         = a.location                    
                     AND c.order_type       = 'S'                                                                        
                     AND c.part_no          = b.part_no                        
                     AND c.target_bin        IS NOT NULL)                   
	BEGIN	
		SELECT @err_msg = 'WARNING:  Existing target bins will be modified. ' + char(13) + 'Do you wish to continue?'
		RETURN -2
	END

	IF EXISTS(SELECT * 
		    FROM tdc_pick_queue a(NOLOCK),
		         tdc_bin_replenishment b(NOLOCK),
		         tdc_soft_alloc_tbl c(NOLOCK)
		   WHERE a.trans_source   = 'MGT'
		     AND a.trans          = 'MGTB2B'
		     AND a.location       = @location
		     AND a.trans_type_no  = 0
		     AND a.trans_type_ext = 0
		     AND a.line_no	  = 0
		     AND b.location	  = a.location
		     AND b.bin_no	  = a.next_op
		     AND b.auto_replen	  = 1
		     AND c.location	  = a.location
		     AND c.part_no	  = b.part_no
		     AND c.order_no	  = 0
		     AND c.order_ext	  = 0
		     AND c.line_no	  = 0
		     AND c.bin_no	  = a.bin_no)
	BEGIN
		SELECT @err_msg ='An Existing MGTB2B move must be completed before allocation can be completed.'
		RETURN -1
	END

/*
	IF EXISTS (SELECT * 
		     FROM tdc_cons_ords a (NOLOCK), 
		          #so_alloc_management b, tdc_pick_queue c (NOLOCK)
		    WHERE a.consolidation_no = @con_no 
		      AND a.order_no 	     = b.order_no 
		      AND a.order_ext        = b.order_ext 
		      AND a.order_no         = c.trans_type_no 
		      AND a.order_ext        = c.trans_type_ext   
		      AND b.location         = c.location 
		      AND b.part_no          = c.part_no 
		      AND a.order_type       = 'S'
		      AND c.tx_lock         != 'R')
	BEGIN
		SELECT @errmsg = 'ERROR:: Attempting to UPDATE existing Queue transactions'
		return -1
	END	
*/

RETURN 1

GO
GRANT EXECUTE ON  [dbo].[tdc_plw_so_validate_target_bin_sp] TO [public]
GO
