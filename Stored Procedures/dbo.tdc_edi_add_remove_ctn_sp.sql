SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[tdc_edi_add_remove_ctn_sp]
	@asn 		int,
	@cust_code	varchar(10), 
	@cust_po	varchar(20), 
	@ship_to	varchar(10),
	@err_msg varchar(255) OUTPUT
AS

DECLARE @carton_no int,
	@ret 	   int

DECLARE edi_remove_cur CURSOR FOR  
	SELECT carton_no FROM #edi_carton_grid_unassigned
	 WHERE carton_no IN (             
			    SELECT child_serial_no            
			      FROM tdc_dist_group (NOLOCK)      
			     WHERE parent_serial_no = @asn    
			       AND method = '01'           
			       AND type = 'E1'                   
			       AND [function] = 'S'              
			       AND status in ('O', 'C'))

OPEN edi_remove_cur
FETCH NEXT FROM edi_remove_cur INTO @carton_no
WHILE @@FETCH_STATUS = 0
BEGIN
	--IF carton is in the cursor AND in the list table,
	--the user has removed the carton.  call the stored procedure to remove it.
	EXEC @ret = tdc_asn_rmv_carton_sp @asn, @carton_no, '01', @err_msg OUTPUT
        IF @ret <> 0 RETURN @ret

	FETCH NEXT FROM edi_remove_cur INTO @carton_no
END
CLOSE edi_remove_cur
DEALLOCATE edi_remove_cur    


DECLARE edi_add_cur CURSOR FOR 
	SELECT carton_no FROM  #edi_carton_grid_assigned
	 WHERE carton_no NOT IN(             
		    SELECT child_serial_no            
		      FROM tdc_dist_group (NOLOCK)      
		     WHERE parent_serial_no = @asn    
		       AND method = '01'           
		       AND type = 'E1'                   
		       AND [function] = 'S'              
		       AND status in ('O', 'C'))

OPEN edi_add_cur
FETCH NEXT FROM edi_add_cur INTO @carton_no
WHILE @@FETCH_STATUS = 0
BEGIN
	--IF carton is in the cursor AND in the grid table,
	--the user has added the carton.  call the stored procedure to add it.
	EXEC @ret = tdc_asn_is_cart_mp_sp @carton_no, '01'
        
	IF @ret = 0 -- master pack
	BEGIN
		EXEC @ret = tdc_asn_add_carton_sp @asn, @carton_no, '01', @err_msg OUTPUT
	END
	ELSE
	BEGIN
		EXEC @ret = tdc_asn_add_mp_sp @asn, @carton_no, '01', @err_msg OUTPUT
	END
        IF @ret <> 0 RETURN @ret

	FETCH NEXT FROM edi_add_cur INTO @carton_no
END
CLOSE edi_add_cur
DEALLOCATE edi_add_cur 
    

IF NOT EXISTS(SELECT * FROM tdc_edi_processed_asn    
               WHERE asn = @asn)
BEGIN      
	IF @cust_po = '' SELECT @cust_po = NULL
	IF @ship_to = '' SELECT @ship_to = NULL                                         
	INSERT tdc_edi_processed_asn (asn, cust_code,   
	                            cust_po, ship_to)
	VALUES(@asn, @cust_code, @cust_po, @ship_to)
END                                              
 
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_edi_add_remove_ctn_sp] TO [public]
GO
