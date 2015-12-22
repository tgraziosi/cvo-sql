SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_asn_pop_cart_combo_sp]
	@asn_no 	int, 
	@method 	varchar(2), 
	@mode 		int, 
	@cust_no 	varchar(10), 
	@cust_po	varchar(20),
	@ship_to 	varchar(10)
AS

DECLARE @cnt int

	---------------------------------------------------------------------------------------------- 
	-- Check which mode.  If Add, then show all Available cartons that are
	-- not already linked to another ASN.  If Remove, then only show those
	-- cartons tied to this ASN.
	----------------------------------------------------------------------------------------------
	IF (@mode = 1)
	  BEGIN
		SELECT DISTINCT a.carton_no 
		  FROM tdc_stage_carton a (NOLOCK) ,
		       tdc_carton_tx b
		 WHERE a.tdc_ship_flag = 'Y'
		   AND b.carton_no = a.carton_no
		   AND b.cust_code = CASE @cust_no
					WHEN '<All>' THEN b.cust_code
					ELSE @cust_no 
				     END
		   AND ISNULL(b.ship_to_no,'') = CASE ISNULL(@ship_to,'')
							WHEN '' THEN ISNULL(b.ship_to_no,'')
						 	ELSE @ship_to 
						 END
		   AND a.carton_no NOT IN (SELECT DISTINCT child_serial_no
					     FROM tdc_dist_group
					    WHERE method = @method
			   	   	      AND type = 'E1')
		   AND (ISNULL(@cust_po, '') = '' OR b.cust_po = @cust_po)
	  END
	----------------------------------------------------------------------------------------------
	-- Only those cartons linked to the ASN  
	----------------------------------------------------------------------------------------------
	ELSE	
	BEGIN
		SELECT DISTINCT child_serial_no
		  FROM tdc_dist_group (NOLOCK)
		 WHERE parent_serial_no = @asn_no
		   AND method 		= @method
		   AND type 		= 'E1'
	END


	RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_asn_pop_cart_combo_sp] TO [public]
GO
