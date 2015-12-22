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

CREATE PROCEDURE [dbo].[InterBranchAccts_reg_sp]
AS

IF NOT EXISTS(SELECT 1 FROM Organization_all )
BEGIN
	RETURN 0
END

IF NOT EXISTS(SELECT 1 FROM Organization_all WHERE outline_num = '1')
BEGIN
	RAISERROR ('Company Database has no outline_num equal to 1.', 16, 1)
	RETURN 0
END



DECLARE @buf varchar(8000)
DECLARE @buf2 varchar(8000)
DECLARE @company_code varchar(8)
DECLARE @ib_segment  int
DECLARE @ib_offset  int
DECLARE @ib_length int
DECLARE @root_org varchar(30)
DECLARE @ib_flag smallint

SELECT @company_code=company_code,@ib_segment =ib_segment, @ib_offset =ib_offset, @ib_length =ib_length, @ib_flag = ib_flag 
FROM glco


IF @company_code is null or @company_code = ''
BEGIN
	RAISERROR ('glco.company_code field is null or empty.', 16, 1)
	RETURN 0
END 
 
IF (@ib_segment = 0 AND (@ib_flag = 1 OR @ib_flag = 2))
BEGIN
	RAISERROR ('ib_segment expects greater than 0 when ib_flag is 1 or 2.', 16, 1)
	RETURN 0
END

IF EXISTS (SELECT name FROM sysobjects          
WHERE name = 'InterBranchAccts' )                     
	DROP VIEW InterBranchAccts 
				
SELECT @root_org =organization_id FROM Organization_all WHERE	outline_num = '1' 	
IF @root_org is null or @root_org = ''
BEGIN
	RAISERROR ('Organization.organization_id field is null or empty.', 16, 1)
	RETURN 0
END


SELECT @buf2 = 'CREATE  VIEW InterBranchAccts AS '

IF EXISTS ( SELECT 1 FROM glco WHERE  ib_flag =0)
	BEGIN	
				
		IF  EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=1 )
			BEGIN				
				SELECT 'InterOrg turned off + security turned on'

				SELECT @buf =	' 
					SELECT 
						gc.timestamp,
						gc.account_code,
						gc.account_description,
						gc.account_type,
						gc.new_flag,
						gc.seg1_code,
						gc.seg2_code,
						gc.seg3_code,
						gc.seg4_code,
						gc.consol_detail_flag,
						gc.consol_type,
						gc.active_date,
						gc.inactive_date,
						gc.inactive_flag,
						gc.currency_code,
						gc.revaluate_flag,
						gc.rate_type_home, 
						gc.rate_type_oper,
						CONVERT(varchar(30), '''  + @root_org+ ''' ) org_id,			
						CONVERT (int, 0) ib_flag,
						CONVERT(varchar(8), '''  + @company_code+ ''' ) company_code
					FROM    glchart gc 
					WHERE 	account_code  IN (SELECT account_code FROM sm_accounts_access_co_vw)'
			END
		ELSE
			BEGIN				
				SELECT 'InterOrg turned off + security turned off'
				SELECT @buf =	' 
					SELECT 
						gc.timestamp,
						gc.account_code,
						gc.account_description,
						gc.account_type,
						gc.new_flag,
						gc.seg1_code,
						gc.seg2_code,
						gc.seg3_code,
						gc.seg4_code,
						gc.consol_detail_flag,
						gc.consol_type,
						gc.active_date,
						gc.inactive_date,
						gc.inactive_flag,
						gc.currency_code,
						gc.revaluate_flag,
						gc.rate_type_home, 
						gc.rate_type_oper,
						CONVERT(varchar(30), '''  + @root_org + ''' ) org_id,			
						CONVERT (int, 0) ib_flag,
						CONVERT(varchar(8), '''  + @company_code + ''' ) company_code
					FROM    glchart gc '
			END				
	END
ELSE
	BEGIN
	  
	IF  EXISTS (SELECT 1 WHERE dbo.sm_ext_security_is_installed_fn()=1 )
			BEGIN
				
				SELECT 'InterOrg turned on + security turned on'
				SELECT @buf =	' 
					SELECT 
					gc.timestamp,
					gc.account_code,
					gc.account_description,
					gc.account_type,
					gc.new_flag,
					gc.seg1_code,
					gc.seg2_code,
					gc.seg3_code,
					gc.seg4_code,
					gc.consol_detail_flag,
					gc.consol_type,
					gc.active_date,
					gc.inactive_date,
					gc.inactive_flag,
					gc.currency_code,
					gc.revaluate_flag,
					gc.rate_type_home, 
					gc.rate_type_oper,
					gc.organization_id org_id,
					CONVERT (int, 1) ib_flag,
					CONVERT(varchar(8), '''  + @company_code+ ''' ) company_code
				FROM glchart gc
					WHERE account_code  IN (SELECT account_code FROM sm_accounts_access_co_vw) '

			END
		ELSE
			BEGIN				
				SELECT 'InterOrg turned on + security turned off'

				SELECT @buf =	' 
					SELECT 
					gc.timestamp,
					gc.account_code,
					gc.account_description,
					gc.account_type,
					gc.new_flag,
					gc.seg1_code,
					gc.seg2_code,
					gc.seg3_code,
					gc.seg4_code,
					gc.consol_detail_flag,
					gc.consol_type,
					gc.active_date,
					gc.inactive_date,
					gc.inactive_flag,
					gc.currency_code,
					gc.revaluate_flag,
					gc.rate_type_home, 
					gc.rate_type_oper,
					gc.organization_id org_id,
					CONVERT (int, 1) ib_flag,
					CONVERT(varchar(8), '''  + @company_code+ ''' ) company_code
				FROM glchart gc '
					 				
	END
END

if (@buf2 + @buf) is null or (@buf2 + @buf) = ''
	RAISERROR ('InterBranchAccts_reg_sp string to create view is null or empty.', 16, 1)
EXEC ( @buf2 + @buf )
GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON InterBranchAccts TO PUBLIC     

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[InterBranchAccts_reg_sp] TO [public]
GO
