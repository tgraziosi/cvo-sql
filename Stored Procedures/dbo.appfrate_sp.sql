SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\appfrate.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROCEDURE	[dbo].[appfrate_sp]	@freight_code varchar(8),
					@dest_zone varchar(8),
					@org_loc varchar(8),
					@weight float,
					@action smallint				
AS

DECLARE	@iv_flag smallint, @org_zone varchar(8), @orig_zone_code varchar(8),
	@freight_amt float, @result float

SELECT	@orig_zone_code = NULL, @result = 0

IF	@action = 1
BEGIN
	
	SELECT	@orig_zone_code = ""

 	SELECT @orig_zone_code
	
	RETURN
END	

IF @dest_zone IS NULL OR @freight_code IS NULL 
 OR @weight = 0 OR @org_loc = ""
BEGIN
	SELECT @result
	RETURN
END

SELECT	@freight_amt = NULL

SELECT	@freight_amt = MIN ( freight_amt )
FROM	arfrate
WHERE	freight_code = @freight_code
AND	orig_zone_code = @org_loc
AND	@dest_zone BETWEEN from_dest_zone_code AND thru_dest_zone_code
AND	max_weight >= @weight

IF @freight_amt IS NULL
	SELECT @result
ELSE
	SELECT @freight_amt

RETURN


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[appfrate_sp] TO [public]
GO
