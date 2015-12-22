SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****************************************************************/
/* Name:	tdc_asn_add_mp_sp				*/
/*								*/
/* Input:							*/
/*	asn_no	-	Advanced Ship Notice Number		*/
/*	pack_no	-	Master Pack Number			*/
/*	method	-	Distribution Method			*/
/*								*/
/* Output:        						*/
/*	errmsg	-	Null if no errors.			*/
/*								*/
/* Description:							*/
/*	This SP will be called to see if the passed in master	*/
/*	pack can be added to the distribution grouping tables.  */
/*	If so, then this routine will add the record and exit   */
/*	with a status code of 0, otherwise a -1 will be 	*/
/*	returned and the @errmsg field will store the reason.	*/
/*								*/
/* Revision History:						*/
/* 	Date		Who	Description			*/
/*	----		---	-----------			*/
/* 	08/05/1999	CAC	Initial				*/
/*								*/
/****************************************************************/

CREATE PROCEDURE [dbo].[tdc_asn_add_mp_sp]
	(@asn_no int, @pack_no int, @method char(2), @errmsg varchar(80) OUTPUT)
AS

	/*
	 * Declare local variables 
	 */
	DECLARE @retstat	int
	DECLARE @reccnt		int
	DECLARE @tasn		int
	DECLARE @language 	varchar(10)

	/* 
	 * Initialize the return status code to successful 
	 */
	SELECT @retstat = 0
	SELECT @errmsg = ''
	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

	/* 
	 * Verify that the Master Pack is not already tied to another ASN 
	 */
	SELECT @tasn = isnull(parent_serial_no, 0)
	  FROM tdc_dist_group (NOLOCK)
	 WHERE child_serial_no = @pack_no
	   AND method = @method
	   AND type = 'E1'

	IF (@tasn <> 0)
	   BEGIN
		SELECT @retstat = -1
	--	SELECT @errmsg = 'Master Pack already tied to ASN: ' + convert(char(12), @tasn)
 		SELECT @errmsg = err_msg 
			FROM tdc_lookup_error 
				WHERE module = 'SPR' AND trans = 'tdc_asn_add_mp_sp' AND err_no = -101 AND language = @language
		SELECT @errmsg = @errmsg + convert(char(12), @tasn)
		GOTO exitsp
	   END


	/*
	 * Everything looks good, lets go ahead and create the dist group record.
	 */
	INSERT INTO tdc_dist_group
	   (method, type, parent_serial_no, child_serial_no, quantity, status, [function])
	VALUES
	   (@method, 'E1', @asn_no, @pack_no, 1, 'O', 'S')


exitsp:
	RETURN @retstat
GO
GRANT EXECUTE ON  [dbo].[tdc_asn_add_mp_sp] TO [public]
GO
