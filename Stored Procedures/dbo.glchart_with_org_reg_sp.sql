SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2007 Epicor Software Corporation, 2007    
                  All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[glchart_with_org_reg_sp] 
AS

DECLARE @ib_flag smallint, @ib_segment smallint, @ib_offset smallint, @ib_length smallint, @buf varchar(8000), @initial_pos smallint

	SELECT @ib_flag  = 0, @ib_segment = 0, @ib_offset = 0, @ib_length = 0

	SELECT @ib_flag = ib_flag, @ib_segment = ib_segment, @ib_offset = ib_offset, @ib_length = ib_length 
	FROM glco

	IF (@ib_segment = 1 ) 
		SELECT @initial_pos = @ib_offset
	ELSE IF (@ib_segment = 2 ) 
		SELECT @initial_pos = MAX(len(seg_code)) + @ib_offset FROM glseg1
	ELSE IF (@ib_segment = 3 ) 
		BEGIN
			SELECT @initial_pos = MAX(len(seg_code)) FROM glseg1
			SELECT @initial_pos = @initial_pos + MAX(len(seg_code)) + @ib_offset FROM glseg2
		END
	ELSE IF (@ib_segment = 4 ) 
		BEGIN
			SELECT @initial_pos = MAX(len(seg_code)) FROM glseg1
			SELECT @initial_pos = @initial_pos + MAX(len(seg_code)) FROM glseg2
			SELECT @initial_pos = @initial_pos + MAX(len(seg_code)) + @ib_offset FROM glseg3
		END

	SELECT @buf = 'IF EXISTS (SELECT name FROM sysobjects WHERE type = ''V'' AND name = ''glchart_with_org_vw'' ) DROP VIEW glchart_with_org_vw   '
	EXEC (@buf)

	SELECT @buf = 'CREATE VIEW glchart_with_org_vw AS '

	IF (@ib_flag = 0 )
		BEGIN
			SELECT @buf = @buf + 'SELECT  (SELECT organization_id FROM Organization_all WHERE outline_num = ''1'') org_id , account_code , account_description, account_type from glchart '
		END
	ELSE
		BEGIN

			SELECT @buf = @buf + 'SELECT (CASE WHEN (SELECT organization_id FROM Organization_all o WHERE substring(account_code,' + convert(varchar(10),@initial_pos) + ',' + convert(varchar(10),@ib_length) + ') = o.branch_account_number) is null '
			SELECT @buf = @buf + ' then (SELECT organization_id FROM Organization_all WHERE outline_num = ''1'') else '
			SELECT @buf = @buf + '	(SELECT organization_id FROM Organization_all o WHERE substring(account_code,' + convert(varchar(10),@initial_pos) + ',' + convert(varchar(10),@ib_length) + ')= o.branch_account_number) end) '
			SELECT @buf = @buf + ' org_id ,  account_code , account_description, account_type '
			SELECT @buf = @buf + ' from glchart '
		END

	EXEC (@buf)

	SELECT @buf = 'IF EXISTS (SELECT name FROM sysobjects WHERE type = ''V'' AND name = ''glchart_with_org_vw'' ) GRANT ALL ON glchart_with_org_vw TO PUBLIC   '
	EXEC (@buf)
GO
GRANT EXECUTE ON  [dbo].[glchart_with_org_reg_sp] TO [public]
GO
