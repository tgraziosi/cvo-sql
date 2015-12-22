SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_wow_fill_sp] 
	@index      int, 	-- Inventory = 1, SalesOrder = 2, Queue = 3
	@inv_index  int,	-- Location / Part = 1, Buyers = 2, Cateries = 3, Vendors = 4, BinGroups = 5
	@userid     varchar(50) 
AS

DECLARE @ALL VARCHAR(5)

SELECT @ALL = '[ALL]'


---------------------------------------------------------------------------------------------------------------------------
-- Sales order setup
---------------------------------------------------------------------------------------------------------------------------
IF @index = 1
BEGIN
	TRUNCATE TABLE #from_loc
	TRUNCATE TABLE #to_loc
	TRUNCATE TABLE #from_part_location
	TRUNCATE TABLE #to_part_location
	TRUNCATE TABLE #from_category
	TRUNCATE TABLE #to_category
	TRUNCATE TABLE #from_buyer
	TRUNCATE TABLE #to_buyer
	TRUNCATE TABLE #from_vendor
	TRUNCATE TABLE #to_vendor
	TRUNCATE TABLE #from_bin_group
	TRUNCATE TABLE #to_bin_group


	IF @inv_index = 1 --LOCATIONS
	BEGIN
		IF EXISTS(SELECT * FROM tdc_wow_location (NOLOCK) 
			   WHERE userid = @userid 
			     AND all_locations > 0)
		BEGIN
			INSERT INTO #to_loc 
			SELECT @all
		END
		ELSE
		BEGIN
			INSERT INTO #to_loc 
			SELECT location 
			  FROM tdc_wow_location (NOLOCK) 
			 WHERE userid = @userid
		END
	
		INSERT INTO #from_loc 
		SELECT location 
		  FROM locations (NOLOCK) 
		 WHERE location NOT IN (SELECT location 
					  FROM #to_loc
					 UNION 
					SELECT location
					  FROM #from_loc) 
		   AND void = 'N'
 
		--PART/LOCATIONS
		IF EXISTS(SELECT * FROM tdc_wow_part_location (NOLOCK) 
			   WHERE userid = @userid 
			     AND all_partlocations > 0)
		BEGIN
			INSERT INTO #to_part_location (part_no, location) 
			SELECT @ALL, @ALL
		END	
		ELSE
		BEGIN
			INSERT INTO #to_part_location 
			SELECT part_no, location 
			  FROM tdc_wow_part_location (NOLOCK) 
			 WHERE userid = @userid 			
		END
	
		IF EXISTS(SELECT * FROM tdc_wow_location (NOLOCK) 
			   WHERE userid = @userid 
			     AND all_locations > 0)
		BEGIN
			INSERT INTO #from_part_location 
			SELECT a.part_no, a.location 
			  FROM inv_list a 
			 WHERE a.part_no + '@@@***@@@' + a.location 
					NOT IN (SELECT b.part_no + '@@@***@@@' + b.location
						  FROM #to_part_location b
						 WHERE a.part_no = b.part_no
						   AND a.location = b.location)	
		END
		ELSE
		BEGIN
			INSERT INTO #from_part_location 
			SELECT a.part_no, a.location 
			  FROM inv_list a 
			 WHERE a.part_no + '@@@***@@@' + a.location 
					NOT IN (SELECT b.part_no + '@@@***@@@' + b.location
						  FROM #to_part_location b
						 WHERE a.part_no = b.part_no
						   AND a.location = b.location)	
			  AND a.location IN (SELECT location FROM #to_loc) 				
		END	

	END
	ELSE IF @inv_index = 2 --Buyers
	BEGIN
 
		IF EXISTS(SELECT * FROM tdc_wow_buyer (NOLOCK) 
			   WHERE userid = @userid 
			     AND all_buyers > 0)
		BEGIN
			INSERT INTO #to_buyer (buyer, [description]) 
			SELECT @ALL, @ALL
		END
		ELSE
		BEGIN
			INSERT INTO #to_buyer (buyer, [description]) 
			SELECT a.buyer, b.[description] 
			  FROM tdc_wow_buyer a (NOLOCK), 
			       buyers b (NOLOCK) 
			 WHERE a.buyer = b.kys 
			   AND a.userid = @userid
		END

		INSERT INTO #from_buyer 
		SELECT kys as buyer, [description] 
		  FROM buyers (NOLOCK)
		 WHERE kys NOT IN (SELECT buyer 
				     FROM #to_buyer
				    UNION
				   SELECT buyer
				     FROM #from_buyer) 
		   AND void = 'N'
	END
	ELSE IF @inv_index = 3 -- Categories
	BEGIN
 
		IF EXISTS(SELECT * FROM tdc_wow_category (NOLOCK) 
			   WHERE userid = @userid 
			     AND all_categories > 0)
		BEGIN
			INSERT INTO #to_category (category, [description]) 
			SELECT @all, @all
		END
		ELSE
		BEGIN
			INSERT INTO #to_category (category, [description]) 
			SELECT a.category, b.[description] 
			  FROM tdc_wow_category a (NOLOCK), 
			       category b (NOLOCK) 
			 WHERE a.category = b.kys 
			   AND a.userid = @userid
		END

		INSERT INTO #from_category 
		SELECT kys as category, [description] 
		  FROM category (NOLOCK)
		 WHERE kys NOT IN (SELECT category 
				     FROM #to_category
				    UNION 
				   SELECT category		
				    FROM #from_category) 
		  AND void = 'N'
	
	END
	ELSE IF @inv_index = 4 -- Vendors
	BEGIN
 
		IF EXISTS(SELECT * FROM tdc_wow_vendor (NOLOCK) 
			   WHERE userid = @userid 
			     AND all_vendors > 0)
		BEGIN
			INSERT INTO #to_vendor (vendor, vendor_name) 
			SELECT @all, @all
		END
		ELSE
		BEGIN
			INSERT INTO #to_vendor (vendor, vendor_name) 
			SELECT a.vendor, b.vendor_name 
			  FROM tdc_wow_vendor a (NOLOCK), 
			       apvend b (NOLOCK) 
			 WHERE a.vendor = b.vendor_code 
			   AND a.userid = @userid
		END

		INSERT INTO #from_vendor 
		SELECT vendor_code, vendor_name 
		  FROM apvend (NOLOCK)
		 WHERE vendor_code NOT IN (SELECT vendor 
					     FROM #to_vendor
					    UNION
					   SELECT vendor
					     FROM #from_vendor) 
	END
	ELSE IF @inv_index = 5 -- Bin Group
	BEGIN
 
		IF EXISTS(SELECT * FROM tdc_wow_bin_group (NOLOCK) 
			   WHERE userid = @userid 
			     AND all_bin_groups > 0)
		BEGIN
			INSERT INTO #to_bin_group (group_code, [description]) 
			SELECT @all, @all
		END
		ELSE
		BEGIN
			INSERT INTO #to_bin_group (group_code, [description]) 
			SELECT a.group_code, b.[description] 
			  FROM tdc_wow_bin_group a (NOLOCK), 
			       tdc_bin_group b (NOLOCK) 
			 WHERE a.group_code = b.group_code 
			   AND a.group_code_id = b.group_code_id 
			   AND a.userid = @userid
		END
	
		INSERT INTO #from_bin_group 
		SELECT group_code, [description] 
		  FROM tdc_bin_group
		 WHERE group_code NOT IN (SELECT group_code 
					    FROM #to_bin_group
					   UNION
					  SELECT group_code 
					    FROM #to_bin_group)
	END
END



---------------------------------------------------------------------------------------------------------------------------
-- Sales order setup
---------------------------------------------------------------------------------------------------------------------------
ELSE IF @index = 2
BEGIN

	TRUNCATE TABLE #to_cust_code
	TRUNCATE TABLE #from_cust_code
	TRUNCATE TABLE #to_ship_to
	TRUNCATE TABLE #from_ship_to

	--CUSTOMER CODES
	IF EXISTS(SELECT * FROM tdc_wow_cust_code (NOLOCK) 
		   WHERE userid = @userid 
		     AND all_cust_code > 0)
	BEGIN
		INSERT INTO #to_cust_code (customer_code, customer_name) 
		VALUES (@ALL, @ALL)
	END
	ELSE
	BEGIN
		INSERT INTO #to_cust_code (customer_code, customer_name) 
		SELECT a.customer_code, b.customer_name 
		  FROM tdc_wow_cust_code a (NOLOCK), 
		       arcust b (NOLOCK) 
		 WHERE a.customer_code = b.customer_code 
		   AND a.userid = @userid
	END

	INSERT INTO #from_cust_code 
	SELECT customer_code, customer_name 
	  FROM arcust (NOLOCK)
	 WHERE customer_code NOT IN (SELECT customer_code 
				       FROM #from_cust_code
				      UNION
				     SELECT customer_code 
				       FROM #to_cust_code) 
	--SHIP TO
	IF EXISTS(SELECT * FROM tdc_wow_ship_to (NOLOCK) 
		   WHERE userid = @userid AND all_ship_to > 0)
	BEGIN
		INSERT INTO #to_ship_to (customer_code, ship_to_code, ship_to_name) 
		VALUES (@ALL, @ALL, @ALL)
	END
	ELSE
	BEGIN
		INSERT INTO #to_ship_to (customer_code, ship_to_code, ship_to_name) 
		SELECT a.customer_code, a.ship_to_code, b.ship_to_name 
		  FROM tdc_wow_ship_to a (NOLOCK), 
		       arshipto b (NOLOCK) 
		 WHERE a.customer_code = b.customer_code 
		   AND a.ship_to_code = b.ship_to_code 
		   AND a.userid = @userid
		ORDER BY a.customer_code, a.ship_to_code
	END

	INSERT INTO #from_ship_to 
	SELECT a.customer_code, a.ship_to_code, a.ship_to_name 
	  FROM arshipto a
	 WHERE a.customer_code + '@@@***@@@' + a.ship_to_code
			       NOT IN (SELECT b.customer_code + '@@@***@@@' + b.ship_to_code
				         FROM #to_ship_to b
					WHERE b.customer_code = a.customer_code
					  AND b.ship_to_code  = a.ship_to_code
				        UNION 
				       SELECT c.customer_code + '@@@***@@@' + c.ship_to_code
				       FROM #from_ship_to c
					WHERE c.customer_code = a.customer_code
					  AND c.ship_to_code  = a.ship_to_code)
	   AND customer_code IN (SELECT customer_code 
				   FROM #to_cust_code)
END

---------------------------------------------------------------------------------------------------------------------------
-- Queue setup
---------------------------------------------------------------------------------------------------------------------------
ELSE IF @index = 3
BEGIN
	TRUNCATE TABLE #to_trans_type
	TRUNCATE TABLE #from_trans_type	
	TRUNCATE TABLE #trans_type

	-- Fill temp table with available transaction types
	INSERT INTO #trans_type (trans_type,[description]) VALUES ('STDPICK',   'Sales Order Pick')
	INSERT INTO #trans_type (trans_type,[description]) VALUES ('XFERPICK',  'Xfer Order Pick')
	INSERT INTO #trans_type (trans_type,[description]) VALUES ('WOPPICK',   'Work Order Pick')
	INSERT INTO #trans_type (trans_type,[description]) VALUES ('MGTB2B', 	'Management Bin To Bin')
	INSERT INTO #trans_type (trans_type,[description]) VALUES ('PLWB2B', 	'Planners Work Bench Bin To Bin')
	INSERT INTO #trans_type (trans_type,[description]) VALUES ('POPTWY', 	'Purchase Order Putaway')
	INSERT INTO #trans_type (trans_type,[description]) VALUES ('XPTWY', 	'Xfer Order Putaway')
	INSERT INTO #trans_type (trans_type,[description]) VALUES ('CRPTWY', 	'Credit Order Putaway')
	INSERT INTO #trans_type (trans_type,[description]) VALUES ('WOPTWY', 	'Work Order Putaway')
	INSERT INTO #trans_type (trans_type,[description]) VALUES ('ADHRECB2B', 'ADHOC Receipt Bin To Bin')


	--TRANSACTION TYPES
	IF EXISTS(SELECT * FROM tdc_wow_trans_type (NOLOCK) 
		   WHERE userid = @userid 
		     AND all_trans_type > 0)
	BEGIN
		INSERT INTO #to_trans_type (trans_type, [description]) 
		VALUES(@ALL, @ALL)
	END
	ELSE
	BEGIN
		INSERT INTO #to_trans_type (trans_type, [description]) 
		SELECT a.trans_type, b.[description] 
		  FROM tdc_wow_trans_type a (NOLOCK), 
		       #trans_type b (NOLOCK) 
		 WHERE a.trans_type = b.trans_type 
		   AND a.userid = @userid
	END

	INSERT INTO #from_trans_type 
	SELECT trans_type, [description] 
	  FROM #trans_type (NOLOCK)
	 WHERE trans_type NOT IN (SELECT trans_type 
				    FROM #to_trans_type
				   UNION 
				  SELECT trans_type 
				    FROM #from_trans_type) 	
END

GO
GRANT EXECUTE ON  [dbo].[tdc_wow_fill_sp] TO [public]
GO
