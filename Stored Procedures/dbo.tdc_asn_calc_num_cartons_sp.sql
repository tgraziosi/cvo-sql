SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****************************************************************/
/* Name:	tdc_asn_calc_num_cartons_sp			*/
/*								*/
/* Input:							*/
/*	asn_no	-	Advanced Ship Notice Number		*/
/*	method	-	Distribution Method			*/
/*								*/
/* Output:        						*/
/*	status	-	Carton Count				*/
/*								*/
/* Description:							*/
/*	This SP will be called to calculate the number of 	*/
/*	cartons associated with this ASN.  This SP will need to */
/* 	be coded to handle Master Packs in future releases.	*/
/*								*/
/* Revision History:						*/
/* 	Date		Who	Description			*/
/*	----		---	-----------			*/
/* 	08/10/1999	CAC	Initial				*/
/*								*/
/****************************************************************/

CREATE PROCEDURE [dbo].[tdc_asn_calc_num_cartons_sp]
	(@asn_no int, @method char(2))
AS

	/*
	 * Declare local variables 
	 */
	DECLARE @carton_cnt	int


	/* Initialize carton count. */
	SELECT @carton_cnt = 0


	/* 
	 * Calculate the number of cartons.  For now, this statement assumes
	 * that Master Packs are not being used (i.e. a single level link between
	 * the ASN and cartons).  Future releases should include Master Pack functionality.
	 */
	SELECT @carton_cnt = count(*)
	  FROM tdc_dist_group (NOLOCK)
	 WHERE parent_serial_no = @asn_no
	   AND method = @method
	   AND type = 'E1'


	RETURN @carton_cnt
GO
GRANT EXECUTE ON  [dbo].[tdc_asn_calc_num_cartons_sp] TO [public]
GO
