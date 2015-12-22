SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_wow_save_sp] 
	@all_selected		int = 0, 
	@sub_all_selected 	int = 0, 
	@index 			int = 1, 
	@sub_index 		int = 1, 
	@userid 		varchar(50)
AS

--Main tabs are: Inventory = 1, SalesOrder = 2, Queue = 3
--Sub Tabs for Inventory main tab are:
---------------LocationPart, Buyers, Cateries, Vendors, BinGroups

--Sub Tabs for SalesOrder main tab are:
---------------CustCodeShipTo

--Sub Tabs for Queue main tab are:
---------------TransTypes
IF @index = 1 --SalesOrder; Theres only one sub tab
BEGIN
	IF @sub_index = 1
	BEGIN
		DELETE FROM tdc_wow_location WHERE userid = @userid
		DELETE FROM tdc_wow_part_location WHERE userid = @userid
		IF @all_selected > 0
		BEGIN
			INSERT INTO tdc_wow_location (userid, all_locations) VALUES (@userid, 1)
		END
		ELSE
		BEGIN
			INSERT INTO tdc_wow_location (userid, location) SELECT @userid, location FROM #to_loc
		END
	
		IF @sub_all_selected > 0
		BEGIN
			INSERT INTO tdc_wow_part_location (userid, all_partlocations) VALUES (@userid, 1)
		END
		ELSE
		BEGIN
			INSERT INTO tdc_wow_part_location (userid, part_no, location) 
			SELECT @userid, a.part_no, a.location FROM #to_part_location a, #to_loc b
			--WHERE a.location = b.location 
			--SCR 36864 08-11-06 ToddR
		END


	END
	IF @sub_index = 2
	BEGIN
		DELETE FROM tdc_wow_buyer WHERE userid = @userid

		IF @all_selected > 0
		BEGIN
			INSERT INTO tdc_wow_buyer (userid, all_buyers) VALUES (@userid, 1)
		END
		ELSE
		BEGIN
			INSERT INTO tdc_wow_buyer (userid, buyer) SELECT @userid, buyer FROM #to_buyer
		END
	END

	IF @sub_index = 3
	BEGIN
		DELETE FROM tdc_wow_category WHERE userid = @userid

		IF @all_selected > 0
		BEGIN
			INSERT INTO tdc_wow_category (userid, all_categories) VALUES (@userid, 1)
		END
		ELSE
		BEGIN
			INSERT INTO tdc_wow_category (userid, category) SELECT @userid, category FROM #to_category
		END
	END

	IF @sub_index = 4
	BEGIN
		DELETE FROM tdc_wow_vendor WHERE userid = @userid

		IF @all_selected > 0
		BEGIN
			INSERT INTO tdc_wow_vendor (userid, all_vendors) VALUES (@userid, 1)
		END
		ELSE
		BEGIN
			INSERT INTO tdc_wow_vendor (userid, vendor) SELECT @userid, vendor FROM #to_vendor
		END
	END

	IF @sub_index = 5
	BEGIN
		DELETE FROM tdc_wow_bin_group WHERE userid = @userid

		IF @all_selected > 0
		BEGIN
			INSERT INTO tdc_wow_bin_group (userid, all_bin_groups) VALUES (@userid, 1)
		END
		ELSE
		BEGIN
			INSERT INTO tdc_wow_bin_group (userid, group_code, group_code_id) SELECT @userid, group_code, '' FROM #to_bin_group
		END
	END

END

IF @index = 2 --SalesOrder; Theres only one sub tab
BEGIN
	DELETE FROM tdc_wow_cust_code WHERE userid = @userid
	DELETE FROM tdc_wow_ship_to WHERE userid = @userid
	IF @all_selected > 0
	BEGIN
		INSERT INTO tdc_wow_cust_code (userid, all_cust_code) VALUES (@userid, 1)
	END
	ELSE
	BEGIN
		INSERT INTO tdc_wow_cust_code (userid, customer_code) SELECT @userid, customer_code FROM #to_cust_code
	END

	IF @sub_all_selected > 0
	BEGIN
		INSERT INTO tdc_wow_ship_to (userid, all_ship_to) VALUES (@userid, 1)
	END
	ELSE
	BEGIN
		INSERT INTO tdc_wow_ship_to (userid, customer_code, ship_to_code) 
		SELECT @userid, a.customer_code, a.ship_to_code FROM #to_ship_to a, #to_cust_code b
		WHERE a.customer_code = b.customer_code
	END

END

IF @index = 3 --TRANS TYPE; Theres only one sub tab
BEGIN
	DELETE FROM tdc_wow_trans_type WHERE userid = @userid
	IF @all_selected > 0
	BEGIN
		INSERT INTO tdc_wow_trans_type (userid, all_trans_type) VALUES (@userid, 1)
	END
	ELSE
	BEGIN
		INSERT INTO tdc_wow_trans_type (userid, trans_type) 
		SELECT @userid, trans_type FROM #to_trans_type
	END

END
RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_wow_save_sp] TO [public]
GO
