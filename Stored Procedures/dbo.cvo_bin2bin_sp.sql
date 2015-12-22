SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
v1.1 CT 28/11/2013 - Issue #1406 - if from and to bin are the same do nothing 

*/

-- EXEC cvo_bin2bin_sp 'BC804HOR5818', '001', 'W02B-03-02', 'F02G-03-11', 1, 'manager' 
CREATE PROC [dbo].[cvo_bin2bin_sp] (@part_no	VARCHAR(30),
								@location	VARCHAR(10),
								@from_bin	VARCHAR(12),
								@to_bin		VARCHAR(12),
								@qty		DECIMAL(20,8),
								@user		VARCHAR(20))
AS
BEGIN
	DECLARE @date_expires	DATETIME,
			@data			VARCHAR(7500)

	-- START v1.1
	IF @from_bin = @to_bin
	BEGIN
		RETURN
	END
	-- END v1.1

	-- Create temporary tables	
	CREATE TABLE #adm_bin_xfer (
		issue_no	int null,
		location	varchar (10)	not null,
		part_no		varchar (30)	not null,
		lot_ser		varchar (25)	not null,
		bin_from	varchar (12)	not null,
		bin_to		varchar (12)	not null,
		date_expires datetime		not null,
		qty			decimal(20,8)	not null,
		who_entered	varchar (50)	not null,
		reason_code	varchar (10)	null,
		err_msg		varchar (255)	null,
		row_id		int identity	not null)	

	CREATE TABLE #temp_who (
		who		VARCHAR(50),
		login_id	VARCHAR(50))

	-- Get expiry date from from_bin
	SELECT
		@date_expires = date_expires
	FROM
		dbo.lot_bin_stock (NOLOCK)
	WHERE
		location = @location
		AND part_no = @part_no
		AND bin_no = @from_bin

	
	-- Populate tables
	INSERT INTO #temp_who (who, login_id) VALUES ('manager', 'manager')

	INSERT INTO #adm_bin_xfer (
		issue_no, 
		location, 
		part_no, 
		lot_ser, 
		bin_from, 
		bin_to, 
		date_expires, 
		qty, 
		who_entered, 
		reason_code, 
		err_msg) 													
	SELECT
		NULL,
		@location,
		@part_no,
		'1',
		@from_bin,
		@to_bin,
		@date_expires,         
		@qty,
		@user, 
		NULL, 
		NULL
	
	-- Execute move
	EXEC dbo.tdc_bin_xfer 

	-- Write logs
	INSERT INTO dbo.tdc_ei_bin_log (
		module, 
		trans, 
		tran_no, 
		tran_ext, 
		location, 
		part_no, 
		from_bin, 
		userid, 
		direction, 
		quantity)
	SELECT
		'ADH',	
		'BN2BN',  
		issue_no,       
		0,			
		location, 
		part_no,		
		bin_from,	  
		who_entered,		
		-1,        
		qty
	FROM
		#adm_bin_xfer

	INSERT INTO dbo.tdc_ei_bin_log (
		module, 
		trans, 
		tran_no, 
		tran_ext, 
		location, 
		part_no, 
		to_bin, 
		userid, 
		direction, 
		quantity) 															  
	SELECT
		'ADH',	  
		'BN2BN', 
		issue_no + 1,    
		0,		
		location,
		part_no,	
		bin_to,	
		who_entered,   
		1,        
		qty
	FROM
		#adm_bin_xfer

	INSERT INTO dbo.tdc_3pl_bin_activity_log (
		trans, 
		location, 
		part_no, 
		bin_no, 
		bin_group, 
		uom, 
		qty, 
		userid, 
		expert, 
		to_bin_no, 
		to_bin_group, 
		to_location) 																
	SELECT
		'BN2BN', 
		a.location, 
		a.part_no,		
		a.bin_from, 
		b.group_code,
		d.uom, 
		a.qty,  
		a.who_entered, 
		'N', 
		a.bin_to,
		c.group_code,
		a.location
	FROM
		#adm_bin_xfer a
	INNER JOIN
		dbo.tdc_bin_master b (NOLOCK)
	ON
		a.location = b.location
		AND a.bin_from = b.bin_no
	INNER JOIN
		dbo.tdc_bin_master c (NOLOCK)
	ON
		a.location = c.location
		AND a.bin_to = c.bin_no
	INNER JOIN
		dbo.inv_master d (NOLOCK)
	ON
		a.part_no = d.part_no

	SELECT @data = dbo.f_create_tdc_log_bin2bin_data_string (@part_no, @qty, @to_bin)	

	INSERT INTO tdc_log (
		tran_date,
		UserID,
		trans_source,
		module,
		trans,
		tran_no,
		tran_ext,
		part_no,
		lot_ser,
		bin_no,
		location,
		quantity,
		data) 										
	SELECT 
		GETDATE(), 
		who_entered, 
		'CO', 
		'ADH', 
		'BN2BN', 
		'', 
		'', 
		part_no, 
		'1', 
		bin_from, 
		location, 
		CAST(CAST(qty AS INT)AS VARCHAR(20)), 
		@data
	FROM	
		#adm_bin_xfer

	RETURN
END

GO
GRANT EXECUTE ON  [dbo].[cvo_bin2bin_sp] TO [public]
GO
