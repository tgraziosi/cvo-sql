SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[CVO_Promo_Override_VW]
AS
SELECT DISTINCT 
                      TOP (100) PERCENT t1.ship_to_region AS Terr, t1.cust_code AS Customer, t1.order_no, t1.status, t1.req_ship_date, t2.promo_id, t2.promo_level, 
                      CAST(SUM(t3.ordered) AS DECIMAL(12, 0)) AS OrgPcsOrd, Ovr2.Moverride_date AS OverrideDate, t4.override_user 
                      AS Override_User, t4.failure_reason AS Failure_Reason
FROM         dbo.orders_all AS t1 WITH (nolock) INNER JOIN
                      dbo.CVO_orders_all AS t2 WITH (nolock) ON t1.order_no = t2.order_no AND t1.ext = t2.ext INNER JOIN
                      dbo.ord_list AS t3 WITH (nolock) ON t1.order_no = t3.order_no AND t1.ext = t3.order_ext LEFT OUTER JOIN
                          (SELECT     order_no, MAX(override_date) AS Moverride_date
                            FROM          dbo.cvo_promo_override_audit
                            GROUP BY order_no) AS Ovr2 ON t1.order_no = Ovr2.order_no INNER JOIN
                      dbo.cvo_promo_override_audit AS t4 ON t1.order_no = t4.order_no AND t1.ext = t4.order_ext AND t4.override_date = Ovr2.Moverride_date AND 
                      Ovr2.order_no = t4.order_no
WHERE     (t1.ext = '0') AND (t1.status <> 'v') AND (t2.promo_id IS NOT NULL) AND (t2.promo_id <> '') AND (t3.part_no NOT LIKE '__z%') AND 
                      (t3.part_no NOT LIKE '%case%')
GROUP BY t1.ship_to_region, t1.cust_code, t1.order_no, t1.status, t1.req_ship_date, t2.promo_id, t2.promo_level, Ovr2.Moverride_date, t4.override_user, 
                      t4.failure_reason
ORDER BY t2.promo_id, t2.promo_level, t1.req_ship_date, t1.order_no

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
         Begin Table = "t1"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 121
               Right = 230
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t2"
            Begin Extent = 
               Top = 6
               Left = 268
               Bottom = 121
               Right = 484
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t3"
            Begin Extent = 
               Top = 6
               Left = 522
               Bottom = 121
               Right = 735
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Ovr2"
            Begin Extent = 
               Top = 6
               Left = 773
               Bottom = 91
               Right = 946
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t4"
            Begin Extent = 
               Top = 6
               Left = 984
               Bottom = 121
               Right = 1152
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
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Outp', 'SCHEMA', N'dbo', 'VIEW', N'CVO_Promo_Override_VW', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N'ut = 720
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
', 'SCHEMA', N'dbo', 'VIEW', N'CVO_Promo_Override_VW', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=2
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'CVO_Promo_Override_VW', NULL, NULL
GO
