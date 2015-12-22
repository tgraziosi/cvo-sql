SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tdc_print_carton_label_sp](
			@trans      varchar(20),
			@user_id    varchar(50),
			@station_id varchar(20),
			@carton_no  int,
			@tran_type  varchar(2))
AS

DECLARE	
	@airbill_no          	varchar (18),   @carton_class     	char    (10), 
	@address1 		varchar (40),	@date_shipped        	varchar (30),
	@address2 		varchar (40),	@shipper 		varchar (10),
	@address3 		varchar (40),	@city 		        varchar (40),
	@attention 	     	varchar (40),	@cust_code 		varchar (40),
	@location 	     	varchar (20),	@carton_type      	char    (10), 
	@cust_name          	varchar (40),	@cust_po 		varchar (40),
	@country 	        varchar (40),	@ship_to_name 		varchar (40),
	-- START v1.1
	@ship_to_no 		varchar (10),	@tracking_no 		varchar (30),
	-- @ship_to_no 		varchar (10),	@tracking_no 		varchar (25),
	-- END v1.1
	@state 		        char    (40),	@zip 		        varchar (10),
	@weight     		varchar (20),   @weight_uom  		varchar (2),
	@format_id              varchar (40),   @printer_id             varchar (30),
	@number_of_copies       int,            @carrier_code           varchar (10),
	@order_no               int,            @order_ext              varchar (10),
	@template_code          varchar (10),	@f_note			varchar (255),
	@Order_Plus_Ext 	varchar (20),	@return_value		int,
	@header_add_note	varchar (255),  @SSCC			varchar(18),
	@RFID_flag		char 	(1),  	@epc_tag		varchar(24),
	@sgtin			varchar (24),
-- add all address lines from order DMoon 2_2_2012
	@address4 		varchar (40),
	@address5 		varchar (40),
    @ord_plus_ext   varchar(20) 
--

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
	@order_ext 	    = CAST(order_ext  AS varchar(10)),
	@order_no           = CAST(order_no   AS varchar(10)),
--
	@ord_plus_ext		= CAST(order_no  AS varchar(10)) + '-' + CAST(order_ext AS varchar(4)), -- DMoon
--
	@ship_to_name       = [name],          			
	@ship_to_no         = ship_to_no,    			
	@shipper            = shipper,       			
	@state              = state,         			 
	@template_code      = template_code, 			
	@tracking_no        = cs_tracking_no,			
	@weight             = CAST(weight AS varchar(20)),       
	@weight_uom         = weight_uom,    			
	@zip                = zip,
	@SSCC		    = SSCC,
	@epc_tag	    = epc_tag,
	@sgtin		    = sgtin,
	@RFID_flag	    = CASE ISNULL(tag_type, '') WHEN '' THEN 'N' ELSE 'Y' END
  FROM tdc_carton_tx (NOLOCK) 
 WHERE carton_no = @carton_no

-- get additional ship to address lines from orders table DMoon 2_2_2012
	SELECT @address4 = ship_to_add_4,
		   @address5 = ship_to_add_5
	FROM   orders (NOLOCK)
	WHERE  order_no = @order_no and ext = @order_ext
--
	

-- select * from orders where sold_to <> ''

/*
-- DMoon comment out - Believe in CVO application the carton label will not be used for Global ship to orders
--JVM 07/28/2010
IF EXISTS(SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext AND sold_to IS NOT NULL AND LTRIM (sold_to) <> '' AND RTRIM (sold_to) <> '')
BEGIN
	SELECT	@ship_to_no		= a.ship_to_code,		       
			@Ship_To_Name	= a.address_name, 
			@address1		= a.addr1,  
			@address2		= a.addr2,   
			@address3		= a.addr3,  
			@city			= a.city,     
			@country		= a.country_code,   
			@state			= a.state,     
			@zip			= a.postal_code  
	FROM    armaster_all a  (NOLOCK)
	WHERE   a.customer_code = (SELECT sold_to FROM orders (NOLOCK) WHERE order_no = @order_no AND ext = @order_ext ) AND
		    address_type = 9
END	  
--END   SED008 -- Global Ship To
*/

SELECT	@Order_Plus_Ext  = (CAST(@order_no  AS varchar(10)) + '-' + CAST  (@order_ext  AS varchar(10)))
-- Remove the '0' after the '.'
EXEC tdc_trim_zeros_sp @Weight OUTPUT

SELECT @location = location 
  FROM orders (NOLOCK) 
 WHERE order_no  = @order_no
   AND ext       = @order_ext

SELECT @cust_name = customer_name 
  FROM arcust (NOLOCK)
 WHERE customer_code = @cust_code

IF @trans = 'MANFST'
BEGIN
	SELECT @f_note = REPLACE(f_note, CHAR(13)+CHAR(10), '/')  
	  FROM orders (NOLOCK) 
	 WHERE order_no  = @order_no
	   AND ext       = @order_ext

	INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_F_NOTE',   	ISNULL(@f_note,		''))
END

-- Order header additional note
SELECT @header_add_note = CAST(note AS varchar(255))
  FROM notes (NOLOCK)
 WHERE code_type = 'O'
   AND code      = @order_no           
   AND line_no   = 0

IF @header_add_note IS NULL SET @header_add_note = ''

EXEC tdc_parse_string_sp @header_add_note, @header_add_note OUTPUT

INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDRESS1',   	ISNULL(@address1,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDRESS2', 		ISNULL(@address2,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDRESS3', 		ISNULL(@address3,	''))
--
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDRESS4', 		ISNULL(@address4,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ADDRESS5', 		ISNULL(@address5,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_PLUS_EXT',       ISNULL(@ord_plus_ext,   '')) 
--
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_AIRBILL_NO', 	ISNULL(@airbill_no,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ATTENTION', 	ISNULL(@attention,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ROUTING',	        ISNULL(@carrier_code,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CARTON_CLASS', 	ISNULL(@carton_class,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CARTON_NO',     	ISNULL(CAST(@carton_no AS varchar(20)), ''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CARTON_TYPE',   	ISNULL(@carton_type,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CITY', 		ISNULL(@city,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_COUNTRY', 		ISNULL(@country,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_CODE', 	ISNULL(@cust_code,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_NAME', 	ISNULL(@cust_name,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_CUST_PO', 		ISNULL(@cust_po,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_DATE_SHIPPED', 	ISNULL(@date_shipped,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_LOCATION', 		ISNULL(@location,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_NO', 		ISNULL(@order_no,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_EXT', 	ISNULL(@order_ext,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ORDER_PLUS_EXT', 	@Order_Plus_Ext)
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_NAME', 	ISNULL(@ship_to_name,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIP_TO_NO', 	ISNULL(@ship_to_no,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SHIPPER', 		ISNULL(@shipper,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_STATE', 		ISNULL(@state,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TEMPLATE_CODE', 	ISNULL(@template_code,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TRACKING_NO', 	ISNULL(@tracking_no,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_USER_ID', 		ISNULL(@user_id,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_STATION_ID', 	ISNULL(@station_id,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_WEIGHT', 		ISNULL(@weight,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_WEIGHT_UOM', 	ISNULL(@weight_uom,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_ZIP', 		ISNULL(@zip,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_TRAN_TYPE', 	ISNULL(@tran_type,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_HEADER_ADD_NOTE', 	ISNULL(@header_add_note,''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SSCC', 		ISNULL(@SSCC,		''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_RFID_FLAG', 	ISNULL(@RFID_flag,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_EPC_TAG', 		ISNULL(@epc_tag,	''))
INSERT INTO #PrintData (data_field, data_value) VALUES ('LP_SGTIN', 		ISNULL(@sgtin,		''))

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

-- IF label hasn't been set up, exit
IF @return_value != 0
BEGIN
	TRUNCATE TABLE #PrintData
	RETURN
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_print_carton_label_sp] TO [public]
GO
