SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*                        						*/
/* This SP is used to set the status of an order / extension in ADM	*/
/*									*/
/* Given a parent it will find all unique order / ext combinations and	*/
/* call the tdc_set_status sp to update status to 'new_type'	*/
/*									*/
/* WARNING: There is probably a MUCH better way to do this, but I ran	*/
/*          out of time and am doing what works for now...		*/
/* NOTE: This SP is designed to only process a #dist_parent_status	*/
/*	 with one parent.						*/
/* NOTE: Assumes caller has verified this parent is valid 		*/
/* NOTE: Based on tdc_dist_get_all_containers stored procedure		*/
/*									*/
/* 06/26/1998	Initial		GCJ					*/
/*									*/

CREATE PROCEDURE [dbo].[tdc_update_parent_status_sp]
AS
	DECLARE @err int, @temp_child int, @done int, @new_type varchar (3), @order_no int
	DECLARE @order_ext int

	/* Initialize the error code to no errors */
	SELECT @err = 0

	/* Get new type */
	SELECT @new_type = (SELECT new_type FROM #dist_parent_status)

	/* Create temp tables */
	CREATE TABLE #children (parent int)
	CREATE TABLE #out (parent int)
	CREATE TABLE #tmp (serial_no int)
	CREATE TABLE #orders (
		order_no int NOT NULL, 
		order_ext int NOT NULL
	)

	TRUNCATE TABLE #children

	INSERT INTO #children (parent) SELECT parent_serial_no FROM #dist_parent_status

	/* Use the input table to store the values of all children */
	TRUNCATE TABLE #dist_parent_status

	WHILE EXISTS (SELECT * FROM #children)
	BEGIN
		TRUNCATE TABLE #tmp

		/* Error check */
		INSERT INTO #tmp (serial_no)
			SELECT DISTINCT p.parent
			FROM tdc_dist_group g, #children p
			WHERE	p.parent = g.parent_serial_no 
				AND g.status <> 'C' AND g.status <> 'O' AND g.status <> 'V'
				AND g.[function] = 'S'

		IF EXISTS (SELECT * FROM #tmp)
		BEGIN
			/* May need to setup a transaction to exit and rollback */
			/* here in the future. 					*/

			SELECT @err = -1

			DELETE FROM #children WHERE parent IN (SELECT * from #tmp)
		END
		
		INSERT INTO #out (parent) SELECT parent FROM #children

		TRUNCATE TABLE #tmp

		INSERT INTO #tmp (serial_no)
			SELECT DISTINCT g2.parent_serial_no 
				FROM tdc_dist_group g1, tdc_dist_group g2, #children p
				WHERE (g1.parent_serial_no = p.parent AND
					g1.child_serial_no = g2.parent_serial_no
					AND g1.[function] = 'S' 
					AND g2.[function] = 'S')
	
		TRUNCATE TABLE #children

		INSERT INTO #children (parent) SELECT serial_no FROM #tmp
	END

	/* We now have a table #out that lists the parents down the tree for the	*/
	/* root (given) parent. Find the children associated with these parents		*/

	TRUNCATE TABLE #tmp

	INSERT INTO #tmp (serial_no)
		SELECT DISTINCT child_serial_no
			FROM tdc_dist_group
			WHERE parent_serial_no IN (SELECT * FROM #out)
				AND [function] = 'S'

	/* We now have the children #tmp. Search the tdc_dist_item_pick table for	*/
	/* these children and return the unique order / ext combinations.		*/

	TRUNCATE TABLE #orders

	INSERT INTO #orders (order_no, order_ext)
		SELECT DISTINCT order_no, order_ext
			FROM tdc_dist_item_pick
			WHERE child_serial_no IN (SELECT * FROM #tmp)
			AND [function] = 'S'
			GROUP BY order_no, order_ext
	
	/* Now we have the unique order / ext combinations #orders. Update each one in	*/
	/* ADM using tdc_set_status						*/

	DECLARE order_cursor CURSOR FOR 
		SELECT order_no, order_ext FROM #orders

	OPEN order_cursor

	FETCH NEXT FROM order_cursor INTO @order_no, @order_ext
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		IF (@@FETCH_STATUS <> -2) /* Row changed */
		BEGIN
			EXEC tdc_set_status @order_no, @order_ext, @new_type
		END

		FETCH NEXT FROM order_cursor INTO @order_no, @order_ext
	END

	DEALLOCATE order_cursor
	
RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_update_parent_status_sp] TO [public]
GO
