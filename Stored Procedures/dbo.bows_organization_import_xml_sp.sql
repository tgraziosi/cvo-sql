SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                


























































CREATE PROC [dbo].[bows_organization_import_xml_sp] @debug_flag int = 0, @orgXml ntext 
AS

-- #include "STANDARD DECLARES.INC"





































DECLARE @rowcount		INT
DECLARE @error			INT
DECLARE @errmsg			VARCHAR(128)
DECLARE @log_activity		VARCHAR(128)
DECLARE @procedure_name		VARCHAR(128)
DECLARE @location		VARCHAR(128)
DECLARE @buf			VARCHAR(1000)
DECLARE @ret			INT
DECLARE @text_value		VARCHAR(255)
DECLARE @int_value		INT
DECLARE @return_value		INT
DECLARE @transaction_started	INT
DECLARE @version			VARCHAR(128)
DECLARE @len				INTEGER
DECLARE @i				INTEGER

-- end "STANDARD DECLARES.INC"


SET @procedure_name='bows_organization_import_xml_sp'

    -- #include "STANDARD ENTRY.INC"
    SET NOCOUNT ON
    SELECT @location = @procedure_name + ': Location ' + 'STANDARD ENTRY' + ', line: ' + RTRIM(LTRIM(STR(3))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
    SELECT @version='1.0'
    IF @debug_flag > 0
        BEGIN
        SELECT 'PS_SIGNAL'='DIAGNOSTIC ON'
        END
    SELECT @buf = @procedure_name + ': Entry (version ' + @version + ') at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END
    SELECT @return_value = 0, @transaction_started = 0
    -- end "STANDARD ENTRY.INC"


    	DECLARE @ret_status int, @hDoc int, @userid int,@username nvarchar(30)
	DECLARE @controlling_org_id nvarchar(15), @detail_org_id nvarchar(15)

	SELECT  @ret_status = 0, @hDoc = 0

------CREATE TEMP TABLES------

CREATE TABLE #OrganizationXML
(	OrganizationID			nvarchar(15),	
	OrganizationName		nvarchar(30),
	OrganizationActiveFlag          int,
	OrganizationOutlineNum		nvarchar(60),
	OrganizationRegionFlag		int,		
	add_flag			int
)

CREATE TABLE #OrgOrgRelXML
(	controlling_org_id		nvarchar(15),
	detail_org_id			nvarchar(15),
	sequence_id			integer,
	add_flag			int
)

------CREATE TEMP TABLES------



SELECT @location = @procedure_name + ': Location ' + 'Parse and prepare the XML document' + ', line: ' + RTRIM(LTRIM(STR(92))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
EXEC @ret_status = sp_xml_preparedocument @hDoc OUTPUT, @orgXml

    -- "STANDARD ERROR XML.INC" BEGIN
    SELECT @rowcount = @@ROWCOUNT, @error = @@ERROR
    IF @error <> 0
        BEGIN
        
    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

        IF @transaction_started > 0
            BEGIN
            ROLLBACK TRANSACTION
            END
        SELECT @buf = 'ERROR: Error number ' + RTRIM(LTRIM(STR(@error))) + ' has occured at ' + @location
        RAISERROR (@buf,16,1)
	SELECT '$FIN_RESULTS$'
	SELECT '<result>-1</result>'
	RETURN
    END


    -- "STANDARD ERROR XML.INC" END





SELECT @location = @procedure_name + ': Location ' + 'Insert data from XML to temp tables' + ', line: ' + RTRIM(LTRIM(STR(99))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO #OrganizationXML SELECT DISTINCT
	OrganizationID,
	OrganizationName,
	OrganizationActiveFlag, 
	OrganizationOutlineNum,
	OrganizationRegionFlag,			
	0
FROM OPENXML (@hDoc, '/OrganizationsDoc/Organization',2)
WITH #OrganizationXML

INSERT INTO #OrganizationXML SELECT DISTINCT
	ToOrganizationID OrganizationID,
	ToOrganizationName OrganizationName,
	ToOrganizationActiveFlag OrganizationActiveFlag, 
	ToOrganizationOutlineNum OrganizationOutlineNum,
	0,					
	0
FROM OPENXML (@hDoc, '/OrganizationsDoc/Organization/OrganizationRelationship',2)
WITH (	ToOrganizationID			nvarchar(15),	
	ToOrganizationName			nvarchar(30),
	ToOrganizationActiveFlag 	        int, 
	ToOrganizationOutlineNum 		nvarchar(60)
      )
WHERE ToOrganizationID NOT IN (SELECT OrganizationID FROM #OrganizationXML)

INSERT INTO #OrgOrgRelXML SELECT
	OrganizationID controlling_org_id,
	ToOrganizationID detail_org_id,
	0,
	0
FROM OPENXML (@hDoc, '/OrganizationsDoc/Organization/OrganizationRelationship',2)
WITH(	OrganizationID		nvarchar(15) 	'../OrganizationID',
	ToOrganizationID	nvarchar(15)	
    )

--release XML document
SELECT @location = @procedure_name + ': Location ' + 'Release XML document' + ', line: ' + RTRIM(LTRIM(STR(136))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
IF @hDoc<>0 EXEC sp_xml_removedocument @hDoc




SELECT @location = @procedure_name + ': Location ' + 'Update the relations sequence id' + ', line: ' + RTRIM(LTRIM(STR(142))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
DECLARE OrgRel SCROLL CURSOR FOR SELECT DISTINCT controlling_org_id FROM #OrgOrgRelXML order by controlling_org_id
OPEN OrgRel

FETCH OrgRel INTO @controlling_org_id

WHILE @@FETCH_STATUS = 0
BEGIN
	

	DECLARE OrgRel2 SCROLL CURSOR FOR SELECT DISTINCT detail_org_id FROM #OrgOrgRelXML WHERE controlling_org_id = @controlling_org_id
	DECLARE @sequence int
	SELECT @sequence = 1
	
	OPEN OrgRel2
	
	FETCH OrgRel2 INTO @detail_org_id

	WHILE @@FETCH_STATUS = 0
	BEGIN

		UPDATE 	#OrgOrgRelXML
		SET	sequence_id = @sequence
		WHERE	controlling_org_id 	= @controlling_org_id
		AND	detail_org_id		= @detail_org_id
	
		SELECT @sequence = @sequence + 1

		FETCH OrgRel2 INTO @detail_org_id

	END

	CLOSE OrgRel2
	DEALLOCATE OrgRel2

	FETCH OrgRel INTO @controlling_org_id

END

CLOSE OrgRel
DEALLOCATE OrgRel





UPDATE #OrganizationXML 
SET add_flag = 1
WHERE OrganizationID IN (SELECT organization_id FROM Organization)




UPDATE #OrganizationXML 
SET add_flag = 2
WHERE OrganizationOutlineNum IN (SELECT outline_num FROM Organization)


UPDATE #OrgOrgRelXML
SET add_flag = 1
WHERE controlling_org_id + detail_org_id IN (SELECT  controlling_org_id + detail_org_id FROM OrganizationOrganizationRel)




EXEC ibget_userid_sp @userid OUTPUT, @username OUTPUT




SELECT @location = @procedure_name + ': Location ' + 'Insert and update data in Organization and Organization relation tables' + ', line: ' + RTRIM(LTRIM(STR(212))) IF @debug_flag > 0 BEGIN SELECT 'PS_LOCATION'=@location END
INSERT INTO Organization( organization_id, organization_name, active_flag, outline_num, branch_account_number, new_flag, create_date, create_username, 
			  last_change_date, last_change_username, addr1, addr2, addr3, addr4, addr5, addr6, city, state, postal_code, country, tax_id_num,
			  region_flag, inherit_security, inherit_setup ) 
SELECT
	OrganizationID organization_id,
	OrganizationName organization_name,
	OrganizationActiveFlag active_flag,
	OrganizationOutlineNum outline_num,
	'',
	1,
	GETDATE(),
	@username,
	GETDATE(),
	@username,
	'',
	'',
	'',
	'',
	'',
	'',
	'',
	'',
	'',
	'',
	'',
	OrganizationRegionFlag region_flag,				
	0,
	0
FROM #OrganizationXML
WHERE add_flag = 0



EXEC IBDirectChilds_reg_sp



EXEC IBregion_all_reg_sp




UPDATE Organization 
SET 	organization_name = orgXML.OrganizationName,
	active_flag = orgXML.OrganizationActiveFlag,
	   
	last_change_date = GETDATE(),
	last_change_username = @username,
	region_flag = OrganizationRegionFlag
FROM #OrganizationXML orgXML, Organization org
WHERE orgXML.add_flag = 1	
AND orgXML.OrganizationID = org.organization_id
	



INSERT INTO OrganizationOrganizationRel SELECT
	NULL,
	controlling_org_id,
	detail_org_id,
	sequence_id,
	722815,
	GETDATE(),
	@username,
	GETDATE(),
	@username,
	0					
FROM #OrgOrgRelXML
WHERE add_flag = 0



UPDATE OrganizationOrganizationRel SET
	last_change_date = GETDATE(),
	last_change_username = @username
FROM #OrgOrgRelXML orgRelXML, OrganizationOrganizationRel orgRel
WHERE add_flag = 1
AND orgRelXML.controlling_org_id = orgRel.controlling_org_id
AND orgRelXML.detail_org_id = orgRel.detail_org_id


    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END



DROP TABLE #OrganizationXML
DROP TABLE #OrgOrgRelXML

SELECT '$FIN_RESULTS$'
SELECT '<result>0</result>'

RETURN 0
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[bows_organization_import_xml_sp] TO [public]
GO
