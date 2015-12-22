SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[ib_glchart_reg_sp]
AS

IF NOT EXISTS(SELECT 1 FROM Organization_all WHERE outline_num = '1')
	RETURN 0




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


IF (@ib_segment = 0 AND (@ib_flag = 1 OR @ib_flag = 2))
	RETURN 0


IF EXISTS (SELECT name FROM sysobjects          
WHERE name = 'ib_glchart_vw' )                     
	DROP VIEW ib_glchart_vw 
				
SELECT @root_org =organization_id FROM Organization_all WHERE	outline_num = '1' 	


SELECT @buf2 = 'CREATE  VIEW ib_glchart_vw AS '

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
					WHERE 	account_code  IN (SELECT account_code FROM sm_accounts_access_vw)'
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
					WHERE  account_code  IN (SELECT account_code FROM sm_accounts_access_vw) '

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

EXEC ( @buf2 + @buf )
GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON ib_glchart_vw TO PUBLIC     
GO
GRANT EXECUTE ON  [dbo].[ib_glchart_reg_sp] TO [public]
GO
