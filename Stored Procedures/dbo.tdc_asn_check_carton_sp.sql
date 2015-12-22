SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****************************************************************/
/* Name:	tdc_asn_check_carton_sp				*/
/*								*/
/* Input:							*/
/*	carton	-	Carton Number				*/
/*	method	-	Distribution Method			*/
/*								*/
/* Output:        						*/
/*	return status - 	1 = carton tied to some ASN.	*/
/*				0 = carton not tied to any ASN. */
/*								*/
/* Description:							*/
/*	This SP will be called to see if the passed in carton	*/
/*	is linked to any ASN.					*/
/*								*/
/* Revision History:						*/
/* 	Date		Who	Description			*/
/*	----		---	-----------			*/
/* 	08/09/1999	CAC	Initial				*/
/*								*/
/****************************************************************/

CREATE PROCEDURE [dbo].[tdc_asn_check_carton_sp]
	(@carton int, @method char(2))
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
	 * Check to see if carton is tied to an asn. 
	 */
	SELECT @reccnt = 0
	SELECT @reccnt = count(*)
	  FROM tdc_dist_group (NOLOCK)
	 WHERE child_serial_no = @carton
	   AND method = @method
	   AND type = 'E1'

	IF (@reccnt = 0)
	   BEGIN
		SELECT @retstat = 0	/* Not tied to an ASN */
	   END
	ELSE
	   BEGIN
		SELECT @retstat = 1	/* Carton tied to an ASN. */
	   END
 


exitsp:
	RETURN @retstat
GO
GRANT EXECUTE ON  [dbo].[tdc_asn_check_carton_sp] TO [public]
GO
