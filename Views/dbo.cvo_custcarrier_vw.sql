SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/*where t1.customer_code = '014121'
select * from cust_carrier_account  */
CREATE VIEW [dbo].[cvo_custcarrier_vw]
AS
SELECT TOP (100) PERCENT 
t1.customer_code, 
t1.ship_to_code, 
t1.address_name, 
t1.city, t1.state, t1.postal_code, t1.country, 
t1.status_type,
isnull(t1.freight_code,'') as freight_code, 
t1.fob_code, 
cv.freight_charge, 
ISNULL(t1.ship_via_code, '') AS Carrier, 
ISNULL(cca1.account, '') AS Carrier_account, ISNULL(cv.rx_carrier, '') 
AS Rx_carrier, ISNULL(ccarx.account, '') AS Rx_account, 
ISNULL(cv.bo_carrier, '') AS Bo_carrier, ISNULL(ccabo.account, '') AS Bo_account
-- 11/25/2013 - only select sold-to customers.
FROM  dbo.armaster_all AS t1
LEFT OUTER JOIN dbo.CVO_armaster_all AS cv ON t1.customer_code = cv.customer_code AND t1.ship_to_code = cv.ship_to 
LEFT OUTER JOIN dbo.cust_carrier_account AS cca1 ON t1.customer_code = cca1.cust_code AND t1.ship_to_code = cca1.ship_to AND t1.ship_via_code = cca1.routing 
LEFT OUTER JOIN dbo.cust_carrier_account AS ccarx ON t1.customer_code = ccarx.cust_code AND t1.ship_to_code = ccarx.ship_to AND 
               cv.rx_carrier = ccarx.routing 
LEFT OUTER JOIN dbo.cust_carrier_account AS ccabo ON t1.customer_code = ccabo.cust_code AND t1.ship_to_code = ccabo.ship_to AND cv.bo_carrier = ccabo.routing
where t1.address_type <> 1 -- no drop ships
ORDER BY t1.customer_code



GO
GRANT REFERENCES ON  [dbo].[cvo_custcarrier_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_custcarrier_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_custcarrier_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_custcarrier_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_custcarrier_vw] TO [public]
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[13] 2[16] 3) )"
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
         Begin Table = "t1"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 135
               Right = 283
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "cv"
            Begin Extent = 
               Top = 7
               Left = 331
               Bottom = 135
               Right = 552
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "cca1"
            Begin Extent = 
               Top = 7
               Left = 600
               Bottom = 135
               Right = 789
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ccarx"
            Begin Extent = 
               Top = 140
               Left = 48
               Bottom = 268
               Right = 283
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ccabo"
            Begin Extent = 
               Top = 149
               Left = 330
               Bottom = 277
               Right = 519
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 17
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         W', 'SCHEMA', N'dbo', 'VIEW', N'cvo_custcarrier_vw', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N'idth = 1200
         Width = 1200
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
', 'SCHEMA', N'dbo', 'VIEW', N'cvo_custcarrier_vw', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=2
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'cvo_custcarrier_vw', NULL, NULL
GO
