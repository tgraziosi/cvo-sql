SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[CVO_CS_rx_bo_summary_vw]
AS

-- created by Elizabeth LaBarbera   3/22/2012
SELECT     TOP (100) PERCENT t3.type_code, t1.part_no, t3.description, SUM(t1.ordered) AS 'QTY ON BO'
FROM         dbo.ord_list AS t1 WITH (nolock) INNER JOIN
                      dbo.orders_all AS t2 WITH (nolock) ON t1.order_no = t2.order_no AND t1.order_ext = t2.ext INNER JOIN
                      dbo.inv_master AS t3 WITH (nolock) ON t1.part_no = t3.part_no
WHERE     (t2.status NOT IN ('t', 'v')) AND (t2.sch_ship_date <= GETDATE() - 1) AND (t2.type = 'i') AND (t3.type_code IN ('frame', 'sun', 'parts')) AND (t2.user_category LIKE 'RX%')
GROUP BY t3.type_code, t1.part_no, t3.description
ORDER BY t3.type_code, t1.part_no, t3.description
GO
GRANT CONTROL ON  [dbo].[CVO_CS_rx_bo_summary_vw] TO [public]
GO
GRANT REFERENCES ON  [dbo].[CVO_CS_rx_bo_summary_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_CS_rx_bo_summary_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_CS_rx_bo_summary_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_CS_rx_bo_summary_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_CS_rx_bo_summary_vw] TO [public]
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
               Bottom = 125
               Right = 259
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t2"
            Begin Extent = 
               Top = 6
               Left = 297
               Bottom = 125
               Right = 497
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t3"
            Begin Extent = 
               Top = 6
               Left = 535
               Bottom = 125
               Right = 747
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
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
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
', 'SCHEMA', N'dbo', 'VIEW', N'CVO_CS_rx_bo_summary_vw', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'CVO_CS_rx_bo_summary_vw', NULL, NULL
GO
