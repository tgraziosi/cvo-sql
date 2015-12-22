SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_ship_autoship_transfer_sp] (@xfer_no INT,  @user_id varchar(50))
AS
BEGIN
	DECLARE @currentstage	VARCHAR(255),      
			@allshipped		INT,      
			@err_msg		VARCHAR(255), 
			@stage_no		CHAR(11),
			@carton_no		INT,
			@retval			INT

	-- Create temporary tables
	IF OBJECT_ID('tempdb..#adm_ship_order') IS NOT NULL 
		DROP TABLE #adm_ship_order

	IF OBJECT_ID('tempdb..#cartonsToShip') IS NOT NULL  
		DROP TABLE #cartonsToShip

	IF OBJECT_ID('tempdb..#xfersToShip') IS NOT NULL  
		DROP TABLE #xfersToShip
	
	IF OBJECT_ID('tempdb..#temp_ship_confirm_cartons')  IS NOT NULL 
		DROP TABLE #temp_ship_confirm_cartons

	IF OBJECT_ID('tempdb..#temp_ship_confirm_display_tbl') IS NOT NULL 
		DROP TABLE #temp_ship_confirm_display_tbl
 
	IF OBJECT_ID('tempdb..#temp_fedex_close_tbl') IS NOT NULL 
		DROP TABLE #temp_fedex_close_tbl  

	CREATE TABLE #adm_ship_order (
		order_no int not null,           
		ext int not null,                 
		who varchar(50) not null,         
		err_msg varchar(255) null,        
		row_id int identity not null)    

 
	CREATE TABLE #cartonsToShip (
		order_no INT,            
		order_ext INT,            
		carton_no INT,            
		tot_ord_freight DECIMAL(20,8),  
		tot_multi_carton_ord_freight DECIMAL(20,8),  
		master_pack CHAR(1),        
		commit_ok INT,            
		first_so_in_carton INT) 

 
	CREATE TABLE #xfersToShip (
		order_no INT,  
		order_ext INT,  
		carton_no INT,  
		commit_ok INT) 

	CREATE TABLE #temp_ship_confirm_cartons (
		carton_no INT NOT NULL)  

	CREATE TABLE #temp_ship_confirm_display_tbl  (
		selected         INT DEFAULT 0,               
		stage_no         VARCHAR(50) NOT NULL,        
		carton_no        INT NOT NULL,                
		master_pack      CHAR(1) NOT NULL,            
		order_no         INT NOT NULL,                
		order_ext        INT NOT NULL,                
		tdc_ship_flag    CHAR(1) NULL,                
		adm_ship_flag    CHAR(1) NULL,                
		tdc_ship_date    DATETIME NULL,               
		adm_ship_date    DATETIME NULL,               
		carrier_code     VARCHAR(10) NULL,            
		stage_hold       CHAR(1))

	CREATE TABLE #temp_fedex_close_tbl (
		sel_flg INT NOT NULL DEFAULT 0,   
		location        VARCHAR(10) NOT NULL)             

	-- Create temp_who table if it doesn't exist
	IF (SELECT OBJECT_ID('tempdb..#temp_who')) IS NULL 
	BEGIN   
		CREATE TABLE #temp_who (
			who		VARCHAR(50),
			login_id	VARCHAR(50))
		
		INSERT INTO #temp_who (who, login_id) VALUES (@user_id, @user_id)
	END

	-- Get carton for transfer
	SELECT
		@carton_no = carton_no
	FROM
		dbo.tdc_carton_tx (NOLOCK)
	WHERE
		order_no = @xfer_no
		AND order_ext = 0
		AND order_type = 'T'

	IF ISNULL(@carton_no,0) = 0
	BEGIN
		RETURN -1
	END 

	-- Get stage number for carton
	SELECT 
		@stage_no = stage_no
	FROM 
		dbo.tdc_stage_carton (NOLOCK)  
	WHERE 
		carton_no = @carton_no

	IF ISNULL(@stage_no,'') = ''
	BEGIN
		RETURN -2
	END 

	-- Load working tables 
	EXEC tdc_ship_confirm_temp_tables 0,@stage_no,'ALL','999'
	EXEC @retval = tdc_ship_confirm_sp @stage_no, 0, @user_id, 'Y', @currentstage OUTPUT, @allshipped OUTPUT, @err_msg OUTPUT
	IF @retval < 0 
	BEGIN
		RETURN -3
	END 

	EXEC CVO_atm_xfer_receipts_sp 

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[cvo_ship_autoship_transfer_sp] TO [public]
GO
