SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_cdock_header] 
	@location 	varchar(10), 
	@tran_type 	varchar(10), 
	@part_no 	varchar(30), 
	@from_date 	varchar(50), 
	@to_date	varchar(50)
AS
 
 
-------------------------------
-- Load order temp table
-------------------------------
TRUNCATE TABLE #xdock_demand
TRUNCATE TABLE #tmp_cdock_mgt

IF @tran_type = 'SO-CDOCK' OR @tran_type = 'ALL'
BEGIN
	INSERT INTO #xdock_demand (tran_type, tran_no, tran_ext, location, line_no, part_no, qty_cdocked, cust_code, cust_name, committed_qty)
	SELECT trans, cast(trans_type_no as varchar), trans_type_ext, a.location, line_no, part_no, qty_to_process, cust_code, 
	         (SELECT customer_name FROM arcust (NOLOCK) WHERE customer_code = cust_code),
		 (SELECT SUM(c.qty) FROM tdc_cdock_mgt c (NOLOCK) 
                   WHERE a.trans_type_no  = c.tran_no                                                              
	             AND a.trans_type_ext = c.tran_ext       
	             AND a.location       = c.location
		     AND a.line_no	  = c.line_no
		     AND a.part_no	  = c.part_no)            
	    FROM tdc_pick_queue a (NOLOCK),                                                             
	         orders         b (NOLOCK)                                                              
	   WHERE trans = 'SO-CDOCK'
	     AND trans_type_no  = order_no                                                              
	     AND trans_type_ext = ext                                                                   
	     AND sch_ship_date BETWEEN CONVERT(DATETIME, @from_date) AND CONVERT(DATETIME, @to_date + ' 23:59:59.998')
	     AND (@location = 'ALL' OR a.location = @location)
	     AND (@part_no = 'ALL' OR a.part_no = @part_no)
END
IF @tran_type = 'WO-CDOCK' OR @tran_type = 'ALL'
BEGIN
	INSERT INTO #xdock_demand (tran_type, tran_no, tran_ext, location, line_no, part_no, qty_cdocked, cust_code, cust_name, committed_qty)
	SELECT trans, cast(trans_type_no as varchar), trans_type_ext, a.location, line_no, a.part_no, qty_to_process, '', '',
		 (SELECT SUM(c.qty) FROM tdc_cdock_mgt c (NOLOCK) 
                   WHERE a.trans_type_no  = c.tran_no                                                              
	             AND a.trans_type_ext = c.tran_ext       
	             AND a.location       = c.location
		     AND a.line_no	  = c.line_no
		     AND a.part_no	  = c.part_no)             
	    FROM tdc_pick_queue a (NOLOCK),                                                             
	         produce        b (NOLOCK)                                                              
	   WHERE trans = 'WO-CDOCK'
	     AND trans_type_no  = prod_no                                                               
	     AND trans_type_ext = prod_ext                                                              
	     AND sch_date BETWEEN CONVERT(DATETIME, @from_date) AND CONVERT(DATETIME, @to_date + ' 23:59:59.998')
	     AND (@location = 'ALL' OR a.location = @location)
	     AND (@part_no = 'ALL' OR a.part_no = @part_no)
END
IF @tran_type = 'XFER-CDOCK' OR @tran_type = 'ALL'
BEGIN
	INSERT INTO #xdock_demand (tran_type, tran_no, tran_ext, location, line_no, part_no, qty_cdocked, cust_code, cust_name, committed_qty)
	SELECT trans, cast(trans_type_no as varchar), trans_type_ext, a.location, line_no, part_no, qty_to_process, to_loc,  
       		 (SELECT [name] FROM locations (NOLOCK) WHERE location = to_loc),
		 (SELECT SUM(c.qty) FROM tdc_cdock_mgt c (NOLOCK) 
                   WHERE a.trans_type_no  = c.tran_no                                                                 
	             AND a.location       = c.location
		     AND a.line_no	  = c.line_no
		     AND a.part_no	  = c.part_no)                                  
	    FROM tdc_pick_queue a (NOLOCK),                                                             
	         xfers          b (NOLOCK)                                                              
	   WHERE trans = 'XFER-CDOCK'
	     AND trans_type_no  = xfer_no  
	     --AND sch_ship_date BETWEEN CONVERT(DATETIME, @from_date) AND CONVERT(DATETIME, @to_date + ' 23:59:59.998')
	     --AND (@location = 'ALL' OR a.location = @location)
	     --AND (@part_no = 'ALL' OR a.part_no = @part_no)
END
 

GO
GRANT EXECUTE ON  [dbo].[tdc_cdock_header] TO [public]
GO
