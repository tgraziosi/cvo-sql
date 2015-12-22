SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_print_xfer_carton_label_sp](
			@trans      VARCHAR(20),
			@user_id    VARCHAR(50),
			@station_id VARCHAR(20),
			@carton_no  INT)
AS

DECLARE	
	@airbill_no          	VARCHAR (18),   @carton_class     	CHAR    (10), 
	@address1 		VARCHAR (40),	@date_shipped        	VARCHAR (30),
	@address2 		VARCHAR (40),	@shipper 		VARCHAR (10),
	@address3 		VARCHAR (40),	@city 		        VARCHAR (40),
	@attention 	     	VARCHAR (40),	@cust_code 		VARCHAR (40),
	@to_loc			VARCHAR (20),   @to_loc_name		VARCHAR (40),
	@from_loc 	     	VARCHAR (20),	@carton_type      	CHAR    (10), 
	@cust_name          	VARCHAR (40),	@cust_po 		VARCHAR (40),
	@country 	        VARCHAR (40),	@ship_to_name 		VARCHAR (40),
	-- START v1.1
	@ship_to_no 		VARCHAR (10),	@tracking_no 		VARCHAR (30),
	-- @ship_to_no 		VARCHAR (10),	@tracking_no 		VARCHAR (25),
	-- END v1.1
	@state 		        CHAR    (40),	@zip 		        VARCHAR (10),
	@weight     		VARCHAR (20),   @weight_uom  		VARCHAR (2),
	@format_id              VARCHAR (40),   @printer_id             VARCHAR (30),
	@number_of_copies       INT,            @carrier_code           VARCHAR (10),
	@xfer_no                INT,            @template_code          VARCHAR (10),
	@return_value		int

SELECT 	
	@address1           = address1,      			
	@address2           = address2,      			
	@address3           = address3,      			
	@attention          = attention,     			
	@airbill_no         = cs_airbill_no, 			
	@carrier_code       = carrier_code,  			
	@carton_class       = carton_class,  			
	@carton_type        = carton_type,   			
       	@city               = city,          			
        @country            = country,       			
	@cust_code          = cust_code,     			
	@cust_po            = cust_po,       			
 	@date_shipped       = date_shipped,  			
	@xfer_no            = CAST(order_no   AS VARCHAR(10)),
	@ship_to_name       = [name],          			
	@ship_to_no         = ship_to_no,    			
	@shipper            = shipper,       			
	@state              = state,         			 
	@template_code      = template_code, 			
	@tracking_no        = cs_tracking_no,			
	@weight             = CAST(weight AS VARCHAR(20)),       
	@weight_uom         = weight_uom,    			
	@zip                = zip
  FROM tdc_carton_tx (NOLOCK) 
 WHERE carton_no = @carton_no

-- Remove the '0' after the '.'
EXEC tdc_trim_zeros_sp @Weight OUTPUT

SELECT @from_loc = from_loc, @to_loc = to_loc, @to_loc_name = to_loc_name
  FROM xfers (NOLOCK) 
 WHERE xfer_no = @xfer_no

INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDRESS1',   	ISNULL(@address1,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDRESS2', 		ISNULL(@address3,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDRESS3', 		ISNULL(@address3,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_AIRBILL_NO', 	ISNULL(@airbill_no,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ATTENTION', 	ISNULL(@attention,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CARTON_CLASS', 	ISNULL(@carton_class,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CARTON_NO',     	ISNULL(CAST(@carton_no AS VARCHAR(20)), ''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CARTON_TYPE',   	ISNULL(@carton_type,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CITY', 		ISNULL(@city,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_COUNTRY', 		ISNULL(@country,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DATE_SHIPPED', 	ISNULL(@date_shipped,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_FROM_LOCATION', 	ISNULL(@from_loc,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ROUTING',	        ISNULL(@carrier_code,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_NAME', 	ISNULL(@ship_to_name,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_NO', 	ISNULL(@ship_to_no,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIPPER', 		ISNULL(@shipper,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_STATE', 		ISNULL(@state,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_STATION_ID', 	ISNULL(@station_id,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TEMPLATE_CODE', 	ISNULL(@template_code,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC', 		ISNULL(@to_loc,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TO_LOC_NAME', 	ISNULL(@to_loc_name,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TRACKING_NO', 	ISNULL(@tracking_no,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_USER_ID', 		ISNULL(@user_id,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_WEIGHT', 		ISNULL(@weight,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_WEIGHT_UOM', 	ISNULL(@weight_uom,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_XFER_NO', 		ISNULL(@xfer_no,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ZIP', 		ISNULL(@zip,		''))

IF (@@ERROR <> 0 )
BEGIN
	RAISERROR ('Insert into #PrintData Failed', 16, 1)					
	RETURN
END

-- Now let's run the tdc_print_label_sp to get format_id, printer_id, and number of copies -----
EXEC @return_value = tdc_print_label_sp 'PPS', @trans, 'VB', @station_id

-- IF label hasn't been set up for the station id, try finding a record for the user id
IF @return_value != 0
BEGIN
	EXEC @return_value = tdc_print_label_sp 'PPS', @trans, 'VB', @user_id
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_print_xfer_carton_label_sp] TO [public]
GO
