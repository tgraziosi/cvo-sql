SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****************************************************************/
/* Name:	tdc_asn_is_cart_mp_sp				*/
/*								*/
/* Input:							*/
/*	pack_no	-	Master Pack Number			*/
/*	method	-	Distribution Method			*/
/*								*/
/* Output:        						*/
/*								*/
/* Description:							*/
/*	This SP will be called to see if the passed in master   */
/*      pack is located in the distribution grouping tables.	*/
/*								*/
/* Revision History:						*/
/* 	Date		Who	Description			*/
/*	----		---	-----------			*/
/* 	08/05/1999	CAC	Initial				*/
/*								*/
/****************************************************************/

CREATE PROCEDURE [dbo].[tdc_asn_is_cart_mp_sp]
	(@pack_no int, @method char(2))
AS

	/*
	 * Declare local variables 
	 */
	DECLARE @retstat	int
	DECLARE @reccnt		int


	/* 
	 * Initialize the return status code to successful 
	 */
	SELECT @retstat = 0


 	/* 
	 * NOTE:  For Master Pack, we will make assumption always rule S1 for Staging.
	 */
	SELECT @reccnt = 0
	SELECT @reccnt = count(*)
	  FROM tdc_dist_group (NOLOCK)
	 WHERE parent_serial_no = @pack_no
	   AND method = @method
	   AND type = 'S1'
	   AND status = 'O'

	IF (@reccnt = 0)
	   BEGIN
		SELECT @retstat = -1
		GOTO exitsp
	   END
 
exitsp:
	RETURN @retstat
GO
GRANT EXECUTE ON  [dbo].[tdc_asn_is_cart_mp_sp] TO [public]
GO
