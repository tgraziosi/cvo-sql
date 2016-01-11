
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_move_into_backup_tables]
AS


CREATE TABLE #temp_table1(
	parent INT NOT NULL,
	child INT NOT NULL,
	type VARCHAR(2) NOT NULL
)

CREATE TABLE #temp_table2(
	parent_id INT NOT NULL,
	child_id INT NOT NULL,
	type VARCHAR(2) NOT NULL
)

CREATE TABLE #xfer_no(
	xfer_no INT NOT NULL
)


TRUNCATE TABLE #temp_table1
TRUNCATE TABLE #temp_table2
TRUNCATE TABLE #xfer_no

DECLARE @xfer_no INT, @type VARCHAR(2)
DECLARE @parent INT, @child INT 

-- cvo
RETURN 0

INSERT INTO #xfer_no (xfer_no) SELECT DISTINCT p.order_no FROM xfers x (nolock), tdc_dist_item_pick p (nolock) WHERE x.xfer_no = p.order_no AND x.status = 'S' AND p.[function] = 'T'	

IF NOT EXISTS (SELECT * FROM #xfer_no)
	RETURN 0

DECLARE back_up CURSOR FOR SELECT xfer_no FROM #xfer_no 

OPEN back_up
FETCH NEXT FROM back_up INTO @xfer_no

WHILE (@@FETCH_STATUS = 0)
BEGIN
	/* take care of the pick ship verify order */
	IF NOT EXISTS (SELECT * FROM tdc_dist_group g (nolock), tdc_dist_item_pick i (nolock)
			WHERE g.child_serial_no = i.child_serial_no
			AND g.[function] = 'T' AND i.[function] = 'T' 
			AND i.order_no = @xfer_no AND i.method = g.method)
	BEGIN
		INSERT INTO tdc_bkp_dist_item_pick (method, order_no, order_ext, line_no, part_no, lot_ser, bin_no, 
					quantity, child_serial_no, [function], type, status, bkp_status, bkp_date)
			SELECT method,order_no,order_ext, line_no, part_no, lot_ser, bin_no, 
					quantity, child_serial_no, [function], type, status, 'C', GETDATE() 
							FROM tdc_dist_item_pick (nolock)
							WHERE order_no = @xfer_no AND [function] = 'T' 
		DELETE tdc_tote_bin_tbl FROM tdc_tote_bin_tbl a, tdc_dist_item_pick b
		WHERE a.order_no = b.order_no AND a.order_type = b.[function] AND a.line_no = b.line_no
		AND a.part_no = b.part_no
		DELETE FROM tdc_dist_item_pick WHERE order_no = @xfer_no AND [function] = 'T'



		INSERT INTO tdc_bkp_dist_item_list (order_no, order_ext, line_no, part_no, quantity, shipped,
 				[function], bkp_status, bkp_date)
		 	SELECT order_no, order_ext, line_no, part_no, quantity, shipped, [function],'C', GETDATE() 
							FROM tdc_dist_item_list (nolock)
							WHERE order_no = @xfer_no AND [function] = 'T' 
		DELETE FROM tdc_dist_item_list WHERE order_no = @xfer_no AND [function] = 'T'
	END
	ELSE
	BEGIN
		INSERT INTO #temp_table1 (parent, child, type) 
			SELECT DISTINCT g.parent_serial_no, g.child_serial_no, g.type
			FROM tdc_dist_group g (nolock), tdc_dist_item_pick i (nolock)
			WHERE g.child_serial_no = i.child_serial_no
			AND g.[function] = 'T' AND i.[function] = 'T' AND i.order_no = @xfer_no 

		WHILE EXISTS (SELECT parent_serial_no 
				FROM tdc_dist_group (nolock)
				WHERE child_serial_no IN (SELECT DISTINCT parent FROM #temp_table1) 
				AND [function] = 'T')
		BEGIN
			INSERT INTO #temp_table2 (parent_id, child_id, type)
				SELECT DISTINCT parent_serial_no, child_serial_no, type
						FROM tdc_dist_group (nolock)	
						WHERE child_serial_no IN (SELECT DISTINCT parent FROM #temp_table1)
						AND [function] = 'T'

			DELETE FROM #temp_table2 WHERE parent_id IN (SELECT DISTINCT parent FROM #temp_table1)
							AND child_id IN (SELECT DISTINCT child FROM #temp_table1)

			IF EXISTS (SELECT * FROM #temp_table2)
					INSERT INTO #temp_table1 (parent, child, type)
					SELECT parent_id, child_id, type FROM #temp_table2
			ELSE 
					BREAK
		END

		INSERT INTO tdc_bkp_dist_item_pick (method, order_no, order_ext, line_no, part_no, lot_ser, bin_no, 
					quantity, child_serial_no, [function], type, status, bkp_status, bkp_date)
				SELECT method,order_no,order_ext, line_no, part_no, lot_ser, bin_no, 
					quantity, child_serial_no, [function], type, status, 'C', GETDATE() 
							FROM tdc_dist_item_pick (nolock)
							WHERE order_no = @xfer_no AND [function] = 'T' 
		DELETE FROM tdc_dist_item_pick WHERE order_no = @xfer_no AND [function] = 'T' 

		INSERT INTO tdc_bkp_dist_item_list (order_no, order_ext, line_no, part_no, quantity, shipped,
 				[function], bkp_status, bkp_date)
		 	SELECT order_no, order_ext, line_no, part_no, quantity, shipped, [function],'C', GETDATE()  
							FROM tdc_dist_item_list (nolock)
							WHERE order_no = @xfer_no AND [function] = 'T' 
		DELETE FROM tdc_dist_item_list WHERE order_no = @xfer_no AND [function] = 'T'

		DECLARE back_up_group CURSOR FOR
				SELECT parent, child, type FROM #temp_table1 

		OPEN back_up_group
		FETCH NEXT FROM back_up_group INTO @parent, @child, @type

		WHILE (@@FETCH_STATUS = 0)
		BEGIN

			INSERT INTO tdc_bkp_dist_group (method, type, parent_serial_no, child_serial_no, quantity,  
				status, [function], bkp_status, bkp_date)
				SELECT method, type, parent_serial_no, child_serial_no, quantity, status, [function], 'C', GETDATE() 
							FROM tdc_dist_group (nolock)
							WHERE child_serial_no = @child   
							AND parent_serial_no = @parent
							AND [function] = 'T' AND type = @type 

			DELETE FROM tdc_dist_group 	WHERE child_serial_no = @child   
							AND parent_serial_no = @parent
							AND [function] = 'T' AND type = @type 

			FETCH NEXT FROM back_up_group INTO @parent, @child, @type
		END

		CLOSE back_up_group
		DEALLOCATE back_up_group
	END
	FETCH NEXT FROM back_up INTO @xfer_no
END

CLOSE back_up
DEALLOCATE back_up

RETURN 0


GO

GRANT EXECUTE ON  [dbo].[tdc_move_into_backup_tables] TO [public]
GO
