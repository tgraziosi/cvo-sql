SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                

CREATE PROCEDURE [dbo].[am_glchart_root_reg_sp]
AS

IF NOT EXISTS(SELECT 1 FROM Organization_all )
	RETURN 0


DECLARE @buf varchar(8000)
DECLARE @buf2 varchar(8000)
DECLARE @company_code varchar(8)
DECLARE @ib_segment  int
DECLARE @ib_offset  int
DECLARE @ib_length int
DECLARE @root_org varchar(30)

SELECT @company_code=company_code,@ib_segment =ib_segment, 
	@ib_offset =ib_offset, @ib_length =ib_length  
FROM glco
		
IF (@ib_segment = 0)
	RETURN 0

SELECT @root_org =organization_id FROM Organization_all WHERE	outline_num = '1' 	


IF EXISTS (SELECT name FROM sysobjects   WHERE name = 'am_glchart_root_vw' )                     
	DROP VIEW am_glchart_root_vw                             


SELECT @buf2 = 'CREATE  VIEW am_glchart_root_vw AS '

IF EXISTS ( SELECT 1 FROM glco WHERE  ib_flag =0)
	BEGIN	
							
		SELECT @buf =	' SELECT 	coa.timestamp,
			coa.account_code, 
			coa.account_description,
			coa.account_type,
			coa.new_flag,
			coa.seg1_code,
			coa.seg2_code,
			coa.seg3_code,
			coa.seg4_code,
			coa.consol_detail_flag,
			coa.consol_type,
			coa.active_date,
			coa.inactive_date,
			coa.inactive_flag,
			coa.currency_code,
			coa.revaluate_flag,
			coa.rate_type_home,
			coa.rate_type_oper 
			FROM glchart coa '
	END
ELSE
	BEGIN	  			
		SELECT @buf =	' SELECT 	coa.timestamp,
				coa.account_code, 
				coa.account_description,
				coa.account_type,
				coa.new_flag,
				coa.seg1_code,
				coa.seg2_code,
				coa.seg3_code,
				coa.seg4_code,
				coa.consol_detail_flag,
				coa.consol_type,
				coa.active_date,
				coa.inactive_date,
				coa.inactive_flag,
				coa.currency_code,
				coa.revaluate_flag,
				coa.rate_type_home,
				coa.rate_type_oper 

			FROM 	glchart coa, Organization_all o
			WHERE 
				substring (seg'+CONVERT (varchar,@ib_segment)+'_code,'+ CONVERT (varchar,@ib_offset)+',' + CONVERT (varchar,@ib_length)+') = o.branch_account_number 			 	
				AND o.organization_id = ''' + @root_org  + ''''

/*
		AND account_code  IN (SELECT account_code FROM sm_accounts_access_co_vw) '					
*/
	END


EXEC ( @buf2 + @buf )
GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE ON am_glchart_root_vw TO PUBLIC     

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[am_glchart_root_reg_sp] TO [public]
GO
