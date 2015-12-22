SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****************************************************************/
/* Name:	tdc_asn_rmv_mp_sp				*/
/*								*/
/* Input:							*/
/*	asn_no	-	Advanced Ship Notice (ASN)		*/
/*	pack_no	-	Master Pack Number			*/
/*	method	-	Distribution Method			*/
/*								*/
/* Output:        						*/
/*	errmsg	-	Return Error Message			*/
/*								*/
/* Description:							*/
/*	This SP will be called to remove a master pack from the	*/
/*	distribution grouping tables.				*/
/*								*/
/* Revision History:						*/
/* 	Date		Who	Description			*/
/*	----		---	-----------			*/
/* 	08/05/1999	CAC	Initial				*/
/*								*/
/****************************************************************/

CREATE PROCEDURE [dbo].[tdc_asn_rmv_mp_sp]
	(@asn_no int, @pack_no int, @method char(2), @errmsg varchar(80) OUTPUT)
AS

	/*
	 * Declare local variables 
	 */
	DECLARE @retstat	int
	DECLARE @reccnt		int
	DECLARE @language 	varchar(10)

	/* 
	 * Initialize the return status code to successful 
	 */
	SELECT @retstat = 0
	SELECT @errmsg = ''
	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

	/* 
	 * Verify that the master pack is tied to the asn. 
	 */
	SELECT @reccnt = 0
	SELECT @reccnt = count(*)
	  FROM tdc_dist_group (NOLOCK)
	 WHERE parent_serial_no = @asn_no
	   AND child_serial_no = @pack_no
	   AND method = @method
	   AND type = 'E1'

	IF (@reccnt = 0)
	   BEGIN
		SELECT @retstat = -1
	--	SELECT @errmsg = 'Master Pack Must be attached to ASN before Removing!'
 		SELECT @errmsg = err_msg 
			FROM tdc_lookup_error 
				WHERE module = 'SPR' AND trans = 'tdc_asn_rmv_mp_sp' AND err_no = -101 AND language = @language
		GOTO exitsp
	   END
 

	/* 
	 * Verify that the status is okay O - Open, C - Closed.
	 * If C, then the operator should not be allowed to remove items from the
	 * ASN.
	 */
	SELECT @reccnt = 0
	SELECT @reccnt = count(*)
	  FROM tdc_dist_group (NOLOCK)
	 WHERE parent_serial_no = @asn_no
	   AND child_serial_no = @pack_no
	   AND method = @method
	   AND type = 'E1'
	   AND status = 'O'

	IF (@reccnt = 0)
	   BEGIN
		SELECT @retstat = -1
	--	SELECT @errmsg = 'ASN has been closed, Operator must re-open to remove Master Pack!'
 		SELECT @errmsg = err_msg 
			FROM tdc_lookup_error 
				WHERE module = 'SPR' AND trans = 'tdc_asn_rmv_mp_sp' AND err_no = -102 AND language = @language
		GOTO exitsp
	   END
 

	/*
	 * Everything looks good, lets go ahead and remove the dist group record.
	 */
	DELETE FROM tdc_dist_group
	 WHERE parent_serial_no = @asn_no
	   AND child_serial_no = @pack_no
	   AND method = @method
	   AND type = 'E1'
	   AND status = 'O'

exitsp:
	RETURN @retstat
GO
GRANT EXECUTE ON  [dbo].[tdc_asn_rmv_mp_sp] TO [public]
GO
