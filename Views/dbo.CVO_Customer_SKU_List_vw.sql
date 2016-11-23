SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[CVO_Customer_SKU_List_vw]
AS
    SELECT TOP ( 100 ) PERCENT
            t1.category AS Collection ,
            t1.part_no AS ItemCode ,
            t2.field_2 AS Model ,
            t1.type_code AS Type ,
            t1.cmdty_code AS Material ,
            t2.category_2 AS demographic ,
            t3.price_a AS ListPrice ,
            CONVERT(VARCHAR, t2.field_26, 101) AS ReleaseDate ,
            t2.field_3 AS Color ,
            LEFT(t2.field_17, 2) + '/' + t2.field_6 + '/' + t2.field_8 AS Size ,
			ISNULL(t2.field_23,'') AS Sun_Lens_Color, -- 11/21/2016 - add for suns
            t1.upc_code
    FROM    dbo.inv_master AS t1 WITH ( NOLOCK )
            INNER JOIN dbo.inv_master_add AS t2 WITH ( NOLOCK ) ON t1.part_no = t2.part_no
            INNER JOIN dbo.part_price AS t3 WITH ( NOLOCK ) ON t1.part_no = t3.part_no
            INNER JOIN inv_list inv ( NOLOCK ) ON inv.part_no = t1.part_no
    WHERE   t2.field_26 < GETDATE() + 30
            AND inv.location = '001'
            AND ( ( t1.type_code IN ( 'sun', 'frame' ) )
                  AND ( t2.field_28 > GETDATE() )
                  OR ( t1.type_code IN ( 'sun', 'frame' ) )
                  AND ( t2.field_28 IS NULL )
                )

-- tag - 082312 - exclude voided items
            AND t1.void <> 'V'
    ORDER BY Collection ,
            Model ,
            ItemCode;


GO
GRANT CONTROL ON  [dbo].[CVO_Customer_SKU_List_vw] TO [public]
GO
GRANT REFERENCES ON  [dbo].[CVO_Customer_SKU_List_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_Customer_SKU_List_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_Customer_SKU_List_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_Customer_SKU_List_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_Customer_SKU_List_vw] TO [public]
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
               Right = 234
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t2"
            Begin Extent = 
               Top = 6
               Left = 272
               Bottom = 125
               Right = 432
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t3"
            Begin Extent = 
               Top = 6
               Left = 470
               Bottom = 125
               Right = 668
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
', 'SCHEMA', N'dbo', 'VIEW', N'CVO_Customer_SKU_List_vw', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'CVO_Customer_SKU_List_vw', NULL, NULL
GO
