SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                




























	
CREATE PROC [dbo].[bows_organization_export_xml_sp]
	@debug_flag 	int
AS
-->>>======================Init===========================

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

DECLARE @hDoc int
DECLARE @ret_status int
SELECT @hDoc = 0, @ret_status = 0
SET @procedure_name = 'ibifcws_sp'

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


-->>>=================Form Resulting XML==================
SELECT '$FIN_RESULTS$' --Keyword for the result parser

SELECT '<OrganizationsDoc>'

SELECT  
	Organization.organization_id as ID,
	Organization.organization_name as Name,
	Organization.active_flag as ActiveFlag,
	Organization.outline_num as OutlineNum,
	Organization.region_flag as RegionFlag,
	Organization.branch_account_number as BranchAccountNumber,
	Organization.new_flag as NewFlag,
	Organization.addr1 as Address1,
	Organization.addr2 as Address2,
	Organization.addr3 as Address3,
	Organization.addr4 as Address4,
	Organization.addr5 as Address5,
	Organization.addr6 as Address6, 
	Organization.city,
	Organization.state,
	Organization.postal_code as PostalCode,
	Organization.country as Country,
	Organization.tax_id_num as TaxIDNum
FROM Organization_all Organization 
for xml auto, elements

SELECT '</OrganizationsDoc>'

-->>>==========================End========================



    -- "STANDARD EXIT.INC" BEGIN
    SELECT @buf = @procedure_name + ': Exit at ' + CONVERT(CHAR(20),GETDATE())
    IF @debug_flag > 0
        BEGIN
        SELECT @buf
        END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[bows_organization_export_xml_sp] TO [public]
GO
