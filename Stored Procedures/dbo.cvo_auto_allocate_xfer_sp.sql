SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_auto_allocate_xfer_sp]	@xfer_no INT
AS
BEGIN

	DECLARE @template_code  varchar(20),
			@user_id  varchar(50),
			@ret   int 

	SET @user_id = 'AUTO_ALLOC'  

	-- In order to allocate a xfer: 1. tdc_config.flag = 'xfer_auto_allocate' MUST BE active = 'Y'    
	--								2. the status MUST BE = 'N' 
				 --------------    
	IF (SELECT active FROM tdc_config (NOLOCK) WHERE [function] = 'xfer_auto_allocate') != 'Y' 
		RETURN 0 -- Exit out --    
				 --------------        
	IF NOT EXISTS (SELECT 1 FROM dbo.xfers_all (NOLOCK) WHERE xfer_no = @xfer_no AND status = 'N')
		RETURN 0    -- Exit out --    

	-- Make sure that the transfer passes the criteria filter    
	EXEC @ret = cvo_xfer_auto_alloc_criteria_validate_sp @xfer_no, @template_code OUTPUT    
	    
	IF @ret < 0 
		RETURN -99   

	
	IF NOT EXISTS(SELECT * FROM tdc_plw_process_templates (NOLOCK) WHERE UserID = @user_id AND order_type = 'T')    
	BEGIN    
	 RAISERROR ('Must setup process template for user ''AUTO_ALLOC''', 16, 1)    
	 RETURN -1    
	END    
	  
	    
	IF NOT EXISTS(SELECT * FROM tdc_plw_criteria_templates (NOLOCK) WHERE UserID = @user_id AND template_type = 'T')    
	BEGIN    
	 RAISERROR ('Must setup criteria template for user ''AUTO_ALLOC''', 16, 1)    
	 RETURN -1    
	END    

	-- Unallocate xfer
	EXEC cvo_plw_xfer_unallocate_sp @xfer_no, @user_id

	-- Create temp table
	IF (object_id('tempdb..#xfer_alloc_management')       IS NOT NULL) 
		DROP TABLE #xfer_alloc_management   
	IF (OBJECT_ID('tempdb..#xfer_soft_alloc_byline_tbl')  IS NOT NULL) 
		DROP TABLE #xfer_soft_alloc_byline_tbl
	IF (OBJECT_ID('tempdb..#xfer_lb_stock')               IS NOT NULL) 
		DROP TABLE #xfer_lb_stock    
	IF (OBJECT_ID('tempdb..#xfer_soft_alloc_working_tbl') IS NOT NULL) 
		DROP TABLE #xfer_soft_alloc_working_tbl  

	CREATE TABLE #xfer_alloc_management(                                    
		sel_flg             int             NOT NULL,               
		sel_flg2            int             NOT NULL,               
		prev_alloc_pct      decimal(15, 2)  NOT NULL,               
		curr_alloc_pct      decimal(15, 2)  NOT NULL,               
		curr_fill_pct       decimal(15, 2)  NOT NULL,               
		xfer_no             int             NOT NULL,               
		to_loc              varchar(10)     NOT NULL,               
		from_loc            varchar(10)     NOT NULL,               
		status              char(1)         NOT NULL,               
		carrier_code        varchar(20)         NULL,               
		sch_ship_date       datetime        NOT NULL)  

	CREATE TABLE #xfer_soft_alloc_byline_tbl (
		line_no  int   NOT NULL)

	CREATE TABLE #xfer_lb_stock(                                                           
		from_loc            varchar(10)     NOT NULL,               
		part_no             varchar(30)     NOT NULL,               
		lot_ser             varchar(25)     NOT NULL,               
		bin_no              varchar(12)     NOT NULL,               
		avail_qty           decimal(24,8)   NOT NULL,               
		warning             char(1)             NULL)  

	CREATE TABLE #xfer_soft_alloc_working_tbl(                              
		xfer_no             int             NOT NULL,               
		from_loc            varchar(10)     NOT NULL,               
		line_no             int             NOT NULL,              
		part_no             varchar(30)     NOT NULL,               
		lb_tracking         char(1)         NOT NULL,               
		qty_needed          decimal(24, 8)  NOT NULL,               
		conv_factor         decimal(20, 8)  NOT NULL)   

	-- Load details into table
	INSERT #xfer_alloc_management (
		sel_flg,              
		sel_flg2,              
		prev_alloc_pct,              
		curr_alloc_pct,               
		curr_fill_pct,               
		xfer_no,              
		to_loc,               
		from_loc,           
		[status],               
		carrier_code,              
		sch_ship_date)
	SELECT
		-1,
		0,
		0,
		0,
		0,
		xfer_no,
		to_loc,
		from_loc,
		[status],
		routing,
		sch_ship_date
	FROM
		xfers
	WHERE
		xfer_no = @xfer_no

	-- Call the allocation routine
	EXEC tdc_plw_xfer_soft_alloc_sp @user_id, @template_code, 'ORDER BY  xfer_no ASC'

	RETURN 1
END
GO
GRANT EXECUTE ON  [dbo].[cvo_auto_allocate_xfer_sp] TO [public]
GO
