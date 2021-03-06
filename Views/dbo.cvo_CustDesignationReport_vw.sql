SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[cvo_CustDesignationReport_vw]
AS
SELECT TOP (100) PERCENT
    t2.territory_code,
    t1.customer_code,
    t2.address_name,
    t2.addr2,
    CASE
        WHEN t2.addr3 LIKE '%, __ %' THEN
            ''
        ELSE
            t2.addr3
    END AS addr3,
    city,
    state,
    postal_code AS Zip,
    country_code AS CC,
    t1.code,
    t3.description,
    CASE
        WHEN primary_flag = 1 THEN
            'Y'
        ELSE
            ''
    END AS Pri,
    t1.start_date,
    t1.end_date,
    t2.price_code price_class -- 042015 - LF request
FROM
    dbo.cvo_cust_designation_codes AS t1
    INNER JOIN dbo.armaster AS t2
        ON t1.customer_code = t2.customer_code
    INNER JOIN dbo.cvo_designation_codes AS t3
        ON t1.code = t3.code
WHERE (t2.address_type = 0)
ORDER BY
    t1.code, t1.customer_code
;



GO
GRANT REFERENCES ON  [dbo].[cvo_CustDesignationReport_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_CustDesignationReport_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_CustDesignationReport_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_CustDesignationReport_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_CustDesignationReport_vw] TO [public]
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
               Right = 192
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t2"
            Begin Extent = 
               Top = 6
               Left = 230
               Bottom = 121
               Right = 440
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t3"
            Begin Extent = 
               Top = 6
               Left = 478
               Bottom = 121
               Right = 630
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
', 'SCHEMA', N'dbo', 'VIEW', N'cvo_CustDesignationReport_vw', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'cvo_CustDesignationReport_vw', NULL, NULL
GO
