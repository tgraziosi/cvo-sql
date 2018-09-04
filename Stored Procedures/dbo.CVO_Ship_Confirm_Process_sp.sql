SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--SET QUOTED_IDENTIFIER ON
--SET ANSI_NULLS ON
--GO
---- v1.1 CT 30/07/2012 - Remove inserts/deletes of tdc_config option mod_ebo_inv

CREATE proc [dbo].[CVO_Ship_Confirm_Process_sp]
AS
BEGIN

	SET NOCOUNT ON

	-- Declarations
	DECLARE	@default_station_id varchar(3),
			@stage_no			varchar(50),
			@last_stage_no		varchar(50),
			@user_id			varchar(50),
			@iRet				int,
			@currentstage		varchar(255),      
			@allshipped			int, 
			@err_msg			varchar(255)

	-- Create working tables
	IF (OBJECT_ID('tempdb..#temp_who') IS NOT NULL) 
		DROP TABLE #temp_who

	IF OBJECT_ID('tempdb..#temp_ship_confirm_display_tbl') IS NOT NULL 
		DROP TABLE #temp_ship_confirm_display_tbl

	IF OBJECT_ID('tempdb..#tdc_ship_xfer') IS NOT NULL 
		DROP TABLE #tdc_ship_xfer                

	IF OBJECT_ID('tempdb..#temp_fedex_close_tbl') IS NOT NULL 
		DROP TABLE #temp_fedex_close_tbl         

	IF OBJECT_ID('tempdb..#temp_ship_confirm_cartons') IS NOT NULL 
		DROP TABLE #temp_ship_confirm_cartons    

	IF OBJECT_ID('tempdb..#stages_to_process') IS NOT NULL 
		DROP TABLE #stages_to_process    

	IF OBJECT_ID('tempdb..#adm_ship_order') IS NOT NULL 
		DROP TABLE #adm_ship_order

	IF OBJECT_ID('tempdb..#cartonsToShip') IS NOT NULL  
		DROP TABLE #cartonsToShip

	IF OBJECT_ID('tempdb..#xfersToShip') IS NOT NULL  
		DROP TABLE #xfersToShip

	CREATE TABLE #temp_who (who varchar(50), login_id varchar(50))

	CREATE TABLE #temp_ship_confirm_cartons (carton_no INT NOT NULL)  
               
	CREATE TABLE #temp_fedex_close_tbl (sel_flg INT NOT NULL DEFAULT 0, location VARCHAR(10) NOT NULL)  
          
	CREATE TABLE #temp_ship_confirm_display_tbl (selected INT DEFAULT 0, stage_no VARCHAR(50) NOT NULL, carton_no INT NOT NULL, master_pack CHAR(1) NOT NULL,
												order_no INT NOT NULL, order_ext INT NOT NULL, tdc_ship_flag CHAR(1) NULL,  adm_ship_flag CHAR(1) NULL, 
												tdc_ship_date DATETIME NULL, adm_ship_date DATETIME NULL, carrier_code VARCHAR(10) NULL, stage_hold CHAR(1)) 
                   
	CREATE TABLE #tdc_ship_xfer (xfer_no INT NOT NULL, err_msg VARCHAR(255) NULL, who VARCHAR(50) NOT NULL, row_id INT IDENTITY NOT NULL)

	CREATE TABLE #stages_to_process (stage_no varchar(50))

	CREATE TABLE #adm_ship_order (order_no int not null, ext int not null, who varchar(50) not null, err_msg varchar(255) null, row_id int identity not null)    

	CREATE TABLE #cartonsToShip (order_no INT, order_ext INT, carton_no INT, tot_ord_freight DECIMAL(20,8), tot_multi_carton_ord_freight DECIMAL(20,8),  
								master_pack CHAR(1), commit_ok INT, first_so_in_carton INT) 

	CREATE TABLE #xfersToShip (order_no INT, order_ext INT, carton_no INT, commit_ok INT) 

	-- Get the default station id for the process
	SET @default_station_id = NULL
	SELECT @default_station_id = value_str FROM dbo.tdc_config WHERE [function] = 'DEFAULT_STATION_ID' 
	IF ISNULL(@default_station_id,'') = ''
	BEGIN
		INSERT cvo_ship_confirm_audit (process_run_date, error_result)
		VALUES (GETDATE(), 'No default station id exists') 
		RETURN -1
	END

	-- Set the user id
	SET @user_id = suser_name()	 

	-- Used by WMS - Run as manager
	INSERT INTO #temp_who (who, login_id) VALUES ('manager', 'manager')

	-- Call routine to populate the working table
	-- 0 = Stages to be confirmed, ALL = All stages, ALL = all carrier codes
	EXEC tdc_ship_confirm_temp_tables 0,'ALL','ALL',@default_station_id

	IF @@ERROR <> 0
	BEGIN
		INSERT cvo_ship_confirm_audit (process_run_date, error_result)
		VALUES (GETDATE(), 'Error running tdc_ship_confirm_temp_tables routine') 
		RETURN -1
	END

	-- Create a list of the stages to process
	INSERT	#stages_to_process (stage_no)
	SELECT	DISTINCT stage_no FROM #temp_ship_confirm_display_tbl WHERE stage_hold = 'N'

	-- For each stage call the ship confirm routine
	SET @last_stage_no = ''
	
	SELECT	TOP 1 @stage_no = stage_no
	FROM	#stages_to_process
	WHERE	stage_no > @last_stage_no
	ORDER BY stage_no ASC

	-- If records are found then process them
	WHILE @@ROWCOUNT <> 0
	BEGIN

		-- Initialize output parameters
		SET	@currentstage = NULL
		SET	@allshipped = NULL
		SET	@err_msg = NULL

		-- Call the ship confirm process
		EXEC @iRet = dbo.tdc_ship_confirm_sp @stage_no, 0, @user_id, 'Y', @currentstage OUTPUT, @allshipped OUTPUT, @err_msg OUTPUT

		-- Deal with the results
		IF @@ERROR <> 0
		BEGIN
			INSERT cvo_ship_confirm_audit (process_run_date, stage_no, error_result)
			VALUES (GETDATE(), @stage_no, 'Error tdc_ship_confirm_sp routine') 
			RETURN -1
		END

		IF @iRet < 1
		BEGIN
			INSERT cvo_ship_confirm_audit (process_run_date, stage_no, error_result)
			VALUES (GETDATE(), @stage_no, CASE WHEN ISNULL(@err_msg,'') = '' THEN 'Error tdc_ship_confirm_sp routine' ELSE @err_msg END) 
			RETURN -1
		END

		-- Insert any error conditions that have occured - non masterpack
		INSERT	cvo_ship_confirm_audit (process_run_date, stage_no, masterpack_no, masterpack_flag,	carton_no, error_result)
		SELECT	GETDATE(), @stage_no, NULL, 'N', carton_no, stage_error
		FROM	tdc_stage_carton(NOLOCK)
        WHERE	stage_error IS NOT NULL 
        AND		adm_ship_flag = 'N' 
        AND		stage_no = @stage_no
        AND		carton_no NOT IN (SELECT carton_no FROM tdc_master_pack_ctn_tbl)

		-- Insert any error conditions that have occured - masterpack
		INSERT	cvo_ship_confirm_audit (process_run_date, stage_no, masterpack_no, masterpack_flag,	carton_no, error_result)
		SELECT	DISTINCT GETDATE(), @stage_no, NULL, 'N', pack_no, stage_error
        FROM	tdc_stage_carton a (NOLOCK)
		JOIN	tdc_master_pack_ctn_tbl b (NOLOCK)
		ON		a.carton_no = b.carton_no
		WHERE	stage_error IS NOT NULL 
        AND		adm_ship_flag = 'N' 
        AND		stage_no = @stage_no
                    
		-- Get the next stage to process
		SET @last_stage_no = @stage_no
	
		SELECT	TOP 1 @stage_no = stage_no
		FROM	#stages_to_process
		WHERE	stage_no > @last_stage_no
		ORDER BY stage_no ASC
	END	

	-- Call transfer notifications custom routine
	-- START v1.1
	/*
	IF NOT EXISTS (SELECT * FROM dbo.tdc_config WHERE [function] = 'mod_ebo_inv')  
		INSERT INTO tdc_config ([function],mod_owner, description, active) VALUES ('mod_ebo_inv','EBO','Allow modify inventory from eBO','Y')   
	*/
	-- END v1.1

	EXEC CVO_atm_xfer_receipts_sp 

	-- START v1.1
	--DELETE FROM dbo.tdc_config WHERE [function] = 'mod_ebo_inv'  
	-- END v1.1


	-- Clear up working tables
	IF (OBJECT_ID('tempdb..#temp_who') IS NOT NULL) 
		DROP TABLE #temp_who

	IF OBJECT_ID('tempdb..#temp_ship_confirm_display_tbl') IS NOT NULL 
		DROP TABLE #temp_ship_confirm_display_tbl

	IF OBJECT_ID('tempdb..#tdc_ship_xfer') IS NOT NULL 
		DROP TABLE #tdc_ship_xfer                

	IF OBJECT_ID('tempdb..#temp_fedex_close_tbl') IS NOT NULL 
		DROP TABLE #temp_fedex_close_tbl         

	IF OBJECT_ID('tempdb..#temp_ship_confirm_cartons') IS NOT NULL 
		DROP TABLE #temp_ship_confirm_cartons    

	IF OBJECT_ID('tempdb..#stages_to_process') IS NOT NULL 
		DROP TABLE #stages_to_process    

	IF OBJECT_ID('tempdb..#adm_ship_order') IS NOT NULL 
		DROP TABLE #adm_ship_order

	IF OBJECT_ID('tempdb..#cartonsToShip') IS NOT NULL  
		DROP TABLE #cartonsToShip

	IF OBJECT_ID('tempdb..#xfersToShip') IS NOT NULL  
		DROP TABLE #xfersToShip

END

GO
GRANT EXECUTE ON  [dbo].[CVO_Ship_Confirm_Process_sp] TO [public]
GO
