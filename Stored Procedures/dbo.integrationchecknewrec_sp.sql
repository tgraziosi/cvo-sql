SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/

CREATE PROCEDURE [dbo].[integrationchecknewrec_sp]
AS
BEGIN
	DECLARE @pathout VARCHAR(8000), @pathtemp VARCHAR(8000)

	IF( ( SELECT COUNT(id_code) FROM epintegrationrecs WHERE type BETWEEN 1 AND 6 ) > 0 )
	BEGIN
		SELECT @pathtemp = inpath 
		FROM epconfig

		SELECT @pathout = outpath 
		FROM epconfig
	END

	IF( ( SELECT COUNT(id_code) FROM epintegrationrecs WHERE type = 1 ) > 0 )
	BEGIN							
		EXEC doxml_sp @pathout, @pathtemp, 'requestSuppliers', 'supplier', 1
	END

	IF( ( SELECT COUNT(id_code) FROM epintegrationrecs WHERE type = 2 ) > 0 )
	BEGIN	
		EXEC doxml_sp @pathout, @pathtemp, 'requestInventory', 'item', 2
	END

	IF( ( SELECT COUNT(id_code) FROM epintegrationrecs WHERE type = 3 ) > 0 )
	BEGIN			
		EXEC doxml_sp @pathout, @pathtemp, 'requestLocations', 'location', 3
	END

	IF( ( SELECT COUNT(id_code) FROM epintegrationrecs WHERE type BETWEEN 4 AND 6 ) > 0 )
	BEGIN			
		EXEC doxml_sp @pathout, @pathtemp, 'requestAccountsLive', 'root', 4
	END
END

GRANT EXECUTE ON integrationchecknewrec_sp TO PUBLIC

GO
GRANT EXECUTE ON  [dbo].[integrationchecknewrec_sp] TO [public]
GO
