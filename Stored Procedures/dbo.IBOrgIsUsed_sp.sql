SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2005 Epicor Software Corporation, 2005    
                  All Rights Reserved                    
*/                                                

CREATE PROCEDURE [dbo].[IBOrgIsUsed_sp] @org_id varchar(30), @debug int
AS
BEGIN
	IF (@org_id IS NULL OR @org_id = '')
		RETURN 0

	


	IF EXISTS (SELECT 1 FROM gltrxdet WHERE org_id = @org_id )
	BEGIN
		RETURN 1
	END 
	IF EXISTS (SELECT 1 FROM gltrx_all WHERE org_id = @org_id )
	BEGIN
		RETURN 1
	END 
	IF EXISTS (SELECT 1 FROM glrecur_all WHERE org_id = @org_id )
	BEGIN
		RETURN 1
	END 
	IF EXISTS (SELECT 1 FROM glreall_all WHERE org_id = @org_id )
	BEGIN
		RETURN 1
	END 

	IF EXISTS (SELECT 1 FROM glreadet WHERE org_id = @org_id )
	BEGIN
		RETURN 1
	END 
	IF EXISTS (SELECT 1 FROM glrecdet WHERE org_id = @org_id )
	BEGIN
		RETURN 1
	END 
	IF EXISTS (SELECT 1 FROM ibdet WHERE org_id = @org_id )
	BEGIN
		RETURN 1
	END 
	IF EXISTS (SELECT 1 FROM ibhdr WHERE controlling_org_id = @org_id OR detail_org_id = @org_id)
	BEGIN
		RETURN 1
	END 
	IF EXISTS (SELECT 1 FROM ibifc WHERE controlling_org_id = @org_id OR detail_org_id = @org_id )
	BEGIN
		RETURN 1
	END 
	IF EXISTS (SELECT 1 FROM iblink WHERE org_id = @org_id )
	BEGIN
		RETURN 1
	END 

	IF EXISTS (SELECT 1 FROM OrganizationOrganizationDef WHERE controlling_org_id = @org_id OR detail_org_id = @org_id)
	BEGIN
		RETURN 1
	END 
	IF EXISTS (SELECT 1 FROM OrganizationOrganizationRel WHERE controlling_org_id = @org_id OR detail_org_id = @org_id)
	BEGIN
		RETURN 1
	END 
	IF EXISTS (SELECT 1 FROM OrganizationOrganizationTrx WHERE controlling_org_id = @org_id OR detail_org_id = @org_id)
	BEGIN
		RETURN 1
	END 


	



	


	
	CREATE TABLE #Errors(
	errorfound smallint
	)
	IF EXISTS(SELECT 1 FROM sminstap_vw WHERE app_id = 2000 and company_id IN (SELECT company_id FROM glco) )
	BEGIN

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM artrxage WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM artrxpdt WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM artrxcdt WHERE org_id = '" +  @org_id + "'" )	
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM artrxrev WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM artrxstlhdr_all WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM arinpchg_all WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM arinpcdt WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM arinppyt_all WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM arinppdt WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM arinprev WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM arinpstlhdr WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM arnonardet WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM artrxndet WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END
	END
	




	



	IF EXISTS( SELECT 1 FROM sminstap_vw WHERE app_id = 4000 and company_id IN (SELECT company_id FROM glco) )
	BEGIN

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM aptrxage WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM apaprtrx WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM apbranch WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM apcash WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM apdmdet WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM apinpchg_all WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM apinpcdt WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM apinppyt_all WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM apinppdt WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM apinpstl WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM appadet WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM appydet WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM appystl WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM aprptvoa WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM aprptvod WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM aprptvoh WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM apvadet WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM apvodet WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END
	END
	




	


	IF EXISTS( SELECT 1 FROM sminstap_vw WHERE app_id = 10000 and company_id IN (SELECT company_id FROM glco) )
	BEGIN

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM amasset WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM amaphdr WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM amapdet WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END


		EXEC ( "INSERT INTO #Errors SELECT 1 FROM amtmplas WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM amtrxast WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM amtrxhdr WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END
	END
	



	



	IF EXISTS( SELECT 1 FROM sminstap_vw WHERE app_id = 7000 and company_id IN (SELECT company_id FROM glco) )
	BEGIN

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM cmtrx WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM cmtrxbtr WHERE from_org_id = '" +  @org_id + "' OR to_org_id = '" + @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM cmtrxdtl WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM cminpbtr WHERE from_org_id = '" +  @org_id + "' OR to_org_id = '" + @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END


		EXEC ( "INSERT INTO #Errors SELECT 1 FROM cminpdtl WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM cmmandtl WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END

		EXEC ( "INSERT INTO #Errors SELECT 1 FROM cmmanhdr WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END


		EXEC ( "INSERT INTO #Errors SELECT 1 FROM cmrechst WHERE org_id = '" +  @org_id + "'" )
		IF EXISTS (select 1 from #Errors)
		BEGIN
			DROP TABLE #Errors
			RETURN 1
		END
	END 
	



	RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[IBOrgIsUsed_sp] TO [public]
GO
