SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****************************************************************/
/* Name:	tdc_asn_add_carton_sp				*/
/*								*/
/* Input:							*/
/*	asn_no	-	Advanced Ship Notice Number		*/
/*	carton	-	Carton Number				*/
/*	method	-	Distribution Method			*/
/*								*/
/* Output:        						*/
/*	errmsg	-	Null if no errors.			*/
/*								*/
/* Description:							*/
/*	This SP will be called to see if the passed in carton	*/
/*	can be added to the distribution grouping tables.  If	*/
/*	so, then this routine will add the record and exit with */
/*	a status code of 0, otherwise a -1 will be returned and */
/*	the @errmsg field will store the reason.		*/
/*								*/
/* Revision History:						*/
/* 	Date		Who	Description			*/
/*	----		---	-----------			*/
/* 	08/05/1999	CAC	Initial				*/
/*								*/
/****************************************************************/

CREATE PROCEDURE [dbo].[tdc_asn_add_carton_sp]
	@asn_no int, @carton int, @method char(2), @errmsg varchar(80) OUTPUT 
AS

	/*
	 * Declare local variables 
	 */
	DECLARE @retstat	int
	DECLARE @reccnt		int
	DECLARE @tasn		int
	DECLARE @stat		varchar(1)


	/* 
	 * Initialize the return status code to successful 
	 */
	SELECT @retstat = 0
	SELECT @tasn	= 0
	SELECT @stat	= ''
	SELECT @errmsg = ''


	/* 
	 * Verify that the carton has been Staged. 
	 */
	SELECT @reccnt = 0
	SELECT @reccnt = count(*)
	  FROM tdc_stage_carton (NOLOCK)
	 WHERE carton_no = @carton

	IF (@reccnt = 0)
	   BEGIN
		SELECT @retstat = -1
		SELECT @errmsg = 'Carton Must be staged!'
		GOTO exitsp
	   END
 

	/* 
	 * Verify that the carton has been Staged and Ship Confirmed. 
	 */
	SELECT @reccnt = 0
	SELECT @reccnt = count(*)
	  FROM tdc_stage_carton (NOLOCK)
	 WHERE carton_no = @carton
	   AND tdc_ship_flag = 'Y'

	IF (@reccnt = 0)
	   BEGIN
		SELECT @retstat = -2
		SELECT @errmsg = 'Carton Must be ship confirmed!'
		GOTO exitsp
	   END

	/* 
	 * Verify that the carton is not already tied to another ASN 
	 */
	SELECT @tasn = isnull(parent_serial_no, 0)
	  FROM tdc_dist_group (NOLOCK)
	 WHERE child_serial_no = @carton
	   AND method = @method
	   AND type = 'E1'

	IF (@tasn <> 0)
	   BEGIN
		SELECT @retstat = -3
		SELECT @errmsg = 'Carton already tied to ASN: ' + convert(char(12), @tasn)
		GOTO exitsp
	   END

	/* 
	 * Verify that the ASN is Open.
	 */
	/* Remove Isnull function. Isnull function only works if record exists 	*/
	/* and the retrieved value is NULL.  If there is no record, Isnull does */
	/* not work - dsu 							*/
	SELECT @stat = status
	  FROM tdc_dist_group (NOLOCK)
	 WHERE parent_serial_no = @asn_no
	   AND method = @method
	   AND type = 'E1'

	IF @stat = ''
		SELECT @stat = 'O'

	IF (@stat = 'C')
	   BEGIN
		SELECT @retstat = -4
		SELECT @errmsg = 'ASN Closed, You will need to re-open!'
		GOTO exitsp
	   END

	IF (@stat <> 'O')
	   BEGIN
		SELECT @retstat = -5
		SELECT @errmsg = 'ERR: Invalid Status: ' + @stat
		GOTO exitsp
	   END
	


	/*
	 * Everything looks good, lets go ahead and create the dist group record.
	 */
	INSERT INTO tdc_dist_group
	   (method, type, parent_serial_no, child_serial_no, quantity, status, [function])
	VALUES
	   (@method, 'E1', @asn_no, @carton, 1, 'O', 'S')


exitsp:
	RETURN @retstat
GO
GRANT EXECUTE ON  [dbo].[tdc_asn_add_carton_sp] TO [public]
GO
