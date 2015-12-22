SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SCR #34537 4/19/05 By Jim : added assign_user_id = @user_id in where clause for trans is picker. if tran_id not found then check assign_user_id is null
-- SCR #34537 4/21/05 By Jim : assign_user_id can be either @user_id or @user_config_group

CREATE PROCEDURE [dbo].[tdc_next_q_tran_config_sp]
		  @user_id   varchar (50)
AS

DECLARE @tran_id 			int,
	@any_bins_assigned		char(1),
	@any_items_assigned		char(1),
	@pick_or_put_queue		varchar(4),
	@all_locations_assigned		int,
	@user_assigned_bins		varchar(30),
	@user_assigned_bin_groups	varchar(30),
	@user_assigned_items		varchar(30),
	@user_assigned_item_groups	varchar(30),
	@user_assigned_resources	varchar(30),
	@user_assigned_freights		varchar(30),
	@trans_type 			varchar(20),
	@user_config_group 		varchar(20)
	
	
/*	Set defaults	*/
SELECT @tran_id  	   = 0
SELECT @any_bins_assigned  = 'N'
SELECT @any_items_assigned = 'N'
SELECT @pick_or_put_queue  = 'Pick'

------------------------------------------------------------------------------------------------------------------------------
--  GET A TRANSACTION WITH THE HIGHEST PRIORITY LOCKED BY THE SAME USER (FOR EXAMPLE, WHEN APPLICATION WAS TERMINATED)	    --
--					FROM THE PICK OR PUT QUEUE 				    			    --
------------------------------------------------------------------------------------------------------------------------------
SELECT @tran_id = tran_id 
  FROM tdc_pick_queue (NOLOCK)
 WHERE [user_id] = @user_id 
   AND tx_lock = 'C'
 ORDER BY priority DESC, seq_no DESC

IF (@tran_id != 0)
BEGIN	
	UPDATE tdc_pick_queue SET date_time = getdate() WHERE tran_id = @tran_id -- update just date_time
	RETURN (@tran_id)
END
	
SELECT @tran_id = tran_id 
  FROM tdc_put_queue (NOLOCK)
 WHERE [user_id] = @user_id 
   AND tx_lock = 'C'
 ORDER BY priority DESC, seq_no DESC

IF (@tran_id != 0)
BEGIN	
	UPDATE tdc_pick_queue SET date_time = getdate() WHERE tran_id = @tran_id -- update just date_time
	RETURN (@tran_id)
END
------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------
--  		GET A TRANSACTION WITH THE HIGHEST PRIORITY ORDER LOCKED BY THE SAME USER 				    --
--					FROM THE PICK QUEUE	 				    			    --
------------------------------------------------------------------------------------------------------------------------------
SELECT @tran_id = tran_id 
  FROM tdc_pick_queue (NOLOCK) 
 WHERE [user_id] = @user_id AND tx_lock = 'O' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
 ORDER BY priority DESC, seq_no DESC

IF (@tran_id != 0)
BEGIN	
	UPDATE tdc_pick_queue SET date_time = getdate(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
	RETURN (@tran_id)
END
------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------
--  		GET A TRANSACTION WITH THE HIGHEST PRIORITY ASSIGNED TO THE USER REGARDLESS LOCATIONS / BINS / PARTS 	    --
--					FROM THE PICK OR PUT QUEUE 				    			    --
------------------------------------------------------------------------------------------------------------------------------
SELECT @tran_id = tran_id FROM tdc_pick_queue (NOLOCK)
 WHERE assign_user_id = @user_id  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
 ORDER BY priority DESC, seq_no DESC

IF (@tran_id != 0)
BEGIN	
	UPDATE tdc_pick_queue SET date_time = getdate(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
	RETURN (@tran_id)
END

SELECT @tran_id = tran_id FROM tdc_put_queue (NOLOCK)
 WHERE assign_user_id = @user_id  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
 ORDER BY priority DESC, seq_no DESC

IF (@tran_id != 0)
BEGIN	
	UPDATE tdc_put_queue SET date_time = getdate(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
	RETURN (@tran_id)
END
------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------
--  				CHECK THE USER'S CONFIGURATION 	    							    --
------------------------------------------------------------------------------------------------------------------------------


-- Get the config group that the user belongs to.
SELECT @user_config_group = group_id FROM tdc_user_config_assign_users (NOLOCK) WHERE userid = @user_id

-- Get the config group that the user belongs to.
IF EXISTS(SELECT * FROM tdc_user_config_locations (NOLOCK) 
	   WHERE group_id IN (@user_id, @user_config_group)
             AND location = '<All>')
BEGIN
	SET @all_locations_assigned = 1
END
ELSE
BEGIN
	SET @all_locations_assigned = 0
END

--If the user doen't belong to a group, he/she doesn't get next transaction.
IF @user_config_group IS NULL
	RETURN -1

--If the group, that the user belongs to, has no assigned location, he/she doesn't get next transaction.
IF NOT EXISTS (SELECT * FROM tdc_user_config_locations (NOLOCK) WHERE group_id = @user_config_group)
	RETURN -1

-- Check if the group, that the user belongs to, has any BINs assigned in the assigned locations.
SELECT @user_assigned_bins = MAX(value) FROM tdc_user_config_bins  (NOLOCK)
 WHERE group_id = @user_config_group 
   AND location IN (SELECT location FROM tdc_user_config_locations (NOLOCK) WHERE group_id = @user_config_group)

IF @user_assigned_bins IS NOT NULL
	SELECT @any_bins_assigned = 'Y'
	
-- Check if the group, that the user belongs to, has any Items assigned in the assigned locations.                     	  
SELECT @user_assigned_items = MAX(value) FROM tdc_user_config_items (NOLOCK)
 WHERE group_id = @user_config_group 
   AND location IN (SELECT location FROM tdc_user_config_locations (NOLOCK) WHERE group_id = @user_config_group) AND type = 'I'

-- Check if the group, that the user belongs to, has any Item Groups assigned in the assigned locations.	                      	  
SELECT @user_assigned_item_groups = MAX(value) FROM tdc_user_config_items (NOLOCK) 
 WHERE group_id = @user_config_group
   AND location IN (SELECT location FROM tdc_user_config_locations (NOLOCK) WHERE group_id = @user_config_group) AND type = 'G'

-- Check if the group, that the user belongs to, has any Resources assigned in the assigned locations.	                      	  
SELECT @user_assigned_resources = MAX(value) FROM tdc_user_config_items (NOLOCK) 
 WHERE group_id = @user_config_group
   AND location IN (SELECT location FROM tdc_user_config_locations (NOLOCK) WHERE group_id = @user_config_group) AND type = 'R'

-- Check if the group, that the user belongs to, has any Freight Classes assigned in the assigned locations.	                      	  
SELECT @user_assigned_freights = MAX(value) FROM tdc_user_config_items (NOLOCK) 
 WHERE group_id = @user_config_group
   AND location IN (SELECT location FROM tdc_user_config_locations (NOLOCK) WHERE group_id = @user_config_group) AND type = 'F'	

IF (@user_assigned_items     IS NOT NULL) OR (@user_assigned_item_groups IS NOT NULL)
OR (@user_assigned_resources IS NOT NULL) OR (@user_assigned_freights    IS NOT NULL)
	SELECT @any_items_assigned = 'Y'


------------------------------------------------------------------------------------------------------------------------------
--		NOW WE ARE READY TO HAVE REAL FUN!!!
------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------
-- 		GET A TRANSACTION WITH THE HIGHEST PRIORITY ASSIGNED TO THE CONFIG GROUP, THAT THE USER BELONGS TO,	    --
--					FROM THE PICK OR PUT QUEUE 				    			    --
------------------------------------------------------------------------------------------------------------------------------
IF @any_bins_assigned = 'Y' AND @user_assigned_bins = '<All>' AND  @any_items_assigned = 'Y' 
BEGIN
	IF (@user_assigned_items     = '<All>') OR (@user_assigned_item_groups = '<All>')
	OR (@user_assigned_resources = '<All>') OR (@user_assigned_freights    = '<All>')
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
			   AND a.location = b.location 
		         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		ELSE
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
		         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC

		IF @tran_id = 0	-- Check the PUT queue		
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			ELSE
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		END
	END
	ELSE IF (@user_assigned_items <> '<All>') AND (@user_assigned_items IS NOT NULL) 
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
			   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
					    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'I')
		         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		ELSE
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
					    WHERE group_id = @user_config_group AND type = 'I')
		         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC

		IF @tran_id = 0	-- Check the PUT queue				
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
				   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
						    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'I')
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC	
			ELSE
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
						    WHERE group_id = @user_config_group AND type = 'I')
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC	
		END
	END
	ELSE IF (@user_assigned_item_groups <> '<All>') AND (@user_assigned_item_groups IS NOT NULL) 
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
						    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
									WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
		         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		ELSE
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
						    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
									WHERE group_id = @user_config_group AND type = 'G'))
		         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC

		IF @tran_id = 0	-- Check the PUT queue				
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
									WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			ELSE
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
									WHERE group_id = @user_config_group AND type = 'G'))
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		END
	END
	ELSE IF (@user_assigned_resources <> '<All>') AND (@user_assigned_resources IS NOT NULL) 
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
					    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
							         WHERE group_id = @user_config_group AND c.location = b.location AND type = 'R'))
		         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		ELSE
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
					    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
							         WHERE group_id = @user_config_group AND type = 'R'))
		         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC

		IF @tran_id = 0	-- Check the PUT queue				
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
									 WHERE group_id = @user_config_group AND c.location = b.location AND type = 'R'))
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			ELSE
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
									 WHERE group_id = @user_config_group AND type = 'R'))
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		END
	END
	ELSE IF (@user_assigned_freights <> '<All>') AND (@user_assigned_freights IS NOT NULL) 
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
					    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
					                 	     WHERE group_id = @user_config_group AND c.location = b.location AND type = 'F'))
		         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		ELSE
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
					    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
					                 	     WHERE group_id = @user_config_group AND type = 'F'))
		         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
	
		IF @tran_id = 0	-- Check the PUT queue				
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
						                 	     WHERE group_id = @user_config_group AND c.location = b.location AND type = 'F'))
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			ELSE
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
						                 	     WHERE group_id = @user_config_group AND type = 'F'))
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		END
	END
END
ELSE IF @any_bins_assigned = 'Y' AND @user_assigned_bins = '<All>' AND  @any_items_assigned = 'N' 
BEGIN
	IF @all_locations_assigned = 0
		SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
		 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
		   AND a.location = b.location 
	         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
	ELSE
		SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
		 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
	         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC

	IF @tran_id = 0	-- Check the PUT queue				
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
		ELSE
			SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
	END
END
ELSE IF @any_bins_assigned = 'Y' AND @user_assigned_bins != '<All>' AND  @any_items_assigned = 'Y' 
BEGIN
	IF (@user_assigned_items     = '<All>') OR (@user_assigned_item_groups = '<All>')
	OR (@user_assigned_resources = '<All>') OR (@user_assigned_freights    = '<All>')
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
			   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
					    UNION
					   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
					    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)
								  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
			    OR bin_no IS NULL)
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		ELSE
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                    WHERE group_id = @user_config_group AND type = 'B'
					    UNION
					   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
					    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)
								  WHERE group_id = @user_config_group AND type = 'G'))
			    OR bin_no IS NULL)
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC

		IF @tran_id = 0	-- Check the PUT queue		
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
				   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                            WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
						    UNION
						   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
									  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
				    OR bin_no IS NULL)
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			ELSE
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                            WHERE group_id = @user_config_group AND type = 'B'
						    UNION
						   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
									  WHERE group_id = @user_config_group AND type = 'G'))
				    OR bin_no IS NULL)
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		END
	END
	ELSE IF (@user_assigned_items <> '<All>') AND (@user_assigned_items IS NOT NULL) 
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
			   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
					    UNION
					   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
					    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
								  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
			    OR bin_no IS NULL)
			   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
					    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'I')
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		ELSE
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                    WHERE group_id = @user_config_group AND type = 'B'
					    UNION
					   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
					    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
								  WHERE group_id = @user_config_group AND type = 'G'))
			    OR bin_no IS NULL)
			   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
					    WHERE group_id = @user_config_group AND type = 'I')
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC

		IF @tran_id = 0	-- Check the PUT queue				
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
				   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                            WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
						    UNION
						   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)
									  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
				    OR bin_no IS NULL)
				   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
						    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'I')
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC	
			ELSE
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                            WHERE group_id = @user_config_group AND type = 'B'
						    UNION
						   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)
									  WHERE group_id = @user_config_group AND type = 'G'))
				    OR bin_no IS NULL)
				   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
						    WHERE group_id = @user_config_group AND type = 'I')
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC	

		END
	END
	ELSE IF (@user_assigned_item_groups <> '<All>') AND (@user_assigned_item_groups IS NOT NULL) 
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
			   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
					    UNION
					   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
					    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
								  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
			    OR bin_no IS NULL)
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
	 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
								WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		ELSE
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                    WHERE group_id = @user_config_group AND type = 'B'
					    UNION
					   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
					    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
								  WHERE group_id = @user_config_group AND type = 'G'))
			    OR bin_no IS NULL)
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
	 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
								WHERE group_id = @user_config_group AND type = 'G'))
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC

		IF @tran_id = 0	-- Check the PUT queue				
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
				   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                            WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
						    UNION
						   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
									  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
				    OR bin_no IS NULL)
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
														 AND c.location = b.location AND type = 'G'))
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			ELSE
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                            WHERE group_id = @user_config_group AND type = 'B'
						    UNION
						   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
									  WHERE group_id = @user_config_group AND type = 'G'))
				    OR bin_no IS NULL)
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
														            AND type = 'G'))
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		END
	END
	ELSE IF (@user_assigned_resources <> '<All>') AND (@user_assigned_resources IS NOT NULL) 
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
			   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
					    UNION
					   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
					    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
								  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
			    OR bin_no IS NULL)
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
	 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
													  AND c.location = b.location AND type = 'R'))
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		ELSE
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                    WHERE group_id = @user_config_group AND type = 'B'
					    UNION
					   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
					    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
								  WHERE group_id = @user_config_group AND type = 'G'))
			    OR bin_no IS NULL)
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
	 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
													             AND type = 'R'))
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC

		IF @tran_id = 0	-- Check the PUT queue				
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
				   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                            WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
						    UNION
						   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
									  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
				    OR bin_no IS NULL)
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
														  AND c.location = b.location AND type = 'R'))
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			ELSE
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                            WHERE group_id = @user_config_group AND type = 'B'
						    UNION
						   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
									  WHERE group_id = @user_config_group AND type = 'G'))
				    OR bin_no IS NULL)
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
														             AND type = 'R'))
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		END
	END
	ELSE IF (@user_assigned_freights <> '<All>') AND (@user_assigned_freights IS NOT NULL) 
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
			   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
					    UNION
					   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
					    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
								  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
			    OR bin_no IS NULL)
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
	 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
					                 	     WHERE group_id = @user_config_group 
								       AND c.location = b.location AND type = 'F'))
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		ELSE
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                    WHERE group_id = @user_config_group AND type = 'B'
					    UNION
					   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
					    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
								  WHERE group_id = @user_config_group AND type = 'G'))
			    OR bin_no IS NULL)
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
	 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
					                 	     WHERE group_id = @user_config_group 
								       AND type = 'F'))
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC

		IF @tran_id = 0	-- Check the PUT queue				
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
				   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                            WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
						    UNION
						   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
									  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
				    OR bin_no IS NULL)
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
						                 	     WHERE group_id = @user_config_group 
								  	       AND c.location = b.location AND type = 'F'))
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			ELSE
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                            WHERE group_id = @user_config_group AND type = 'B'
						    UNION
						   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
									  WHERE group_id = @user_config_group AND type = 'G'))
				    OR bin_no IS NULL)
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
						                 	     WHERE group_id = @user_config_group 
								  	       AND type = 'F'))
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
		END
	END
END
ELSE IF @any_bins_assigned = 'Y' AND @user_assigned_bins != '<All>' AND  @any_items_assigned = 'N' 
BEGIN
	IF @all_locations_assigned = 0
		SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
		 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
		   AND a.location = b.location 
		   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                            WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
				    UNION
				   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
				    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
							  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
		    OR bin_no IS NULL)
	         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
	ELSE
		SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
		 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
		   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                            WHERE group_id = @user_config_group AND type = 'B'
				    UNION
				   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
				    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
							  WHERE group_id = @user_config_group AND type = 'G'))
		    OR bin_no IS NULL)
	         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC

	IF @tran_id = 0	-- Check the PUT queue				
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
			   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
					    UNION
					   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
					    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
								  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
			    OR bin_no IS NULL)
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
		ELSE
			SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
	                                    WHERE group_id = @user_config_group AND type = 'B'
					    UNION
					   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
					    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
								  WHERE group_id = @user_config_group AND type = 'G'))
			    OR bin_no IS NULL)
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
	END
END
ELSE IF @any_bins_assigned = 'N' AND  @any_items_assigned = 'Y' 
BEGIN
	IF (@user_assigned_items     = '<All>') OR (@user_assigned_item_groups = '<All>')
	OR (@user_assigned_resources = '<All>') OR (@user_assigned_freights    = '<All>')
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
		ELSE
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC

		IF @tran_id = 0	-- Check the PUT queue				
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
			ELSE
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
		END
	END
	ELSE IF (@user_assigned_items <> '<All>') AND (@user_assigned_items IS NOT NULL) 
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
			   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
								  AND c.location = b.location AND type = 'I')
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
		ELSE
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
								                                AND type = 'I')
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC

		IF @tran_id = 0	-- Check the PUT queue				
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
				   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
								  			    AND c.location = b.location  AND type = 'I')
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
			ELSE
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
								  			      AND type = 'I')
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
		END
	END
	ELSE IF (@user_assigned_item_groups <> '<All>') AND (@user_assigned_item_groups IS NOT NULL) 
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
	 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
					                 	WHERE group_id = @user_config_group 
								  AND c.location = b.location  AND type = 'G'))
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
		ELSE
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
	 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
					                 	WHERE group_id = @user_config_group 
								  AND type = 'G'))
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC

		IF @tran_id = 0	-- Check the PUT queue				
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
						                 	WHERE group_id = @user_config_group 
									  AND c.location = b.location  AND type = 'G'))
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
			ELSE
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
						                 	WHERE group_id = @user_config_group 
									  AND type = 'G'))
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
		END
	END
	ELSE IF (@user_assigned_resources <> '<All>') AND (@user_assigned_resources IS NOT NULL) 
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
	 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
					                 	 WHERE group_id = @user_config_group  
								   AND c.location = b.location AND type = 'R'))
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
		ELSE
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
	 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
					                 	 WHERE group_id = @user_config_group  
								   AND type = 'R'))
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC

		IF @tran_id = 0	-- Check the PUT queue				
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
						                 	 WHERE group_id = @user_config_group 
									   AND c.location = b.location AND type = 'R'))
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
			ELSE
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
						                 	 WHERE group_id = @user_config_group 
									   AND type = 'R'))
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
		END
	END
	ELSE IF (@user_assigned_freights <> '<All>') AND (@user_assigned_freights IS NOT NULL) 
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
	 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
					                 	     WHERE group_id = @user_config_group 
								       AND c.location = b.location AND type = 'F'))
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
 		ELSE
			SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
	 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
					                 	     WHERE group_id = @user_config_group 
								       AND type = 'F'))
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC

		IF @tran_id = 0	-- Check the PUT queue				
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
						                 	     WHERE group_id = @user_config_group 
									       AND c.location = b.location AND type = 'F'))
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
			ELSE
				SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
		 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
						                 	     WHERE group_id = @user_config_group 
									       AND type = 'F'))
	                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
		END
	END
END
ELSE IF @any_bins_assigned = 'N' AND  @any_items_assigned = 'N' 
BEGIN
	IF @all_locations_assigned = 0
		SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
		 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
		   AND a.location = b.location 
	         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, a.priority DESC, seq_no DESC
	ELSE
		SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
		 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
	         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, a.priority DESC, seq_no DESC

	IF @tran_id = 0	-- Check the PUT queue				
	BEGIN
		IF @all_locations_assigned = 0
			SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			   AND a.location = b.location 
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, a.priority DESC, seq_no DESC
		ELSE
			SELECT @pick_or_put_queue = 'Put', @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
			 WHERE assign_user_id = @user_config_group  AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
	                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, a.priority DESC, seq_no DESC
	END
END

-- We've found a transaction that is assigned to the config group, that the user belongs to.
IF (@tran_id != 0)
BEGIN
	IF @pick_or_put_queue = 'Pick' 
		UPDATE tdc_pick_queue SET date_time = getdate(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
	ELSE
		UPDATE tdc_put_queue  SET date_time = getdate(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id

	RETURN (@tran_id)
END

------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------
-- 		GET A TRANSACTION WITH THE HIGHEST PRIORITY FROM THE PUT QUEUE 				    		    --
--						or									    --
-- 		GET A TRANSACTION WITH THE HIGHEST PRIORITY ASSIGNED TO THE PICKER GROUP				    --
--					FROM THE PICK QUEUE ONLY 				    			    --
------------------------------------------------------------------------------------------------------------------------------
DECLARE trans_type_assign CURSOR FOR
	SELECT type FROM tdc_user_config_tran_types (NOLOCK) WHERE group_id = @user_config_group ORDER BY priority 

OPEN trans_type_assign
FETCH NEXT FROM trans_type_assign INTO @trans_type

WHILE(@@FETCH_STATUS = 0)
BEGIN
	IF @trans_type = 'PUTAWAY'	-- check put queue
	BEGIN
		IF @any_bins_assigned = 'Y' AND @user_assigned_bins = '<All>' AND  @any_items_assigned = 'Y' 
		BEGIN
			IF (@user_assigned_items     = '<All>') OR (@user_assigned_item_groups = '<All>')
			OR (@user_assigned_resources = '<All>') OR (@user_assigned_freights    = '<All>')
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_items <> '<All>') AND (@user_assigned_items IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
							    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'I')
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC	
				ELSE
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
							    WHERE group_id = @user_config_group AND type = 'I')
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC	
			END
			ELSE IF (@user_assigned_item_groups <> '<All>') AND (@user_assigned_item_groups IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
										WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
										WHERE group_id = @user_config_group AND type = 'G'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_resources <> '<All>') AND (@user_assigned_resources IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
										 WHERE group_id = @user_config_group AND c.location = b.location AND type = 'R'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
										 WHERE group_id = @user_config_group AND type = 'R'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_freights <> '<All>') AND (@user_assigned_freights IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	     WHERE group_id = @user_config_group AND c.location = b.location AND type = 'F'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	     WHERE group_id = @user_config_group AND type = 'F'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
		END
		ELSE IF @any_bins_assigned = 'Y' AND @user_assigned_bins = '<All>' AND  @any_items_assigned = 'N' 
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
			ELSE
				SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
		END
		ELSE IF @any_bins_assigned = 'Y' AND @user_assigned_bins != '<All>' AND  @any_items_assigned = 'Y' 
		BEGIN
			IF (@user_assigned_items     = '<All>') OR (@user_assigned_item_groups = '<All>')
			OR (@user_assigned_resources = '<All>') OR (@user_assigned_freights    = '<All>')
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
		                                            WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
					    OR bin_no IS NULL)
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
		                                            WHERE group_id = @user_config_group AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND type = 'G'))
					    OR bin_no IS NULL)
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_items <> '<All>') AND (@user_assigned_items IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
		                                            WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
							    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'I')
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC	
				ELSE
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
		                                            WHERE group_id = @user_config_group AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
							    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'I')
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC	
			END
			ELSE IF (@user_assigned_item_groups <> '<All>') AND (@user_assigned_item_groups IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
		                                            WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
															 AND c.location = b.location AND type = 'G'))
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
		                                            WHERE group_id = @user_config_group AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
															            AND type = 'G'))
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_resources <> '<All>') AND (@user_assigned_resources IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
		                                            WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
										 WHERE group_id = @user_config_group AND c.location = b.location AND type = 'R'))
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
		                                            WHERE group_id = @user_config_group AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
										 WHERE group_id = @user_config_group AND type = 'R'))
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_freights <> '<All>') AND (@user_assigned_freights IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
		                                            WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	     WHERE group_id = @user_config_group 
									  	       AND c.location = b.location AND type = 'F'))
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
		                                            WHERE group_id = @user_config_group AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	     WHERE group_id = @user_config_group 
									  	       AND type = 'F'))
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
		END
		ELSE IF @any_bins_assigned = 'Y' AND @user_assigned_bins != '<All>' AND  @any_items_assigned = 'N' 
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
				   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
		                                    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
						    UNION
						   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
									  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
				    OR bin_no IS NULL)
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
			ELSE
				SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
		                                    WHERE group_id = @user_config_group AND type = 'B'
						    UNION
						   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
									  WHERE group_id = @user_config_group AND type = 'G'))
				    OR bin_no IS NULL)
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
		END
		ELSE IF @any_bins_assigned = 'N' AND  @any_items_assigned = 'Y' 
		BEGIN
			IF (@user_assigned_items     = '<All>') OR (@user_assigned_item_groups = '<All>')
			OR (@user_assigned_resources = '<All>') OR (@user_assigned_freights    = '<All>')
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_items <> '<All>') AND (@user_assigned_items IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
									  			    AND c.location = b.location  AND type = 'I')
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
									  			                AND type = 'I')
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_item_groups <> '<All>') AND (@user_assigned_item_groups IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	WHERE group_id = @user_config_group 
										  AND c.location = b.location  AND type = 'G'))
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	WHERE group_id = @user_config_group 
										  AND type = 'G'))
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_resources <> '<All>') AND (@user_assigned_resources IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	 WHERE group_id = @user_config_group 
										   AND c.location = b.location AND type = 'R'))
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	 WHERE group_id = @user_config_group 
										   AND type = 'R'))
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_freights <> '<All>') AND (@user_assigned_freights IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	     WHERE group_id = @user_config_group 
										       AND c.location = b.location AND type = 'F'))
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	     WHERE group_id = @user_config_group 
										       AND type = 'F'))
		                         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
		END
		ELSE IF @any_bins_assigned = 'N' AND  @any_items_assigned = 'N' 
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, a.priority DESC, seq_no DESC
			ELSE
				SELECT @tran_id = tran_id FROM tdc_put_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
		                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, a.priority DESC, seq_no DESC
		END
		
		-- We've found a transaction 
		IF (@tran_id != 0)
		BEGIN
			CLOSE      trans_type_assign
			DEALLOCATE trans_type_assign
			UPDATE tdc_put_queue  SET date_time = GETDATE(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id		
			RETURN @tran_id
		END
		
		FETCH NEXT FROM trans_type_assign INTO @trans_type
	END -- PUTAWAY
--------------------------------------------------------------------------------------------------------------------------------------------------
	ELSE IF @trans_type = 'PLWB2B' OR @trans_type = 'MGTB2B'	-- check pick queue 
	BEGIN
		IF @any_bins_assigned = 'Y' AND @user_assigned_bins = '<All>' AND  @any_items_assigned = 'Y' 
		BEGIN
			IF (@user_assigned_items     = '<All>') OR (@user_assigned_item_groups = '<All>')
			OR (@user_assigned_resources = '<All>') OR (@user_assigned_freights    = '<All>')
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location 
				         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
				         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC		
			END
			ELSE IF (@user_assigned_items <> '<All>') AND (@user_assigned_items IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'I')
				         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'I')
				         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_item_groups <> '<All>') AND (@user_assigned_item_groups IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
								    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
											WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
				         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
								    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
											WHERE group_id = @user_config_group AND type = 'G'))
				         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_resources <> '<All>') AND (@user_assigned_resources IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
								    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
										         WHERE group_id = @user_config_group AND c.location = b.location AND type = 'R'))
				         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
								    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
										         WHERE group_id = @user_config_group AND type = 'R'))
				         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_freights <> '<All>') AND (@user_assigned_freights IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
							    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	     WHERE group_id = @user_config_group AND c.location = b.location AND type = 'F'))
				         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
							    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	     WHERE group_id = @user_config_group AND type = 'F'))
				         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
		END
		ELSE IF @any_bins_assigned = 'Y' AND @user_assigned_bins = '<All>' AND  @any_items_assigned = 'N' 
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
			         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
			ELSE
				SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
		END
		ELSE IF @any_bins_assigned = 'Y' AND @user_assigned_bins != '<All>' AND  @any_items_assigned = 'Y' 
		BEGIN
			IF (@user_assigned_items     = '<All>') OR (@user_assigned_item_groups = '<All>')
			OR (@user_assigned_resources = '<All>') OR (@user_assigned_freights    = '<All>')
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
					    OR bin_no IS NULL)
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group AND type = 'G'))
					    OR bin_no IS NULL)
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_items <> '<All>') AND (@user_assigned_items IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
							    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'I')
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
	 			ELSE
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
							    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'I')
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_item_groups <> '<All>') AND (@user_assigned_item_groups IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
										WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
										WHERE group_id = @user_config_group AND type = 'G'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_resources <> '<All>') AND (@user_assigned_resources IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
										 WHERE group_id = @user_config_group AND c.location = b.location AND type = 'R'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK) 
										 WHERE group_id = @user_config_group AND type = 'R'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_freights <> '<All>') AND (@user_assigned_freights IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	     WHERE group_id = @user_config_group 
										       AND c.location = b.location AND type = 'F'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group AND type = 'B'
							    UNION
							   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
										  WHERE group_id = @user_config_group AND type = 'G'))
					    OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	     WHERE group_id = @user_config_group 
										       AND type = 'F'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
		END
		ELSE IF @any_bins_assigned = 'Y' AND @user_assigned_bins != '<All>' AND  @any_items_assigned = 'N' 
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
				   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                            WHERE group_id = @user_config_group AND c.location = b.location AND type = 'B'
						    UNION
						   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
									  WHERE group_id = @user_config_group AND c.location = b.location AND type = 'G'))
				    OR bin_no IS NULL)
			         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
			ELSE
				SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND (bin_no IN (SELECT value FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                            WHERE group_id = @user_config_group AND type = 'B'
						    UNION
						   SELECT bin_no FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value FROM tdc_user_config_bins c (NOLOCK) 
									  WHERE group_id = @user_config_group AND type = 'G'))
				    OR bin_no IS NULL)
			         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
		END
		ELSE IF @any_bins_assigned = 'N' AND  @any_items_assigned = 'Y' 
		BEGIN
			IF (@user_assigned_items     = '<All>') OR (@user_assigned_item_groups = '<All>')
			OR (@user_assigned_resources = '<All>') OR (@user_assigned_freights    = '<All>')
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_items <> '<All>') AND (@user_assigned_items IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
										  AND c.location = b.location AND type = 'I')
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT value FROM tdc_user_config_items c (NOLOCK) WHERE group_id = @user_config_group 
										                                AND type = 'I')
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_item_groups <> '<All>') AND (@user_assigned_item_groups IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	WHERE group_id = @user_config_group 
										  AND c.location = b.location  AND type = 'G'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE category IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	WHERE group_id = @user_config_group 
										  AND type = 'G'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_resources <> '<All>') AND (@user_assigned_resources IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	 WHERE group_id = @user_config_group  
										   AND c.location = b.location AND type = 'R'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
				ELSE
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE type_code IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	 WHERE group_id = @user_config_group  
										   AND type = 'R'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
			ELSE IF (@user_assigned_freights <> '<All>') AND (@user_assigned_freights IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND a.location = b.location 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	     WHERE group_id = @user_config_group 
										       AND c.location = b.location AND type = 'F'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
		 		ELSE
					SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
					   AND part_no IN (SELECT part_no FROM inv_master (NOLOCK)
			 				    WHERE freight_class IN (SELECT value FROM tdc_user_config_items c (NOLOCK)
							                 	     WHERE group_id = @user_config_group 
										       AND type = 'F'))
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC,  seq_no DESC, part_no DESC, a.priority DESC
			END
		END
		ELSE IF @any_bins_assigned = 'N' AND  @any_items_assigned = 'N' 
		BEGIN
			IF @all_locations_assigned = 0
				SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
				   AND a.location = b.location 
			         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, a.priority DESC, seq_no DESC
			ELSE
				SELECT @tran_id = tran_id FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type AND tx_lock = 'R' AND tran_id NOT IN (SELECT tran_id FROM #prev_tran) 
			         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, a.priority DESC, seq_no DESC
		END
		
		-- We've found a transaction 
		IF (@tran_id != 0)
		BEGIN
			CLOSE      trans_type_assign
			DEALLOCATE trans_type_assign
			UPDATE tdc_pick_queue SET date_time = getdate(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id
			RETURN @tran_id
		END
		
		FETCH NEXT FROM trans_type_assign INTO @trans_type
	END  -- PLWB2B OR MGTB2B
------------------------------------------------------------------------------------------------------------------------------
	ELSE --   @trans_type = 'PICKER'
	BEGIN				-- check pick queue only
		IF @any_bins_assigned = 'Y' AND @user_assigned_bins = '<All>' AND  @any_items_assigned = 'Y' 
		BEGIN

			IF (@user_assigned_items     = '<All>') OR (@user_assigned_item_groups = '<All>')
			OR (@user_assigned_resources = '<All>') OR (@user_assigned_freights    = '<All>')
			BEGIN
				IF @all_locations_assigned = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location 
				         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location 
					         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location 
					         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
				ELSE
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
				         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
			END
			ELSE IF (@user_assigned_items <> '<All>') AND (@user_assigned_items IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location
					   AND part_no IN (SELECT value 
							     FROM tdc_user_config_items c (NOLOCK)
							    WHERE group_id = @user_config_group 
							      AND c.location = b.location 
							      AND type = 'I')
				        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location 
						   AND part_no IN (SELECT value 
								     FROM tdc_user_config_items c (NOLOCK)
								    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'I')
					         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location 
						   AND part_no IN (SELECT value 
								     FROM tdc_user_config_items c (NOLOCK)
								    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'I')
					         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
				ELSE
				BEGIN				
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND part_no IN (SELECT value 
							     FROM tdc_user_config_items c (NOLOCK)
							    WHERE group_id = @user_config_group
							      AND type = 'I')
				        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT value 
								     FROM tdc_user_config_items c (NOLOCK)
								    WHERE group_id = @user_config_group 
								      AND type = 'I')
					        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT value 
								     FROM tdc_user_config_items c (NOLOCK)
								    WHERE group_id = @user_config_group 
								      AND type = 'I')
					        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
			END
			ELSE IF (@user_assigned_item_groups <> '<All>') AND (@user_assigned_item_groups IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK)
							    WHERE category IN (SELECT value 
									         FROM tdc_user_config_items c (NOLOCK)
									        WHERE group_id = @user_config_group 
									          AND c.location = b.location 
									          AND type = 'G'))
				        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location 
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
								    WHERE category IN (SELECT value 
										         FROM tdc_user_config_items c (NOLOCK)
										        WHERE group_id = @user_config_group 
										          AND c.location = b.location 
										          AND type = 'G'))
					         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location 
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
								    WHERE category IN (SELECT value 
										         FROM tdc_user_config_items c (NOLOCK)
										        WHERE group_id = @user_config_group 
										          AND c.location = b.location 
										          AND type = 'G'))
					         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
				ELSE
				BEGIN				
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK)
							    WHERE category IN (SELECT value 
									         FROM tdc_user_config_items c (NOLOCK)
									        WHERE group_id = @user_config_group  
									          AND type = 'G'))
				        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
								    WHERE category IN (SELECT value 
										         FROM tdc_user_config_items c (NOLOCK)
										        WHERE group_id = @user_config_group 
										          AND type = 'G'))
					         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
								    WHERE category IN (SELECT value 
										         FROM tdc_user_config_items c (NOLOCK)
										        WHERE group_id = @user_config_group 
										          AND type = 'G'))
					         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
			END
			ELSE IF (@user_assigned_resources <> '<All>') AND (@user_assigned_resources IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK)
							    WHERE type_code IN (SELECT value 
									         FROM tdc_user_config_items c (NOLOCK)
									        WHERE group_id = @user_config_group 
									          AND c.location = b.location 
									          AND type = 'R'))
				        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location 
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
								    WHERE type_code IN (SELECT value 
										         FROM tdc_user_config_items c (NOLOCK)
										        WHERE group_id = @user_config_group 
										          AND c.location = b.location 
										          AND type = 'R'))
					         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location 
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
								    WHERE type_code IN (SELECT value 
										         FROM tdc_user_config_items c (NOLOCK)
										        WHERE group_id = @user_config_group 
										          AND c.location = b.location 
										          AND type = 'R'))
					         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
				ELSE
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK)
							    WHERE type_code IN (SELECT value 
									         FROM tdc_user_config_items c (NOLOCK)
									        WHERE group_id = @user_config_group 
									          AND type = 'R'))
				        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
								    WHERE type_code IN (SELECT value 
										         FROM tdc_user_config_items c (NOLOCK)
										        WHERE group_id = @user_config_group 
										          AND type = 'R'))
					         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
								    WHERE type_code IN (SELECT value 
										         FROM tdc_user_config_items c (NOLOCK)
										        WHERE group_id = @user_config_group 
										          AND type = 'R'))
					         ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
			END
			ELSE IF (@user_assigned_freights <> '<All>') AND (@user_assigned_freights IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK)
							    WHERE freight_class IN (SELECT value 
									              FROM tdc_user_config_items c (NOLOCK)
									             WHERE group_id = @user_config_group 
									               AND c.location = b.location 
									               AND type = 'F'))
				        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
								    WHERE freight_class IN (SELECT value 
										              FROM tdc_user_config_items c (NOLOCK)
										             WHERE group_id = @user_config_group 
										               AND c.location = b.location 
										               AND type = 'F'))
					        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
								    WHERE freight_class IN (SELECT value 
										              FROM tdc_user_config_items c (NOLOCK)
										             WHERE group_id = @user_config_group 
										               AND c.location = b.location 
										               AND type = 'F'))
					        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
				ELSE
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK)
							    WHERE freight_class IN (SELECT value 
									              FROM tdc_user_config_items c (NOLOCK)
									             WHERE group_id = @user_config_group 
									               AND type = 'F'))
				        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
								    WHERE freight_class IN (SELECT value 
										              FROM tdc_user_config_items c (NOLOCK)
										             WHERE group_id = @user_config_group 
										               AND type = 'F'))
					        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
								    WHERE freight_class IN (SELECT value 
										              FROM tdc_user_config_items c (NOLOCK)
										             WHERE group_id = @user_config_group 
										               AND type = 'F'))
					        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
			END
		END
		ELSE IF @any_bins_assigned = 'Y' AND @user_assigned_bins = '<All>' AND  @any_items_assigned = 'N' 
		BEGIN
			IF @all_locations_assigned = 0
			BEGIN
				SELECT TOP 1 @tran_id = tran_id 
				  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type
				   AND assign_user_id = @user_id
				   AND tx_lock = 'R' 
				   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
				   AND a.location = b.location					
			        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
	
				IF @tran_id = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_config_group
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location
					ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
				END

				IF @tran_id = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id IS NULL
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location
					ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
				END
			END
			ELSE
			BEGIN
				SELECT TOP 1 @tran_id = tran_id 
				  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type
				   AND assign_user_id = @user_id
				   AND tx_lock = 'R' 
				   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)			
			        ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
	
				IF @tran_id = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_config_group
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
				END

				IF @tran_id = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id IS NULL
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
				END
			END
		END
		ELSE IF @any_bins_assigned = 'Y' AND @user_assigned_bins != '<All>' AND  @any_items_assigned = 'Y' 
		BEGIN
			IF (@user_assigned_items     = '<All>') OR (@user_assigned_item_groups = '<All>')
			OR (@user_assigned_resources = '<All>') OR (@user_assigned_freights    = '<All>')
			BEGIN
				IF @all_locations_assigned = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location					
					   AND (bin_no IN (SELECT value 
							     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group 
							      AND c.location = b.location 
							      AND type = 'B'
							    UNION
							   SELECT bin_no 
							     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value 
										   FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group 
										    AND c.location = b.location 
										    AND type = 'G'))
					       OR bin_no IS NULL)
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND c.location = b.location 
											    AND type = 'G'))
						       OR bin_no IS NULL)
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND c.location = b.location 
											    AND type = 'G'))
						       OR bin_no IS NULL)
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
				ELSE
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)			
					   AND (bin_no IN (SELECT value 
							     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group 
							      AND type = 'B'
							    UNION
							   SELECT bin_no 
							     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value 
										   FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group 
										    AND type = 'G'))
					       OR bin_no IS NULL)
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND type = 'G'))
						       OR bin_no IS NULL)
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND type = 'G'))
						       OR bin_no IS NULL)
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
			END
			ELSE IF (@user_assigned_items <> '<All>') AND (@user_assigned_items IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location					
					   AND (bin_no IN (SELECT value 
							     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group 
							      AND c.location = b.location 
							      AND type = 'B'
							    UNION
							   SELECT bin_no 
							     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value 
										   FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group 
										    AND c.location = b.location 
										    AND type = 'G'))
					       OR bin_no IS NULL)
					   AND part_no IN (SELECT value 
							     FROM tdc_user_config_items c (NOLOCK) 
							    WHERE group_id = @user_config_group 
							      AND c.location = b.location 
							      AND type = 'I')
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND c.location = b.location 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT value 
								     FROM tdc_user_config_items c (NOLOCK) 
								    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'I')
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND c.location = b.location 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT value 
								     FROM tdc_user_config_items c (NOLOCK) 
								    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'I')
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
				ELSE
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)				
					   AND (bin_no IN (SELECT value 
							     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group 
							      AND type = 'B'
							    UNION
							   SELECT bin_no 
							     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value 
										   FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group 
										    AND type = 'G'))
					       OR bin_no IS NULL)
					   AND part_no IN (SELECT value 
							     FROM tdc_user_config_items c (NOLOCK) 
							    WHERE group_id = @user_config_group 
							      AND type = 'I')
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT value 
								     FROM tdc_user_config_items c (NOLOCK) 
								    WHERE group_id = @user_config_group 
								      AND type = 'I')
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT value 
								     FROM tdc_user_config_items c (NOLOCK) 
								    WHERE group_id = @user_config_group 
								      AND type = 'I')
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
			END
			ELSE IF (@user_assigned_item_groups <> '<All>') AND (@user_assigned_item_groups IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location					
					   AND (bin_no IN (SELECT value 
							     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group 
							      AND c.location = b.location 
							      AND type = 'B'
							    UNION
							   SELECT bin_no 
							     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value 
										   FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group 
										    AND c.location = b.location 
										    AND type = 'G'))
					       OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK) 
							    WHERE category IN (SELECT value 
										 FROM tdc_user_config_items c (NOLOCK) 
										WHERE group_id = @user_config_group 
										  AND c.location = b.location 
										  AND type = 'G'))
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND c.location = b.location 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK) 
								    WHERE category IN (SELECT value 
											 FROM tdc_user_config_items c (NOLOCK) 
											WHERE group_id = @user_config_group 
											  AND c.location = b.location 
											  AND type = 'G'))
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND c.location = b.location 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK) 
								    WHERE category IN (SELECT value 
											 FROM tdc_user_config_items c (NOLOCK) 
											WHERE group_id = @user_config_group 
											  AND c.location = b.location 
											  AND type = 'G'))
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
				ELSE
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)			
					   AND (bin_no IN (SELECT value 
							     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group 
							      AND type = 'B'
							    UNION
							   SELECT bin_no 
							     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value 
										   FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group 
										    AND type = 'G'))
					       OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK) 
							    WHERE category IN (SELECT value 
										 FROM tdc_user_config_items c (NOLOCK) 
										WHERE group_id = @user_config_group 
										  AND type = 'G'))
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK) 
								    WHERE category IN (SELECT value 
											 FROM tdc_user_config_items c (NOLOCK) 
											WHERE group_id = @user_config_group 
											  AND type = 'G'))
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK) 
								    WHERE category IN (SELECT value 
											 FROM tdc_user_config_items c (NOLOCK) 
											WHERE group_id = @user_config_group 
											  AND type = 'G'))
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
			END
			ELSE IF (@user_assigned_resources <> '<All>') AND (@user_assigned_resources IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location					
					   AND (bin_no IN (SELECT value 
							     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group 
							      AND c.location = b.location 
							      AND type = 'B'
							    UNION
							   SELECT bin_no 
							     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value 
										   FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group 
										    AND c.location = b.location 
										    AND type = 'G'))
					       OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK) 
							    WHERE type_code IN (SELECT value 
										  FROM tdc_user_config_items c (NOLOCK) 
										 WHERE group_id = @user_config_group 
										   AND c.location = b.location 
										   AND type = 'R'))
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND c.location = b.location 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK) 
								    WHERE type_code IN (SELECT value 
											  FROM tdc_user_config_items c (NOLOCK) 
											 WHERE group_id = @user_config_group 
											   AND c.location = b.location 
											   AND type = 'R'))
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND c.location = b.location 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK) 
								    WHERE type_code IN (SELECT value 
											  FROM tdc_user_config_items c (NOLOCK) 
											 WHERE group_id = @user_config_group 
											   AND c.location = b.location 
											   AND type = 'R'))
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
				ELSE
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)			
					   AND (bin_no IN (SELECT value 
							     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group 
							      AND type = 'B'
							    UNION
							   SELECT bin_no 
							     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value 
										   FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group 
										    AND type = 'G'))
					       OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK) 
							    WHERE type_code IN (SELECT value 
										  FROM tdc_user_config_items c (NOLOCK) 
										 WHERE group_id = @user_config_group 
										   AND type = 'R'))
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK) 
								    WHERE type_code IN (SELECT value 
											  FROM tdc_user_config_items c (NOLOCK) 
											 WHERE group_id = @user_config_group 
											   AND type = 'R'))
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK) 
								    WHERE type_code IN (SELECT value 
											  FROM tdc_user_config_items c (NOLOCK) 
											 WHERE group_id = @user_config_group 
											   AND type = 'R'))
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
			END
			ELSE IF (@user_assigned_freights <> '<All>') AND (@user_assigned_freights IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0				
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location					
					   AND (bin_no IN (SELECT value 
							     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group 
							      AND c.location = b.location 
							      AND type = 'B'
							    UNION
							   SELECT bin_no 
							     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value 
										   FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group 
										    AND c.location = b.location 
										    AND type = 'G'))
					       OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK) 
							    WHERE freight_class IN (SELECT value 
										      FROM tdc_user_config_items c (NOLOCK) 
										     WHERE group_id = @user_config_group 
										       AND c.location = b.location 
										       AND type = 'F'))
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND c.location = b.location 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK) 
								    WHERE freight_class IN (SELECT value 
											      FROM tdc_user_config_items c (NOLOCK) 
											     WHERE group_id = @user_config_group 
											       AND c.location = b.location 
											       AND type = 'F'))
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND c.location = b.location 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK) 
								    WHERE freight_class IN (SELECT value 
											      FROM tdc_user_config_items c (NOLOCK) 
											     WHERE group_id = @user_config_group 
											       AND c.location = b.location 
											       AND type = 'F'))
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
				ELSE
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)				
					   AND (bin_no IN (SELECT value 
							     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group 
							      AND type = 'B'
							    UNION
							   SELECT bin_no 
							     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value 
										   FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group 
										    AND type = 'G'))
					       OR bin_no IS NULL)
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK) 
							    WHERE freight_class IN (SELECT value 
										      FROM tdc_user_config_items c (NOLOCK) 
										     WHERE group_id = @user_config_group 
										       AND type = 'F'))
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK) 
								    WHERE freight_class IN (SELECT value 
											      FROM tdc_user_config_items c (NOLOCK) 
											     WHERE group_id = @user_config_group 
											       AND type = 'F'))
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND (bin_no IN (SELECT value 
								     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
				                                    WHERE group_id = @user_config_group 
								      AND type = 'B'
								    UNION
								   SELECT bin_no 
								     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
								    WHERE group_code IN (SELECT value 
											   FROM tdc_user_config_bins c (NOLOCK)
											  WHERE group_id = @user_config_group 
											    AND type = 'G'))
						       OR bin_no IS NULL)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK) 
								    WHERE freight_class IN (SELECT value 
											      FROM tdc_user_config_items c (NOLOCK) 
											     WHERE group_id = @user_config_group 
											       AND type = 'F'))
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
			END
		END
		ELSE IF @any_bins_assigned = 'Y' AND @user_assigned_bins != '<All>' AND  @any_items_assigned = 'N' 
		BEGIN
			IF @all_locations_assigned = 0
			BEGIN
				SELECT TOP 1 @tran_id = tran_id 
				  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type
				   AND assign_user_id = @user_id
				   AND tx_lock = 'R' 
				   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
				   AND a.location = b.location					
				   AND (bin_no IN (SELECT value 
						     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
		                                    WHERE group_id = @user_config_group 
						      AND c.location = b.location 
						      AND type = 'B'
						    UNION
						   SELECT bin_no 
						     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value 
									   FROM tdc_user_config_bins c (NOLOCK)
									  WHERE group_id = @user_config_group 
									    AND c.location = b.location 
									    AND type = 'G'))
				       OR bin_no IS NULL)
		                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
	
				IF @tran_id = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_config_group
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location
					   AND (bin_no IN (SELECT value 
							     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group 
							      AND c.location = b.location 
							      AND type = 'B'
							    UNION
							   SELECT bin_no 
							     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value 
										   FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group 
										    AND c.location = b.location 
										    AND type = 'G'))
					       OR bin_no IS NULL)					 
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
				END

				IF @tran_id = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id IS NULL
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location
					   AND (bin_no IN (SELECT value 
							     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group 
							      AND c.location = b.location 
							      AND type = 'B'
							    UNION
							   SELECT bin_no 
							     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value 
										   FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group 
										    AND c.location = b.location 
										    AND type = 'G'))
					       OR bin_no IS NULL)					 
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
				END
			END
			ELSE
			BEGIN
				SELECT TOP 1 @tran_id = tran_id 
				  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type
				   AND assign_user_id = @user_id
				   AND tx_lock = 'R' 
				   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)			
				   AND (bin_no IN (SELECT value 
						     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
		                                    WHERE group_id = @user_config_group 
						      AND type = 'B'
						    UNION
						   SELECT bin_no 
						     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
						    WHERE group_code IN (SELECT value 
									   FROM tdc_user_config_bins c (NOLOCK)
									  WHERE group_id = @user_config_group 
									    AND type = 'G'))
				       OR bin_no IS NULL)
		                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
	
				IF @tran_id = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_config_group
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND (bin_no IN (SELECT value 
							     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group 
							      AND type = 'B'
							    UNION
							   SELECT bin_no 
							     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value 
										   FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group 
										    AND type = 'G'))
					       OR bin_no IS NULL)					 
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
				END

				IF @tran_id = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id IS NULL
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND (bin_no IN (SELECT value 
							     FROM tdc_user_config_bins c (NOLOCK)  -- All the assigned BINs
			                                    WHERE group_id = @user_config_group 
							      AND type = 'B'
							    UNION
							   SELECT bin_no 
							     FROM tdc_bin_master (NOLOCK) -- All the assigned Bin Groups
							    WHERE group_code IN (SELECT value 
										   FROM tdc_user_config_bins c (NOLOCK)
										  WHERE group_id = @user_config_group 
										    AND type = 'G'))
					       OR bin_no IS NULL)					 
			                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, bin_no DESC, a.priority DESC, seq_no DESC
				END
			END
		END
		ELSE IF @any_bins_assigned = 'N' AND  @any_items_assigned = 'Y' 
		BEGIN
			IF (@user_assigned_items     = '<All>') OR (@user_assigned_item_groups = '<All>')
			OR (@user_assigned_resources = '<All>') OR (@user_assigned_freights    = '<All>')
			BEGIN
				IF @all_locations_assigned = 0					
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location					  
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
				ELSE
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)					  
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
			END
			ELSE IF (@user_assigned_items <> '<All>') AND (@user_assigned_items IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0					
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location					  
					   AND part_no IN (SELECT value 
							     FROM tdc_user_config_items c (NOLOCK) 
							    WHERE group_id = @user_config_group 
							      AND c.location = b.location 
							      AND type = 'I')
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND part_no IN (SELECT value 
								     FROM tdc_user_config_items c (NOLOCK) 
								    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'I')
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND part_no IN (SELECT value 
								     FROM tdc_user_config_items c (NOLOCK) 
								    WHERE group_id = @user_config_group 
								      AND c.location = b.location 
								      AND type = 'I')
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
				ELSE
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)			  
					   AND part_no IN (SELECT value 
							     FROM tdc_user_config_items c (NOLOCK) 
							    WHERE group_id = @user_config_group 
							      AND type = 'I')
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT value 
								     FROM tdc_user_config_items c (NOLOCK) 
								    WHERE group_id = @user_config_group 
								      AND type = 'I')
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT value 
								     FROM tdc_user_config_items c (NOLOCK) 
								    WHERE group_id = @user_config_group 
								      AND type = 'I')
				                 ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
			END
			ELSE IF (@user_assigned_item_groups <> '<All>') AND (@user_assigned_item_groups IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location					  
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK)
			 				    WHERE category IN (SELECT value 
									         FROM tdc_user_config_items c (NOLOCK) 
									        WHERE group_id = @user_config_group 
									          AND c.location = b.location 
									          AND type = 'G'))
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
				 				    WHERE category IN (SELECT value 
										         FROM tdc_user_config_items c (NOLOCK) 
										        WHERE group_id = @user_config_group 
										          AND c.location = b.location 
										          AND type = 'G'))
				                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
				 				    WHERE category IN (SELECT value 
										         FROM tdc_user_config_items c (NOLOCK) 
										        WHERE group_id = @user_config_group 
										          AND c.location = b.location 
										          AND type = 'G'))
				                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
				ELSE
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)			  
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK)
			 				    WHERE category IN (SELECT value 
									         FROM tdc_user_config_items c (NOLOCK) 
									        WHERE group_id = @user_config_group 
									          AND type = 'G'))
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
				 				    WHERE category IN (SELECT value 
										         FROM tdc_user_config_items c (NOLOCK) 
										        WHERE group_id = @user_config_group 
										          AND type = 'G'))
				                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
				 				    WHERE category IN (SELECT value 
										         FROM tdc_user_config_items c (NOLOCK) 
										        WHERE group_id = @user_config_group 
										          AND type = 'G'))
				                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
			END
			ELSE IF (@user_assigned_resources <> '<All>') AND (@user_assigned_resources IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0					
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location					  
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK)
			 				    WHERE type_code IN (SELECT value 
									          FROM tdc_user_config_items c (NOLOCK) 
									         WHERE group_id = @user_config_group 
									           AND c.location = b.location 
									           AND type = 'R'))
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
				 				    WHERE type_code IN (SELECT value 
										          FROM tdc_user_config_items c (NOLOCK) 
										         WHERE group_id = @user_config_group 
										           AND c.location = b.location 
										           AND type = 'R'))
				                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
				 				    WHERE type_code IN (SELECT value 
										          FROM tdc_user_config_items c (NOLOCK) 
										         WHERE group_id = @user_config_group 
										           AND c.location = b.location 
										           AND type = 'R'))
				                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
				ELSE
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)			  
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK)
			 				    WHERE type_code IN (SELECT value 
									          FROM tdc_user_config_items c (NOLOCK) 
									         WHERE group_id = @user_config_group 
									           AND type = 'R'))
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
				 				    WHERE type_code IN (SELECT value 
										          FROM tdc_user_config_items c (NOLOCK) 
										         WHERE group_id = @user_config_group 
										           AND type = 'R'))
				                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
				 				    WHERE type_code IN (SELECT value 
										          FROM tdc_user_config_items c (NOLOCK) 
										         WHERE group_id = @user_config_group 
										           AND type = 'R'))
				                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
			END
			ELSE IF (@user_assigned_freights <> '<All>') AND (@user_assigned_freights IS NOT NULL) 
			BEGIN
				IF @all_locations_assigned = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location					  
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK)
			 				    WHERE freight_class IN (SELECT value 
									              FROM tdc_user_config_items c (NOLOCK) 
									             WHERE group_id = @user_config_group 
									               AND c.location = b.location 
									               AND type = 'F'))
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
				 				    WHERE freight_class IN (SELECT value 
										              FROM tdc_user_config_items c (NOLOCK) 
										             WHERE group_id = @user_config_group 
										               AND c.location = b.location 
										               AND type = 'F'))
				                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND a.location = b.location
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
				 				    WHERE freight_class IN (SELECT value 
										              FROM tdc_user_config_items c (NOLOCK) 
										             WHERE group_id = @user_config_group 
										               AND c.location = b.location 
										               AND type = 'F'))
				                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
				ELSE
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_id
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)			  
					   AND part_no IN (SELECT part_no 
							     FROM inv_master (NOLOCK)
			 				    WHERE freight_class IN (SELECT value 
									              FROM tdc_user_config_items c (NOLOCK) 
									             WHERE group_id = @user_config_group 
									               AND type = 'F'))
			                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
		
					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id = @user_config_group
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
				 				    WHERE freight_class IN (SELECT value 
										              FROM tdc_user_config_items c (NOLOCK) 
										             WHERE group_id = @user_config_group 
										               AND type = 'F'))
				                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END

					IF @tran_id = 0
					BEGIN
						SELECT TOP 1 @tran_id = tran_id 
						  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
						 WHERE assign_group = @trans_type
						   AND assign_user_id IS NULL
						   AND tx_lock = 'R' 
						   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
						   AND part_no IN (SELECT part_no 
								     FROM inv_master (NOLOCK)
				 				    WHERE freight_class IN (SELECT value 
										              FROM tdc_user_config_items c (NOLOCK) 
										             WHERE group_id = @user_config_group 
										               AND type = 'F'))
				                ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, seq_no DESC, part_no DESC, a.priority DESC
					END
				END
			END
		END
		ELSE IF @any_bins_assigned = 'N' AND  @any_items_assigned = 'N' 
		BEGIN
			IF @all_locations_assigned = 0
			BEGIN
				SELECT TOP 1 @tran_id = tran_id 
				  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type
				   AND assign_user_id = @user_id
				   AND tx_lock = 'R' 
				   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
				   AND a.location = b.location					  
				ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, a.priority DESC, seq_no DESC
	
				IF @tran_id = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_config_group
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location
					ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, a.priority DESC, seq_no DESC
				END

				IF @tran_id = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id IS NULL
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					   AND a.location = b.location
					ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, a.priority DESC, seq_no DESC
				END
			END
			ELSE
			BEGIN
				SELECT TOP 1 @tran_id = tran_id 
				  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
				 WHERE assign_group = @trans_type
				   AND assign_user_id = @user_id
				   AND tx_lock = 'R' 
				   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)			  
				ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, a.priority DESC, seq_no DESC
	
				IF @tran_id = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id = @user_config_group
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, a.priority DESC, seq_no DESC
				END

				IF @tran_id = 0
				BEGIN
					SELECT TOP 1 @tran_id = tran_id 
					  FROM tdc_pick_queue a (NOLOCK), tdc_user_config_locations b (NOLOCK)
					 WHERE assign_group = @trans_type
					   AND assign_user_id IS NULL
					   AND tx_lock = 'R' 
					   AND tran_id NOT IN (SELECT tran_id FROM #prev_tran)
					ORDER BY (CAST(b.priority AS char (1)) + b.location) DESC, a.priority DESC, seq_no DESC
				END
			END
		END
		
		-- We've found a transaction that is assigned to the PICKER group
		IF (@tran_id != 0)
		BEGIN
			CLOSE      trans_type_assign
			DEALLOCATE trans_type_assign
		
			UPDATE tdc_pick_queue SET date_time = getdate(), [user_id] = @user_id, tx_lock = 'C' WHERE tran_id = @tran_id		
			RETURN (@tran_id)
		END
		
		FETCH NEXT FROM trans_type_assign INTO @trans_type
	END	
END

CLOSE      trans_type_assign
DEALLOCATE trans_type_assign
------------------------------------------------------------------------------------------------------------------------------

RETURN -1
GO
GRANT EXECUTE ON  [dbo].[tdc_next_q_tran_config_sp] TO [public]
GO
