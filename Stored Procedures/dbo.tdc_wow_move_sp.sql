SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_wow_move_sp] 
	@index      	int, 	-- Inventory = 1, SalesOrder = 2, Queue = 3
	@sub_index  	int,	-- LocationPart = 1, Buyers = 2, Cateries = 3, Vendors = 4, BinGroups = 5
	@action		int,	-- AddAll = 1, Add = 2, Remove = 3, RemoveAll = 4, CheckAll = 5
	@record		varchar(255), -- The record to add or remove
	@sub_record	varchar(255), -- The extra column to find distinct record
	@userid     	varchar(50) 
AS

DECLARE @ALL VARCHAR(5)

SELECT @ALL = '[ALL]'


------------------------------------------------------------------------------------------------------------------------
-- Inventory Cfg
------------------------------------------------------------------------------------------------------------------------
IF @index = 1
BEGIN
	IF @sub_index = 0 --Locations
	BEGIN
		IF @action = 0 --Add All
		BEGIN
			INSERT INTO #to_loc	
			SELECT * FROM #from_loc

			TRUNCATE TABLE #from_loc
		END
		ELSE IF @action = 1 --Add
		BEGIN
			INSERT INTO #to_loc	
			SELECT * FROM #from_loc
 			 WHERE location = @record

			DELETE FROM #from_loc
			WHERE location = @record
		END
		ELSE IF @action = 2 --Remove
		BEGIN
			INSERT INTO #from_loc	
			SELECT * FROM #to_loc
 			 WHERE location = @record

			DELETE FROM #to_loc
			WHERE location = @record
		END
		ELSE IF @action = 3 --Remove All
		BEGIN
			INSERT INTO #from_loc	
			SELECT * FROM #to_loc

			TRUNCATE TABLE #to_loc
		END

		-- Load available parts based on the locations selected
		IF NOT EXISTS(SELECT * FROM #to_loc
			       WHERE location = @ALL)--If user has not chosen all
		BEGIN
			INSERT INTO #from_part_location 
			SELECT part_no, location
			  FROM inv_list
			 WHERE location IN (SELECT location
					      FROM #to_loc)
			   AND location + '$$%%$$' + part_no NOT IN (SELECT location + '$$%%$$' + part_no
								       FROM #from_part_location
								      UNION
								     SELECT location + '$$%%$$' + part_no
								       FROM #to_part_location)
			 
			--- Remove any ship_to_codes that this has affected
			DELETE FROM #to_part_location
			WHERE location NOT IN(SELECT location
						FROM #to_loc)
			  AND location != @all
	
			DELETE FROM #from_part_location
			WHERE location NOT IN(SELECT location
						FROM #to_loc)
		END
		ELSE
		BEGIN
			INSERT INTO #from_part_location 
			SELECT part_no, location
			  FROM inv_list
			 WHERE location + '$$%%$$' + part_no NOT IN (SELECT location + '$$%%$$' + part_no
								       FROM #from_part_location
								      UNION
								     SELECT location + '$$%%$$' + part_no
								       FROM #to_part_location)
		END

	END
	ELSE IF @sub_index = 1 -- Parts
	BEGIN
		IF @action = 0 --Add All
		BEGIN
			INSERT INTO #to_part_location	
			SELECT * FROM #from_part_location

			TRUNCATE TABLE #from_part_location
		END
		ELSE IF @action = 1 --Add
		BEGIN
			INSERT INTO #to_part_location	
			SELECT * FROM #from_part_location
 			 WHERE part_no = @record
			   AND location = @sub_record

			DELETE FROM #from_part_location
 			 WHERE part_no = @record
			   AND location = @sub_record
		END
		ELSE IF @action = 2 --Remove
		BEGIN
			INSERT INTO #from_part_location	
			SELECT * FROM #to_part_location
 			 WHERE part_no = @record
			   AND location = @sub_record

			DELETE FROM #to_part_location
 			 WHERE part_no = @record
			   AND location = @sub_record
		END
		ELSE IF @action = 3 --Remove All
		BEGIN
			INSERT INTO #from_part_location	
			SELECT * FROM #to_part_location

			TRUNCATE TABLE #to_part_location
		END
	END
	ELSE IF @sub_index = 2 -- Buyers
	BEGIN
		IF @action = 0 --Add All
		BEGIN
			INSERT INTO #to_buyer	
			SELECT * FROM #from_buyer

			TRUNCATE TABLE #from_buyer
		END
		ELSE IF @action = 1 --Add
		BEGIN
			INSERT INTO #to_buyer	
			SELECT * FROM #from_buyer
 			 WHERE buyer = @record

			DELETE FROM #from_buyer
			WHERE buyer = @record
		END
		ELSE IF @action = 2 --Remove
		BEGIN
			INSERT INTO #from_buyer	
			SELECT * FROM #to_buyer
 			 WHERE buyer = @record

			DELETE FROM #to_buyer
			WHERE buyer = @record
		END
		ELSE IF @action = 3 --Remove All
		BEGIN
			INSERT INTO #from_buyer	
			SELECT * FROM #to_buyer

			TRUNCATE TABLE #to_buyer
		END
	END
	ELSE IF @sub_index = 3 -- Category
	BEGIN
		IF @action = 0 --Add All
		BEGIN
			INSERT INTO #to_category	
			SELECT * FROM #from_category

			TRUNCATE TABLE #from_category
		END
		ELSE IF @action = 1 --Add
		BEGIN
			INSERT INTO #to_category	
			SELECT * FROM #from_category
 			 WHERE category = @record

			DELETE FROM #from_category
			WHERE category = @record
		END
		ELSE IF @action = 2 --Remove
		BEGIN
			INSERT INTO #from_category	
			SELECT * FROM #to_category
 			 WHERE category = @record

			DELETE FROM #to_category
			WHERE category = @record
		END
		ELSE IF @action = 3 --Remove All
		BEGIN
			INSERT INTO #from_category	
			SELECT * FROM #to_category

			TRUNCATE TABLE #to_category
		END
	END
	ELSE IF @sub_index = 4 -- Vendor
	BEGIN
		IF @action = 0 --Add All
		BEGIN
			INSERT INTO #to_vendor	
			SELECT * FROM #from_vendor

			TRUNCATE TABLE #from_vendor
		END
		ELSE IF @action = 1 --Add
		BEGIN
			INSERT INTO #to_vendor	
			SELECT * FROM #from_vendor
 			 WHERE vendor = @record

			DELETE FROM #from_vendor
			WHERE vendor = @record
		END
		ELSE IF @action = 2 --Remove
		BEGIN
			INSERT INTO #from_vendor	
			SELECT * FROM #to_vendor
 			 WHERE vendor = @record

			DELETE FROM #to_vendor
			WHERE vendor = @record
		END
		ELSE IF @action = 3 --Remove All
		BEGIN
			INSERT INTO #from_vendor	
			SELECT * FROM #to_vendor

			TRUNCATE TABLE #to_vendor
		END
	END	
	ELSE IF @sub_index = 5 --Group Code
	BEGIN
		IF @action = 0 --Add All
		BEGIN
			INSERT INTO #to_bin_group	
			SELECT * FROM #from_bin_group

			TRUNCATE TABLE #from_bin_group
		END
		ELSE IF @action = 1 --Add
		BEGIN
			INSERT INTO #to_bin_group	
			SELECT * FROM #from_bin_group
 			 WHERE group_code = @record

			DELETE FROM #from_bin_group
			WHERE group_code = @record
		END
		ELSE IF @action = 2 --Remove
		BEGIN
			INSERT INTO #from_bin_group	
			SELECT * FROM #to_bin_group
 			 WHERE group_code = @record

			DELETE FROM #to_bin_group
			WHERE group_code = @record
		END
		ELSE IF @action = 3 --Remove All
		BEGIN
			INSERT INTO #from_bin_group	
			SELECT * FROM #to_bin_group

			TRUNCATE TABLE #to_bin_group
		END

	END
END

/*
		IF @action = 0 --Add All
		BEGIN
			PRINT 'HERE'
		END
		ELSE IF @action = 1 --Add
		BEGIN
			PRINT 'HERE'
		END
		ELSE IF @action = 2 --Remove
		BEGIN
			PRINT 'HERE'
		END
		ELSE IF @action = 3 --Remove All
		BEGIN
			PRINT 'HERE'
		END
*/

------------------------------------------------------------------------------------------------------------------------
-- Sales Order Cfg
------------------------------------------------------------------------------------------------------------------------
ELSE IF @index = 2
BEGIN
	IF @sub_index = 0 --Customer Codes
	BEGIN
		IF @action = 0 --Add All
		BEGIN
			INSERT INTO #to_cust_code	
			SELECT * FROM #from_cust_code

			TRUNCATE TABLE #from_cust_code
		END
		ELSE IF @action = 1 --Add
		BEGIN
			INSERT INTO #to_cust_code	
			SELECT * FROM #from_cust_code
			WHERE customer_code = @record

			DELETE FROM #from_cust_code
			WHERE customer_code = @record
		END
		ELSE IF @action = 2 --Remove
		BEGIN
			INSERT INTO #from_cust_code	
			SELECT * FROM #to_cust_code
			WHERE customer_code = @record

			DELETE FROM #to_cust_code
			WHERE customer_code = @record
		END
		ELSE IF @action = 3 --Remove All
		BEGIN
			INSERT INTO #from_cust_code	
			SELECT * FROM #to_cust_code

			TRUNCATE TABLE #to_cust_code
		END

		-- Load available ship to codes based on the customer codes selected
		IF NOT EXISTS(SELECT * FROM #to_cust_code
			       WHERE customer_code = @ALL)--If user has not chosen all
		BEGIN
			INSERT INTO #from_ship_to 
			SELECT customer_code, ship_to_code, ship_to_name 
			  FROM arshipto
			 WHERE customer_code NOT IN (SELECT customer_code
						       FROM #to_ship_to
						      UNION 
						     SELECT customer_code
						       FROM #from_ship_to)
			   AND customer_code IN (SELECT customer_code 
						   FROM #to_cust_code)
			--- Remove any ship_to_codes that this has affected
			DELETE FROM #to_ship_to
			WHERE customer_code NOT IN(SELECT customer_code
						     FROM #to_cust_code)
			  AND customer_code != @all
	
			DELETE FROM #from_ship_to
			WHERE customer_code NOT IN(SELECT customer_code
						     FROM #to_cust_code)
		END
		ELSE
		BEGIN
			INSERT INTO #from_ship_to (customer_code, ship_to_code, ship_to_name )
			SELECT customer_code, ship_to_code, ship_to_name 
			  FROM arshipto
			 WHERE customer_code NOT IN (SELECT customer_code
						       FROM #to_ship_to
						      UNION 
						     SELECT customer_code
						       FROM #from_ship_to)
		END

	END
	ELSE IF @sub_index = 1 --Ship To
	BEGIN
		IF @action = 0 --Add All
		BEGIN
			INSERT INTO #to_ship_to	
			SELECT * FROM #from_ship_to

			TRUNCATE TABLE #from_ship_to
		END
		ELSE IF @action = 1 --Add
		BEGIN
			INSERT INTO #to_ship_to	
			SELECT * FROM #from_ship_to
			WHERE customer_code = @record
			  AND ship_to_code = @sub_record

			DELETE FROM #from_ship_to
			WHERE customer_code = @record
			  AND ship_to_code = @sub_record
		END
		ELSE IF @action = 2 --Remove
		BEGIN
			INSERT INTO #from_ship_to	
			SELECT * FROM #to_ship_to
			WHERE customer_code = @record
			  AND ship_to_code = @sub_record

			DELETE FROM #to_ship_to
			WHERE customer_code = @record
			  AND ship_to_code = @sub_record
		END
		ELSE IF @action = 3 --Remove All
		BEGIN
			INSERT INTO #from_ship_to	
			SELECT * FROM #to_ship_to

			TRUNCATE TABLE #to_ship_to
		END
	END
END

------------------------------------------------------------------------------------------------------------------------
-- Queue transactions
------------------------------------------------------------------------------------------------------------------------
ELSE IF @index = 3
BEGIN
	IF @action = 0 --Add All
	BEGIN
		INSERT INTO #to_trans_type     
		SELECT * FROM #from_trans_type 
    
    		TRUNCATE TABLE #from_trans_type 
	END
	ELSE IF @action = 1 --Add
	BEGIN
		INSERT INTO #to_trans_type (trans_type, [description]) 
             	SELECT trans_type, [description]                      
             	  FROM #from_trans_type                               
             	 WHERE trans_type = @record

		DELETE FROM #from_trans_type    
		 WHERE trans_type = @record
	END
	ELSE IF @action = 2 --Remove
	BEGIN
		INSERT INTO #from_trans_type (trans_type, [description]) 
		SELECT trans_type, [description]                       
		  FROM #to_trans_type                                  
		 WHERE trans_type = @record

		DELETE FROM #to_trans_type   
		 WHERE trans_type = @record
	END
	ELSE IF @action = 3 --Remove All
	BEGIN
    
		INSERT INTO #from_trans_type    
		SELECT * FROM #to_trans_type 
 
		TRUNCATE TABLE #to_trans_type 
	END
END
GO
GRANT EXECUTE ON  [dbo].[tdc_wow_move_sp] TO [public]
GO
