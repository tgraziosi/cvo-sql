SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE FUNCTION [dbo].[sm_taxcode_vs_org_fn] (@taxcode varchar(8), @org_id varchar(30))
RETURNS smallint
BEGIN		
		DECLARE @ret SMALLINT
		SELECT @ret = CASE WHEN COUNT (access) = 0 THEN 1 ELSE 0 END
		FROM (
		SELECT  dbo.sm_account_vs_org_fn( dbo.IBAcctMask_fn(t.sales_tax_acct_code,@org_id) , @org_id)  access
			FROM 	artax h, artaxdet d, artxtype t
			WHERE h.tax_code = d.tax_code  
			AND t.tax_type_code = d.tax_type_code
			AND h.tax_code = @taxcode
		GROUP BY t.sales_tax_acct_code 
		) a
		WHERE a.access =0

	RETURN @ret
END
GO
GRANT REFERENCES ON  [dbo].[sm_taxcode_vs_org_fn] TO [public]
GO
GRANT EXECUTE ON  [dbo].[sm_taxcode_vs_org_fn] TO [public]
GO
