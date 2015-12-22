SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[attaxvend]
AS
      SELECT a.vendor_code, a.at_tax_code
      FROM atapvend a WITH( NOLOCK ), attax b, atco c 
      WHERE c.voprocs_invoice_taxflag = 1
            AND a.at_tax_code = b.tax_code
GO
GRANT SELECT ON  [dbo].[attaxvend] TO [public]
GO
GRANT INSERT ON  [dbo].[attaxvend] TO [public]
GO
GRANT DELETE ON  [dbo].[attaxvend] TO [public]
GO
GRANT UPDATE ON  [dbo].[attaxvend] TO [public]
GO
