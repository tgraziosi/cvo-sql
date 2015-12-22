SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

                                                                   
/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[get_locations_xml_sp] @from varchar(20), @to varchar(20),  @xmlDoc ntext   
AS

	IF @from = '' BEGIN
		SET @from = NULL
	END
	IF @to = '' BEGIN
		SET @to = NULL
	END

	CREATE TABLE #LocationsXML
	( 
		id			varchar(12),
		status		varchar(2)
	)
	DECLARE @ret_status int, @hDoc int
	EXEC @ret_status = sp_xml_preparedocument @hDoc OUTPUT, @xmlDoc  

	INSERT INTO #LocationsXML( 
			id, status
		)SELECT id, status 
	 FROM OPENXML(@hDoc, '/locations/location',2)
	WITH #LocationsXML

	IF NOT EXISTS (SELECT TOP 1 * FROM #LocationsXML) BEGIN
		IF CHARINDEX('%',@from,0) > 0 BEGIN
			SELECT 	location,
				name
			  FROM 	locations
			WHERE location like @from OR location like @to
		END
		ELSE BEGIN
			SELECT 	location,
				name
			  FROM 	locations
			WHERE location BETWEEN isnull(@from, (select min(location) from locations))
						and  isnull(@to, (select max(location) from locations))
		END
	END
	ELSE BEGIN
		SELECT 	location,
			name
		  FROM 	locations INNER JOIN #LocationsXML ON location = id
	END

GO
GRANT EXECUTE ON  [dbo].[get_locations_xml_sp] TO [public]
GO
