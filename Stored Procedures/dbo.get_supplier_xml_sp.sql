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


                                        
CREATE PROC [dbo].[get_supplier_xml_sp] @from varchar(20), @to varchar(20), @companyCode varchar(20), @xmlDoc ntext   
AS



		DECLARE @db_name varchar(20), @STR varchar(500)
		SELECT @db_name = db_name 
		FROM CVO_Control..smcomp WHERE company_id = @companyCode

	CREATE TABLE #SuppliersXML
	( 
		id			varchar(12),
		status		varchar(2)
	)
	DECLARE @ret_status int, @hDoc int
	EXEC @ret_status = sp_xml_preparedocument @hDoc OUTPUT, @xmlDoc, '<suppliers xmlns:x="http://Epicor.com/BackOfficeAP/GetSuppliersRequest" />'

	INSERT INTO #SuppliersXML(id, status)
	SELECT id, status 
	 FROM OPENXML(@hDoc, "/x:suppliers/x:supplier",2)
	WITH (	id varchar(12) "./x:id",
			status varchar(2) "./x:status")

	IF NOT EXISTS (SELECT TOP 1 * FROM #SuppliersXML) BEGIN

		IF CHARINDEX("%",@from,0) > 0 BEGIN
				SET @STR = @db_name + "..get_supplier_org_xml_sp '" + @from + "','"+ @to + "',1"
				EXEC (@STR)
		END
		ELSE BEGIN
				SET @STR = @db_name + "..get_supplier_org_xml_sp '" + @from + "','"+ @to + "',2"
				EXEC (@STR)				
		END
	END
	ELSE BEGIN
				SET @STR = @db_name + "..get_supplier_org_xml_sp '" + @from + "','"+ @to + "',3"
				EXEC (@STR)		
	END



GO
GRANT EXECUTE ON  [dbo].[get_supplier_xml_sp] TO [public]
GO
