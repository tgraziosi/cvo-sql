SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*                        						*/
/* This SP is used to undo a Ship Verify Transaction.			*/
/*									*/
/* Given a parent it will find all decendants and change their status	*/
/* from V to C.								*/
/*									*/
/* NOTE: This SP is designed to only process a #dist_un_verify with	*/
/*	 one parent.							*/
/* NOTE: Assumes caller has verified this parent is valid for an	*/
/*	 Un_verify transaction						*/
/* NOTE: Based on tdc_dist_get_all_containers stored procedure		*/
/*									*/
/* 06/25/1998	Initial		GCJ					*/
/*									*/

CREATE PROCEDURE [dbo].[tdc_un_ship_verify_sp]
AS
	DECLARE @err int, @temp_child int, @done int

	/* Initialize the error code to no errors */
	SELECT @err = 0

	/* Create temp tables */
	CREATE TABLE #parents (parent int)
	CREATE TABLE #tmp (serial_no int)

	TRUNCATE TABLE #parents

	INSERT INTO #parents (parent) SELECT parent_serial_no FROM #dist_un_verify

	EXEC @err = tdc_search_order_no 	
	IF (@err < 0)
	BEGIN
		RETURN @err
	END

	/* Use the input table to store the values of all children */
	TRUNCATE TABLE #dist_un_verify

	WHILE EXISTS (SELECT * FROM #parents)
	BEGIN
		TRUNCATE TABLE #tmp

		INSERT INTO #tmp (serial_no)
			SELECT DISTINCT p.parent
			FROM tdc_dist_group g, #parents p
			WHERE	p.parent = g.parent_serial_no AND g.status <> 'V' AND g.[function] = 'S'

		IF EXISTS (SELECT * FROM #tmp)
		BEGIN
			/* May need to setup a transaction to exit and rollback */
			/* here in the future. 					*/

			SELECT @err = -1

			DELETE FROM #parents WHERE parent IN (SELECT * from #tmp)
		END
		
		UPDATE tdc_dist_group SET status = 'C' WHERE [function] = 'S' AND parent_serial_no IN (SELECT parent FROM #parents)

		TRUNCATE TABLE #tmp

		INSERT INTO #tmp (serial_no)
			SELECT DISTINCT g2.parent_serial_no 
				FROM tdc_dist_group g1, tdc_dist_group g2, #parents p
				WHERE (g1.parent_serial_no = p.parent AND
					g1.child_serial_no = g2.parent_serial_no
					AND g1.[function] = 'S' AND g2.[function] = 'S')
	
		TRUNCATE TABLE #parents

		INSERT INTO #parents (parent) SELECT serial_no FROM #tmp
	END

DROP TABLE #parents
DROP TABLE #tmp
	
RETURN @err
GO
GRANT EXECUTE ON  [dbo].[tdc_un_ship_verify_sp] TO [public]
GO
