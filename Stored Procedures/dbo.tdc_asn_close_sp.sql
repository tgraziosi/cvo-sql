SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****************************************************************/
/* Name:	tdc_asn_close_sp				*/
/*								*/
/* Input:							*/
/*	asn_no	-	Advanced Ship Notice (ASN)		*/
/*								*/
/* Output:        						*/
/*	errmsg	-	Return Error Message			*/
/*								*/
/* Description:							*/
/*	This SP will be called to close an open ASN.		*/
/*								*/
/* Revision History:						*/
/* 	Date		Who	Description			*/
/*	----		---	-----------			*/
/* 	08/09/1999	CAC	Initial				*/
/*								*/
/****************************************************************/

CREATE PROCEDURE [dbo].[tdc_asn_close_sp]
	(@asn_no int, @method char(2), @errmsg varchar(80) OUTPUT)
AS

	/*
	 * Declare local variables 
	 */
	DECLARE @retstat	int
	DECLARE @reccnt		int
	DECLARE @stat		varchar(1)
	DECLARE @language 	varchar(10)

	/* 
	 * Initialize the return status code to successful 
	 */
	SELECT @retstat = 0
	SELECT @errmsg = ''
	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

	/* 
	 * Verify that the ASN status is O - Open before attempting to close.
	 */
IF (SELECT COUNT(*) FROM tdc_dist_group (NOLOCK) 
	WHERE parent_serial_no = @asn_no
	   AND method = @method
	   AND type = 'E1') = 0
	BEGIN
		SELECT @stat =  'Z'
	END
ELSE
	BEGIN
		SELECT @stat = ISNULL(status,'Z')
	  	FROM tdc_dist_group (NOLOCK)
	 	WHERE parent_serial_no = @asn_no
	   	AND method = @method
	   	AND type = 'E1'

	END



	/* ASN not found, send error message to user. */
	IF (@stat = 'Z')
	   BEGIN
		SELECT @retstat = -1
	--	SELECT @errmsg = 'ASN Does Not Exist, Can Not Close!'
 		SELECT @errmsg = err_msg 
			FROM tdc_lookup_error 
				WHERE module = 'SPR' AND trans = 'tdc_asn_close_sp' AND err_no = -101 AND language = @language
		GOTO exitsp
	   END

	/* ASN already closed, notify user. */
	IF (@stat = 'C')
	   BEGIN
		SELECT @retstat = -1
	--	SELECT @errmsg = 'ASN Already Closed!'
 		SELECT @errmsg = err_msg 
			FROM tdc_lookup_error 
				WHERE module = 'SPR' AND trans = 'tdc_asn_close_sp' AND err_no = -102 AND language = @language
		GOTO exitsp
	   END
 
	/* Everything O.K., go ahead and close out the ASN. */
	IF (@stat = 'O')
	   BEGIN
		BEGIN TRANSACTION
			UPDATE tdc_dist_group
		   	   SET status = 'C'
			 WHERE parent_serial_no = @asn_no
			SELECT @retstat = 0
		COMMIT TRANSACTION
		GOTO exitsp
	   END

	/* Unrecognized dist group status for ASN type = 'E1', flag error... */
	SELECT @retstat = -1
	--	SELECT @errmsg = 'Unrecognized ASN status code: ' + @stat
 	SELECT @errmsg = err_msg 
		FROM tdc_lookup_error 
			WHERE module = 'SPR' AND trans = 'tdc_asn_close_sp' AND err_no = -103 AND language = @language
	SELECT @errmsg = @errmsg + @stat
exitsp:
	
	RETURN @retstat
GO
GRANT EXECUTE ON  [dbo].[tdc_asn_close_sp] TO [public]
GO
