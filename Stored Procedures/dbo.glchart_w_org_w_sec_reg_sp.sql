SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE PROC [dbo].[glchart_w_org_w_sec_reg_sp] 
AS

DECLARE @ib_flag smallint, @buf varchar(8000)

	SELECT @ib_flag  = 0

	SELECT @ib_flag = ib_flag
	FROM glco

	SELECT @buf = 'IF EXISTS (SELECT name FROM sysobjects WHERE type = ''V'' AND name = ''glchart_w_org_w_sec_vw'' ) DROP VIEW glchart_w_org_w_sec_vw   '
	EXEC (@buf)

	SELECT @buf = 'CREATE VIEW glchart_w_org_w_sec_vw AS '

	IF (@ib_flag = 0 )
		BEGIN
			SELECT @buf = @buf + 'SELECT  (SELECT organization_id FROM Organization_all WHERE outline_num = ''1'') org_id , account_code , account_description, account_type from glchart '
		END
	ELSE
		BEGIN
			SELECT @buf = @buf + 'SELECT org_id , account_code , account_description, account_type  from ib_glchart_vw'
		END

	EXEC (@buf)

	SELECT @buf = 'IF EXISTS (SELECT name FROM sysobjects WHERE type = ''V'' AND name = ''glchart_w_org_w_sec_vw'' ) GRANT ALL ON glchart_w_org_w_sec_vw TO PUBLIC   '
	EXEC (@buf)

GO
GRANT EXECUTE ON  [dbo].[glchart_w_org_w_sec_reg_sp] TO [public]
GO
