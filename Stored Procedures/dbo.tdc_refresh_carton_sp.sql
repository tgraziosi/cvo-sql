SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*   JVC Pack Verification.  This procedure will refresh the      */
/*   Carton Header record information in case the operator has    */
/*   made updates to the Order via Platinum interface. (i.e.      */
/*   ship_to_zip, ...						  */
/*								  */
/*								  */
/* 10/18/1998	Initial		CAC				  */
/*								  */

CREATE PROCEDURE [dbo].[tdc_refresh_carton_sp]
  @carton_no	int
AS
	/* Declare local variables */
	DECLARE @cnt 		int
	DECLARE @tcust_code 	varchar(10)
	DECLARE @tcust_po 	varchar(20)
	-- DECLARE @tcarrier_code 	varchar(20)
	DECLARE @tship_to_no 	varchar(10)
	DECLARE @tname 		varchar(40)
	DECLARE @tadr1 		varchar(40)
	DECLARE @tadr2 		varchar(40)
	DECLARE @tadr3 		varchar(40)
	DECLARE @tcity 		varchar(40)
	DECLARE @tstate 	varchar(40)
	DECLARE @tcountry 	varchar(40)
	DECLARE @tzip 		varchar(10)
	DECLARE @tattention 	varchar(40)
	DECLARE @tbill_to_key 	varchar(10)


	SELECT @cnt = 0

	SELECT @tcust_code = ''
	SELECT @tcust_po = ''
	-- SELECT @tcarrier_code = ''
	SELECT @tship_to_no = ''
	SELECT @tname = ''
	SELECT @tadr1 = ''
	SELECT @tadr2 = '' 
	SELECT @tadr3 = ''
	SELECT @tcity = ''
	SELECT @tstate = ''
	SELECT @tzip = ''
	SELECT @tcountry = ''
	SELECT @tattention = ''
	SELECT @tbill_to_key = ''
       
	
	SELECT @tcust_code 	= o.cust_code,
	       @tcust_po 	= o.cust_po,
	       -- @tcarrier_code 	= o.routing,
	       @tship_to_no 	= o.ship_to,
	       @tname 		= o.ship_to_name,
	       @tadr1 		= o.ship_to_add_1,
	       @tadr2 		= o.ship_to_add_2, 
	       @tadr3 		= o.ship_to_add_3,
	       @tcity 		= o.ship_to_city,
	       @tstate 		= o.ship_to_state,
	       @tzip 		= o.ship_to_zip,
	       @tcountry 	= o.ship_to_country,
	       @tattention 	= o.attention,
	       @tbill_to_key 	= o.bill_to_key       
	  FROM orders o, tdc_carton_tx tc
	 WHERE o.order_no = tc.order_no
	   AND o.ext = tc.order_ext
	   AND tc.carton_no = @carton_no

	/* Perform the refresh */
	UPDATE tdc_carton_tx
		set	cust_code 	= @tcust_code,
			cust_po 	= @tcust_po,
			-- carrier_code 	= @tcarrier_code,
			ship_to_no 	= @tship_to_no,
			[name] 		= @tname,
			address1 	= @tadr1,
			address2 	= @tadr2,
			address3 	= @tadr3,
			city 		= @tcity,
			state 		= @tstate, 
			zip 		= @tzip,
			country 	= @tcountry,
			attention 	= @tattention,
			bill_to_key 	= @tbill_to_key			
	 WHERE carton_no = @carton_no

RETURN @@error
GO
GRANT EXECUTE ON  [dbo].[tdc_refresh_carton_sp] TO [public]
GO
