SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[CVO_INV_CRED_ALL_VW]
AS
-- All Invoices / Credits Live and Epicor

select	
	m.address_name,
	x.customer_code,
	x.ship_to_code,
	x.doc_ctrl_num,
	x.trx_ctrl_num,
	amt_inv=x.amt_tot_chg,
	x.amt_freight,
	x.amt_tax,
	x.amt_paid_to_date,
	unpaid_balance=x.amt_tot_chg - x.amt_paid_to_date,
convert(varchar,dateadd(day,x.date_doc - 711858,'1/1/1950'),101) date_doc,
convert(varchar,dateadd(day,x.date_applied - 711858,'1/1/1950'),101) date_applied,
convert(varchar,dateadd(day,x.date_due - 711858,'1/1/1950'),101) date_due,
	x.cust_po_num,
	x.order_ctrl_num,
CASE WHEN x.apply_trx_type = '2031' THEN 'Invoice' WHEN x.apply_trx_type = '2032' THEN 'Credit' End as trx_type,
m.territory_code,
m.salesperson_code
from	artrx x, armaster m
where	x.customer_code = m.customer_code
and	m.address_type = 0
and	x.doc_ctrl_num = x.apply_to_num
and	x.trx_type = x.apply_trx_type
and	x.trx_type in ('2031','2032')
--and m.customer_code = @CUST

UNION 

SELECT 
	m.address_name,
	x.customer_code,
	x.ship_to_code,
	x.doc_ctrl_num,
	x.trx_ctrl_num,
	amt_inv=x.amt_net,
	x.amt_freight,
	x.amt_tax,
	amt_paid_to_date=x.amt_paid,
	unpaid_balance=x.amt_net - x.amt_paid,
convert(varchar,dateadd(day,x.date_doc - 711858,'1/1/1950'),101) date_doc,
convert(varchar,dateadd(day,x.date_applied - 711858,'1/1/1950'),101) date_applied,
convert(varchar,dateadd(day,x.date_due - 711858,'1/1/1950'),101) date_due,
	x.cust_po_num,
	x.order_ctrl_num,
CASE WHEN x.apply_trx_type = '2031' THEN 'Invoice' WHEN x.apply_trx_type = '2032' THEN 'Credit' End as trx_type,
m.territory_code,
m.salesperson_code
from	arinpchg x, armaster m
where	x.customer_code = m.customer_code
and	x.trx_type IN ('2031','2032')
--and m.customer_code = @CUST
GO
GRANT REFERENCES ON  [dbo].[CVO_INV_CRED_ALL_VW] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_INV_CRED_ALL_VW] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_INV_CRED_ALL_VW] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_INV_CRED_ALL_VW] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_INV_CRED_ALL_VW] TO [public]
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', N'dbo', 'VIEW', N'CVO_INV_CRED_ALL_VW', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'CVO_INV_CRED_ALL_VW', NULL, NULL
GO
