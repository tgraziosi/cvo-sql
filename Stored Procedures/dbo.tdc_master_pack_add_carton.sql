SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 03/01/2012 - Fix issue with address for global ship to
-- v1.1 CB 27/02/2012 - Masterpack changes
-- v1.2 CB 05/03/2012 - Back out Masterpack Changes - Requirement change
-- v1.3 CB 06/03/2012 - Add changes for Masterpack
-- v1.4 CB 22/06/2012 - Use carrier from global ship to
-- v1.5 CT 15/08/2012 - Remove v1.4, always pull the carrier from the order
-- v1.6 CB 25/02/2014 - Add back in carrier validation on masterpacks
-- v1.7 CB 14/03/2014 - Move code to pick up carrier
-- v1.8 CB 08/05/2014 - Issue #572 - Masterpack - Polarized Labs
-- v1.9 CB 10/07/2014 - Do not validate carriers when master packing for Polarized Labs
-- v2.0 CB 24/09/2014 - Fix issue with 'ALLOW_MASTERPACK_GLOBAL_SHIP_TO' being switched off and stopping functionality
-- v2.1 CB 12/08/2016 - Add back in validation for Global Ship To 
CREATE PROC [dbo].[tdc_master_pack_add_carton]  
 @pack_no  int,  
 @carton_no  int,   
 @user_id  varchar(50),   
 @err_msg varchar(255) OUTPUT,
 @pack_option int = 0  
AS  
  
DECLARE @new_freight_allow_type varchar(10),  
 @freight_allow_type varchar(10),  
 @new_back_ord_flag char(1),  
 @back_ord_flag char(1),  
 @cust_code varchar(10),
@ship_to varchar(10), -- v1.1  
@carrier varchar(10), -- v1.1
@global_lab varchar(10) -- v1.1

-- v2.0 Start
DECLARE @ship_via_code VARCHAR(10), 
       @address_name  VARCHAR(40), 
       @addr1         VARCHAR(40), 
       @addr2         VARCHAR(40), 
       @addr3         VARCHAR(40), 
       @city          VARCHAR(40), 
       @state         VARCHAR(40), 
       @postal_code   VARCHAR(15), 
       @country       VARCHAR(40),
       @sold_to       VARCHAR(10)

SET @sold_to = ''
SELECT @sold_to = ISNULL(o.sold_to,'')
FROM   orders_all o (NOLOCK), 
       tdc_carton_tx ca (NOLOCK)
WHERE  o.order_no   = ca.order_no  AND
       o.ext        = ca.order_ext AND
       ca.carton_no = @carton_no 
-- v2.0 End
  
 IF EXISTS(SELECT * FROM tdc_master_pack_tbl(NOLOCK)  
     WHERE pack_no = @pack_no  
       AND status != 'O')  
 BEGIN  
  SELECT @err_msg = 'Master Pack is not open'  
  RETURN -1  
 END   
  
 IF NOT EXISTS(SELECT * FROM tdc_carton_tx(NOLOCK) WHERE carton_no = @carton_no)  
 BEGIN  
  SELECT @err_msg = 'Invalid carton no'  
  RETURN -2  
 END  
  
 IF EXISTS(SELECT * FROM tdc_carton_tx(NOLOCK) WHERE carton_no = @carton_no AND status NOT IN('C', 'F'))  
 BEGIN  
  SELECT @err_msg = 'Carton must be status closed or freighted.'  
  RETURN -3  
 END  
  
 IF EXISTS(SELECT * FROM tdc_master_pack_ctn_tbl(NOLOCK) WHERE carton_no = @carton_no)  
 BEGIN  
  IF EXISTS(SELECT * FROM tdc_master_pack_ctn_tbl(NOLOCK) WHERE pack_no = @pack_no AND carton_no = @carton_no)  
  BEGIN  
   SELECT @err_msg = 'Carton is already assigned to this master pack.'  
   RETURN -4  
  END  
  ELSE  
  BEGIN  
   SELECT @err_msg = 'Carton is assigned to another master pack.'  
   RETURN -5  
  END  
 END  

 IF ((NOT EXISTS (SELECT 1 FROM cvo_armaster_all a (NOLOCK) JOIN tdc_carton_tx b (NOLOCK)
				ON a.customer_code = b.cust_code
				WHERE b.carton_no = @carton_no AND consol_ship_flag = 1) 
	AND NOT EXISTS (SELECT 1 FROM cvo_consolidate_shipments a (NOLOCK) JOIN tdc_carton_tx b (NOLOCK)
					ON a.order_no = b.order_no AND a.order_ext = b.order_ext
					WHERE b.carton_no = @carton_no)) AND @pack_option = 2)
 BEGIN
   SELECT @err_msg = 'Customer is not set for consolidate shipments.'  
   RETURN -5  
 END  

	-- v1.7 Start
	SELECT	@cust_code = cust_code,
			@ship_to = ship_to_no,
			@carrier = carrier_code
	FROM	tdc_carton_tx (NOLOCK)
	WHERE	carton_no = @carton_no
	-- v1.7 End

-- v1.6 Start
	IF EXISTS (SELECT 1 FROM tdc_carton_tx a (NOLOCK) JOIN tdc_master_pack_ctn_tbl b (NOLOCK) ON a.carton_no = b.carton_no
		WHERE pack_no = @pack_no AND carrier_code <> @carrier AND @pack_option = 2)
	BEGIN
	   SELECT @err_msg = 'You cannot mix carriers, this order needs to be on a separate consolidation.'  
	   RETURN -5  
	END
-- v1.6 End  

-- v1.8 Start
-- v1.9 Start
--	IF EXISTS (SELECT 1 FROM tdc_carton_tx a (NOLOCK) JOIN tdc_master_pack_ctn_tbl b (NOLOCK) ON a.carton_no = b.carton_no
--		WHERE pack_no = @pack_no AND carrier_code <> @carrier AND @pack_option = 3)
--	BEGIN
--	   SELECT @err_msg = 'You cannot mix carriers for Lab Orders, this order needs to be on a separate consolidation.'  
--	   RETURN -6  
--	END
-- v1.9 End

IF (@pack_option = 3)
BEGIN
	IF NOT EXISTS (SELECT 1 FROM tdc_carton_tx a (NOLOCK) JOIN orders_all b (NOLOCK) ON a.order_no = b.order_no AND a.order_ext = b.ext 
			WHERE a.carton_no = @carton_no AND ISNULL(b.sold_to,'') <> '')
	BEGIN
	   SELECT @err_msg = 'This carton is not a Global Lab order.'  
	   RETURN -7  
	END

	SELECT	@global_lab = ISNULL(b.sold_to,'')
	FROM	tdc_carton_tx a (NOLOCK) 
	JOIN	orders_all b (NOLOCK) 
	ON		a.order_no = b.order_no 
	AND		a.order_ext = b.ext 
	WHERE	a.carton_no = @carton_no

	IF EXISTS (SELECT 1 FROM armaster_all (NOLOCK) WHERE customer_code = @global_lab AND address_type = 9
					AND (ISNULL(ship_via_code,'') = '' OR LEFT(ISNULL(ship_via_code,'ZZZZ'),4) = 'USPS'))
	BEGIN
	   SELECT @err_msg = 'No Default Ship Via Set for this destination.'   
	   RETURN -8  
	END

	IF EXISTS (SELECT 1 FROM tdc_carton_tx a (NOLOCK) JOIN tdc_master_pack_ctn_tbl b (NOLOCK) ON a.carton_no = b.carton_no
				JOIN orders_all c (NOLOCK) ON a.order_no = c.order_no AND a.order_ext = c.ext
			WHERE pack_no = @pack_no AND ISNULL(c.sold_to,'') <> @global_lab)
	BEGIN
	   SELECT @err_msg = 'You cannot add the carton - Global Lab is not the same as the carton already assigned.'   
	   RETURN -9 
	END

END

-- v1.8 End  

/* v1.2 Start
-- v1.1 On do the following error checking if consolidated 
IF ((EXISTS (SELECT 1 FROM cvo_armaster_all a (NOLOCK) JOIN tdc_carton_tx b (NOLOCK)
				ON a.customer_code = b.cust_code
				WHERE b.carton_no = @carton_no AND consol_ship_flag = 1)) 
	OR (EXISTS (SELECT 1 FROM cvo_consolidate_shipments a (NOLOCK) JOIN tdc_carton_tx b (NOLOCK)
					ON a.order_no = b.order_no AND a.order_ext = b.order_ext
					WHERE b.carton_no = @carton_no))) AND @pack_option = 2

BEGIN
 
	-- v1.1 If the carrier on the order is like USPS% then error - can not consolidate US postal
	IF EXISTS (SELECT 1 FROM tdc_carton_tx (NOLOCK) WHERE carton_no = @carton_no AND carrier_code LIKE 'USPS%')
	BEGIN
	   SELECT @err_msg = 'You cannot consolidate orders with a carrier of US Postal.'  
	   RETURN -5  
	END  

	-- v1.1 Can not consolidate a lab order
	IF EXISTS (SELECT 1 FROM tdc_carton_tx a (NOLOCK) JOIN orders_all b (NOLOCK) ON a.order_no = b.order_no AND a.order_ext = b.ext 
			WHERE a.carton_no = @carton_no AND  ISNULL(b.sold_to,'') <> '')
	BEGIN
	   SELECT @err_msg = 'You cannot consolidate a Lab order.'  
	   RETURN -5  
	END  

	-- v1.1 Must have the same customer code and ship to
	SELECT	@cust_code = cust_code,
			@ship_to = ship_to_no,
			@carrier = carrier_code
	FROM	tdc_carton_tx (NOLOCK)
	WHERE	carton_no = @carton_no

	IF EXISTS (SELECT 1 FROM tdc_carton_tx a (NOLOCK) JOIN tdc_master_pack_ctn_tbl b (NOLOCK) ON a.carton_no = b.carton_no
			WHERE pack_no = @pack_no AND (a.cust_code <> @cust_code OR a.ship_to_no <> @ship_to))
	BEGIN
	   SELECT @err_msg = 'You cannot add the carton - Customer/Ship To is not the same.'  
	   RETURN -5  
	END  

	IF EXISTS (SELECT 1 FROM tdc_carton_tx a (NOLOCK) JOIN tdc_master_pack_ctn_tbl b (NOLOCK) ON a.carton_no = b.carton_no
		WHERE pack_no = @pack_no AND carrier_code <> @carrier)
	BEGIN
	   SELECT @err_msg = 'You cannot mix carriers, this orders needs to be on a separate consolidation.'  
	   RETURN -5  
	END  


END 
*/
-- v2.1 Start
-- v1.3 Validation for global ship to's
IF (@pack_option = 1)
BEGIN
	IF NOT EXISTS (SELECT 1 FROM tdc_carton_tx a (NOLOCK) JOIN orders_all b (NOLOCK) ON a.order_no = b.order_no AND a.order_ext = b.ext 
			WHERE a.carton_no = @carton_no AND ISNULL(b.sold_to,'') <> '')
	BEGIN
	   SELECT @err_msg = 'This carton is not a Global Lab order.'  
	   RETURN -5  
	END

	SELECT	@global_lab = ISNULL(b.sold_to,'')
	FROM	tdc_carton_tx a (NOLOCK) 
	JOIN	orders_all b (NOLOCK) 
	ON		a.order_no = b.order_no 
	AND		a.order_ext = b.ext 
	WHERE	a.carton_no = @carton_no

	IF EXISTS (SELECT 1 FROM armaster_all (NOLOCK) WHERE customer_code = @global_lab AND address_type = 9
					AND (ISNULL(ship_via_code,'') = '' OR LEFT(ISNULL(ship_via_code,'ZZZZ'),4) = 'USPS'))
	BEGIN
	   SELECT @err_msg = 'No Default Ship Via Set for this destination.'   
	   RETURN -5  
	END

	IF EXISTS (SELECT 1 FROM tdc_carton_tx a (NOLOCK) JOIN tdc_master_pack_ctn_tbl b (NOLOCK) ON a.carton_no = b.carton_no
				JOIN orders_all c (NOLOCK) ON a.order_no = c.order_no AND a.order_ext = c.ext
			WHERE pack_no = @pack_no AND ISNULL(c.sold_to,'') <> @global_lab)
	BEGIN
	   SELECT @err_msg = 'You cannot add the carton - Global Lab is not the same as the carton already assigned.'   
	   RETURN -5  
	END

END
-- v1.2 End
-- v2.1 End

-- START v1.5
/*
-- v1.4 Start

IF EXISTS (SELECT 1 FROM tdc_carton_tx a (NOLOCK) JOIN orders_all b (NOLOCK) ON a.order_no = b.order_no AND a.order_ext = b.ext 
		WHERE a.carton_no = @carton_no AND ISNULL(b.sold_to,'') <> '')
BEGIN

	SELECT	@global_lab = ISNULL(b.sold_to,'')
	FROM	tdc_carton_tx a (NOLOCK) 
	JOIN	orders_all b (NOLOCK) 
	ON		a.order_no = b.order_no 
	AND		a.order_ext = b.ext 
	WHERE	a.carton_no = @carton_no

	IF EXISTS (SELECT 1 FROM armaster_all (NOLOCK) WHERE customer_code = @global_lab AND address_type = 9
					AND (ISNULL(ship_via_code,'') = ''))
	BEGIN
	   SELECT @err_msg = 'No Default Ship Via Set for this Global Ship To.'   
	   RETURN -5  
	END

	SELECT	@carrier = ISNULL(ship_via_code,'')
	FROM	armaster_all (NOLOCK)
	WHERE	customer_code = @global_lab
	AND		address_type = 9

	IF @carrier > ''
	BEGIN
		UPDATE	tdc_master_pack_tbl
		SET		carrier_code = @carrier
		WHERE	pack_no = @pack_no

		UPDATE	tdc_carton_tx
		SET		carrier_code = @carrier
		WHERE	carton_no = @carton_no
	END

END

-- v1.4 End
*/
-- END v1.5
 --------------------------------------------------------------------------------------------------------------------  
 -- If other order(s) have been packed into the carton, make sure they have the same:  
 --  freight_allow_type of 8 if manifest enabled,   
 --  back_ord_flag must match  
 --------------------------------------------------------------------------------------------------------------------  
 IF EXISTS(SELECT *   
      FROM tdc_master_pack_ctn_tbl a(NOLOCK),  
           tdc_carton_tx b(NOLOCK)  
     WHERE pack_no = @pack_no  
       AND a.carton_no = b.carton_no  
       AND order_no NOT IN (SELECT order_no FROM tdc_carton_tx(nolock) WHERE carton_no = @carton_no))  
 BEGIN  
  SELECT TOP 1 @new_freight_allow_type = a.freight_allow_type,  
         @new_back_ord_flag = a.back_ord_flag  
    FROM orders a(NOLOCK),  
         tdc_carton_tx b(NOLOCK)  
   WHERE b.carton_no = @carton_no  
     AND a.order_no = b.order_no  
     AND a.ext = b.order_ext  
  
  SELECT TOP 1 @freight_allow_type = a.freight_allow_type,  
               @back_ord_flag = a.back_ord_flag  
    FROM orders a(NOLOCK),   
         tdc_carton_tx b(NOLOCK)  
   WHERE b.carton_no = @carton_no  
     AND a.order_no = b.order_no  
     AND a.ext = b.order_ext  
   
  IF EXISTS(SELECT * FROM tdc_config(NOLOCK)   
             WHERE [function] = 'manifest_type'  
        AND active = 'Y')  
  BEGIN  
  --BEGIN SED009 -- Consolidated Shipments
  --JVM 09/21/2010  
  --Remove validation for Consolidated Shipment
   /*IF ISNULL(@new_freight_allow_type, '') != '8'  
   BEGIN  
    SELECT @err_msg = 'Freight Type must be 8 (No Charge Freight)'  
    RETURN -6  
   END*/  
   --END   SED009 -- Consolidated Shipments
     
   IF @new_freight_allow_type != @freight_allow_type  
   BEGIN  
    SELECT @err_msg = 'Freight type does not match freight type of other order(s) in the carton'  
    RETURN -7  
   END  
  END  
  
  IF @new_back_ord_flag != @back_ord_flag  
  BEGIN  
   SELECT @err_msg = 'Back Order Flag does not match back order flag of other order(s) in the carton'  
   RETURN -8  
  END  
  
    
    
 END  
  
 -- Get the cust code for the carton   
 SELECT @cust_code = MAX(cust_code)  
   FROM tdc_carton_tx  
  WHERE carton_no = @carton_no  
  
  IF EXISTS(SELECT * FROM tdc_master_pack_tbl(NOLOCK)  
     WHERE pack_no = @pack_no)  
 BEGIN  
  --BEGIN SED009 -- Consolidated Shipments
  --JVM 09/21/2010
  --IF @cust_code != (SELECT cust_code FROM tdc_master_pack_tbl WHERE pack_no = @pack_no)  
  IF (@cust_code != (SELECT cust_code FROM tdc_master_pack_tbl WHERE pack_no = @pack_no))
	AND @sold_to = '' -- v2.0
-- v2.0     AND NOT EXISTS (SELECT * FROM tdc_config (NOLOCK) WHERE [function] = 'ALLOW_MASTERPACK_GLOBAL_SHIP_TO' AND active = 'Y')
  --END   SED009 -- Consolidated Shipments
  BEGIN  
   SELECT @err_msg = 'Carton must have the same customer as the master pack.'  
   RETURN -9  
  END  
   
  UPDATE tdc_master_pack_tbl   
     SET modified_by = @user_id,  
         last_modified_date = GETDATE()  
   WHERE pack_no = @pack_no  
 END    
 ELSE -- Master pack record does not exist, insert it.  
 BEGIN  
  INSERT INTO tdc_master_pack_tbl (pack_no, cust_code, create_date, created_by, status, carrier_code, weight, [name], address1,   
        address2, address3, city, state, zip, country, attention, cs_tx_no, cs_tracking_no, cs_zone,   
        cs_oversize, cs_call_tag_no, cs_airbill_no, cs_other, cs_pickup_no, cs_dim_weight, cs_published_freight,   
        cs_disc_freight, cs_estimated_freight, date_shipped, freight_to, cust_freight, adjust_rate, charge_code,   
        template_code, last_modified_date, modified_by)  
  SELECT TOP 1 @pack_no, @cust_code, GETDATE(), @user_id, 'O', carrier_code, NULL, [name], address1, address2, address3, city,
   state, zip, country, attention, cs_tx_no, cs_tracking_no, cs_zone, cs_oversize, cs_call_tag_no, cs_airbill_no,   
   cs_other, cs_pickup_no, cs_dim_weight, cs_published_freight, cs_disc_freight, cs_estimated_freight, date_shipped,   
   freight_to, cust_freight, adjust_rate, charge_code, template_code, GETDATE(), @user_id  
    FROM tdc_carton_tx(NOLOCK)  
   WHERE carton_no = @carton_no 

  --BEGIN SED009 -- Consolidated Shipments
  --JVM 09/21/2010
	-- v2,0 Start
   -- v2.0 IF EXISTS (SELECT * FROM tdc_config (NOLOCK) WHERE [function] = 'ALLOW_MASTERPACK_GLOBAL_SHIP_TO' AND active = 'Y')
   IF (@sold_to > '') 
   BEGIN
	   --select ship_via_code, address_name, addr1, addr2,addr3,city, state,postal_code,country,  * from armaster_all where customer_code = 'AAI001'  and address_type = 9

--		SELECT @sold_to = ISNULL(o.sold_to,'')
--		FROM   orders         o (NOLOCK), 
--		       tdc_carton_tx ca (NOLOCK)
--		WHERE  o.order_no   = ca.order_no  AND
--		       o.ext        = ca.order_ext AND
--		       ca.carton_no = @carton_no 
		-- v2.0 End

	   SELECT @cust_code     = customer_code, -- new cust_code from Global Ship to
			  @ship_via_code = ISNULL(ship_via_code,''), -- v1.6
			  @address_name  = ISNULL(address_name,''), 
			  @addr1         = ISNULL(addr2,''), -- v1.0 addr1
			  @addr2         = ISNULL(addr3,''), -- v1.0 addr2
			  @addr3         = ISNULL(addr4,''), -- v1.0 addr3
			  @city          = ISNULL(city,''), 
			  @state         = ISNULL(state,''), 
			  @postal_code   = ISNULL(postal_code,''),  
			  @country       = ISNULL(country,'')
	   FROM   armaster_all 
	   WHERE  customer_code = @sold_to AND 
	          address_type  = 9

	   UPDATE tdc_master_pack_tbl
	   SET    cust_code    = @cust_code,
	          --carrier_code = @ship_via_code, -- v1.3 -- v1.5
	          [name]       = @address_name ,
	          address1     = @addr1 ,
			  address2     = @addr2, 
			  address3     = @addr3, 
			  city         = @city, 
			  state        = @state, 
			  zip          = @postal_code, 
			  country      = @country
	   WHERE  pack_no      = @pack_no
	END
  --END   SED009 -- Consolidated Shipments
    
 END     
  
 -- Insert the carton record  
 INSERT INTO tdc_master_pack_ctn_tbl(pack_no, carton_no, create_date, created_by)      
 VALUES(@pack_no, @carton_no, GETDATE(), @user_id)  
  
RETURN 0  
GO
GRANT EXECUTE ON  [dbo].[tdc_master_pack_add_carton] TO [public]
GO
