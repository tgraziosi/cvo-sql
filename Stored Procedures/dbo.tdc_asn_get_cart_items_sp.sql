SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****************************************************************/
/* Name:	tdc_asn_get_cart_items_sp			*/
/*								*/
/* Input:							*/
/*								*/
/* Output:        						*/
/*	errmsg	-	Null if no errors.			*/
/*								*/
/* Description:							*/
/*	This SP will be used to traverse and return the 	*/
/*	containers and it's items associated with an ASN.	*/
/*	NOTE: this procedure was cloned from			*/
/*	tdc_dist_get_container_items.				*/
/*								*/
/* Revision History:						*/
/* 	Date		Who	Description			*/
/*	----		---	-----------			*/
/* 	08/10/1999	CAC	Initial				*/
/*								*/
/****************************************************************/
CREATE PROC [dbo].[tdc_asn_get_cart_items_sp] AS

set nocount on

/*
 * Tables used internally
 */
CREATE TABLE #tmp (serial_no int)
CREATE TABLE #group_list (
	parent_serial_no int,	-- smallest container serial numbers in the tree list of
	child_serial_no int	-- containers that have the correct status
	)
CREATE TABLE #next_group_list (
	parent_serial_no int,	-- smallest container serial numbers in the tree list of
	child_serial_no int	-- containers that have the correct status
	)
/*
 * Declare/Initialize error code(s)
 */
DECLARE @err_wrong_status int,
	@warning int
SELECT	@err_wrong_status	= -1009,
	@warning		= -1000

DECLARE @return_code int
SELECT	@return_code = 0


TRUNCATE TABLE #all_containers_list
TRUNCATE TABLE #sm_containers_list
TRUNCATE TABLE #items_list
/*
 * Check for any containers that do not exist in our tdc_dist_group table.
 *
 * Generate a warning message.
 */
TRUNCATE TABLE #tmp
INSERT INTO #tmp
	SELECT DISTINCT serial_no
	FROM #int_list_in
	WHERE serial_no NOT IN (SELECT parent_serial_no from tdc_dist_group)
IF EXISTS (SELECT * FROM #tmp) BEGIN
	SELECT @return_code = @warning
	INSERT INTO #err_list_out
		SELECT @return_code, 'Container '+convert(varchar(10),serial_no)+' does not exist in the system'
		FROM #tmp
	/*
	 * Die here?  No, we will treat it as if it were a batch, allowing parallel errors
	 */
	END

/*
 * The following INSERT uses DISTINCT in case #int_list_in contains duplicate entries
 */
TRUNCATE TABLE #group_list
TRUNCATE TABLE #next_group_list
INSERT INTO #next_group_list
	SELECT DISTINCT g.parent_serial_no, g.child_serial_no
		FROM #int_list_in i, tdc_dist_group g
		WHERE i.serial_no = g.parent_serial_no


/*
 * Traverse the tdc_dist_group tree, collecting the next level of containers as we go
 * on our merry way
 */
WHILE EXISTS (SELECT * FROM #next_group_list) 
	BEGIN
		/*
		 * These containers are accepted--use them for our smallest container so far.
		 */
		TRUNCATE TABLE #group_list
		INSERT INTO #group_list
			SELECT * FROM #next_group_list

		/*
	 	 * ...And for our cumulative list of all containers.
	 	 */
		INSERT INTO #all_containers_list
			SELECT DISTINCT parent_serial_no FROM #next_group_list

		/*
		 * Get the next tree level (if it exists)
		 */
		TRUNCATE TABLE #next_group_list
		INSERT INTO #next_group_list
			SELECT g.parent_serial_no, g.child_serial_no
			  FROM tdc_dist_group g, #group_list l
			 WHERE g.parent_serial_no = l.child_serial_no
	END

/*
 * Now assign the group list to our output containers list
 */
INSERT INTO #sm_containers_list
	SELECT * FROM #group_list

INSERT INTO #items_list
	SELECT DISTINCT p.child_serial_no
		FROM tdc_dist_item_pick p, #group_list g
		WHERE p.child_serial_no = g.child_serial_no

RETURN @return_code
GO
GRANT EXECUTE ON  [dbo].[tdc_asn_get_cart_items_sp] TO [public]
GO
